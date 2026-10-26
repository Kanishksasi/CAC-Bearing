import SwiftUI
import SwiftData

struct ResultView: View {
    let session: Session
    @Environment(\.returnHome) private var returnHome
    @Query(sort: \Session.date) private var all: [Session]
    @Query private var plans: [CarePlan]
    @Query private var settings: [UserSettings]
    @State private var pdfURL: URL?
    @State private var pdfError = false
    @State private var reportSharing = false
    private var earlier: [Session] { all.filter { $0.date <= session.date } }

    var body: some View {
        BearingPage {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    SectionCaption(title: session.exercise.isManual ? "Your result" : "3. Your result")
                    Text(session.customTitle.isEmpty && session.exercise == .armRaise ? session.side.title : session.displayTitle).font(.largeTitle.bold())
                    if session.exercise.isAngle && (session.exercise != .armRaise || !session.customTitle.isEmpty) {
                        Text(session.exercise.sideTitle(session.side)).font(.headline)
                    }
                    Text(session.date.formatted(.dateTime.locale(Loc.locale).year().month(.abbreviated).day().hour().minute()))
                        .font(.subheadline).foregroundStyle(BearingStyle.muted)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text(session.measurementTitle).font(.headline)
                    Text(session.valueText).font(.system(.largeTitle, design: .serif).weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(session.exercise.isManual ? Loc.t("Manual entry") : Strings.countedLine(session))
                        .font(.subheadline).foregroundStyle(BearingStyle.muted)
                    if let sway = session.swayRatio {
                        Text(Loc.f("Sway: %.3f of shoulder width", sway)).font(.callout)
                    }
                    if let foot = session.liftedFootRaw {
                        Text(foot == Side.left.rawValue ? Loc.t("Left foot lifted") : Loc.t("Right foot lifted"))
                    }
                }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
                    .background(BearingStyle.wash, in: RoundedRectangle(cornerRadius: 24))
                PrivacyNote()
                VStack(alignment: .leading, spacing: 12) {
                    Text("What this number means").font(.title3.bold())
                    if session.value != nil {
                        Text(session.exercise.resultMeaning)
                        if session.exercise.isAngle {
                            Text("The summary uses the middle value of counted attempts. With two, it uses their average.")
                        }
                        if session.swayRatio != nil {
                            Text("Sway describes side-to-side hip movement compared with shoulder width during this hold.")
                        }
                        Text("A larger or smaller number does not tell you whether your health changed.")
                    } else {
                        Text("This recording did not give a usable value. Read the reasons below before trying again.")
                    }
                }.padding(20).background(BearingStyle.surface, in: RoundedRectangle(cornerRadius: 20))
                ExplainCardView(session: session)
                if !session.customInstructions.isEmpty { Text(session.customInstructions) }
                comparison
                Text("Keep the same routine, side, and phone position when comparing sessions.")
                    .font(.callout).foregroundStyle(BearingStyle.muted)
                SessionTrendView(session: session, sessions: all)
                if !session.exercise.isManual { Text(Strings.setupVariationNote).font(.callout).foregroundStyle(BearingStyle.muted) }
                if session.exercise.isAngle {
                    NavigationLink {
                        SetupView(voiceEnabled: settings.first?.voiceEnabled ?? true,
                                  initialSide: session.side == .right ? .left : .right, exercise: session.exercise, template: session.cameraTemplateSnapshot,
                                  helperMode: settings.first?.caregiverMode ?? false)
                    } label: {
                        Text(session.exercise == .kneeBend ? Loc.t("Record the other side") : Loc.t("Record the other arm"))
                    }.buttonStyle(BearingSecondaryButton())
                }
                Text("PDF includes recording details, matching history, and review notes.")
                    .font(.callout).foregroundStyle(BearingStyle.muted)
                if !session.recentExports.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent report exports").font(.headline)
                        ForEach(session.recentExports.reversed()) { event in
                            Text(event.preparedAt.formatted(.dateTime.locale(Loc.locale).month().day().hour().minute()))
                            Text(event.handedToAnotherAppAt == nil ? Loc.t("PDF prepared on this phone") : Loc.t("Handed to another app"))
                        }
                        Text("Receipt and review are not confirmed.").font(.callout)
                    }
                }
                Button { returnHome() } label: {
                    Text("Done").font(.headline).frame(maxWidth: .infinity, minHeight: 56)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain).foregroundStyle(Color.accentColor)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            exportButton.padding(.horizontal, 24).padding(.vertical, 12).background(BearingStyle.paper)
        }
        .navigationTitle("Result")
        .alert("The PDF could not be created.", isPresented: $pdfError) {
            Button("OK", role: .cancel) {}
        } message: { Text("Try creating the summary again.") }
    }

    private var exportButton: some View {
        Button { reportSharing = true } label: {
            Label("Create PDF summary", systemImage: "doc.text")
        }.buttonStyle(BearingPrimaryButton())
            .sheet(isPresented: $reportSharing) { ReportSharingView(session: session, sessions: all, plan: plans.first) }
    }

    @ViewBuilder private var comparison: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let baseline = BaselineService.startingPoint(for: session, in: earlier) {
                Text("Your starting point").font(.headline)
                Text("This is your own earlier record, not a target to reach.").font(.callout)
                Text(session.formattedValue(baseline)).font(.title2.bold())
                Text(session.exercise.isAngle ? Loc.t("Design choice: your first three sessions with at least two counted attempts each.") : Loc.t("Your starting point uses your first three matching entries.")).font(.callout)
                if let difference = BaselineService.change(for: session, in: earlier) {
                    Text("Difference from your own earlier sessions").font(.headline)
                    Text("Plus means a larger number. Minus means a smaller number.").font(.callout)
                    Text((difference < 0 ? "−" : "+") + session.formattedValue(abs(difference))).font(.title2.bold())
                }
            } else {
                HStack(spacing: 8) {
                    ForEach(0..<Parameters.baselineSessions, id: \.self) { index in
                        Capsule().fill(index < min(BaselineService.comparable(to: session, in: earlier).count, Parameters.baselineSessions) ? Color.accentColor : BearingStyle.line)
                            .frame(height: 6)
                    }
                }.accessibilityHidden(true)
                Text(Loc.f("Building your starting point: %lld of %lld sessions.",
                           min(BaselineService.comparable(to: session, in: earlier).count, Parameters.baselineSessions), Parameters.baselineSessions))
                Text(session.exercise.isAngle ? Loc.t("Your starting point uses sessions with at least two counted attempts.") : Loc.t("Only matching check-ins with a recorded value are included.")).font(.callout)
            }
        }
    }
}

struct ExplainCardView: View {
    let session: Session
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(session.exercise.isManual ? Loc.t("How this was recorded") : Loc.t("How we measured this")).font(.title3.bold())
            ForEach(NotCountedReason.allCases, id: \.self) { reason in
                let count = session.notCountedReasons.filter { $0 == reason.rawValue }.count
                if count > 0 { Text(Loc.f("%lld not counted: %@", count, reason.message)) }
            }
            if session.countedPeaks.count >= 2,
               let latest = session.latest, let low = session.lowest, let high = session.highest {
                Text(session.exercise == .armRaise ? Strings.explainMeasureLine(latest: latest, low: low, high: high)
                     : Loc.f("Projected angle: %.0f degrees. Your counted attempts ranged from %.0f to %.0f degrees.", latest, low, high))
                Text("This spread shows variation between attempts. It is not a measurement error range.")
            } else if let latest = session.latest {
                Text(Loc.f(session.exercise == .armRaise ? "Projected arm angle: %.0f degrees. The spread is not available with one counted attempt."
                           : "Projected angle: %.0f degrees. The spread is not available with one counted attempt.", latest))
            }
            Text(session.exercise.method).foregroundStyle(BearingStyle.muted)
            if !session.exercise.isManual { Text(session.exercise.limits).foregroundStyle(BearingStyle.muted) }
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(BearingStyle.surface, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}
