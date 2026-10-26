# Bearing implementation notes

This document describes the arm-only foundation. The later user-requested expansion, current features, schema, and new checks are described in [feature-expansion.md](feature-expansion.md).

The current build follows Revision 2 of the supplied October 25 spec. The Word reference and pasted spec supplied product requirements. Their example prompts, schedules, scores, submission advice, and suggested messages to other people were reference material, not actions to execute.

## Behavior and assumptions

The newer arm raise scope replaces the former five-routine build. There are no care plan screens, caregiver mode, rear camera controls, or trend charts. Each saved session represents three attempts for one anatomical side. The other side has a separate session and starting point. New screens keep the existing English and Spanish localization support.

All pose coordinates use pixels with Vision Y upward. Y is flipped only when drawing, preserving the repository's coordinate contract. Anatomical data is never mirrored. The front preview and skeleton each mirror their own displayed content once. The camera outputs upright portrait frames and the preview uses the same 9:16 bounds as the overlay. Confirm their alignment on a device.

CameraService owns one Vision request on a serial queue. It drops late camera frames and sends value frames through a stream that keeps only the latest event. Each restart subscribes to a new stream, so cancellation on backgrounding cannot permanently end delivery. No image buffer goes to the main actor or into storage. PoseService returns an empty joint set when Vision has no usable observation. The filter marks held joints as imputed and holds them for at most two frames. Required joints must be fresh to contribute an angle.

Alignment requires a complete timestamped second with less than three percent movement on either axis. Tilt, missing frames, missing joints, extra people, and framing interruptions reset that interval. Shoulder asymmetry is allowed. A watchdog expires readiness if the camera stops delivering frames or motion readings become stale. Start is disabled and has an explicit VoiceOver action.

An attempt must start with the arm low, reach the supported protocol peak, and return low. The peak is the median of the five highest fresh smoothed angles. Trunk lean is checked around the sample representing that median, so a single outlier cannot move the lean check. Tracking continuity covers the movement and recording boundaries. At least eighty percent of received frames must be fresh, and time gaps and fresh sample rate are checked separately. Tilt is checked from motion updates as well as camera frames, including updates between frames. No tilt correction is applied to angles.

Recording tasks are cancellable. Leaving the screen or backgrounding stops capture, speech, and motion updates. Incomplete attempts are discarded. Each attempt pauses for review, which lets the result finish speaking. Returning from the background can restart setup, including after an attempt review. Save errors keep the results available for another save attempt.

SwiftData's active schema contains Session and UserSettings only, with CloudKit disabled. Existing fields remain to allow additive migration and readable historical numbers. They do not create synthetic attempt peaks. The removed CarePlan entity is covered by a migration fixture test. Old scheduled reminders are cancelled on launch. Migration uses SwiftData's automatic model migration; see [Apple's model migration overview](https://developer.apple.com/videos/play/wwdc2023/10195/).

PDFs have unique temporary filenames and are created only after a tap. Each PDF uses the selected session, its date, and earlier eligible records for that arm. Future sessions do not change a historical PDF's baseline. Longer summaries continue onto another page, with the limits and disclaimer kept together. The footer appears on every page. Temporary PDFs are removed through Delete all my data. App storage is not excluded from device backups, which the privacy screen states.

The privacy manifest declares system boot time reason 35F9.1 for elapsed time checks. Raw monotonic clock readings remain in memory. This matches [Apple’s elapsed-time reason](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype).

The tuning constants are in `Bearing/Bearing/Pose/Parameters.swift`. Core messages are in `Localization/Strings.swift`; the localization catalog also contains the screen labels. Historic unused catalog entries are retained from the existing work. Active copy has tests for translations, banned words, and sentence lengths, with the required disclaimer as the explicit wording exception.

## Verification

Verified on October 25, 2026 using the iPhone 16 Pro simulator with iOS 18.6. All 70 unit tests and all 12 interface tests passed in a clean build. The interface suite includes saved-result PDF creation, return to home, the opposite-arm choice, and completion at the largest text size. The palette test resolves light and dark colors and requires at least 4.5:1 contrast for every custom text color combination. Home accessibility audits passed in light and dark appearances. See `design-notes.md` for the result audit's scroll-content limitation and the complementary screenshot and largest-text checks. The unsigned Release build compiled for a physical iPhone target. English and Spanish PDF previews were inspected, including a multi-page stress case. PrivacyInfo.xcprivacy also passed plist validation.

Synthetic tests exercise both anatomical sides, known angles, pixel conversion, display mapping, confidence tiers, imputation, smoothing, timestamps, camera gaps, missing motion, gravity tilt, extra people, framing, lean, ordered movement, robust peaks, and starting-point comparisons. Storage tests cover old-store migration, save and delete, and PDF content and layout. Interface tests cover the new scope, empty history, deletion confirmation, a blocked start gate, Spanish setup, large text, and an accessibility audit.

The migration test intentionally opens an older three-model store and then opens the current two-model store. Core Data may log that persistent history for the removed CarePlan entity is truncated. The test verifies that session values and preferences survive. iOS 18.6 also logs transformable array class messages; round-trip tests check that arrays remain readable.

No volunteer counts, agreement numbers, device frame rates, or student contributions are invented. Follow the separate device and validation checklists before making submission claims.

## Three sentences for a judge

Bearing measures a simple arm movement using the camera on the phone. It explains which attempts counted and compares them with the person's own earlier sessions. The person chooses when to create and share a PDF summary.

## Module explanations

Camera and pose: The camera sends one picture at a time to Apple's body joint model. We turn the joint locations into pixels so picture shape does not distort the angle math. The app keeps no pictures or video.

Filtering and geometry: The filter smooths small changes using the time between frames. A missing joint can be drawn briefly, but its held position cannot count as a fresh measurement. Angle math uses the shoulder, hip, and elbow on the same anatomical side.

Alignment and tilt: Start stays blocked until the person and phone are steadily positioned. Missing camera or motion updates cannot look ready. The app explains what needs to change using text, symbols, and voice.

Movement engine: Each attempt starts low, rises, and returns low. The engine checks tracking gaps, phone tilt, body framing, and torso lean. It records a plain reason when an attempt is not counted.

Storage and comparisons: Only session numbers and settings are stored. A starting point uses three earlier sessions with enough counted attempts for the same arm. Older build records stay readable but do not mix with the new method.

Views and accessibility: The screens guide one step at a time and let each result finish speaking. People can use large text, Spanish, or VoiceOver. State cues always include words and shapes as well as color.

PDF and privacy: A PDF is made only after the person asks for it. It covers the session on screen and explains the limits of a flat camera picture. The person chooses where to share it and can delete the app's saved data.

Tests: We use made-up joint coordinates with known movements to test the rules. Other tests check saved records, PDFs, translation, and navigation. Real iPhone tests are still needed to check the camera setup and use outside the simulator.
