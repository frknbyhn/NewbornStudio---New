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
        Task {
            let count = await countFaces(in: image)
            await MainActor.run {
                switch count {
                case 0: completion(.noFace)
                case 1: completion(.ok)
                default: completion(.multipleFaces)
                }
            }
        }
    }

    private static func countFaces(in image: UIImage) async -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        let orientation = cgOrientation(from: image.imageOrientation)
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNDetectFaceRectanglesRequest()
                request.revision = VNDetectFaceRectanglesRequestRevision2
                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
                do {
                    try handler.perform([request])
                    continuation.resume(returning: request.results?.count ?? 0)
                } catch {
                    print("FaceDetectionService: Vision request failed: \(error)")
                    continuation.resume(returning: 0)
                }
            }
        }
    }

    private static func cgOrientation(from orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
