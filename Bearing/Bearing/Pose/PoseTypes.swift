import CoreGraphics
import Vision

enum Side: String, Codable, CaseIterable, Sendable {
    case left, right
    var title: String { self == .right ? Loc.t("Right arm") : Loc.t("Left arm") }
}

// Left and right always mean the person's anatomical sides.
enum JointName: String, CaseIterable, Codable, Sendable {
    case leftShoulder, rightShoulder, leftElbow, rightElbow, leftHip, rightHip, leftWrist, rightWrist, leftKnee, rightKnee, leftAnkle, rightAnkle

    var confidenceTier: Float {
        switch self {
        case .leftElbow, .rightElbow, .leftWrist, .rightWrist, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle: return Parameters.elbowConfidence
        default: return Parameters.shoulderHipConfidence
        }
    }

    var visionName: VNHumanBodyPoseObservation.JointName {
        switch self {
        case .leftShoulder: return .leftShoulder
        case .rightShoulder: return .rightShoulder
        case .leftElbow: return .leftElbow
        case .rightElbow: return .rightElbow
        case .leftHip: return .leftHip
        case .rightHip: return .rightHip
        case .leftWrist: return .leftWrist
        case .rightWrist: return .rightWrist
        case .leftKnee: return .leftKnee
        case .rightKnee: return .rightKnee
        case .leftAnkle: return .leftAnkle
        case .rightAnkle: return .rightAnkle
        }
    }
}

struct JointPoint: Sendable {
    var position: CGPoint // pixels, origin lower-left, Y upward
    var confidence: Float
    var isImputed: Bool // held from an earlier frame
}

struct PoseFrame: Sendable {
    let timestamp: TimeInterval
    let size: CGSize // pixel size of the source frame
    var joints: [JointName: JointPoint]
    var multiplePeople = false
}

extension JointPoint {
    func isFresh(for joint: JointName) -> Bool {
        !isImputed && confidence.isFinite && confidence >= joint.confidenceTier
            && position.x.isFinite && position.y.isFinite
    }
}
