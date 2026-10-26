import SwiftUI
import SwiftData
import PDFKit

struct ReportSharingView: View {
    let session: Session
    let sessions: [Session]
    let plan: CarePlan?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var history = false
    @State private var includePlan = false
    @State private var instructions = false
    @State private var url: URL?
    @State private var exportID: UUID?
    @State private var consent = false
    @State private var sharing = false
    @State private var error = false
    @State private var errorMessage = Loc.t("The PDF could not be created.")
    @State private var handedOff = false

    var body: some View {
        NavigationStack {
            Group {
                if let url {
                    PDFPreview(url: url).accessibilityLabel(Loc.t("Report preview"))
                } else {
                    Form {
                        Section {
                            Text("Choose what this report includes. Review the PDF before choosing where to share it.")
                            Toggle("Include matching history", isOn: $history)
                            Text("Includes starting-point records and up to 24 matching records.").font(.footnote)
                            Toggle("Include plan details", isOn: $includePlan)
                            Toggle("Include saved custom instructions", isOn: $instructions)
                            Text("The selected result, date, routine, and recording details are always included.").font(.footnote)
                        }
                        Section {
                            Text("Physician connections are not available. Choose your clinician's agreed sharing method.")
                            Text("A share sheet cannot verify the recipient or confirm that a clinician read the report.")
                            Text("Shared copies may remain with the recipient after you delete data from Bearing.")
                        }
                    }.scrollContentBackground(.hidden).background(BearingStyle.paper)
                }
            }
            .navigationTitle(url == nil ? Loc.t("Report details") : Loc.t("Report"))
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 12) {
                    if url != nil {
                        Toggle("I reviewed this PDF.", isOn: $consent)
                            .toggleStyle(.switch).tint(Color.accentColor).accessibilityIdentifier("ReportConsent")
                        if handedOff {
                            Text("Handed to another app. Receipt and review are not confirmed.").font(.callout)
                        }
                        Button("Share PDF") { sharing = true }
                            .buttonStyle(BearingPrimaryButton()).disabled(!consent)
                    } else {
                        Button("Preview PDF") { prepare() }.buttonStyle(BearingPrimaryButton())
                    }
                }.padding(20).background(BearingStyle.paper)
            }
            .sheet(isPresented: $sharing) {
                if let url { ReportActivityView(url: url) { complete in if complete { markHandoff() } } }
            }
            .alert(errorMessage, isPresented: $error) { Button("OK", role: .cancel) {} }
        }.buttonStyle(.automatic)
    }
    private func prepare() {
        let old = session.recentExportsData
        do {
            let made = try ReportBuilder.makePDF(for: session, in: sessions, plan: plan,
                historyIncluded: history, planIncluded: includePlan, instructionsIncluded: instructions)
            let event = ReportExport(includesHistory: history, includesPlan: includePlan, includesInstructions: instructions)
            session.recentExports.append(event)
            do { try context.save() }
            catch { try? FileManager.default.removeItem(at: made); throw error }
            exportID = event.id; url = made
        } catch { session.recentExportsData = old; self.error = true }
    }
    private func markHandoff() {
        guard let exportID else { return }
        let old = session.recentExportsData
        var events = session.recentExports
        if let index = events.firstIndex(where: { $0.id == exportID }) { events[index].handedToAnotherAppAt = .now }
        session.recentExports = events
        do { try context.save(); handedOff = true }
        catch { session.recentExportsData = old; errorMessage = Loc.t("Sharing status could not be saved. Shared copies cannot be recalled."); self.error = true }
    }
}

private struct PDFPreview: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView(); view.autoScales = true; view.displayMode = .singlePageContinuous
        view.document = PDFDocument(url: url); return view
    }
    func updateUIView(_ view: PDFView, context: Context) {}
}

private struct ReportActivityView: UIViewControllerRepresentable {
    let url: URL
    let completed: (Bool) -> Void
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let view = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        view.completionWithItemsHandler = { _, complete, _, _ in
            Task { @MainActor in completed(complete) }
        }
        return view
    }
    func updateUIViewController(_ view: UIActivityViewController, context: Context) {}
}
