import SwiftUI
import SwiftData
import Charts

struct PlanView: View {
    @Environment(\.modelContext) private var context
    @Query private var plans: [CarePlan]
    @Query private var sessions: [Session]
    @State private var routines: Set<Exercise> = []
    @State private var goal = 3
    @State private var reminders = false
    @State private var days: Set<Int> = CarePlan.defaultReminderDays
    @State private var time = Date()
    @State private var message: String?
    @State private var error = false
    @State private var saving = false
    @State private var reviewing = false
    @State private var commitRequested = false
    private var plan: CarePlan? { plans.first }
    var body: some View {
        Form {
            Section {
                Text("Choose routines you already follow. This is your personal plan.")
                ForEach(Exercise.allCases) { exercise in
                    Toggle(exercise.title, isOn: Binding(get: { routines.contains(exercise) }, set: { value in
                        if value { routines.insert(exercise) } else { routines.remove(exercise) }
                    })).tint(Color.accentColor)
                }
                Stepper(Loc.f("Weekly goal: %lld check-ins", goal), value: $goal, in: CarePlan.goalRange)
            } header: { Text("Your routines") }
            if let plan {
                Section {
                    let week = PlanService.thisWeek(plan: plan, sessions: sessions)
                    Text(PlanService.weekLine(week)).font(.headline)
                    let weeks = PlanService.recentWeeks(plan: plan, sessions: sessions)
                    if weeks.contains(where: { $0.done > 0 }) {
                        Chart(weeks, id: \.weekStart) { week in
                            BarMark(x: .value(Loc.t("Week"), week.weekStart, unit: .weekOfYear), y: .value(Loc.t("Check-ins"), week.done))
                                .foregroundStyle(Color.accentColor)
                        }.frame(height: 160).environment(\.calendar, PlanService.mondayCalendar())
                            .accessibilityLabel(Loc.t("Saved check-ins over four weeks"))
                    } else {
                        Text("Your weekly history will appear after you save a check-in.").foregroundStyle(BearingStyle.muted)
                    }
                    Text("Only saved entries with a recorded value count. The chart uses your saved routine choices.").font(.footnote)
                } header: { Text("Check-ins this week") }
            }
            Section {
                Toggle("Local reminders", isOn: $reminders).tint(Color.accentColor)
                DatePicker("Reminder time", selection: $time, displayedComponents: .hourAndMinute)
                DisclosureGroup("Reminder days") {
                    ForEach(CarePlan.weekdayOrder, id: \.self) { day in
                        Toggle(weekday(day), isOn: Binding(get: { days.contains(day) }, set: { value in
                            if value { days.insert(day) } else { days.remove(day) }
                        })).tint(Color.accentColor)
                    }
                }
                Text("Opening Bearing refreshes reminders for the next four weeks.").font(.footnote)
                Text("Reminders stay on this phone. Notification permission is requested when you save with reminders on.").font(.footnote)
            } header: { Text("Reminders") }
            Section {
                if let plan {
                    NavigationLink("Plan history") { PlanHistoryView(revisions: plan.revisions) }
                }
                Button("Save plan") { commitRequested = false; reviewing = true }.disabled(saving || routines.isEmpty || (reminders && days.isEmpty))
                Text(Strings.disclaimer).font(.footnote)
            }
        }.scrollContentBackground(.hidden).background(BearingStyle.paper).buttonStyle(.automatic).navigationTitle("My plan")
            .task { load() }
            .sheet(isPresented: $reviewing, onDismiss: {
                if commitRequested { commitRequested = false; Task { await save() } }
            }) {
                NavigationStack {
                    BearingPage {
                        Text("Review your plan changes").font(.largeTitle.bold())
                        Text("Accepting saves a new personal plan version. Earlier versions stay in your plan history.")
                        if let plan, !plan.routines.isEmpty {
                            Text("Current plan").font(.headline)
                            Text(plan.routines.map(\.title).joined(separator: ", "))
                            Text(Loc.f("Weekly goal: %lld check-ins", plan.weeklyGoal))
                        }
                        Text("Proposed plan").font(.headline)
                        Text(Exercise.allCases.filter { routines.contains($0) }.map(\.title).joined(separator: ", "))
                        Text(Loc.f("Weekly goal: %lld check-ins", goal))
                        if reminders {
                            Text(time.formatted(.dateTime.locale(Loc.locale).hour().minute()))
                            Text(CarePlan.weekdayOrder.filter { days.contains($0) }.map(weekday).joined(separator: ", "))
                        } else { Text("Local reminders are off. You can still record a check-in.") }
                        Text("This is your personal plan. No physician assignment is verified.")
                        Button("Accept plan changes") { commitRequested = true; reviewing = false }
                            .buttonStyle(BearingPrimaryButton())
                        Button("Keep editing") { reviewing = false }.buttonStyle(BearingSecondaryButton())
                    }.navigationTitle("Review plan")
                }
            }
            .alert("My plan", isPresented: Binding(get: { message != nil || error }, set: { if !$0 { message = nil; error = false } })) {
                Button("OK", role: .cancel) { message = nil; error = false }
            } message: { Text(error ? Loc.t("Changes could not be saved") : (message ?? "")) }
    }
    private func weekday(_ day: Int) -> String {
        let formatter = DateFormatter(); formatter.locale = Loc.locale
        return formatter.weekdaySymbols[day - 1]
    }
    private func load() {
        do {
            let plan = try PlanStore.ensure(context)
            routines = Set(plan.routines); goal = plan.weeklyGoal; reminders = plan.remindersEnabled
            if !plan.reminders.isEmpty { days = plan.reminderWeekdays }
            let slot = plan.reminderTime
            time = Calendar.current.date(bySettingHour: slot.hour, minute: slot.minute, second: 0, of: .now) ?? .now
        } catch { self.error = true }
    }
    private func save() async {
        guard !saving else { return }
        saving = true
        defer { saving = false }
        do {
            let plan = try PlanStore.ensure(context)
            let oldChoices = plan.dayChoicesData
            let oldVersions = plan.revisionsData
            plan.preserveEarlierPlan()
            let oldRoutines = plan.routines, oldGoal = plan.weeklyGoal, oldSlots = plan.reminders, oldEnabled = plan.remindersEnabled
            plan.routines = Array(routines); plan.weeklyGoal = CarePlan.clamp(goal)
            let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
            plan.setReminders(days: days, hour: parts.hour ?? 9, minute: parts.minute ?? 0)
            let scheduler = ReminderScheduler(center: SystemNotificationCenter())
            let requested = reminders
            let enabled = requested ? await scheduler.turnOn(plan: plan, body: ReminderText.body, sessions: sessions) : false
            if !reminders { await scheduler.turnOff(plan: plan, body: ReminderText.body) }
            plan.recordRevision()
            do { try context.save() }
            catch {
                plan.dayChoicesData = oldChoices
                plan.revisionsData = oldVersions
                plan.routines = oldRoutines; plan.weeklyGoal = oldGoal; plan.reminders = oldSlots; plan.remindersEnabled = oldEnabled
                await scheduler.sync(plan: plan, body: ReminderText.body, sessions: sessions)
                throw error
            }
            await scheduler.sync(plan: plan, body: ReminderText.body, sessions: sessions)
            self.reminders = plan.remindersEnabled
            message = requested && !enabled ? Loc.t("Plan saved. Reminders could not be set. Check notification settings.") : Loc.t("Plan saved.")
        } catch { self.error = true }
    }
}
