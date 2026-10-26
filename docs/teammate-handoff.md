# Bearing: teammate handoff, project report, and presentation brief

Prepared October 25, 2026. Updated for the requested routine and custom-check-in expansion. This document describes the implemented iPhone app and its intended use. It is a source for team discussion and a future presentation.

## 1. Copy-ready summary

Bearing is an offline iPhone app for personal movement tracking. It includes five supported camera routines and custom check-ins. Camera routines record projected angles, stand counts, or balance hold and sway. Custom check-ins can reuse a supported routine or record a manual timer or count. Every saved value identifies its source. After enough sessions, it compares the person's latest result with their own starting point. The person can create a PDF summary and choose whether to share it with a clinician or someone they trust.

The intended audience is older adults and veterans in rural areas, including people who use telehealth or have limited internet access. The design provides English and Spanish, spoken instructions, large text, clear setup checks, and a simple path through each session. These are intended beneficiaries from the product brief. The team has not established usability or measurement agreement for these groups.

The core loop is **Measure → Explain → Compare → Share**. Bearing's contribution is the combination of offline processing, a clear explanation of each result, comparison with the person's own records, and user-controlled sharing. This is a design rationale, not a verified claim of market uniqueness.

Required result and PDF text:

> For personal tracking only. Not medical advice or a diagnosis. Share with your clinician.

Spanish:

> Solo para seguimiento personal. No es consejo médico ni un diagnóstico. Comparta esto con su profesional de la salud.

## 2. Problem, audience, and project goal

**Problem hypothesis:** A person may want a simple record of an arm movement between visits. A video call shows a moment, but it does not automatically create a consistent, understandable movement history. Weak internet and long travel distances motivated the offline approach in the supplied brief. We have not collected interviews or local statistics that establish the size of this problem.

**Project goal:** Make it easier to record one supported movement, understand how the number was produced, and choose what to share.

| Person | Intended role | Design response |
| --- | --- | --- |
| Rural older adult | Primary person recording movement | Large controls, numbered instructions, voice, local storage |
| Veteran using telehealth | Intended beneficiary | Offline recording and a portable summary |
| Family member or trusted helper | May help position the phone | Plain setup guidance and visible framing checks |
| Clinician or trusted recipient | May receive the person's PDF | Session date, arm, numbers, counted attempts, reasons, and limits |

The helper can enable Helper camera to use the rear camera. It changes the capture direction and display transform while retaining anatomical joint names. The app does not provide a remote visit, select exercises for a person, or interpret a movement as a health condition.

## 3. What the current app has

| Feature | Implemented behavior |
| --- | --- |
| Guided arm raise | Choose right or left arm; complete three attempts for that arm |
| Setup checks | One person, required joints visible, framing, upright phone, and steady positioning |
| Front-camera preview | Portrait preview with a mirrored display and body-joint overlay |
| Guided timing | Hold to start, three-second countdown, then a six-second recording window |
| Attempt review | Counted or Not counted, with a plain reason when an attempt does not count |
| Explain card | How the projected angle was measured, attempt variation, and camera limitations |
| Personal starting point | Built separately for each arm from three eligible sessions |
| Session history | Local dated records with access to the saved result |
| Earlier-build records | Original summary numbers remain readable and separate from the new starting point |
| PDF summary | Created only on request for the session being viewed; shared through the iOS share sheet |
| Language | English, Spanish, or the system language |
| Accessibility | Dynamic Type, VoiceOver actions, text and shape status cues, and spoken instructions |
| Appearance | Light and dark palettes, consistent spacing, large primary actions, and custom app icons |
| Privacy controls | Camera permission handling, local storage, confirmed deletion, and explicit backup/sharing information |

**Expanded scope:** The current build adds sit to stand, balance, knee bend, shoulder reach, local plans, local reminders, history charts, helper rear-camera mode, and custom check-ins. This expansion was explicitly requested after the arm-only Revision 2 build. Custom templates and manual entries remain local. Remote clinician review and assignments are proposals only.

| Added feature | Implemented behavior |
| --- | --- |
| Sit to stand | Seated calibration, thirty-second count, and separate rise/return thresholds |
| One-leg balance | Ankle-height lift, first hold capped at ten seconds, and normalized hip sway |
| Knee bend | Side-view hip/knee/ankle projected flexion angle |
| Shoulder reach | Side-view shoulder/hip/elbow projected angle |
| Custom templates | Name, existing instructions, supported routine and side; new identity after editing |
| Manual entries | Clearly labeled user count or timer; no camera; inactive time excluded |
| My plan | Routine choices, weekly goal, and four-week count chart |
| Reminders | Local day/time choices, explicit permission, and scheduling error handling |
| Helper camera | Rear camera, with display mirroring matched to camera direction |
| History tools | Routine filtering, name search, and charts that keep unlike values separate |

The original arm-only verification counts below describe that earlier build. Current expansion verification and remaining device checks are recorded in [feature-expansion.md](feature-expansion.md).

Bearing is the current app name. “Bearing + FormFit” is the title of the supplied merged concept document, not a second app inside this build.

## 4. User flow and why it is arranged this way

1. **First launch:** Read the safety and privacy introduction, then choose I understand.
2. **Home:** Start arm raise is the main action. History, Privacy and data, voice, and language remain available.
3. **Prepare:** Choose an arm. Follow numbered steps for phone placement, framing, and the supported movement. Continue stays at the bottom.
4. **Record:** Follow the current instruction and setup checks. Start remains disabled until positioning is ready. Press and hold Start, then follow the countdown and movement cue.
5. **Review each attempt:** Read Counted or Not counted and its explanation. Choose to set up the next attempt. There is no automatic advance that cuts off the spoken result.
6. **Save:** After three attempts, choose Save and see results. A save error leaves results available for another attempt to save.
7. **Understand the result:** See the projected angle, counted attempts, required disclaimer, Explain card, and personal starting-point information.
8. **Choose the next action:** Create the PDF, share it through iOS, record the other arm, or choose Done to return home. Each arm has a separate session.

The interface gives one main action priority at each stage. Preparation reduces the amount to remember during recording. Persistent action areas keep Continue, Start, and PDF creation easy to find. Done appears in the result content so its text can grow at accessibility sizes. The initial empty history also offers a direct start.

## 5. What the arm-angle numbers mean

The app measures the angle between two lines in the camera picture: shoulder to hip, and shoulder to elbow. It converts Vision's joint positions into image pixels before angle calculations. It preserves anatomical left and right in the measurement data. Mirroring and drawing transformations are confined to the display.

For a counted attempt, the engine takes the median of the five highest fresh smoothed angle samples. This reduces the influence of one isolated high sample. The session value labeled Arm angle summary or Angle summary is the median of its counted attempt angles. It is not simply the last frame or last attempt.

With at least two counted attempts, the app also shows the lowest and highest counted attempt angles. That spread describes variation between attempts. It is not a measured error bound. With one counted attempt, there is a session value but no spread. With none, there is no angle summary.

Each arm's starting point is the median of the session values from its first three eligible sessions. An eligible session has at least two counted attempts. The app shows progress while this starting point is being built. Only later sessions receive a signed difference from that starting point. Historical results do not borrow records from their future.

A difference in degrees is a difference in this camera-based record. Phone placement, viewpoint, lighting, clothing, tracking, and movement can affect it. The app does not label a difference as a health improvement or decline. A flat camera picture does not establish true 3D shoulder motion.

## 6. Illustrative case study

**Status: fictional scenario with invented example numbers. This is not a participant story, a real app measurement, or validation evidence. Do not present these numbers as a live demonstration.**

“Alex” is an imagined older adult in rural Northwest Arkansas who uses an iPhone and sometimes has weak internet. Alex wants a record of one arm movement to discuss during a future visit. A trusted person helps place the phone on a steady surface.

Alex opens Bearing, reads the introduction, selects the right arm, and follows the setup steps. If the phone tilts, Start remains unavailable until it is upright and steady. If tracking becomes unreliable during an attempt, the app explains why it was not counted. Alex reviews three attempts, saves the session, and later chooses whether to share a PDF.

This hypothetical sequence illustrates the calculation when all listed attempts count:

| Right-arm session | Example counted attempt angles | Session median | Starting-point status | Difference shown |
| --- | --- | --- | --- | --- |
| 1 | 108°, 112°, 110° | 110° | 1 of 3 sessions | Not yet available |
| 2 | 111°, 115°, 113° | 113° | 2 of 3 sessions | Not yet available |
| 3 | 112°, 116°, 114° | 114° | Starting point is median of 110°, 113°, 114° = 113° | No difference for a starting-point session |
| 4 | 113°, 117°, 115° | 115° | Starting point remains 113° | +2° |

For session 4, the example spread is 113° to 117°. Its +2° difference does not prove a health change. Alex can create that session's summary and choose a recipient. Bearing does not send the PDF automatically.

**What this scenario demonstrates:** the intended workflow, same-arm comparison, transparent calculation, and user choice. It does not demonstrate real-world accuracy, audience usability, adoption, travel savings, or health outcomes. Replace this scenario with an actual consented account only after collecting and documenting it.

## 7. Basic project report and evidence

| Area | Current evidence | Practical limit |
| --- | --- | --- |
| Unit verification | 70 unit tests passed in the final clean run | Synthetic and software checks do not establish real-world agreement |
| Interface verification | All 12 UI tests passed | Simulator use does not establish usability for intended beneficiaries |
| iPhone build | Unsigned Release build succeeded | A signing team and real-device run are still required |
| Measurement logic | Known joint angles, both arms, pixel conversion, smoothing, gaps, tilt, framing, lean, and ordered movement tested | Real camera conditions remain to be checked |
| Data and PDFs | Save, delete, array persistence, older-store migration, historical comparisons, and PDF contents tested | Shared copies and device backups are outside the app's deletion control |
| Language and layout | English and Spanish, required wording, largest-text flows, export, completion, and opposite-arm selection tested | Installed speech voices and real recording-distance readability need a phone |
| Colors | Actual light/dark custom text-color combinations tested at a minimum 4.5:1 ratio | This is not a certification of the entire app's accessibility |
| Accessibility audits | Earlier home audit includes contrast; result checks include layout, controls, and initial Dynamic Type | Current home and result contrast use palette calculations and screenshots because of an iOS 18.6 offscreen-scanning issue. See feature-expansion.md for current results. |

The final delete-action color also received a targeted contrast test and confirmation-flow check. Real-device frame rate, camera overlay alignment, volunteer counts, agreement statistics, and audience feedback have not been established in this work. Keep those fields blank until measured.

The next evidence to collect is in [the device checklist](device-checklist.md) and [the 2D agreement worksheet](validation-sheet.md). A reference-image comparison must state any timing, viewpoint, and smoothing mismatch. Record volunteers and attempts separately. The resulting engineering check must not be presented as a medical study or proof of results for older adults and veterans.

## 8. Full color specification

These are the intended sRGB hex colors. App accent assets store rounded decimal components. Use these hex values for presentation graphics. The document text and PDF remain suitable for simple black-on-white printing.

| Role | Light mode | RGB | Dark mode | RGB | Where it is used |
| --- | --- | --- | --- | --- | --- |
| Page / paper | #F6F5EF | 246, 245, 239 | #131C19 | 19, 28, 25 | Main screen background |
| Surface | #FFFFFF | 255, 255, 255 | #202C26 | 32, 44, 38 | Primary content surfaces and explanation blocks |
| Main text / ink | #203C32 | 32, 60, 50 | #F0F3EB | 240, 243, 235 | Headings, body copy, result text |
| Supporting text | #52645B | 82, 100, 91 | #B9C9BF | 185, 201, 191 | Secondary descriptions, dates, status text |
| Primary action | #285442 | 40, 84, 66 | #A6D4B6 | 166, 212, 182 | Start, Continue, PDF actions, selected controls |
| Quiet surface / wash | #E6EDE4 | 230, 237, 228 | #2B3D32 | 43, 61, 50 | Selected arm, safety note, secondary controls |
| Divider / line | #D4DDD3 | 212, 221, 211 | #45574B | 69, 87, 75 | Dividers, unselected borders, progress tracks |
| Delete action | #9F302B | 159, 48, 43 | #FFB4A8 | 255, 180, 168 | Destructive data action |
| Text on primary action | #FFFFFF | 255, 255, 255 | #14251C | 20, 37, 28 | Primary-button labels |

**Why this palette:** Ivory and deep green give the app a quiet, recognizable identity. Strong text contrast and a small set of repeated roles make actions and explanations easier to distinguish. Readiness also uses symbols and words, so meaning does not depend on green alone. Color preference and emotional response have not been tested with the intended audience.

The live camera overlay uses white connection lines, green filled circles for fresh joints, and yellow hollow circles for briefly held joints. Filled versus hollow distinguishes these states beyond color. Those overlay colors are display cues, not health ratings. Camera imagery varies, so overlay visibility still needs real-device review.

**App icons:** The light icon uses #F6F5EF, #285442, and an arc in #B9CABB. The dark icon uses #131C19, #A6D4B6, and an arc in #52735E. The icon is opaque and its final shape is masked by iOS. The in-app mark is drawn in SwiftUI; its arc uses the accent color at 22 percent opacity. The icon generator is [scripts/generate-app-icon.swift](../scripts/generate-app-icon.swift).

## 9. Typography, spacing, and visual rules

- Use the system serif design for the welcome heading and main angle. Use the system sans-serif design for instructions and controls.
- Keep the native semantic text styles so Dynamic Type can resize text. Do not replace them with fixed font sizes in the app.
- Page content has 24-point horizontal padding, 20-point top padding, 32-point bottom padding, and a maximum reading width of 600 points.
- Main page sections have 28-point spacing. Content groups use smaller spacing according to their hierarchy.
- Primary buttons have a minimum height of 58 points and an 18-point corner radius. Secondary buttons use a 54-point minimum.
- Main home and result surfaces use 24-point corners. Explanation blocks use 20-point corners. The camera keeps a 9:16 ratio.
- Arm choices stack at accessibility sizes. Action labels omit decorative icons at those sizes to give words more room.
- Use one primary action, restrained borders, and clear headings. The app uses no decorative gradients, stock photos, or invented dashboard scores.
- The mark suggests an angle or bearing. It identifies the app rather than implying a medically precise instrument.

For a presentation, use the light paper background, ink headings, supporting-text captions, and green highlights. Use an opaque green or white surface behind text instead of placing text directly over a camera photo. Preserve the distinction between data and decoration.

## 10. How the software works

**Platform:** Native iPhone app, iOS 17 or later, Swift and SwiftUI. There are no third-party packages, app accounts, analytics, or app-operated network services.

**Pipeline:**

`Front camera → Vision joints → pixel conversion → time-based smoothing → setup gate / arm-raise engine → attempt results → local session → explanation, comparison, history, PDF`

| Module | Teammate explanation |
| --- | --- |
| CameraService / BoundedEventChannel | Reuses the camera setup, drops late frames, and bounds pending work |
| PoseService | Uses Apple's Vision model to locate anatomical body joints |
| SignalFilter / Geometry | Smooths coordinates, labels temporarily held joints, and calculates pixel-based angles |
| AlignmentChecker / TiltMonitor | Requires steady framing and upright positioning before Start |
| ArmRaiseEngine | Checks a full raise-and-lower sequence and records why an attempt did not count |
| MovementEngine and routine engines | Route five supported camera routines to their angle, count, or hold calculations |
| SessionCoordinator | Owns countdown, recording, review, cancellation, speech, and saving flow |
| SessionStore / BaselineService | Saves numeric records and settings and calculates same-arm comparisons |
| ReportBuilder | Creates the requested session's PDF with its own date, explanation, and limits |
| SwiftUI views / SpeechCoach | Present the steps, language, spoken cues, and accessible actions |

Vision inference runs on a dedicated serial camera queue. The UI updates on the main actor. Frames are used in memory and discarded. Start is blocked for missing or stale positioning information. Backgrounding or leaving the recording view stops capture and speech; incomplete attempts are discarded.

The current camera throttle admits frames no closer than 0.030 seconds. This is a code setting, not an observed processing rate. Do not claim a fixed achieved frame rate until measuring a real iPhone.

**Selected engineering settings:** These govern the supported capture protocol and tracking checks. They are tunable engineering choices, not health ranges or medical cutoffs.

| Setting | Current value |
| --- | --- |
| Shoulder/hip joint confidence | 0.3 |
| Elbow joint confidence | 0.5 |
| Timestamp smoothing time constant | 0.065 seconds |
| Maximum held joint | 2 frames; held points cannot count as fresh measurements |
| Fresh-frame fraction | At least 80 percent of received frames |
| Fresh sample rate through movement | At least 15 Hz |
| Maximum tracking gap | 0.25 seconds |
| Setup steady time | 1 second |
| Phone tilt limit | 5° |
| Trunk lean limit near peak | 10° |
| Supported sequence | Starts below 40°, reaches at least 60°, returns below 40° |
| Attempts / countdown / recording | 3 attempts, 3-second countdown, 6-second recording window |
| Starting point | First 3 same-arm sessions with at least 2 counted attempts each |

Use [Parameters.swift](../Bearing/Bearing/Pose/Parameters.swift) as the source of truth for all remaining timing, gap, and framing settings. Do not tell someone to push farther to meet a software setting. The supported protocol may not suit every person's movement.

## 11. Storage, sharing, and limits

The active data models are Session, UserSettings, and CarePlan. CarePlan also contains encoded local custom templates. They store dates, selected sides, numeric summaries, counts, reasons, preferences, plans, and custom names and instructions. Older fields remain for migration compatibility. Current routines and plans use these fields where applicable; older summaries retain their original meaning.

Bearing does not store video, photos, location, or device identifiers. It has no account or app cloud service. Device backups may include app data. A temporary PDF is created only after the person asks. Sharing occurs only through their choice in the iOS share sheet. Copies sent elsewhere and older device backups are outside the app's deletion control.

The PDF covers one selected session, including its date, arm, counted attempts, available angle and spread, starting point, later-session difference, rejection reasons, method, limits, and disclaimer. It includes an optional handwritten name line; the app does not store a name. Content can continue onto another page to prevent overlap. Present it as a PDF summary, not a guaranteed one-page report.

## 12. Presentation plan and team discussion

Suggested ten-slide outline:

1. **Bearing:** One-sentence purpose and the home screen.
2. **The intended need:** Consistent personal records between visits; identify the problem as a hypothesis until interviews support it.
3. **Who it is designed for:** Rural older adults and veterans, helpers, and summary recipients.
4. **The workflow:** Measure, Explain, Compare, Share, supported by actual screens.
5. **What the number means:** Two lines in a flat camera image, counted attempts, median, spread, and limits.
6. **Transparency and privacy:** Reasons, offline processing, local records, optional sharing, and deletion boundaries.
7. **Accessible visual design:** Palette, text hierarchy, numbered instructions, English/Spanish, and large text.
8. **Illustrative scenario:** Clearly label Alex and all example numbers as hypothetical; prefer a real device demonstration once available.
9. **Evidence and remaining work:** 70 unit tests, 12 UI tests, successful Release build, and uncompleted real-device and user checks.
10. **Team contribution and closing:** Explain what we built and tested, then end with the three-sentence explanation below.

Use real screenshots from [design-preview](design-preview/README.md). Result screenshots named test-fixture contain synthetic numbers and must retain that label. Do not reuse them as evidence of a volunteer study. Screen previews are presentation assets, not a finished slide deck.

For a team meeting, have one person explain each of these areas: camera and joints; geometry and filtering; setup and movement checks; storage and comparison; UI and accessibility; PDF and privacy. These are suggested discussion roles, not claims about who built each module. Keep notes on the changes and tests each of us can explain.

Questions the whole team should be able to answer:

- What makes an attempt count, and why can tracking loss prevent a result?
- How is a projected camera angle different from true 3D movement?
- Why does the angle summary use a median, and what does the spread represent?
- How are the starting point and later differences calculated?
- Which information is stored, shared, backed up, or deleted?
- Which results came from software tests, and which real-world checks remain?
- Which code, testing, and design work did each student actually do?

For political context, contest rules, deadlines, endorsements, market comparisons, or external health claims, verify current primary sources before including them. This handoff does not establish any of those claims.

## 13. Three sentences for a judge

Bearing helps people record guided movements and personal check-ins on their iPhone. It explains where each value came from and compares matching records over time. They choose when to create and share a PDF summary.

## Source map

- [README](../README.md): current app scope and build instructions.
- [Implementation notes](implementation-notes.md): architecture, migration, assumptions, and verification.
- [Design notes](design-notes.md): design decisions and accessibility audit limits.
- [BearingStyle.swift](../Bearing/Bearing/Views/BearingStyle.swift): interface surfaces, text colors, buttons, spacing, and mark.
- [AccentColor asset](../Bearing/Bearing/Assets.xcassets/AccentColor.colorset/Contents.json): primary light/dark actions.
- [BaselineService.swift](../Bearing/Bearing/Storage/BaselineService.swift): eligible sessions, median starting point, and historical difference.
- [ReportBuilder.swift](../Bearing/Bearing/Reporting/ReportBuilder.swift): actual exported PDF contents and pagination.
- [Device checklist](device-checklist.md) and [validation worksheet](validation-sheet.md): remaining observations to collect.

Audience and product motivation come from the supplied Bearing + FormFit Revision 2 brief. Implemented behavior and color values were checked against the repository. The fictional case is written solely to explain that behavior. No interviews, volunteer outcomes, achieved device rates, health benefits, student contributions, or endorsements are invented.

See [the future clinician proposal](remote-clinician-proposal.md) for the separate, unimplemented remote-review idea.

The October 25 usability update adds saved voice speed, hands-free setup, and plain result explanations. See [solo-start-and-voice.md](solo-start-and-voice.md) for the flow and hardware checks.

The report now includes an overview, saved ordered attempts, source metadata, personal comparison history, and plan context with review notes. See [detailed-report.md](detailed-report.md). It states which health information is not collected and makes no claim to be a complete medical record.

The local care workflow adds completion-aware reminders, plan acceptance/version history, recording snapshots, report scoping and preview, local export states, and an optional device lock. It does not add physician accounts or remote assignments. Read [local-care-workflow.md](local-care-workflow.md) before presenting the connected loop.
