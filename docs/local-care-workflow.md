# Implemented local care workflow and connected-service boundary

Updated October 25, 2026. The team authorized implementation of the proposed workflow and confirmed that no backend or clinic partner exists yet.

## What works in this build

- Today shows a personal check-in as scheduled, due, snoozed, skipped, or recorded. A saved value from any selected routine completes one personal daily check-in. This is not proof that every exercise was performed.
- Snooze moves a nudge thirty minutes ahead. Skip suppresses that day's nudge without creating a result. Skip can be undone. A recorded value takes precedence over an earlier skip.
- Local notifications contain generic wording. They are one-shot requests covering the next four weeks, refreshed on opening the app, changing the plan, or saving a recording. Completed days are removed from the future schedule. Reconciliation is serialized so stale work cannot overwrite a newer schedule. Deletion invalidates in-flight scheduling.
- Plan edits open a review screen. Accepting saves a version when the configuration changes. Earlier versions remain immutable. Existing plans without saved dates retain an explicitly unknown date.
- Camera and manual recordings snapshot the accepted personal-plan version when the recording view opens. Later plan edits do not change that snapshot. Older recordings do not gain invented snapshots.
- Report creation opens a scope selector. History, plan context, and custom instructions default to excluded. The selected record and its recording details remain included. The person previews the PDF before enabling the sharing action.
- A local export entry distinguishes preparation from the system share sheet handing a file outside Bearing. It does not assert a physician recipient, delivery, or review. The most recent fifty prepared exports are retained with the session.
- Optional device authentication uses the iPhone's passcode or biometrics. Records lock after backgrounding. A privacy cover hides content during app transitions, including modal content. Locking returns to Home, so unsaved results should be saved before leaving. Shared copies are outside this lock.
- Delete all removes sessions, preferences, plans, version history, local export entries, day choices, pending/delivered reminders, and temporary app PDFs. Recipient copies and older device backups remain separate.

## What is not connected

There is no physician account service, credential-verification service, professional inbox, online plan assignment, remote revocation, server delivery receipt, or verified review acknowledgment. No network requests, accounts, clinical recommendations, or medication prescribing were added. The report selector states that physician connections are unavailable.

An offline app cannot verify that a person is a currently authorized professional, authenticate that professional to a server, enforce server access controls, deliver a report to their inbox, or record that they reviewed it. A local verification checkbox, typed email address, or simulated inbox would not implement those requirements.

The new plan versions are explicitly personal plans. They must not be presented as verified professional assignments.

## What is required to enable a real connection

1. Establish who operates the service and who verifies professional identity, credentials, and the care relationship.
2. Choose and configure the backend, authentication system, professional MFA, storage, vendor arrangements, and service regions appropriate to the planned use.
3. Build a professional interface and server-enforced roles, ownership, consent scopes, and revocation. Never trust a client-supplied verified flag.
4. Add authenticated plan offers, immutable authorship/version records, acceptance, and session-to-plan references.
5. Add explicit report upload, cancelable offline queues, idempotent delivery, and genuine recipient/review acknowledgments.
6. Test wrong recipients, cross-account access, expired sessions, stolen links, failed delivery, consent changes, incident handling, and retention behavior.
7. Complete applicable legal, privacy, clinical, and security review before real-data use. Keep prescribing outside this workflow unless a separate appropriate professional prescribing integration is established.

This list describes integration work still needed. It is not a compliance certification or an implemented API.

## Verification scope

Unit tests exercise date boundaries, daylight-saving transitions, completion eligibility, missing values, snooze across midnight, bounded schedules, version immutability, report exclusions, persistence, deletion, and scheduling races. UI tests cover plan review/acceptance, Today actions, and report preview/consent at standard and large text sizes. Real-device notification delivery and device authentication require hardware checks.

## Three sentences for a judge

Bearing helps people follow their personal plan and choose what they share. It keeps saved plan versions, offers private reminders, and previews reports before sharing. A real physician connection still needs a secure service and professional verification.

Final verification: 125 unit tests passed. Four affected UI flows passed across the targeted runs: plan review/acceptance, Today skip/undo, manual-result export/consent, and largest-text result export/consent. The final largest-text sharing labels and English/Spanish strings were checked again. The unsigned iPhone Release build succeeded. Device authentication, app-switcher privacy covers, and actual notification delivery still require real-device checks.
