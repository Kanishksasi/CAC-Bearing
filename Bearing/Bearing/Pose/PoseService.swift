import Vision
import CoreVideo

// Vision joints stay in pixels with Y pointing up. Only drawing flips Y.
final class PoseService {
    private let request = VNDetectHumanBodyPoseRequest()

    func process(_ pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) -> PoseFrame {
        let width = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let height = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        var frame = PoseFrame(timestamp: timestamp, size: CGSize(width: width, height: height), joints: [:])

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do { try handler.perform([request]) } catch { return frame }
        guard let observation = request.results?.first else { return frame }

        frame.multiplePeople = (request.results?.count ?? 0) > 1
        for name in JointName.allCases {
            guard let p = try? observation.recognizedPoint(name.visionName), p.confidence > 0 else { continue }
            let position = Geometry.pixelPoint(p.location, size: frame.size)
            frame.joints[name] = JointPoint(position: position, confidence: p.confidence, isImputed: false)
        }
        return frame
    }
}
