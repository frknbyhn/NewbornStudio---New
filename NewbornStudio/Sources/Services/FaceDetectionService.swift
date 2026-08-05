import UIKit
import Vision

/// Gates photo uploads on-device (no network round trip, no server cost) — every generation
/// scenario needs exactly one clear face to produce a sensible portrait.
enum FaceDetectionService {
    enum Outcome {
        case ok
        case noFace
        case multipleFaces
    }

    static func detectFaceCount(in image: UIImage, completion: @escaping (Outcome) -> Void) {
        // Redrawn on the calling thread (expected to be main, since every call site is a picker
        // delegate callback) into a plain 8-bit sRGB bitmap with orientation baked in as .up —
        // sidesteps the wide-gamut/HEIC CGImage format Vision's request handler rejects outright,
        // and keeps UIKit's image drawing off a background thread.
        guard let cgImage = normalizedCGImage(from: image, maxDimension: 1600) else {
            // Nothing to redraw (degenerate zero-size image) — not evidence one way or the
            // other about a face, so don't block on it.
            DispatchQueue.main.async { completion(.ok) }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let request = VNDetectFaceRectanglesRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            do {
                try handler.perform([request])
                let count = request.results?.count ?? 0
                DispatchQueue.main.async {
                    switch count {
                    case 0: completion(.noFace)
                    case 1: completion(.ok)
                    default: completion(.multipleFaces)
                    }
                }
            } catch {
                // A Vision processing failure is evidence the *check* couldn't run, not that
                // the photo has no face — the previous version blocked on this exact case,
                // which meant a purely internal glitch could reject a perfectly good photo.
                // Fail open: let the photo through rather than punish the user for our error.
                print("FaceDetectionService: Vision request failed, allowing photo through: \(error)")
                DispatchQueue.main.async { completion(.ok) }
            }
        }
    }

    private static func normalizedCGImage(from image: UIImage, maxDimension: CGFloat) -> CGImage? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let scale = min(1, maxDimension / max(size.width, size.height))
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let normalized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return normalized.cgImage
    }
}
