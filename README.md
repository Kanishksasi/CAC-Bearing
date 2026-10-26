# Bearing

We built Bearing for home exercise check-ins between physical therapy visits. It is an offline iPhone app for personal movement tracking, created by Kanishk Sasikumar, Niveth, and Muhammad for the 2026 Congressional App Challenge.

The app includes arm raise, sit to stand, one-leg balance, knee bend, and shoulder reach. Users can follow a local plan, set reminders, compare matching records, and choose what to share in a PDF.

Custom check-ins can use a supported camera routine or a clearly labeled manual timer or count. They have a name, existing instructions, and their own comparison history. Editing creates a new comparison identity while saved sessions keep their original name and instructions. Bearing does not generate or remotely assign exercises.

Open `Bearing/Bearing.xcodeproj` in Xcode and select the Bearing scheme. Choose an iPhone running iOS 17 or later. Set your own signing team for a physical device. The app has no package dependencies, accounts, analytics, or network service.

Camera routines require steady framing, fresh joints, and an upright phone. Sit to stand, balance, and knee bend require the support message to be acknowledged. Start a recording, follow the cue, review the result, and save. Recording can be stopped without saving. Arm raise, knee bend, and shoulder reach use three attempts for one side. Sit to stand uses one thirty-second recording; balance records a hold capped at ten seconds.

Results explain their source and limits. Camera angles, stand counts, hold duration, and manual values keep distinct units. Comparisons and charts use matching routines, sides, and custom identities. Detailed PDF reports cover the selected session, ordered attempts when saved, matching history, and current personal-plan context. Missing information and measurement limits are stated. Reports are created only on request. Sharing uses the iOS share sheet.

Start when ready lets the person tap before stepping back. Recording waits for steady alignment and a spoken countdown. Losing position during the countdown returns to waiting. The required support acknowledgements still apply.

Voice speed offers Slower, Standard, and Faster, with a Try voice sample. Results explain each number, the angle summary calculation, and personal comparisons. See [voice and solo-start notes](docs/solo-start-and-voice.md).

English and Spanish, spoken instructions, VoiceOver actions, large text, and shape plus word setup cues are included. Helper camera mode uses the rear camera when someone holds the phone. Manual check-ins do not request the camera. Their timer pauses when the app becomes inactive.

My plan stores chosen routines and a weekly check-in goal. Optional local reminders request notification permission only when explicitly enabled and saved. Delete all my data removes sessions, settings, plans, custom templates, pending reminders, and temporary PDFs. Device backups and copies shared elsewhere remain outside that deletion.

Earlier saved session numbers remain readable. They do not create new tracked attempts or enter current comparisons. Schema migration is tested with numeric records and preferences.

Build and test on a simulator:

```sh
xcodebuild -project Bearing/Bearing.xcodeproj -scheme Bearing \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -derivedDataPath /tmp/Bearing-build -jobs 2 CODE_SIGNING_ALLOWED=NO \
  -only-testing:BearingTests -only-testing:BearingUITests \
  -parallel-testing-enabled NO test
```

Simulator tests cover synthetic joint sequences, persistence, migration, PDF content, navigation, translation, and accessibility. Actual camera framing, anatomical side mapping, speech timing, measured processing rate, and tilt behavior still require a real iPhone. The simulator cannot establish measurement agreement or usability for the intended audience.

See the [feature notes](docs/feature-expansion.md), [implementation notes](docs/implementation-notes.md), [device checklist](docs/device-checklist.md), and [validation sheet](docs/validation-sheet.md).

For personal tracking only. Not medical advice or a diagnosis. Share with your clinician.

## Interface

The native interface uses a warm ivory and forest green palette, with English, Spanish, and dark appearance. See [design decisions](docs/design-notes.md), [home preview](docs/design-preview/home-light.png), and [setup preview](docs/design-preview/setup-light.png).

## Team handoff

Our [team handoff](docs/teammate-handoff.md) covers the audience, features, example use, colors, movement calculations, and testing.

The [remote clinician proposal](docs/remote-clinician-proposal.md) is documentation only. No remote review, provider identity, server, or remote assignments are implemented.

See [detailed report notes](docs/detailed-report.md) for report contents, storage, and review limits.

Our [earlier video plan](docs/video-production/README.md) has a storyboard, team narration, editing steps, and example assets.

## Local care workflow

Today shows personal check-ins, snooze, skip, and completion-aware local nudges. Plan edits require review and acceptance; saved versions and recording snapshots preserve context. Report sharing starts with scope selection and PDF preview, then explicit confirmation. Optional device authentication protects the app after backgrounding. See [implementation and service boundary](docs/local-care-workflow.md).

Real physician accounts, verified remote assignments, server receipts, and reviewed statuses are not available. They need an operated backend and professional-verification process, which the team does not yet have. No prescribing or network service was added.
