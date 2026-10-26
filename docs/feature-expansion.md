# Bearing feature expansion

Updated October 25, 2026 after the user requested the earlier routines and both kinds of custom check-in. This supersedes the arm-only scope descriptions in older implementation notes. The remote clinician concept remains a proposal, not a feature.

## Current feature set

- Arm raise: three attempts for one anatomical side, projected angle, counted-attempt variation, and comparison history.
- Sit to stand: one thirty-second front-view recording, an initial seated calibration, and hip rise normalized by torso length. Separate rise and return settings prevent wobble from adding repeated counts.
- One-leg balance: ankle-height difference identifies the lifted foot. The first hold is capped at ten seconds. Hip-center variation divided by shoulder width provides a sway estimate. Histories keep left and right lifted feet separate.
- Knee bend: three side-view attempts using projected hip, knee, and ankle flexion. Instructions use a firm chair and a comfortable straight starting position.
- Shoulder reach: three side-view attempts using shoulder, hip, and elbow. The far side does not have to remain visible.
- My plan: selected routines, a weekly check-in goal, and a four-week count chart. A saved record must contain a value to count. Weeks run Monday through Sunday.
- Local reminders: selected days and one time of day, explicit notification permission when enabled and saved, and visible handling of permission or scheduling problems.
- Helper camera: a rear-camera option when a trusted person holds the phone. Display mirroring follows the camera direction. Measurement coordinates remain anatomical and unmirrored.
- History: routine filtering, local name search, and charts of matching records. Counts, angles, hold durations, sides, and custom identities are kept separate.
- Custom camera templates: a name, instructions the person already has, a supported routine, and a side where relevant. Tracking settings stay fixed.
- Manual check-ins: a clearly labeled count or timer without camera access. The timer pauses when the app becomes inactive and excludes paused time.

The app retains English and Spanish, spoken camera guidance, repeat instructions, large text, VoiceOver actions, haptics, explicit attempt review, local history, user-created PDFs, and confirmed data deletion.

## Custom check-ins and data integrity

A custom name is limited to sixty characters and instructions to five hundred. The manual timer can be set between five and six hundred seconds. These are input limits, not health ranges. A manual count is entered by the person. It is never described as a camera measurement.

Editing a custom template starts a new comparison identity. Existing sessions keep their original custom name, instructions, units, and identity. Deleting a template does not delete its saved sessions. Delete all my data removes the templates as well as sessions, settings, plans, pending reminders, and temporary PDFs.

The active SwiftData models are Session, UserSettings, and CarePlan. Custom definitions are encoded inside CarePlan instead of adding another model. New session fields have defaults for additive migration. Older arm-only records retain their numeric arrays and preferences. Older legacy summaries remain labeled and separate from current comparisons.

## Measurement boundaries

All camera routines use Vision anatomical joint names in pixel coordinates. Shoulders and hips use the existing confidence tier; elbows, wrists, knees, and ankles use the higher tier. Held joints are drawing aids and cannot count as fresh measurements. Filtering remains timestamp-based.

Added routines share tilt, fresh-frame coverage, frame-rate, boundary, tracking-gap, framing, and single-person checks. Side-view routines require the near-side chain instead of forcing visibility of the occluded side. The app instructs the person to use the required view; it does not claim to verify every aspect of their posture or instructions, such as crossed arms or an actual chair.

Camera angles are flat picture estimates. Stand counts and sway estimates also depend on setup and tracking. These are not health ratings. The support message must be acknowledged before sit to stand, balance, or knee bend. Each recording can be stopped without saving. The person must not move farther to satisfy a software setting.

Comparisons use matching routine, side or lifted foot, and custom identity. Angle starting points require three sessions with at least two counted attempts each. Other starting points use three matching records with values. A later difference does not establish a health change.

## Reports and privacy

The result and PDF identify manual entries explicitly. Each PDF covers the selected record and snapshots any custom instructions. It includes the appropriate units, available attempt variation, comparison, reasons, method, limits, and required disclaimer. A current personal-plan summary may be included; its goal is labeled as the current goal, not a reconstructed historical goal. Long reports continue onto another page.

All data remains in the app's local store unless the person explicitly shares a PDF or their device backup includes it. There are no app accounts, remote assignments, analytics, app server, or network service. The clinician idea is described only in [remote-clinician-proposal.md](remote-clinician-proposal.md).

## Verification

The prior committed arm-only build had 70 unit tests and 12 UI tests passing. The expansion adds synthetic checks for stand counting, scale independence, calibration, hysteresis, tilt, dropped joints, balance holds and sway, foot changes, both-side knee angles, side-view reach, full-body alignment, and front/rear display mapping.

Data tests cover template persistence, input validity, manual timer pause/resume/cap/reset, snapshot history, unit and template isolation, lifted-foot isolation, Monday week boundaries, PDF sources, deletion, and migration from the arm-only store. Reminder tests use a fake notification center for permission, deduplication, denial, failure, and cancellation. UI tests cover the routine library, support acknowledgement, custom camera setup, manual entries, export, and local planning.

The full expansion run passed 96 unit tests and 18 UI tests. After layout polish, all 96 unit tests and three affected UI tests passed again. Final wording and PDF checks passed 15 targeted unit tests. The unsigned iPhone Release build succeeded. An additional dark-mode home accessibility audit reported a contrast failure for an offscreen label; its exported image contains only the home-indicator area. That audit remains a known simulator limitation, not a passing check. Palette contrast calculations pass in both appearances. See design-notes.md for the audit scope. Simulator checks do not establish agreement or usability for older adults or veterans. A real iPhone is still needed for camera orientation, rear preview alignment, side-view joint visibility, lower-body framing, hold and stand timing, speech, and notification behavior. Use [device-checklist.md](device-checklist.md) and record observations.

## Three sentences for a judge

Bearing offers guided movement routines and custom personal check-ins on an iPhone. It explains the source of each value and compares matching records over time. People choose their local plan, reminders, and when to share a PDF summary.

## Later usability update

Voice speed, a hands-free setup option, and clearer result explanations are documented in [solo-start-and-voice.md](solo-start-and-voice.md). The original measurement calculations and palette remain unchanged.

## Detailed report update

The short PDF summary has been expanded into a report with an overview, saved attempt details, personal history, and plan context. New recordings preserve ordered numeric outcomes and capture metadata. Older unavailable information remains labeled as missing. See [detailed-report.md](detailed-report.md).

## Local plan and privacy update

The local workflow now includes Today, snooze/skip, completion-aware notifications, accepted personal-plan versions, per-recording plan snapshots, report scope/preview/confirmation, local handoff history, and optional device authentication. The physician-service portion remains unavailable without an operated service. See [local-care-workflow.md](local-care-workflow.md).
