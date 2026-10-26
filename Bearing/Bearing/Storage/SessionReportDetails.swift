import Foundation

struct RecordedAttempt: Codable, Equatable {
    var number: Int
    var counted: Bool
    var angle: Double?
    var repetitions: Int?
    var holdSeconds: Double?
    var swayRatio: Double?
    var liftedFoot: String?
    var reason: String?
    var durationSeconds: Double?
}

struct SessionReportDetails: Codable {
    var attempts: [RecordedAttempt]
    var source: String
    var appVersion: String
    var timeZone: String
    var protocolVersion: String
}

extension Session {
    var reportDetails: SessionReportDetails? {
        get { try? JSONDecoder().decode(SessionReportDetails.self, from: reportDetailsData) }
        set { reportDetailsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
}
