import Foundation
import SwiftData
import UserNotifications

@MainActor
struct SessionStore {
    let context: ModelContext

    static func makeContainer(inMemory: Bool = false, url: URL? = nil) throws -> ModelContainer {
        let schema = Schema([Session.self, UserSettings.self, CarePlan.self])
        let configuration = url.map { ModelConfiguration(schema: schema, url: $0, cloudKitDatabase: .none) }
            ?? ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    func save(_ session: Session) throws {
        context.insert(session)
        do { try context.save() }
        catch { context.delete(session); throw error }
    }

    func deleteAllData() throws {
        try context.delete(model: Session.self)
        try context.delete(model: UserSettings.self)
        try context.delete(model: CarePlan.self)
        try context.save()
        ReminderScheduler.clearPending()
        try ReportFiles.removeAll()
    }
}

enum ReportFiles {
    static func removeAll(directory: URL = FileManager.default.temporaryDirectory) throws {
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        for file in files where file.lastPathComponent.hasPrefix("Bearing-") && file.pathExtension == "pdf" {
            try FileManager.default.removeItem(at: file)
        }
        let oldReport = directory.appendingPathComponent("bearing-report.pdf")
        if FileManager.default.fileExists(atPath: oldReport.path) { try FileManager.default.removeItem(at: oldReport) }
    }
}
