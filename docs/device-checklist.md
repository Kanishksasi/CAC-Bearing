# Device verification checklist

Run this checklist on a real iPhone after choosing a signing team in Xcode. Record observations rather than assuming the simulator checks prove camera behavior.

- [ ] Confirm iOS 17 or later, portrait orientation, and the front camera, and Helper camera with the rear camera.
- [ ] Confirm the camera permission explanation. Deny access, open Settings, allow access, and return.
- [ ] Raise the anatomical right arm, then the left. Check that the skeleton follows the same arm in the mirrored preview.
- [ ] Check overlay alignment near every edge at the fixed 9:16 preview ratio.
- [ ] Confirm both shoulders, hips, and elbows are needed for setup. The opposite elbow is not required during an attempt.
- [ ] Tilt the phone back and sideways. Confirm Start blocks and the spoken fix is understandable.
- [ ] Confirm a full second of stillness is required after a tilt, framing, or visibility interruption.
- [ ] Confirm natural shoulder asymmetry does not block setup.
- [ ] Press and hold Start. Confirm the countdown is cancelled safely when leaving or locking the phone.
- [ ] Raise, hold about one second, and lower within the six second recording. Stop for pain or dizziness.
- [ ] Confirm raising without lowering is not counted. Do not ask someone to move farther to satisfy a parameter.
- [ ] Briefly cover the selected elbow near the peak. Confirm sustained tracking loss is not counted.
- [ ] Tilt during an attempt. Confirm it is not counted, including tilt between camera frames.
- [ ] Have a second person enter the image. Confirm setup blocks and an affected attempt is not counted.
- [ ] Check the spoken start, finish, result, and Repeat instructions from the actual recording distance.
- [ ] Confirm the spoken result finishes before continuing to the next attempt.
- [ ] Background after an attempt review, return, and complete the next attempt.
- [ ] Save three attempts for each arm. Check session history and each session's Explain card.
- [ ] Use VoiceOver and the largest text size. Reach all setup, recording, result, and privacy controls.
- [ ] Repeat in Spanish and in dark appearance. Check the actual installed Spanish voice.
- [ ] Turn on airplane mode and finish the full flow.
- [ ] Tap Create PDF summary. Confirm it matches the session on screen, then share through iOS.
- [ ] Open an older session after newer sessions exist. Check that its summary does not borrow future baseline data.
- [ ] Delete all my data. Check confirmation, the completion message, empty history, and reset settings.

## Record actual observations

| Item | Observed value |
|---|---|
| Phone model and iOS version | |
| Debug measured processed frames per second | |
| Room lighting and phone placement | |
| Preview and skeleton alignment | |
| Right and left anatomical mapping | |
| Speech timing and audibility | |
| Full airplane mode flow | |
| Student tester and date | |

Parameters are engineering choices, not medical limits. Record the final values from Parameters.swift and explain any tuning from real test observations. The debug processing-rate label is hidden in Release builds.

## Expanded routines and custom check-ins

- [ ] Verify side-view knee bend and shoulder reach for both anatomical sides. Confirm only the required near-side chain is needed.
- [ ] Verify the sit-to-stand seated start and count against an observed count, without asking for extra movements.
- [ ] Verify balance foot identification, stopping after lowering the foot, the ten-second cap, and sway behavior.
- [ ] Confirm the support acknowledgement blocks Continue for sit to stand, balance, and knee bend.
- [ ] Stop during countdown and recording. Confirm no partial record is saved and a fresh setup can be started.
- [ ] Check helper rear-camera preview and overlay alignment without a second X flip.
- [ ] Create, edit, and delete custom templates. Confirm old results keep their names and instructions.
- [ ] Record a manual count and a manual timer with the camera permission denied.
- [ ] Pause a manual timer, background the app, and return. Confirm inactive time is excluded.
- [ ] Check each routine's PDF units and the manual-entry label.
- [ ] Check routine filters and matching-side or matching-foot history charts.
- [ ] Save a local plan, enable and deny notification permission, change reminder days, and turn reminders off.
- [ ] Delete all data and confirm custom templates, plans, and pending reminders are removed too.

No clinician review portal or remote exercise assignments are present.

## Hands-free start and voice speed

- Choose each voice speed and use Try voice in English and Spanish. Confirm repeat instructions use the choice.
- Tap Start when ready before stepping into view. Confirm no recording begins while framing or tilt needs correction.
- Keep position through the countdown. Confirm movement starts only after the movement cue.
- Leave position during countdown. Confirm the app waits again without saving an attempt.
- Cancel waiting, leave the page, and background the app. Confirm recording cannot begin afterward.
- Keep the required person and support nearby for the routines that need them.
- Read each result explanation and confirm the units match the routine and PDF.

## Local care workflow

- Accept a plan, change it, and inspect the previous version. Verify that an older recording keeps its original snapshot.
- Set a reminder for today, snooze it, skip it, and undo the skip. Save a planned check-in and confirm pending nudges for today are removed.
- Test a snooze across midnight, a time-zone change, and a daylight-saving boundary.
- Open the app after several days and verify the four-week reminder horizon refreshes.
- Preview a report with all optional fields off, then with them on. Check the actual PDF contents before sharing.
- Cancel the system share sheet. Verify that no recipient, receipt, or review is claimed.
- Complete a handoff and confirm the wording remains generic, including Save to Files or printing.
- Enable the optional device lock using real system authentication. Cancel authentication and confirm that records remain locked.
- Background Bearing from a report sheet and a plan-review sheet. Inspect the app-switcher snapshot and unlock behavior.
- Confirm that no biometric information is requested or saved by Bearing itself.
- Delete data while reminder scheduling is in progress. Check pending and delivered notifications and temporary PDFs.
