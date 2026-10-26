import SwiftUI
import SwiftData

@MainActor
enum PlanStore {
    static func ensure(_ context: ModelContext) throws -> CarePlan {
        if let plan = try context.fetch(FetchDescriptor<CarePlan>()).first { return plan }
        let plan = CarePlan(); context.insert(plan)
        do { try context.save(); return plan } catch { context.delete(plan); throw error }
    }
}

struct CustomCheckInsView: View {
    @Environment(\.modelContext) private var context
    @Query private var plans: [CarePlan]
    @Query private var settings: [UserSettings]
    @State private var error = false
    var body: some View {
        BearingPage {
            Text("Make a check-in yours").font(.largeTitle.bold())
            Text("Choose a supported routine or record a timer or count yourself.").foregroundStyle(BearingStyle.muted)
            NavigationLink { CustomEditorView() } label: {
                Label("Create a check-in", systemImage: "plus")
            }.buttonStyle(BearingPrimaryButton())
            if plans.first?.customCheckIns.isEmpty ?? true {
                Text("Your custom check-ins will appear here.")
            }
            ForEach(plans.first?.customCheckIns ?? []) { template in
                VStack(alignment: .leading, spacing: 14) {
                    Text(template.name).font(.title3.bold())
                    Text(template.exercise.title).foregroundStyle(BearingStyle.muted)
                    if !template.instructions.isEmpty { Text(template.instructions) }
                    NavigationLink {
                        if template.exercise.isManual { ManualCheckInView(template: template) }
                        else {
                            SetupView(voiceEnabled: settings.first?.voiceEnabled ?? true, initialSide: template.side,
                                      exercise: template.exercise, template: template, helperMode: settings.first?.caregiverMode ?? false)
                        }
                    } label: { Text("Open check-in") }.buttonStyle(BearingSecondaryButton())
                        .accessibilityIdentifier("OpenCustom").accessibilityLabel(Loc.f("Open %@", template.name))
                    NavigationLink { CustomEditorView(original: template) } label: { Text("Edit check-in").frame(minHeight: 44) }
                        .accessibilityLabel(Loc.f("Edit %@", template.name))
                }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                    .background(BearingStyle.surface, in: RoundedRectangle(cornerRadius: 20))
            }
            PrivacyNote()
        }.navigationTitle("Custom check-ins")
            .task { do { _ = try PlanStore.ensure(context) } catch { self.error = true } }
            .alert("Changes could not be saved", isPresented: $error) { Button("OK", role: .cancel) {} }
    }
}

struct CustomEditorView: View {
    var original: CustomCheckIn?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var instructions = ""
    @State private var exercise = Exercise.armRaise
    @State private var side = Side.right
    @State private var seconds = 60
    @State private var error = false
    @State private var confirmDelete = false
    private var draft: CustomCheckIn { CustomCheckIn(name: name, instructions: instructions, exercise: exercise, side: side, timerSeconds: seconds) }
    var body: some View {
        Form {
            Section {
                TextField("Check-in name", text: $name).accessibilityIdentifier("CustomName")
                    .onChange(of: name) { _, value in name = String(value.prefix(60)) }
                Picker("Record with", selection: $exercise) {
                    ForEach(Exercise.allCases) { Text($0.title).tag($0) }
                }.pickerStyle(.menu).accessibilityIdentifier("CustomRecorder")
                if exercise.isAngle {
                    Picker("Side", selection: $side) {
                        ForEach(Side.allCases, id: \.self) { Text(exercise.sideTitle($0)).tag($0) }
                    }
                }
                if exercise == .manualTimer { Stepper(Loc.f("Timer: %lld seconds", seconds), value: $seconds, in: 5...600, step: 5) }
            }
            Section("Your instructions") {
                TextField("Instructions you already follow", text: $instructions, axis: .vertical).lineLimit(3...8)
                    .onChange(of: instructions) { _, value in instructions = String(value.prefix(500)) }
                Text("Use guidance you already have. Bearing does not choose movements for you.").font(.footnote)
            }
            if original != nil {
                Section {
                    Text("Edits start a new comparison history. Earlier results stay saved.")
                    Button("Delete check-in", role: .destructive) { confirmDelete = true }.tint(BearingStyle.danger)
                }
            }
            Section {
                Text(exercise.isManual ? Loc.t("Manual entries are not camera measurements.") : Loc.t("Camera tracking checks stay fixed for this routine."))
                Button("Save check-in") { save() }.disabled(!draft.isValid).accessibilityIdentifier("SaveCustom")
            }
        }.scrollDismissesKeyboard(.interactively).scrollContentBackground(.hidden).background(BearingStyle.paper).buttonStyle(.automatic)
            .navigationTitle(original == nil ? Loc.t("Create a check-in") : Loc.t("Edit check-in"))
            .task { if let original { name = original.name; instructions = original.instructions; exercise = original.exercise; side = original.side; seconds = original.timerSeconds } }
            .alert("Changes could not be saved", isPresented: $error) { Button("OK", role: .cancel) {} }
            .confirmationDialog("Delete this check-in? Saved results will remain.", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete check-in", role: .destructive) { save(deleting: true) }
                Button("Cancel", role: .cancel) {}
            }
    }
    private func save(deleting: Bool = false) {
        do {
            let plan = try PlanStore.ensure(context)
            let previous = plan.customTemplatesData
            var templates = plan.customCheckIns
            if let original { templates.removeAll { $0.id == original.id } }
            if !deleting {
                var clean = draft
                clean.name = clean.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard clean.isValid else { return }
                templates.append(clean)
            }
            plan.customCheckIns = templates
            do { try context.save(); dismiss() }
            catch { plan.customTemplatesData = previous; throw error }
        } catch { self.error = true }
    }
}
