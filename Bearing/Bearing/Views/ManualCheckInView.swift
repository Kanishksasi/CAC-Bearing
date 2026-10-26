import SwiftUI
import SwiftData

struct ManualCheckInView: View {
    let template: CustomCheckIn
    @Query private var settings: [UserSettings]
    @Query private var plans: [CarePlan]
    @State private var planAtStart: PlanRevision?
    @State private var speech = SpeechCoach()
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var phase
    @State private var count = 0
    @State private var elapsed = 0.0
    @State private var timer: ManualTimerState
    private var running: Bool { timer.running }
    init(template: CustomCheckIn) {
        self.template = template
        _timer = State(initialValue: ManualTimerState(limit: Double(template.timerSeconds)))
    }
    @State private var saved: Session?
    @State private var showResult = false
    @State private var error = false
    var body: some View {
        BearingPage {
            Text(template.name).font(.largeTitle.bold())
            Text("Manual entry").font(.headline)
            ForEach(template.exercise.instructions, id: \.self) { Text($0) }
            if !template.instructions.isEmpty { Text(template.instructions) }
            Button { speech.repeatOnce(spokenInstructions) } label: {
                Label("Repeat instructions", systemImage: "speaker.wave.2")
            }.buttonStyle(BearingSecondaryButton())
            if template.exercise == .manualCount {
                Text(Loc.f("%lld repetitions", count)).font(.largeTitle.bold())
                Stepper("Your count", value: $count, in: 0...1000).frame(minHeight: 56)
            } else {
                Text(Loc.f("%.1f seconds", elapsed)).font(.largeTitle.bold()).monospacedDigit().accessibilityIdentifier("ManualElapsed")
                Text(Loc.f("Timer limit: %lld seconds", template.timerSeconds)).foregroundStyle(BearingStyle.muted)
                Button(running ? Loc.t("Pause timer") : Loc.t("Start timer")) {
                    if running { pause() } else { timer.start(now: CameraService.now) }
                }.buttonStyle(BearingSecondaryButton())
                Button("Reset timer") { timer.reset(); elapsed = 0 }.frame(minHeight: 44)
            }
            Text(Strings.safetyIntro)
            PrivacyNote()
            Button("Save and see results") { save() }.buttonStyle(BearingPrimaryButton())
                .disabled(running || (template.exercise == .manualTimer && elapsed < 0.5))
        }.navigationTitle("Custom check-in")
            .task {
                planAtStart = plans.first?.currentRevision
                speech.speed = SpeechSpeed(rawValue: settings.first?.speechSpeedRaw ?? "normal") ?? .normal
                speech.isEnabled = settings.first?.voiceEnabled ?? true
                speech.speak(spokenInstructions, force: true)
            }
            .task(id: running) {
                guard running else { return }
                while !Task.isCancelled && running {
                    elapsed = timer.tick(now: CameraService.now)
                    do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
                }
            }
            .onChange(of: phase) { _, value in if value != .active { pause() } }
            .onDisappear { pause(); speech.stop() }
            .navigationDestination(isPresented: $showResult) { if let saved { ResultView(session: saved) } }
            .alert("Session could not be saved", isPresented: $error) { Button("OK", role: .cancel) {} }
    }
    private var spokenInstructions: String { (template.exercise.instructions + [template.instructions, Strings.safetyIntro]).joined(separator: " ") }
    private func pause() { timer.pause(now: CameraService.now); elapsed = timer.elapsed(now: CameraService.now) }
    private func save() {
        if saved != nil { showResult = true; return }
        guard !running else { return }
        var result = AttemptResult(side: template.side, counted: true, peakAngle: nil, reason: nil)
        if template.exercise == .manualCount { result.repetitions = count } else { result.holdSeconds = elapsed }
        let record = Session.recorded(exercise: template.exercise, side: template.side, results: [result], template: template)
        record.planAtRecording = planAtStart
        do { try SessionStore(context: context).save(record); refreshReminders(); saved = record; showResult = true }
        catch { self.error = true }
    }
    private func refreshReminders() {
        Task { @MainActor in
            let plan = (try? context.fetch(FetchDescriptor<CarePlan>()))?.first
            let sessions = (try? context.fetch(FetchDescriptor<Session>())) ?? []
            await ReminderScheduler(center: SystemNotificationCenter()).sync(plan: plan, body: ReminderText.body, sessions: sessions)
        }
    }

}
