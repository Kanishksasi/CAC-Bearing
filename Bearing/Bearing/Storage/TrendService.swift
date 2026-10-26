import Foundation

enum TrendService {
    static func series(for session: Session, in sessions: [Session]) -> [Session] {
        sessions.filter {
            !$0.isLegacy && $0.value != nil && $0.date <= session.date && $0.exerciseRaw == session.exerciseRaw
                && $0.customID == session.customID && (!session.exercise.isAngle || $0.side == session.side)
                && (session.exercise != .balance || $0.liftedFootRaw == session.liftedFootRaw)
        }.sorted { $0.date < $1.date }.suffix(12).map { $0 }
    }
}
