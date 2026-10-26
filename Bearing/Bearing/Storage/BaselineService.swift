import Foundation
import SwiftData

enum BaselineService {
    static func eligible(_ sessions: [Session], side: Side) -> [Session] {
        sessions
            .filter { !$0.isLegacy && $0.exercise == .armRaise && $0.customID.isEmpty && $0.side == side && $0.countedPeaks.count >= Parameters.minCountedForBaseline }
            .sorted { $0.date < $1.date }
    }

    static func baseline(_ sessions: [Session], side: Side) -> Double? {
        let first = eligible(sessions, side: side).prefix(Parameters.baselineSessions)
        guard first.count == Parameters.baselineSessions else { return nil }
        return Geometry.median(first.compactMap { $0.latest })
    }

    static func sessionsBuilt(_ sessions: [Session], side: Side) -> Int {
        min(eligible(sessions, side: side).count, Parameters.baselineSessions)
    }

    static func difference(for session: Session, in sessions: [Session]) -> Double? {
        let earlier = sessions.filter { $0.date <= session.date }
        guard let base = baseline(earlier, side: session.side), let latest = session.latest else { return nil }
        let baselineSessions = eligible(earlier, side: session.side).prefix(Parameters.baselineSessions)
        if baselineSessions.contains(where: { $0.persistentModelID == session.persistentModelID }) { return nil }
        return latest - base
    }
    static func comparable(to session: Session, in sessions: [Session]) -> [Session] {
        sessions.filter {
            !$0.isLegacy && $0.date <= session.date && $0.exerciseRaw == session.exerciseRaw
                && $0.customID == session.customID && (!session.exercise.isAngle || $0.side == session.side)
                && (session.exercise != .balance || $0.liftedFootRaw == session.liftedFootRaw)
                && $0.value != nil && (!session.exercise.isAngle || $0.countedPeaks.count >= Parameters.minCountedForBaseline)
        }.sorted { $0.date < $1.date }
    }

    static func startingPoint(for session: Session, in sessions: [Session]) -> Double? {
        let first = comparable(to: session, in: sessions).prefix(Parameters.baselineSessions)
        guard first.count == Parameters.baselineSessions else { return nil }
        return Geometry.median(first.compactMap(\.value))
    }

    static func change(for session: Session, in sessions: [Session]) -> Double? {
        guard let value = session.value, let start = startingPoint(for: session, in: sessions) else { return nil }
        let first = comparable(to: session, in: sessions).prefix(Parameters.baselineSessions)
        guard !first.contains(where: { $0.persistentModelID == session.persistentModelID }) else { return nil }
        return value - start
    }

}
