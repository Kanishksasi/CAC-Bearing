# Detailed Bearing report

The PDF now prioritizes a quick overview and then provides recording details, matching history, and plan context. This replaces the earlier short-summary format for current records. A physician still needs information Bearing does not collect and must interpret the report in context.

## Contents

- Record and export dates, displayed time zone, routine, anatomical side or lifted foot, and manual versus camera source.
- The selected result, units, counted-attempt total, attempt variation, and a plain explanation of the summary calculation.
- Ordered outcomes for new recordings, including measured angles, counts, holds, sway, rejection reasons, and recording duration when saved.
- Camera direction, app build, saved time zone, and method version for new records. Older records explicitly mark unavailable metadata.
- First-three eligible baseline dates and values, a later signed difference when available, and eligibility rules.
- Up to twenty-four recent matching records, ending at the selected record. Saved records without usable values remain visible. Other sides, lifted feet, and custom template identities are excluded.
- Current locally entered plan, the current weekly goal, and four weeks of saved check-in counts through the selected record. Past assignments are not reconstructed.
- The custom instructions saved with the selected record, when present. The report does not claim professional authorship verification.
- Missing health context, space for review notes, method limits, privacy information, and the required disclaimer on every page.

## Boundaries

The report does not contain pain or symptom history, medical history, medicines, vital signs, or physical examination findings. Blank note lines allow discussion without adding health fields to the app. They are not a captured symptom questionnaire. A clinician needs to collect relevant missing information separately.

No video, pictures, or raw joint sequences are saved. Frame rate, joint-coverage percentages, and phone-angle logs are not retroactively invented. Counted means that app recording rules were satisfied. It does not prove safe or correct performance, a health change, or a need for medication. No health ratings, reference ranges, prescriptions, or recommendations are generated.

## Storage

SessionReportDetails stores a Codable snapshot inside the existing Session model. It adds ordered numeric attempt details, source, build, time zone, and method version. New fields have additive defaults. Old records retain their original summary arrays. Their attempt order and unavailable capture details remain unknown.

Report creation is local and on demand. Sharing remains explicit through the existing share sheet. There is no professional portal or transmission service. Exporting does not establish that anyone received or reviewed the report.

## Review and validation

PDF tests verify source isolation, historical cutoff, ordered outcomes, unavailable older metadata, manual-source wording, required footers, translated copy, page bounds, and long content. Test examples are synthetic and provide no measurement-validity evidence. Real physicians and intended users have not reviewed this expanded report in this work.

Three sentences for a judge:

Bearing can share a detailed report of personal movement records. It shows recorded values, attempts, matching history, and what information is missing. A clinician can review the report alongside the person's medical history and other information.

Final verification: 109 unit tests passed, and both targeted app export checks passed. The unsigned iPhone Release build succeeded. The English example and Spanish stress-test pages were rendered and visually inspected. Page bounds, translated text, and required per-page disclaimers passed automated checks. The example at output/pdf/bearing-example-report-synthetic.pdf contains synthetic values and no recorded person.

Report sharing now defaults to the selected record, with optional history, plan context, and custom instructions chosen before PDF preview. A confirmation is required before opening the system share sheet. Accepted personal-plan snapshots appear when available and included. A local handoff entry does not prove delivery or professional review. See local-care-workflow.md.
