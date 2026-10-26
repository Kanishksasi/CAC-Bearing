import SwiftUI
import SwiftData

struct PrivacyView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confirm = false
    @State private var resultMessage: String?
    @State private var deleted = false

    var body: some View {
        BearingPage {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "lock.shield").font(.system(size: 36, weight: .light)).foregroundStyle(Color.accentColor).accessibilityHidden(true)
                Text("Your data stays with you.").font(.system(.largeTitle, design: .serif).weight(.medium))
                Text("What Bearing does").font(.title2.bold())
                Text("Works offline. No accounts. No app-operated server or telemetry. No analytics. No third-party code.")
                Text("Camera pictures stay in memory while Bearing measures movement. The app saves no images or video.")
                Divider().overlay(BearingStyle.line)
                Text("What is saved on this phone").font(.title2.bold())
                Text("Dates, movement values, counts, reasons, plans, custom instructions, and settings stay on this phone.")
                Text("Local reminders use only the days and times you choose.")
                Text("Older session numbers remain available after an app update. They do not set your new starting point.")
                Text("Device backups may include app data.")
                Divider().overlay(BearingStyle.line)
                Text("Sharing").font(.title2.bold())
                Text("A temporary PDF is created when you choose Preview PDF.")
                Text("It is shared only when you choose. Copies may remain wherever you send it.")
                Text("Deleting data here does not remove copies you shared or older device backups.")
                Text("You choose whether history, plan details, and saved custom instructions appear in the PDF.")
                Text("Physician connections are not available. Choose your clinician's agreed sharing method.")
                Text("A share sheet cannot verify the recipient or confirm that a clinician read the report.")
                Text("A device lock is available in Make it yours. It does not protect copies shared outside Bearing.")
                Text(Strings.disclaimer).font(.footnote).foregroundStyle(.primary)
                Button(role: .destructive) { confirm = true } label: {
                    Text("Delete all my data").frame(maxWidth: .infinity, minHeight: 56)
                }.buttonStyle(.bordered).tint(BearingStyle.danger)
            }
        }
        .navigationTitle("Privacy and data")
        .confirmationDialog("Delete all sessions and settings on this phone?", isPresented: $confirm, titleVisibility: .visible) {
            Button("Delete all", role: .destructive) { deleteAll() }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete all my data", isPresented: Binding(get: { resultMessage != nil }, set: { if !$0 { finish() } })) {
            Button("OK", role: .cancel) { finish() }
        } message: { Text(resultMessage ?? "") }
    }

    private func finish() {
        resultMessage = nil
        if deleted { Loc.preference = .system; dismiss() }
    }

    private func deleteAll() {
        do {
            try SessionStore(context: context).deleteAllData()
            deleted = true
            resultMessage = Loc.t("All sessions, settings, and temporary PDFs were deleted.")
        } catch {
            resultMessage = Loc.t("Some data could not be deleted. Try Delete all my data again.")
        }
    }
}
