import UIKit

@MainActor
enum ReportBuilder {
    static func makePDF(for session: Session, in sessions: [Session], plan: CarePlan? = nil, historyIncluded: Bool = true, planIncluded: Bool = true, instructionsIncluded: Bool = true) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Bearing-summary-\(UUID().uuidString).pdf")
        try data(for: session, in: sessions, plan: plan, historyIncluded: historyIncluded, planIncluded: planIncluded, instructionsIncluded: instructionsIncluded).write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    static func data(for session: Session, in sessions: [Session], plan: CarePlan? = nil, historyIncluded: Bool = true, planIncluded: Bool = true, instructionsIncluded: Bool = true, generatedAt: Date = .now) -> Data {
        let earlier = sessions.filter { $0.date <= session.date }
        let details = session.reportDetails
        func date(_ value: Date) -> String {
            value.formatted(.dateTime.locale(Loc.locale).year().month(.abbreviated).day().hour().minute())
        }
        return UIGraphicsPDFRenderer(bounds: ReportPageWriter.page).pdfData { context in
            let pdf = ReportPageWriter(context: context, subtitle: session.displayTitle + " | " + date(session.date))
            pdf.newPage(Loc.t("Record overview"))
            pdf.text(historyIncluded ? Loc.t("Selected record with matching history") : Loc.t("Selected record only"))
            pdf.row(Loc.t("Report created"), date(generatedAt))
            pdf.row(Loc.t("Recorded on"), date(session.date))
            pdf.row(Loc.t("Report time zone"), TimeZone.current.identifier)
            pdf.text(Loc.t("Dates are shown in the report time zone."))
            pdf.text(Loc.t("Name (optional): ______________________"))
            pdf.text(Loc.t("Review date (optional): ______________________"))
            pdf.heading(session.displayTitle)
            if session.exercise.isAngle { pdf.text(session.exercise.sideTitle(session.side), bold: true) }
            pdf.row(Loc.t("Routine"), session.exercise.title)
            pdf.row(Loc.t("Source"), session.exercise.isManual ? Loc.t("Manual entry") : Loc.t("Camera estimate"))
            if session.exercise.isManual {
                pdf.text(session.valueText, size: 19, bold: true)
                pdf.text(Loc.t("You recorded this value yourself. It was not measured by the camera."))
            } else {
                pdf.text(Strings.countedLine(session), bold: true)
                pdf.text(session.measurementTitle + ": " + session.valueText, size: 19, bold: true)
                if session.value == nil {
                    pdf.text(session.exercise.isAngle ? Loc.t("There is no angle summary for this session.") : Loc.t("No value recorded"))
                }
            }
            if let sway = session.swayRatio { pdf.text(Loc.f("Sway: %.3f of shoulder width", sway)) }
            if let foot = session.liftedFootRaw { pdf.text(foot == "left" ? Loc.t("Left foot lifted") : Loc.t("Right foot lifted")) }
            pdf.heading(Loc.t("What this number means"))
            if session.value != nil {
                pdf.text(session.exercise.resultMeaning)
                if session.exercise.isAngle {
                    pdf.text(Loc.t("The summary uses the middle value of counted attempts. With two, it uses their average."))
                    if let low = session.lowest, let high = session.highest, session.countedPeaks.count >= 2 {
                        pdf.text(Loc.f("Observed variation: %.0f to %.0f degrees", low, high))
                        pdf.text(Loc.t("This spread shows variation between attempts. It is not a measurement error range."))
                    } else { pdf.text(Loc.t("The spread is not available with one counted attempt.")) }
                }
                pdf.text(Loc.t("A larger or smaller number does not tell you whether your health changed."))
            } else { pdf.text(Loc.t("This recording did not give a usable value. Read the reasons below before trying again.")) }
            pdf.heading(Loc.t("Review at a glance"))
            pdf.text(Loc.t("This report contains personal movement records, not a full health record."))
            pdf.text(Loc.t("Read the tracking limits and missing information before using these numbers."))
            if session.isLegacy { pdf.text(Loc.t("Older record. Detailed attempts were not saved.")) }

            pdf.newPage(Loc.t("Attempts and recording details"))
            if let details {
                for attempt in details.attempts {
                    pdf.heading(session.exercise.isManual ? Loc.t("Manual entry") : Loc.f("Attempt %lld: %@", attempt.number, attempt.counted ? Strings.counted : Strings.notCounted))
                    if let value = attempt.angle { pdf.text(Loc.f("Projected angle: %.0f degrees", value)) }
                    if let value = attempt.repetitions { pdf.text(Loc.f("%lld repetitions", value)) }
                    if let value = attempt.holdSeconds { pdf.text(Loc.f("%.1f seconds", value)) }
                    if let value = attempt.swayRatio { pdf.text(Loc.f("Sway: %.3f of shoulder width", value)) }
                    if let raw = attempt.reason { pdf.text(NotCountedReason(rawValue: raw)?.message ?? Loc.t("Reason not available")) }
                    else if !attempt.counted { pdf.text(Loc.t("Reason not available")) }
                    if let duration = attempt.durationSeconds { pdf.row(Loc.t("Recording duration"), Loc.f("%.1f seconds", duration)) }
                    else { pdf.row(Loc.t("Recording duration"), Loc.t("Not saved")) }
                    pdf.rule()
                }
            } else {
                pdf.text(Loc.t("The original order of attempts was not saved for this record."))
                for (index, peak) in session.countedPeaks.enumerated() {
                    pdf.text(Loc.f("Counted value %lld: %.0f degrees", index + 1, peak))
                }
            }
            if !session.notCountedReasons.isEmpty {
                pdf.heading(Loc.t("Attempts not counted"))
                for reason in NotCountedReason.allCases {
                    let count = session.notCountedReasons.filter { $0 == reason.rawValue }.count
                    if count > 0 { pdf.text(Loc.f("%lld not counted: %@", count, reason.message)) }
                }
                let known = Set(NotCountedReason.allCases.map(\.rawValue))
                if session.notCountedReasons.contains(where: { !known.contains($0) }) { pdf.text(Loc.t("Some saved reasons are not available in this app version.")) }
            }
            pdf.heading(Loc.t("Recording context"))
            let source: String
            switch details?.source {
            case "front": source = Loc.t("Front camera")
            case "rear": source = Loc.t("Rear camera")
            case "manual": source = Loc.t("Manual entry")
            default: source = Loc.t("Not saved")
            }
            pdf.row(Loc.t("Camera or entry source"), source)
            pdf.row(Loc.t("App version at saving"), details?.appVersion ?? Loc.t("Not saved"))
            pdf.row(Loc.t("Method version at saving"), details?.protocolVersion ?? Loc.t("Not saved"))
            pdf.row(Loc.t("Time zone at saving"), details?.timeZone ?? Loc.t("Not saved"))
            if session.exercise.isManual {
                pdf.text(Loc.t("Camera checks do not apply to manual entries."))
            } else {
                pdf.text(Loc.t("Frame rate, joint coverage, and phone angles were not saved as separate measurements."))
                pdf.text(Loc.t("A counted attempt met the recording rules. It does not confirm correct movement or health."))
            }
            pdf.reserve(145)
            pdf.heading(Loc.t("How these were measured"))
            pdf.text(session.exercise.method)
            if session.exercise.isAngle {
                pdf.text(Loc.t("Each counted angle uses the middle of the highest fresh, smoothed picture-angle samples."))
            }
            if !session.exercise.isManual {
                pdf.text(Loc.t("Setup checks cover phone tilt, body framing, and steady tracking."))
                pdf.text(Loc.t("Held joint positions cannot count as fresh measurements."))
                pdf.text(Loc.t("These checks use engineering settings, not medical cutoffs. Results compare only with your own earlier sessions."))
            }
            if details == nil { pdf.text(Loc.t("Exact recording settings for this older record were not saved.")) }

            if historyIncluded {
            pdf.section(Loc.t("Personal comparison and history"))
            let eligible = BaselineService.comparable(to: session, in: earlier)
            if let baseline = BaselineService.startingPoint(for: session, in: earlier) {
                pdf.row(Loc.t("Your starting point"), session.formattedValue(baseline))
                pdf.text(session.exercise.isAngle ? Loc.t("Design choice: your first three sessions with at least two counted attempts each.")
                         : Loc.t("Your starting point uses your first three matching entries."))
                for entry in eligible.prefix(Parameters.baselineSessions) { pdf.text(date(entry.date) + " | " + entry.valueText) }
                if let difference = BaselineService.change(for: session, in: earlier) {
                    pdf.row(Loc.t("Difference from your own earlier sessions"), (difference < 0 ? "-" : "+") + session.formattedValue(abs(difference)))
                    pdf.text(Loc.t("Plus means a larger number. Minus means a smaller number."))
                } else if session.value == nil {
                    pdf.text(Loc.t("No difference is shown because this record has no value."))
                } else { pdf.text(Loc.t("This record is part of the starting point. No later difference is shown.")) }
            } else {
                pdf.text(Loc.f("Building your starting point: %lld of %lld sessions.", min(eligible.count, Parameters.baselineSessions), Parameters.baselineSessions))
            }
            pdf.text(Loc.t("This is your own earlier record, not a target to reach."))
            pdf.text(Loc.t("Keep the same routine, side, and phone position when comparing sessions."))
            let matching = earlier.filter {
                !$0.isLegacy && $0.exerciseRaw == session.exerciseRaw && $0.customID == session.customID
                    && (!session.exercise.isAngle || $0.side == session.side)
                    && (session.exercise != .balance || $0.liftedFootRaw == session.liftedFootRaw)
            }.sorted { $0.date < $1.date }
            pdf.heading(Loc.t("Matching saved records"))
            pdf.text(Loc.t("History ends at the selected record. Later records are not included."))
            pdf.text(Loc.t("Routine, side or lifted foot, and custom template must match."))
            pdf.text(Loc.f("Showing %lld of %lld matching records, most recent first.", min(24, matching.count), matching.count))
            pdf.text(Loc.t("Date and time | Recorded value | Counted attempts"), bold: true)
            for entry in matching.suffix(24).reversed() {
                pdf.text(date(entry.date) + " | " + entry.valueText + " | "
                         + (entry.exercise.isManual ? Loc.t("Manual entry") : Strings.countedLine(entry)), gap: 10)
                pdf.rule()
            }
            if matching.isEmpty { pdf.text(Loc.t("No matching saved records are available.")) }
            pdf.text(Loc.t("Records without a value remain visible. They do not enter the starting point."))
            if session.exercise.isAngle { pdf.text(Loc.t("One counted attempt can appear in history, but cannot enter the starting point.")) }

            } else { pdf.text(Loc.t("Personal history was left out of this report.")) }
            pdf.section(Loc.t("Plan context and review notes"))
            if planIncluded, let snapshot = session.planAtRecording {
                pdf.heading(Loc.t("Personal plan at recording"))
                pdf.text(Loc.f("Version %lld", snapshot.number))
                pdf.text(snapshot.routines.map(\.title).joined(separator: ", "))
                pdf.text(Loc.f("Weekly goal: %lld check-ins", snapshot.weeklyGoal))
                pdf.text(Loc.t("This is a saved personal plan version, not a verified physician assignment."))
            } else if planIncluded { pdf.text(Loc.t("The plan version at recording was not saved.")) }
            if !planIncluded { pdf.text(Loc.t("Plan details were left out of this report.")) }
            if planIncluded, let plan, !plan.routines.isEmpty {
                pdf.heading(Loc.t("Your current plan"))
                pdf.text(plan.routines.map(\.title).joined(separator: ", "))
                pdf.text(Loc.f("Weekly goal: %lld check-ins", plan.weeklyGoal))
                pdf.text(Loc.t("The goal shown is your current goal."))
                pdf.text(Loc.t("Past goals and assignments were not saved. These counts use the current routine choices."))
                pdf.text(Loc.t("The weeks below end with the selected record's week."))
                for week in PlanService.recentWeeks(plan: plan, sessions: earlier, now: session.date) {
                    pdf.text(date(week.weekStart) + " | " + Loc.f("%lld saved check-ins", week.done))
                }
                pdf.text(Loc.t("Saved entries do not prove that every planned exercise was completed."))
                pdf.text(Loc.t("This plan was entered on this phone. No professional assignment is verified."))
            } else { pdf.text(Loc.t("No current personal plan was provided for this report.")) }
            if instructionsIncluded, !session.customInstructions.isEmpty {
                pdf.heading(Loc.t("Your instructions")); pdf.text(session.customInstructions)
                pdf.text(Loc.t("These are the instructions saved with this record. Their author is not verified."))
            }
            pdf.heading(Loc.t("Information Bearing does not collect"))
            for item in ["Pain, symptoms, injuries, and the reason for doing the routine are not recorded.",
                         "Medicines, medical history, vital signs, and physical examination findings are not recorded.",
                         "Use of support, crossed arms, and how closely instructions were followed are not verified.",
                         "No video, pictures, or raw joint sequences are saved for later review."] {
                pdf.text(Loc.t(item))
            }
            pdf.reserve(340)
            pdf.heading(Loc.t("Notes to discuss with your clinician"))
            pdf.text(Loc.t("Add context when sharing. These blank lines are not saved health information."))
            for item in ["Symptoms or discomfort during the routine: ______________________",
                         "Support or help used: ______________________",
                         "Changes since the last check-in: ______________________",
                         "Questions or requested follow-up: ______________________"] { pdf.text(Loc.t(item), gap: 13) }
            pdf.heading(Loc.t("Limits"))
            pdf.text(session.exercise.limits)
            pdf.text(session.exercise.isManual ? Loc.t("A manual entry does not confirm how a movement was done.") : Strings.setupVariationNote)
            if !session.exercise.isManual { pdf.text(Loc.t("These estimates have not been checked in a medical study.")) }
            pdf.text(Loc.t("This report cannot establish a cause, a medication need, or which exercises are appropriate."))
            pdf.text(Loc.t("Created on this device when you asked for it. Shared only by you."))
        }
    }
}
