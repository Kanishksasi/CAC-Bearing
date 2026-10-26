import SwiftUI
import SwiftData
import UserNotifications

@main
struct BearingApp: App {
    private let container: ModelContainer?

    init() {
        do {
            #if DEBUG && targetEnvironment(simulator)
            let useMemory = ProcessInfo.processInfo.arguments.contains("-UITestFreshStore")
            #else
            let useMemory = false
            #endif
            let made = try SessionStore.makeContainer(inMemory: useMemory)
            #if DEBUG && targetEnvironment(simulator)
            // Test data must stay in the disposable simulator store.
            if useMemory && ProcessInfo.processInfo.arguments.contains("-UITestSampleSession") {
                made.mainContext.insert(Session(side: .right, attemptCount: 3,
                                                countedPeaks: [112, 116, 114], notCountedReasons: []))
                try made.mainContext.save()
            }
            #endif
            let settings = try made.mainContext.fetch(FetchDescriptor<UserSettings>()).first
            Loc.preference = AppLanguage(rawValue: settings?.languageRaw ?? "") ?? .system
            let plan = try made.mainContext.fetch(FetchDescriptor<CarePlan>()).first
            let sessions = try made.mainContext.fetch(FetchDescriptor<Session>())
            container = made
            Task { @MainActor in
                await ReminderScheduler(center: SystemNotificationCenter()).sync(plan: plan, body: ReminderText.body, sessions: sessions)
            }
        } catch { container = nil }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                AppLock(content: HomeView()).modelContainer(container)
            } else {
                ContentUnavailableView(Loc.t("Saved data could not open"), systemImage: "externaldrive.badge.exclamationmark",
                                       description: Text(Loc.t("Restart Bearing to try again. Your saved data has not been deleted.")))
            }
        }
    }
}
