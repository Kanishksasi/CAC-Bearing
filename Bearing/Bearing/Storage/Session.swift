import Foundation
import SwiftData

@Model
final class Session {
    var date: Date
    var exerciseRaw: String
    var leftBest: Double?
    var leftAverage: Double?
    var rightBest: Double?
    var rightAverage: Double?
    var standCount: Int?
    var holdSeconds: Double?
    var swayRatio: Double?
    var liftedFootRaw: String?
    var acceptedTrials: Int
    var rejectedTrials: Int

    var recentExportsData: Data = Data()
    var planAtRecordingData: Data = Data()
    var reportDetailsData: Data = Data()
    var captureVersion: Int = 0
    var customID: String = ""
    var customTitle: String = ""
    var customInstructions: String = ""
    var sideRaw: String = ""
    var attemptCount: Int = 0
    var countedPeaks: [Double] = []
    var notCountedReasons: [String] = []

    init(date: Date = .now, side: Side, attemptCount: Int, countedPeaks: [Double], notCountedReasons: [String]) {
        self.exerciseRaw = "armRaise"
        self.acceptedTrials = countedPeaks.count
        self.rejectedTrials = notCountedReasons.count
        self.date = date
        self.sideRaw = side.rawValue
        self.attemptCount = attemptCount
        self.countedPeaks = countedPeaks
        self.notCountedReasons = notCountedReasons
    }

    // Keep old summary values readable without making up attempt data.
    var isLegacy: Bool { sideRaw.isEmpty && captureVersion == 0 }
    var exercise: Exercise { Exercise(rawValue: exerciseRaw) ?? .armRaise }
    var cameraTemplateSnapshot: CustomCheckIn? {
        guard exercise.isAngle, let id = UUID(uuidString: customID) else { return nil }
        return CustomCheckIn(id: id, name: customTitle, instructions: customInstructions, exercise: exercise, side: side)
    }
    var displayTitle: String { customTitle.isEmpty ? exercise.title : customTitle }
    var value: Double? {
        if exercise.isAngle { return latest }
        if exercise == .sitToStand || exercise == .manualCount { return standCount.map(Double.init) }
        return holdSeconds
    }
    var countedAttemptCount: Int {
        if isLegacy { return acceptedTrials }
        if let details = reportDetails { return details.attempts.filter(\.counted).count }
        if exercise.isAngle { return countedPeaks.count }
        return value == nil ? 0 : min(1, attemptCount)
    }
    var valueText: String {
        guard let value else { return Loc.t("No value recorded") }
        return formattedValue(value)
    }
    func formattedValue(_ value: Double) -> String {
        if exercise.isAngle { return Strings.angle(value) }
        if exercise == .sitToStand || exercise == .manualCount { return Loc.f("%lld repetitions", Int(value)) }
        return Loc.f("%.1f seconds", value)
    }
    var measurementTitle: String {
        if exercise == .armRaise { return Loc.t("Arm angle summary") }
        if exercise.isAngle { return Loc.t("Angle summary") }
        if exercise == .sitToStand { return Loc.t("Recorded stands") }
        if exercise == .balance { return Loc.t("Recorded hold") }
        return Loc.t("Your recorded entry")
    }
    var side: Side { Side(rawValue: sideRaw) ?? .right }
    var latest: Double? { Geometry.median(countedPeaks) }
    var lowest: Double? { countedPeaks.min() }
    var highest: Double? { countedPeaks.max() }
}

@Model
final class UserSettings {
    var appLockEnabled: Bool = false
    var caregiverMode: Bool
    var spokenPrompts: Bool
    // A default lets SwiftData add this field to an older store.
    var hasSeenIntro: Bool = false
    var countdownSeconds: Int = 3
    var hapticsEnabled: Bool = true
    var speechSpeedRaw: String = "normal"
    var boldSkeleton: Bool = false
    var easyStart: Bool = false
    var languageRaw: String = AppLanguage.system.rawValue

    init(caregiverMode: Bool = false, spokenPrompts: Bool = true, hasSeenIntro: Bool = false) {
        self.caregiverMode = caregiverMode
        self.spokenPrompts = spokenPrompts
        self.hasSeenIntro = hasSeenIntro
    }
}

extension UserSettings {
    var voiceEnabled: Bool {
        get { spokenPrompts }
        set { spokenPrompts = newValue }
    }
}
