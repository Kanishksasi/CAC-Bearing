import Foundation

enum Exercise: String, Codable, CaseIterable, Identifiable, Sendable {
    case armRaise, sitToStand, balance, kneeBend, shoulderReach, manualCount, manualTimer
    var id: String { rawValue }
    static let cameraRoutines: [Exercise] = [.armRaise, .sitToStand, .balance, .kneeBend, .shoulderReach]
    var title: String {
        switch self {
        case .armRaise: return Loc.t("Arm raise")
        case .sitToStand: return Loc.t("Sit to stand")
        case .balance: return Loc.t("One-leg balance")
        case .kneeBend: return Loc.t("Knee bend")
        case .shoulderReach: return Loc.t("Shoulder reach")
        case .manualCount: return Loc.t("Manual count")
        case .manualTimer: return Loc.t("Manual timer")
        }
    }
    var symbol: String {
        switch self {
        case .armRaise: return "figure.arms.open"
        case .sitToStand: return "chair"
        case .balance: return "figure.stand"
        case .kneeBend: return "figure.flexibility"
        case .shoulderReach: return "figure.wave"
        case .manualCount: return "number"
        case .manualTimer: return "timer"
        }
    }
    var isManual: Bool { self == .manualCount || self == .manualTimer }
    var isAngle: Bool { self == .armRaise || self == .kneeBend || self == .shoulderReach }
    var isSideView: Bool { self == .kneeBend || self == .shoulderReach }
    var needsSupport: Bool { self == .sitToStand || self == .balance || self == .kneeBend }
    var attempts: Int { isAngle ? Parameters.attemptsPerSide : 1 }
    var seconds: Double {
        switch self {
        case .sitToStand: return Parameters.sitToStandSeconds
        case .balance: return Parameters.balanceMaxSeconds
        default: return Parameters.attemptSeconds
        }
    }
    func sideTitle(_ side: Side) -> String {
        if self == .armRaise || self == .shoulderReach { return side.title }
        return side == .right ? Loc.t("Right side") : Loc.t("Left side")
    }
    func requiredJoints(side: Side, setup: Bool = false) -> Set<JointName> {
        switch self {
        case .armRaise:
            var result: Set<JointName> = [.leftShoulder, .rightShoulder, .leftHip, .rightHip, .elbow(side)]
            if setup { result.insert(.elbow(side == .right ? .left : .right)) }
            return result
        case .sitToStand: return [.leftShoulder, .rightShoulder, .leftHip, .rightHip]
        case .balance: return [.leftShoulder, .rightShoulder, .leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle]
        case .kneeBend: return [.shoulder(side), .hip(side), .knee(side), .ankle(side)]
        case .shoulderReach: return [.shoulder(side), .hip(side), .elbow(side)]
        case .manualCount, .manualTimer: return []
        }
    }
    var instructions: [String] {
        switch self {
        case .armRaise: return Strings.setupSteps
        case .sitToStand: return [Loc.t("Use a firm chair that cannot slide. Face the phone."), Loc.t("Start seated. Keep your shoulders and hips in view."), Loc.t("Cross your arms if comfortable. Stand and sit at your own pace."), Loc.t("The recording lasts thirty seconds. You can stop at any time.")]
        case .balance: return [Loc.t("Face the phone. Keep your shoulders, hips, knees, and feet in view."), Loc.t("Stand beside stable support with someone within reach."), Loc.t("Lift one foot only if comfortable. Lower it whenever you need."), Loc.t("The hold is capped at ten seconds. Stand still before starting.")]
        case .kneeBend: return [Loc.t("Sit on a firm chair beside stable support."), Loc.t("Turn sideways with your chosen side toward the phone."), Loc.t("Keep your shoulder, hip, knee, and ankle in view."), Loc.t("Start with your leg straight if comfortable. Bend your knee, then return. Do three attempts.")]
        case .shoulderReach: return [Loc.t("Prop the phone upright on a steady surface, about chest height."), Loc.t("Turn sideways with your chosen side toward the phone."), Loc.t("Keep your shoulder, hip, and elbow in view."), Loc.t("Start with your arm down. Reach forward, hold briefly, then lower. Do three attempts.")]
        case .manualCount, .manualTimer: return [Loc.t("Use a movement you already know. Follow guidance from your clinician."), Loc.t("This check-in records your entry. The camera does not measure it.")]
        }
    }
    var movementCue: String {
        switch self {
        case .armRaise: return Strings.raiseNow
        case .sitToStand: return Loc.t("Stand and sit at your own pace. Stop whenever you need.")
        case .balance: return Loc.t("Lift one foot if comfortable. Keep support and someone within reach.")
        case .kneeBend: return Loc.t("Bend your knee as comfortable, then return to your starting position.")
        case .shoulderReach: return Loc.t("Reach your arm forward as comfortable. Hold briefly, then lower it.")
        default: return instructions[0]
        }
    }
    var resultMeaning: String {
        switch self {
        case .armRaise: return Loc.t("Degrees describe your arm angle from your body in the picture.")
        case .shoulderReach: return Loc.t("Degrees describe your forward arm angle from your body in the picture.")
        case .kneeBend: return Loc.t("Degrees describe your knee bend in the picture. A straight leg starts at zero.")
        case .sitToStand: return Loc.t("This is the number of seated-to-standing rises counted during this recording.")
        case .balance: return Loc.t("Seconds show the first recorded foot lift, ending when the foot lowers or time ends.")
        case .manualCount: return Loc.t("This is the count you entered. The camera did not count these movements.")
        case .manualTimer: return Loc.t("Seconds show your timer time. Pauses and time outside the app are excluded.")
        }
    }

    var limits: String {
        if isManual { return method }
        if isAngle {
            return Loc.t("A phone camera sees a flat picture, not 3D. This number estimates an angle in that picture.")
        }
        return Loc.t("Camera counts and hold estimates depend on framing and joint tracking. They do not describe your health.")
    }
    var method: String {
        switch self {
        case .armRaise: return Loc.t("The picture angle uses your shoulder, hip, and elbow from the front.")
        case .kneeBend: return Loc.t("The picture angle uses your hip, knee, and ankle. A straight leg is the starting position.")
        case .shoulderReach: return Loc.t("The picture angle uses your shoulder, hip, and elbow from the side.")
        case .sitToStand: return Loc.t("The camera tracks hip height compared with torso length. It counts rises after a seated start.")
        case .balance: return Loc.t("Ankle height marks the lifted foot. Hip movement compared with shoulder width estimates sway.")
        default: return Loc.t("You recorded this value yourself. It was not measured by the camera.")
        }
    }
}

extension JointName {
    static func shoulder(_ side: Side) -> Self { side == .left ? .leftShoulder : .rightShoulder }
    static func hip(_ side: Side) -> Self { side == .left ? .leftHip : .rightHip }
    static func elbow(_ side: Side) -> Self { side == .left ? .leftElbow : .rightElbow }
    static func knee(_ side: Side) -> Self { side == .left ? .leftKnee : .rightKnee }
    static func ankle(_ side: Side) -> Self { side == .left ? .leftAnkle : .rightAnkle }
}
