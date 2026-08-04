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
        DispatchQueue.global(qos: .userInitiated).async {
            // Photos from the library often come back as wide-gamut/HEIC CGImages (extended-range
            // components) that Vision's request handler rejects outright — redrawing into a plain
            // 8-bit sRGB bitmap sidesteps that, and also bakes in imageOrientation so Vision always
            // sees an .up-oriented image regardless of how the photo was captured.
            guard let cgImage = normalizedCGImage(from: image) else {
                DispatchQueue.main.async { completion(.noFace) }
                return
            }
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
                print("FaceDetectionService: Vision request failed: \(error)")
                DispatchQueue.main.async { completion(.noFace) }
            }
        }
    }

    private static func normalizedCGImage(from image: UIImage, maxDimension: CGFloat = 1600) -> CGImage? {
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
