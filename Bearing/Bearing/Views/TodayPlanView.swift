import SwiftUI
import SwiftData

struct TodayPlanView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query private var plans: [CarePlan]
    @Query private var sessions: [Session]
    @State private var now = Date()
    @State private var error = false
    @State private var remindersAvailable = false
    private var plan: CarePlan? { plans.first }

    var body: some View {
        BearingPage {
            Text("Today").font(.largeTitle.bold())
            Text("One saved check-in with a recorded value completes your personal check-in for today.")
                .foregroundStyle(BearingStyle.muted)
            VStack(alignment: .leading, spacing: 16) {
                Label(statusText, systemImage: statusSymbol).font(.title3.bold())
                if let plan, !plan.routines.isEmpty {
                    Text(plan.routines.map(\.title).joined(separator: ", "))
                    Text("Choose one of your planned routines. Follow the instructions you already have.")
                    NavigationLink("Choose a routine") { RoutineLibraryView() }.buttonStyle(BearingPrimaryButton())
                    NavigationLink("Open custom check-ins") { CustomCheckInsView() }.buttonStyle(BearingSecondaryButton())
                    if actionable {
                        Button("Remind me in 30 minutes") { update(snooze: Date().addingTimeInterval(30 * 60)) }
                            .frame(minHeight: 48).disabled(!remindersAvailable)
                        Button("Skip today") { update(skip: true) }.frame(minHeight: 48)
                    }
                    if case .skipped = status {
                        Button("Undo skip") { update() }.frame(minHeight: 48)
                    }
                    if !remindersAvailable { Text("Local reminders are off. You can still record a check-in.").font(.callout) }
                }
            }.padding(20).background(BearingStyle.surface, in: RoundedRectangle(cornerRadius: 20))
            Text("Skipping does not record a result. You can change your choice.").font(.callout)
            NavigationLink("Edit my plan") { PlanView() }.buttonStyle(BearingSecondaryButton())
            PrivacyNote()
        }.navigationTitle("Today")
            .task(id: sessions.count) {
                await refresh()
                while !Task.isCancelled {
                    do { try await Task.sleep(for: .seconds(30)) } catch { return }
                    now = .now
                }
            }
            .onChange(of: scenePhase) { _, phase in if phase == .active { Task { await refresh() } } }
            .alert("Changes could not be saved", isPresented: $error) { Button("OK", role: .cancel) {} }
    }
    private var status: TodayState { TodayPlanService.status(plan: plan, sessions: sessions, now: now) }
    private var statusText: String {
        switch status {
        case .noPlan: return Loc.t("Choose your personal plan to begin.")
        case .noSchedule: return Loc.t("No check-in time is set for today.")
        case .completed: return Loc.t("Your check-in is recorded for today.")
        case .skipped: return Loc.t("Today is skipped.")
        case .snoozed(let date): return Loc.f("Reminder moved to %@", date.formatted(.dateTime.locale(Loc.locale).hour().minute()))
        case .scheduled(let date): return Loc.f("Your check-in time is %@", date.formatted(.dateTime.locale(Loc.locale).hour().minute()))
        case .due: return Loc.t("Your planned check-in is due.")
        }
    }
    private var statusSymbol: String { status == .completed ? "checkmark.circle" : "calendar" }
    private var actionable: Bool { status != .completed && status != .skipped && status != .noPlan && status != .noSchedule }
    private func refresh() async {
        now = .now
        let result = await ReminderScheduler(center: SystemNotificationCenter()).sync(plan: plan, body: ReminderText.body, sessions: sessions)
        if case .scheduled = result { remindersAvailable = true } else { remindersAvailable = false }
    }
    private func update(skip: Bool = false, snooze: Date? = nil) {
        guard let plan else { return }
        let previous = plan.dayChoicesData
        plan.chooseToday(skip: skip, snooze: snooze, now: .now)
        do { try context.save(); Task { await refresh() } }
        catch { plan.dayChoicesData = previous; self.error = true }
    }
}

struct PlanHistoryView: View {
    let revisions: [PlanRevision]
    var body: some View {
        BearingPage {
            Text("Accepted plan versions").font(.largeTitle.bold())
            Text("These are personal plans saved on this phone. Their author is not a verified professional.")
            if revisions.isEmpty { Text("No plan versions have been saved yet.") }
            ForEach(revisions.reversed()) { revision in
                VStack(alignment: .leading, spacing: 12) {
                    Text(Loc.f("Version %lld", revision.number)).font(.headline)
                    if let date = revision.acceptedAt {
                        Text(date.formatted(.dateTime.locale(Loc.locale).year().month().day().hour().minute()))
                    } else { Text("Saved date was not recorded in the earlier build.") }
                    Text(revision.routines.map(\.title).joined(separator: ", "))
                    Text(Loc.f("Weekly goal: %lld check-ins", revision.weeklyGoal))
                }.padding(20).background(BearingStyle.surface, in: RoundedRectangle(cornerRadius: 20))
            }
        }.navigationTitle("Plan history")
    }
}
