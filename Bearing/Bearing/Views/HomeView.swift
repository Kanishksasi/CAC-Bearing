import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query private var allSessions: [Session]
    @Query private var plans: [CarePlan]
    @State private var voicePreview = SpeechCoach()
    @Environment(\.modelContext) private var context
    @Query private var settings: [UserSettings]
    @State private var path = NavigationPath()
    @State private var navigationID = UUID()
    @State private var showIntro = false
    @State private var authenticating = false
    @State private var language = Loc.preference
    @State private var settingsError = false
    private var current: UserSettings? { settings.first }

    var body: some View {
        NavigationStack(path: $path) {
            BearingPage {
                VStack(alignment: .leading, spacing: 16) {
                    BearingMark()
                    Text("Your movement.\nYour own pace.")
                        .font(.system(.largeTitle, design: .serif).weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Personal movement tracking").font(.headline)
                    Text("Guided movement check-ins. A record you can return to.")
                        .font(.body).foregroundStyle(BearingStyle.muted)
                }
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Image(systemName: "figure.arms.open").font(.title2).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Arm raise").font(.title3.bold())
                            Text("One arm. Three attempts.").font(.subheadline).foregroundStyle(BearingStyle.muted)
                        }
                    }
                    NavigationLink {
                        SetupView(voiceEnabled: current?.voiceEnabled ?? true, helperMode: current?.caregiverMode ?? false)
                    } label: {
                        HStack { Text("Start arm raise"); Spacer(); Image(systemName: "arrow.right").accessibilityHidden(true) }
                    }.buttonStyle(BearingPrimaryButton()).accessibilityLabel("Start arm raise")
                    Label("Video is never saved", systemImage: "lock")
                        .font(.footnote).foregroundStyle(BearingStyle.muted)
                }.padding(20).background(BearingStyle.surface, in: RoundedRectangle(cornerRadius: 24))
                VStack(spacing: 0) {
                    NavigationLink { RoutineLibraryView() } label: { homeRow("All routines", symbol: "figure.walk") }
                        .accessibilityLabel("All routines")
                    Divider().overlay(BearingStyle.line)
                    NavigationLink { CustomCheckInsView() } label: { homeRow("Custom check-ins", symbol: "slider.horizontal.3") }
                        .accessibilityLabel("Custom check-ins")
                    Divider().overlay(BearingStyle.line)
                    NavigationLink { TodayPlanView() } label: { homeRow("Today", symbol: "calendar.badge.clock") }
                        .accessibilityLabel("Today")
                    Divider().overlay(BearingStyle.line)
                    NavigationLink { PlanView() } label: { homeRow("My plan", symbol: "calendar") }
                        .accessibilityLabel("My plan")
                    Divider().overlay(BearingStyle.line)
                    NavigationLink { HistoryView() } label: { homeRow("History", symbol: "clock") }
                        .accessibilityLabel("History")
                    Divider().overlay(BearingStyle.line)
                    NavigationLink { PrivacyView() } label: { homeRow("Privacy and data", symbol: "lock.shield") }
                        .accessibilityLabel("Privacy and data")
                }.buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 12) {
                    SectionCaption(title: "Make it yours")
                    Toggle("Spoken instructions", isOn: Binding(
                        get: { current?.voiceEnabled ?? true },
                        set: { value in updateSettings { $0.voiceEnabled = value } }))
                        .frame(minHeight: 48).tint(Color.accentColor)
                    Picker("Voice speed", selection: Binding(
                        get: { SpeechSpeed(rawValue: current?.speechSpeedRaw ?? "normal") ?? .normal },
                        set: { value in updateSettings { $0.speechSpeedRaw = value.rawValue } })) {
                        ForEach(SpeechSpeed.allCases) { speed in Text(speed.title).tag(speed) }
                    }.accessibilityIdentifier("VoiceSpeed")
                    Button("Try voice") {
                        let coach = voicePreview
                        coach.speed = SpeechSpeed(rawValue: current?.speechSpeedRaw ?? "normal") ?? .normal
                        coach.repeatOnce(Loc.t("Move at your own pace. Stop whenever you need."))
                    }.frame(minHeight: 48)
                    Toggle("Lock personal records", isOn: Binding(get: { current?.appLockEnabled ?? false }, set: { value in
                        Task {
                            authenticating = true
                            if await DeviceAuthentication.authenticate() { updateSettings { $0.appLockEnabled = value } }
                            authenticating = false
                        }
                    })).disabled(authenticating).tint(Color.accentColor).frame(minHeight: 48)
                    Text("Uses your device passcode or biometrics after Bearing goes into the background.")
                        .font(.footnote).foregroundStyle(BearingStyle.muted)
                    Text("Locking returns to Home. Save your results before leaving Bearing.").font(.footnote).foregroundStyle(BearingStyle.muted)
                    Toggle("Helper camera", isOn: Binding(get: { current?.caregiverMode ?? false },
                                                          set: { value in updateSettings { $0.caregiverMode = value } }))
                        .frame(minHeight: 48).tint(Color.accentColor)
                    Text("Uses the rear camera when someone holds your phone.").font(.footnote).foregroundStyle(BearingStyle.muted)
                    Divider().overlay(BearingStyle.line)
                    HStack {
                        Text("Language")
                        Spacer()
                        Picker("Language", selection: Binding(get: { language }, set: changeLanguage)) {
                            ForEach(AppLanguage.allCases, id: \.self) { Text($0.title).tag($0) }
                        }.labelsHidden().frame(minHeight: 48).accessibilityIdentifier("LanguagePicker")
                    }
                }
                PrivacyNote()
            }
            .navigationTitle("Bearing")
            .task {
                do {
                    if settings.isEmpty { context.insert(UserSettings()); try context.save() }
                    language = Loc.preference
                    showIntro = !(current?.hasSeenIntro ?? false)
                    await ReminderScheduler(center: SystemNotificationCenter()).sync(plan: plans.first, body: ReminderText.body, sessions: allSessions)
                } catch { settingsError = true }
            }
            .sheet(isPresented: $showIntro) {
                BearingPage {
                    BearingMark().padding(.top, 12)
                    Text("Before you start").font(.system(.largeTitle, design: .serif).weight(.medium))
                    Text(Strings.safetyIntro).font(.title3)
                    Label {
                        Text("Bearing works offline. It has no accounts and does not save video.")
                    } icon: { Image(systemName: "lock.shield").accessibilityHidden(true) }
                    .padding(20).background(BearingStyle.wash, in: RoundedRectangle(cornerRadius: 20))
                    PrivacyNote()
                    Button("I understand") {
                        updateSettings { $0.hasSeenIntro = true }
                        showIntro = false
                    }.buttonStyle(BearingPrimaryButton())
                }.interactiveDismissDisabled().presentationDragIndicator(.visible)
            }
            .alert("Settings could not be saved", isPresented: $settingsError) {
                Button("OK", role: .cancel) {}
            } message: { Text("Try your change again.") }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await ReminderScheduler(center: SystemNotificationCenter()).sync(plan: plans.first, body: ReminderText.body, sessions: allSessions) } }
        }
        .onDisappear { voicePreview.stop() }
        .id(navigationID)
        .environment(\.returnHome, { path = NavigationPath(); navigationID = UUID() })
        .environment(\.locale, Loc.locale)
    }

    private func homeRow(_ title: LocalizedStringKey, symbol: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.title3).frame(width: 28).foregroundStyle(Color.accentColor).accessibilityHidden(true)
            Text(title).font(.headline)
            Spacer()
            Image(systemName: "chevron.right").font(.footnote.bold()).foregroundStyle(BearingStyle.muted).accessibilityHidden(true)
        }.padding(.vertical, 20).contentShape(Rectangle())
    }

    private func changeLanguage(_ value: AppLanguage) {
        Loc.preference = value
        language = value
        updateSettings { $0.languageRaw = value.rawValue }
    }

    private func updateSettings(_ update: (UserSettings) -> Void) {
        guard let current else { return }
        update(current)
        do { try context.save() } catch { settingsError = true }
    }
}

struct SetupView: View {
    @Query private var settings: [UserSettings]
    let voiceEnabled: Bool
    let exercise: Exercise
    let template: CustomCheckIn?
    @StateObject private var coordinator: SessionCoordinator
    @State private var side: Side
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var supportConfirmed = false

    init(voiceEnabled: Bool, initialSide: Side = .right, exercise: Exercise = .armRaise, template: CustomCheckIn? = nil, helperMode: Bool = false) {
        self.exercise = exercise; self.template = template
        _coordinator = StateObject(wrappedValue: SessionCoordinator(exercise: exercise, template: template, helperMode: helperMode))
        self.voiceEnabled = voiceEnabled
        _side = State(initialValue: initialSide)
    }

    var body: some View {
        BearingPage {
            VStack(alignment: .leading, spacing: 14) {
                SectionCaption(title: "1. Prepare")
                Text(template?.name ?? exercise.title).font(.largeTitle.bold())
                if exercise.isAngle {
                    Text(exercise == .kneeBend ? Loc.t("Choose a side") : Loc.t("Choose an arm")).font(.title2.bold())
                    if typeSize.isAccessibilitySize { VStack(spacing: 10) { armChoices } }
                    else { HStack(spacing: 12) { armChoices } }
                }
                if let template, !template.instructions.isEmpty { Text(template.instructions).foregroundStyle(BearingStyle.muted) }
                if exercise.isSideView { Label("Side view", systemImage: "person.crop.rectangle").font(.headline) }
            }
            VStack(alignment: .leading, spacing: 24) {
                ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, step in
                    InstructionRow(number: index + 1, title: "", detail: step)
                }
            }
            if exercise.needsSupport {
                Text(Strings.supportSafety).font(.headline)
                Toggle("Support and someone are within reach", isOn: $supportConfirmed)
                    .tint(Color.accentColor).frame(minHeight: 48)
            }
            Text(Strings.safetyIntro).font(.callout)
                .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                .background(BearingStyle.wash, in: RoundedRectangle(cornerRadius: 18))
            Button { repeatSetup(forceAudio: true) } label: {
                Label("Repeat instructions", systemImage: "speaker.wave.2")
            }.buttonStyle(BearingSecondaryButton())
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            NavigationLink {
                RecordView(coordinator: coordinator, side: side, voiceEnabled: voiceEnabled)
            } label: {
                HStack { Text("Continue"); Spacer(); Image(systemName: "arrow.right").accessibilityHidden(true) }
            }.buttonStyle(BearingPrimaryButton()).accessibilityLabel("Continue")
                .disabled(exercise.needsSupport && !supportConfirmed)
                .padding(.horizontal, 24).padding(.vertical, 12).background(BearingStyle.paper)
        }
        .navigationTitle(Loc.t("Prepare"))
        .task { repeatSetup() }
        .onChange(of: side) { _, _ in repeatSetup() }
        .onDisappear { coordinator.speech.stop() }
    }

    private var armChoices: some View {
        ForEach([Side.right, .left], id: \.self) { choice in
            Button { side = choice } label: {
                HStack(spacing: 8) {
                    Text(exercise.sideTitle(choice)).font(.headline)
                    Spacer(minLength: 4)
                    Image(systemName: side == choice ? "checkmark.circle.fill" : "circle").accessibilityHidden(true)
                }.padding(16).frame(maxWidth: .infinity, minHeight: 58)
                    .foregroundStyle(side == choice ? Color.accentColor : BearingStyle.muted)
                    .background(side == choice ? BearingStyle.wash : BearingStyle.surface, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(side == choice ? Color.accentColor : BearingStyle.line, lineWidth: side == choice ? 2 : 1))
            }.buttonStyle(.plain).accessibilityLabel(exercise.sideTitle(choice))
                .accessibilityAddTraits(side == choice ? [.isSelected] : [])
        }
    }

    private func repeatSetup(forceAudio: Bool = false) {
        coordinator.speech.speed = SpeechSpeed(rawValue: settings.first?.speechSpeedRaw ?? "normal") ?? .normal
        coordinator.speech.isEnabled = voiceEnabled
        let text = ([exercise.title] + (exercise.isAngle ? [exercise.sideTitle(side)] : []) + exercise.instructions
                    + [template?.instructions ?? "", exercise.needsSupport ? Strings.supportSafety : Strings.safetyIntro]).joined(separator: " ")
        if forceAudio { coordinator.speech.repeatOnce(text) } else { coordinator.speech.speak(text, force: true) }
    }
}
