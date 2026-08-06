import UIKit
import AVFoundation

/// Renders a "collage video" for a milestone list entirely on-device — Ken Burns pans across
/// each captured photo, crossfade transitions between them, a title/date caption per item, and
/// branded intro/outro cards. No server round trip, no Wiro credits: this is frame-by-frame
/// Core Graphics rendering fed into an AVAssetWriter, then (optionally) muxed with a bundled
/// background music track.
enum MilestoneVideoRenderer {
    enum RendererError: Error { case noItems, writerFailed, exportFailed }

    struct Item {
        let title: String
        let image: UIImage
        let capturedAt: Date?
    }

    // MARK: - Tunables

    /// 9:16 vertical — ready to share straight to Stories/Reels/TikTok.
    private static let canvasSize = CGSize(width: 1080, height: 1920)
    private static let fps: Int32 = 30
    private static let introDuration: TimeInterval = 1.6
    private static let outroDuration: TimeInterval = 1.8
    private static let itemHoldDuration: TimeInterval = 2.4
    private static let crossfadeDuration: TimeInterval = 0.5
    /// Ken Burns end-state zoom — the far end of the pan is this fraction of the full "cover"
    /// crop, i.e. roughly a 1/0.86 ≈ 1.16x zoom across the segment.
    private static let kenBurnsZoomFactor: CGFloat = 0.86

    /// A single frame-content source in the output timeline — a card or a photo. `render` takes
    /// the segment's own local progress (0...1, independent of any crossfade blending) and
    /// returns a full-canvas frame with no transition alpha applied yet.
    private struct Segment {
        let duration: TimeInterval
        let render: (CGFloat) -> UIImage
    }

    // MARK: - Public entry point

    static func renderCollage(listName: String, items: [Item], progress: @escaping (Float) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let url = try renderSync(listName: listName, items: items, progress: progress)
                DispatchQueue.main.async { completion(.success(url)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    // MARK: - Rendering pipeline

    private static func renderSync(listName: String, items: [Item], progress: @escaping (Float) -> Void) throws -> URL {
        guard !items.isEmpty else { throw RendererError.noItems }

        var segments: [Segment] = [Segment(duration: introDuration) { t in introCardFrame(listName: listName, progress: t) }]
        for (index, item) in items.enumerated() {
            segments.append(Segment(duration: itemHoldDuration) { t in itemFrame(item: item, index: index, progress: t) })
        }
        segments.append(Segment(duration: outroDuration) { t in outroCardFrame(progress: t) })

        // Consecutive segments overlap by crossfadeDuration, so the output timeline is shorter
        // than the sum of each segment's own duration.
        let transitionCount = segments.count - 1
        let totalDuration = segments.reduce(0) { $0 + $1.duration } - Double(transitionCount) * crossfadeDuration
        var segmentStarts: [TimeInterval] = []
        var cursor: TimeInterval = 0
        for (i, seg) in segments.enumerated() {
            segmentStarts.append(cursor)
            cursor += seg.duration
            if i < segments.count - 1 { cursor -= crossfadeDuration }
        }

        let videoOnlyURL = try writeVideoTrack(segments: segments, segmentStarts: segmentStarts, totalDuration: totalDuration, progress: progress)
        progress(0.9)
        let finalURL = try muxAudioIfAvailable(videoURL: videoOnlyURL, videoDuration: totalDuration)
        progress(1.0)
        return finalURL
    }

    private static func writeVideoTrack(segments: [Segment], segmentStarts: [TimeInterval], totalDuration: TimeInterval, progress: @escaping (Float) -> Void) throws -> URL {
        let outputURL = tempOutputURL()
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: canvasSize.width,
            AVVideoHeightKey: canvasSize.height,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 6_000_000]
        ]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writerInput.expectsMediaDataInRealTime = false
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: canvasSize.width,
            kCVPixelBufferHeightKey as String: canvasSize.height
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: pixelBufferAttributes)
        guard writer.canAdd(writerInput) else { throw RendererError.writerFailed }
        writer.add(writerInput)
        guard writer.startWriting() else { throw RendererError.writerFailed }
        writer.startSession(atSourceTime: .zero)

        let totalFrames = max(1, Int((totalDuration * Double(fps)).rounded()))
        var frameIndex = 0
        let doneSemaphore = DispatchSemaphore(value: 0)
        let writingQueue = DispatchQueue(label: "MilestoneVideoRenderer.writing")

        writerInput.requestMediaDataWhenReady(on: writingQueue) {
            while writerInput.isReadyForMoreMediaData {
                guard frameIndex < totalFrames else {
                    writerInput.markAsFinished()
                    doneSemaphore.signal()
                    return
                }
                autoreleasepool {
                    let t = Double(frameIndex) / Double(fps)
                    let frameImage = renderFrame(at: t, segments: segments, segmentStarts: segmentStarts)
                    if let buffer = makePixelBuffer(from: frameImage, pool: adaptor.pixelBufferPool) {
                        let pts = CMTime(value: CMTimeValue(frameIndex), timescale: fps)
                        adaptor.append(buffer, withPresentationTime: pts)
                    }
                }
                frameIndex += 1
                if frameIndex % 6 == 0 {
                    progress(Float(frameIndex) / Float(totalFrames) * 0.85)
                }
            }
        }
        doneSemaphore.wait()

        let finishSemaphore = DispatchSemaphore(value: 0)
        writer.finishWriting { finishSemaphore.signal() }
        finishSemaphore.wait()
        guard writer.status == .completed else { throw RendererError.writerFailed }
        return outputURL
    }

    /// Composites the active segment's frame with the next segment's frame during a crossfade
    /// window; otherwise just the active segment's own frame.
    private static func renderFrame(at time: TimeInterval, segments: [Segment], segmentStarts: [TimeInterval]) -> UIImage {
        var index = 0
        for i in segments.indices where segmentStarts[i] <= time { index = i }
        let seg = segments[index]
        let localT = CGFloat(min(1, max(0, (time - segmentStarts[index]) / seg.duration)))
        let currentImage = seg.render(localT)

        let segEnd = segmentStarts[index] + seg.duration
        let nextIndex = index + 1
        guard nextIndex < segments.count else { return currentImage }
        let overlapStart = segEnd - crossfadeDuration
        guard time >= overlapStart else { return currentImage }

        let alpha = CGFloat(min(1, max(0, (time - overlapStart) / crossfadeDuration)))
        let nextSeg = segments[nextIndex]
        let nextLocalT = CGFloat(min(1, max(0, (time - segmentStarts[nextIndex]) / nextSeg.duration)))
        let nextImage = nextSeg.render(nextLocalT)
        return blend(currentImage, nextImage, alpha: alpha)
    }

    private static func blend(_ base: UIImage, _ overlay: UIImage, alpha: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { _ in
            base.draw(in: CGRect(origin: .zero, size: canvasSize))
            overlay.draw(in: CGRect(origin: .zero, size: canvasSize), blendMode: .normal, alpha: alpha)
        }
    }

    // MARK: - Frame content

    private static func itemFrame(item: Item, index: Int, progress t: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { ctx in
            drawKenBurnsImage(item.image, index: index, progress: t, in: ctx.cgContext)
            drawBottomScrim(in: ctx.cgContext)
            drawCaption(title: item.title, date: item.capturedAt)
        }
    }

    private static func drawKenBurnsImage(_ image: UIImage, index: Int, progress t: CGFloat, in context: CGContext) {
        let canvasAspect = canvasSize.width / canvasSize.height
        guard let cgImage = image.cgImage else { return }
        let pixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        let base = coverRect(imageSize: pixelSize, targetAspect: canvasAspect)

        let endW = base.width * kenBurnsZoomFactor
        let endH = base.height * kenBurnsZoomFactor
        let maxDX = base.width - endW
        let maxDY = base.height - endH
        // Alternate pan direction per item so consecutive photos don't all drift the same way.
        let dir: CGFloat = index % 2 == 0 ? 1 : -1
        let zoomedIn = CGRect(
            x: base.minX + maxDX / 2 + dir * maxDX / 2 * 0.7,
            y: base.minY + maxDY / 2 - dir * maxDY / 2 * 0.5,
            width: endW,
            height: endH
        )
        // Even items zoom IN over the hold (wide -> tight); odd items zoom OUT (tight -> wide) —
        // more visual variety than every photo moving the same way.
        let start = index % 2 == 0 ? base : zoomedIn
        let end = index % 2 == 0 ? zoomedIn : base

        let interpolated = CGRect(
            x: start.minX + (end.minX - start.minX) * t,
            y: start.minY + (end.minY - start.minY) * t,
            width: start.width + (end.width - start.width) * t,
            height: start.height + (end.height - start.height) * t
        )
        guard let cropped = cgImage.cropping(to: interpolated.integral) else { return }
        context.saveGState()
        context.translateBy(x: 0, y: canvasSize.height)
        context.scaleBy(x: 1, y: -1)
        context.draw(cropped, in: CGRect(origin: .zero, size: canvasSize))
        context.restoreGState()
    }

    /// The largest same-aspect-ratio crop centered in `imageSize` — the "fill" behavior every
    /// theme card/preview in the app already uses (scaleAspectFill), just computed in pixel
    /// space so it can feed a CGImage crop.
    private static func coverRect(imageSize: CGSize, targetAspect: CGFloat) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        if imageAspect > targetAspect {
            let cropWidth = imageSize.height * targetAspect
            return CGRect(x: (imageSize.width - cropWidth) / 2, y: 0, width: cropWidth, height: imageSize.height)
        } else {
            let cropHeight = imageSize.width / targetAspect
            return CGRect(x: 0, y: (imageSize.height - cropHeight) / 2, width: imageSize.width, height: cropHeight)
        }
    }

    private static func drawBottomScrim(in context: CGContext) {
        let scrimHeight = canvasSize.height * 0.3
        let rect = CGRect(x: 0, y: canvasSize.height - scrimHeight, width: canvasSize.width, height: scrimHeight)
        let colors = [UIColor.black.withAlphaComponent(0).cgColor, UIColor.black.withAlphaComponent(0.62).cgColor] as CFArray
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
        context.saveGState()
        context.clip(to: rect)
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: rect.minY), end: CGPoint(x: 0, y: rect.maxY), options: [])
        context.restoreGState()
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private static func drawCaption(title: String, date: Date?) {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: Theme.Font.heading(64, weight: 700),
            .foregroundColor: UIColor.white
        ]
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: Theme.Font.body(40, weight: 600),
            .foregroundColor: UIColor.white.withAlphaComponent(0.82)
        ]
        let margin: CGFloat = 72
        var y = canvasSize.height - 220
        (title as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        if let date {
            y += 84
            (dateFormatter.string(from: date) as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: dateAttrs)
        }
    }

    private static func cardBackground(in context: CGContext) {
        let colors = [UIColor(hex: 0xEDE3F7).cgColor, UIColor(hex: 0xFBE1E7).cgColor, UIColor(hex: 0xFFF1E8).cgColor] as CFArray
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.55, 1]) else { return }
        // Without extending past both ends, CGContext leaves the corner beyond the gradient's
        // end point (the diagonal is shorter than the canvas's own diagonal) unpainted —
        // whatever was already in the freshly-allocated bitmap shows through as a stray black/
        // dark triangle in that corner. Caught via COLLAGE_TEST rendering real frames, not
        // visible from reading the code alone.
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: canvasSize.width * 0.4, y: canvasSize.height), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }

    private static func introCardFrame(listName: String, progress t: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { ctx in
            cardBackground(in: ctx.cgContext)
            let alpha = min(1, t / 0.4) // quick fade-in, then hold
            let subtitle = "Milestone Journey"
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: Theme.Font.body(38, weight: 700),
                .foregroundColor: Theme.Color.textSecondaryAlt.withAlphaComponent(alpha)
            ]
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: Theme.Font.heading(84, weight: 700),
                .foregroundColor: Theme.Color.textPrimaryAlt.withAlphaComponent(alpha)
            ]
            let subtitleSize = (subtitle as NSString).size(withAttributes: subtitleAttrs)
            let titleSize = (listName as NSString).size(withAttributes: titleAttrs)
            let totalHeight = subtitleSize.height + 20 + titleSize.height
            let startY = (canvasSize.height - totalHeight) / 2
            (subtitle as NSString).draw(
                at: CGPoint(x: (canvasSize.width - subtitleSize.width) / 2, y: startY),
                withAttributes: subtitleAttrs
            )
            (listName as NSString).draw(
                at: CGPoint(x: (canvasSize.width - titleSize.width) / 2, y: startY + subtitleSize.height + 20),
                withAttributes: titleAttrs
            )
        }
    }

    private static func outroCardFrame(progress t: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { ctx in
            cardBackground(in: ctx.cgContext)
            let alpha = min(1, t / 0.4)
            let brand = "Newborn Studio"
            let tagline = "Made with"
            let taglineAttrs: [NSAttributedString.Key: Any] = [
                .font: Theme.Font.body(38, weight: 700),
                .foregroundColor: Theme.Color.textSecondaryAlt.withAlphaComponent(alpha)
            ]
            let brandAttrs: [NSAttributedString.Key: Any] = [
                .font: Theme.Font.heading(78, weight: 700),
                .foregroundColor: Theme.Color.accentEnd.withAlphaComponent(alpha)
            ]
            let taglineSize = (tagline as NSString).size(withAttributes: taglineAttrs)
            let brandSize = (brand as NSString).size(withAttributes: brandAttrs)
            let totalHeight = taglineSize.height + 16 + brandSize.height
            let startY = (canvasSize.height - totalHeight) / 2
            (tagline as NSString).draw(
                at: CGPoint(x: (canvasSize.width - taglineSize.width) / 2, y: startY),
                withAttributes: taglineAttrs
            )
            (brand as NSString).draw(
                at: CGPoint(x: (canvasSize.width - brandSize.width) / 2, y: startY + taglineSize.height + 16),
                withAttributes: brandAttrs
            )
        }
    }

    // MARK: - Pixel buffer + file helpers

    private static func makePixelBuffer(from image: UIImage, pool: CVPixelBufferPool?) -> CVPixelBuffer? {
        guard let pool else { return nil }
        var pixelBufferOut: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBufferOut)
        guard let pixelBuffer = pixelBufferOut else { return nil }
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ), let cgImage = image.cgImage else { return nil }
        context.draw(cgImage, in: CGRect(origin: .zero, size: canvasSize))
        return pixelBuffer
    }

    private static func tempOutputURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("milestone-collage-\(UUID().uuidString).mp4")
    }

    /// Mixes in a bundled background-music loop if one exists (`milestone_collage_music.m4a` in
    /// the app bundle) — ships silent otherwise, no missing-asset crash. See PROMPT_TEMPLATE.md-
    /// style note: this hook is ready, the actual track is a separate asset-sourcing step.
    private static func muxAudioIfAvailable(videoURL: URL, videoDuration: TimeInterval) throws -> URL {
        guard let musicURL = Bundle.main.url(forResource: "milestone_collage_music", withExtension: "m4a") else {
            return videoURL
        }

        let composition = AVMutableComposition()
        let videoAsset = AVURLAsset(url: videoURL)
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first,
              let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        else { throw RendererError.exportFailed }
        try compVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoAsset.duration), of: videoTrack, at: .zero)

        let audioAsset = AVURLAsset(url: musicURL)
        var compAudioTrack: AVMutableCompositionTrack?
        if let audioTrack = audioAsset.tracks(withMediaType: .audio).first,
           let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            compAudioTrack = track
            var inserted = CMTime.zero
            // Loop the track to cover the whole video — most background loops are shorter than
            // a multi-item collage.
            while inserted < videoAsset.duration {
                let remaining = videoAsset.duration - inserted
                let clipDuration = CMTimeMinimum(audioAsset.duration, remaining)
                try track.insertTimeRange(CMTimeRange(start: .zero, duration: clipDuration), of: audioTrack, at: inserted)
                inserted = inserted + clipDuration
            }
        }

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw RendererError.exportFailed
        }
        let finalURL = tempOutputURL()
        exportSession.outputURL = finalURL
        exportSession.outputFileType = .mp4

        if let compAudioTrack {
            let params = AVMutableAudioMixInputParameters(track: compAudioTrack)
            let fadeInEnd = CMTime(seconds: 1, preferredTimescale: 600)
            params.setVolumeRamp(fromStartVolume: 0, toEndVolume: 0.4, timeRange: CMTimeRange(start: .zero, duration: fadeInEnd))
            let fadeOutStart = CMTimeMaximum(.zero, videoAsset.duration - CMTime(seconds: 1.5, preferredTimescale: 600))
            params.setVolumeRamp(fromStartVolume: 0.4, toEndVolume: 0, timeRange: CMTimeRange(start: fadeOutStart, duration: videoAsset.duration - fadeOutStart))
            let mix = AVMutableAudioMix()
            mix.inputParameters = [params]
            exportSession.audioMix = mix
        }

        let semaphore = DispatchSemaphore(value: 0)
        exportSession.exportAsynchronously { semaphore.signal() }
        semaphore.wait()
        guard exportSession.status == .completed else { throw RendererError.exportFailed }
        try? FileManager.default.removeItem(at: videoURL)
        return finalURL
    }
}
