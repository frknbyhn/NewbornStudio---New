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
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async { completion(.noFace) }
            return
        }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let request = VNDetectFaceRectanglesRequest()
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
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
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
