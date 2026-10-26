import Foundation

enum Strings {
    static var appName: String { Loc.t("Bearing") }
    static var disclaimer: String { Loc.t("For personal tracking only. Not medical advice or a diagnosis. Share with your clinician.") }
    static var safetyIntro: String { Loc.t("Stand or sit steadily. Keep a chair or support within reach. Have someone nearby if you feel unsteady. Stop if you feel pain or dizziness.") }
    static var supportSafety: String { Loc.t("Stand beside stable support. Keep someone within arm’s reach. Stop for pain, dizziness, or unsteadiness.") }
    static var limitsLine: String { Loc.t("A phone camera sees a flat picture, not 3D. This number estimates the angle in the picture. It does not show how far your shoulder can move.") }
    static var setupVariationNote: String { Loc.t("Small differences can come from phone placement or lighting, not only from movement.") }
    static var cameraUsage: String { Loc.t("Bearing uses the camera to measure movement on this phone. Video is never saved or sent anywhere.") }

    static var counted: String { Loc.t("Counted") }
    static var notCounted: String { Loc.t("Not counted") }

    static var reasonTilt: String { Loc.t("Your phone tilted during the attempt. Prop it upright and try again.") }
    static var reasonLowConfidence: String { Loc.t("We could not see the movement clearly. Try more light or a plain background.") }
    static var reasonOutOfFrame: String { Loc.t("Part of your body was out of view. Move back one step.") }
    static var reasonTrunkLean: String { Loc.t("You leaned to the side. Keep your body upright and try again.") }
    static var reasonNoClearRaise: String { Loc.t("We could not record a full raise and lower with this setup. Start with your arm down. Raise it out to the side, hold for one second, then lower it. This routine records this movement only.") }
    static var reasonMotionUnavailable: String { Loc.t("We could not read your phone tilt. Close other apps and try again.") }
    static var fixOnePerson: String { Loc.t("Only one person should be in view.") }

    static var fixJoints: String { Loc.t("We need to see the joints for this routine. Adjust your distance.") }
    static var fixStepBack: String { Loc.t("Step back so the movement fits in view.") }
    static var fixStepCloser: String { Loc.t("Step a little closer.") }
    static var fixTilt: String { Loc.t("Your phone is tilted. Prop it upright.") }
    static var fixStill: String { Loc.t("Hold still for a moment.") }
    static var ready: String { Loc.t("Ready. Press and hold Start.") }

    static var getReady: String { Loc.t("Get ready. Stand facing the phone.") }
    static var raiseNow: String { Loc.t("Raise your arm out to the side. Hold for one second. Then lower it.") }
    static var attemptDone: String { Loc.t("Done.") }

    static var setupSteps: [String] {
        [Loc.t("Prop the phone upright on a steady surface, about chest height."),
         Loc.t("Face the phone. Step back until your upper body and raised elbow fit in view."),
         Loc.t("Start with your arm down. Raise it out to the side as far as comfortable."),
         Loc.t("Hold for one second, then lower it. You will do three attempts for this arm.")]
    }

    static func angle(_ value: Double) -> String { Loc.f("%.0f degrees", value) }

    static func signedAngle(_ value: Double) -> String { (value < 0 ? "−" : "+") + angle(abs(value)) }

    static func countedLine(_ session: Session) -> String {
        Loc.f("%lld of %lld attempts counted", session.countedAttemptCount, session.attemptCount)
    }

    static func explainMeasureLine(latest: Double, low: Double, high: Double) -> String {
        Loc.f("Projected arm angle: %.0f degrees. Your counted attempts ranged from %.0f to %.0f degrees.", latest, low, high)
    }
}
