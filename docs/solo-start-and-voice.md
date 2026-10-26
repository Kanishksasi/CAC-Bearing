# Voice, hands-free setup, and result clarity

Updated October 25, 2026.

Voice speed appears under Make it yours on the home page. Slower, Standard, and Faster use supported iOS speech rates. The choice reuses the existing saved speechSpeedRaw field and applies to preparation, camera cues, repeat instructions, and manual check-ins. Try voice plays a short sample, including when automatic spoken instructions are off.

On the recording page, Start when ready arms a waiting state. It does not record or bypass the alignment gate. The person can tap before stepping back. Fresh joints, framing, one person, phone tilt, and steady positioning must all remain ready. An extra steady interval precedes the three-second countdown. Loss of alignment during the countdown returns to waiting without creating an attempt. Stop without saving, leaving the page, and leaving the foreground cancel the armed state. The existing immediate start remains available when a helper can operate the phone.

Hands-free setup does not remove support requirements. Sit to stand, balance, and knee bend still require the support acknowledgement before continuing.

The result now explains the units, the routine-specific meaning, the middle-value angle summary, and the meaning of plus and minus differences. It states that the starting point is the person's own record rather than a target. Missing values direct the person to recording reasons. PDFs include the same number explanation. The calculations and palette are unchanged.

Hardware checks: confirm voice speed and countdown audibility in both languages; tap before stepping away; interrupt positioning during the countdown; cancel waiting; background the app while armed; try each supported routine with the required support. Check camera timing on a real iPhone before presenting the flow as verified on hardware.

Verification: all 100 unit tests passed, including synthetic pose and tilt recovery, localization, persistence, and PDF checks. Five targeted UI flows passed across the final runs: alignment blocking, hands-free waiting and cancellation, voice selection and result explanation, largest-text recording controls, and largest-text result actions. The large-text recording test waits for the navigation transition before querying repeated labels. The final waiting-footer rerun passed. The unsigned iPhone Release build succeeded. Simulator speech is silenced in UI tests; real voice speed and camera timing remain hardware checks.
