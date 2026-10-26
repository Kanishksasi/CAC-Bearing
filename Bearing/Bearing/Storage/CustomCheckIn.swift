import Foundation

struct CustomCheckIn: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var name: String
    var instructions: String
    var exercise: Exercise
    var side: Side = .right
    var timerSeconds = 60

    var isValid: Bool {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !title.isEmpty && title.count <= 60 && instructions.count <= 500 && (5...600).contains(timerSeconds)
    }
}

@MainActor
extension Session {
    static func recorded(exercise: Exercise, side: Side, results: [AttemptResult], template: CustomCheckIn? = nil, cameraSource: String? = nil) -> Session {
        let session = Session(side: side, attemptCount: results.count,
                              countedPeaks: results.filter(\.counted).compactMap(\.peakAngle),
                              notCountedReasons: results.compactMap { $0.reason?.rawValue })
        session.acceptedTrials = results.filter(\.counted).count
        session.rejectedTrials = results.filter { !$0.counted }.count
        session.captureVersion = 4
        session.reportDetails = SessionReportDetails(attempts: results.enumerated().map { index, result in
            RecordedAttempt(number: index + 1, counted: result.counted, angle: result.counted ? result.peakAngle : nil,
                            repetitions: result.counted ? result.repetitions : nil,
                            holdSeconds: result.counted ? result.holdSeconds : nil,
                            swayRatio: result.counted ? result.swayRatio : nil,
                            liftedFoot: result.liftedFoot?.rawValue, reason: result.reason?.rawValue,
                            durationSeconds: result.durationSeconds)
        }, source: exercise.isManual ? "manual" : (cameraSource ?? "unsaved"),
           appVersion: (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?")
                + " (" + (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?") + ")",
           timeZone: TimeZone.current.identifier, protocolVersion: "bearing-4")
        session.exerciseRaw = exercise.rawValue
        session.customID = template?.id.uuidString ?? ""
        session.customTitle = template?.name ?? ""
        session.customInstructions = template?.instructions ?? ""
        session.standCount = results.first(where: \.counted)?.repetitions
        session.holdSeconds = results.first(where: \.counted)?.holdSeconds
        session.swayRatio = results.first(where: \.counted)?.swayRatio
        session.liftedFootRaw = results.first(where: \.counted)?.liftedFoot?.rawValue
        if exercise == .balance, let foot = session.liftedFootRaw { session.sideRaw = foot }
        return session
    }
}
