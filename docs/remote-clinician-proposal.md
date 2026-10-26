# Future idea: clinician review and exercise assignments

Status: proposal only. The user explicitly requested that this idea not be implemented. The current app has no provider accounts, remote review portal, backend, remote assignments, or automatic judgement of a person's health.

A future version could let a person invite a verified clinician to review selected summaries. That clinician could then send a versioned plan containing exercises, instructions, and a review date. The person could choose whether to accept the plan and which records to share. The clinician would interpret the information in context. A camera estimate or a completed check-in would not establish whether a person is healthy or whether an exercise is appropriate.

A possible flow would be:

1. Verify the professional's identity and establish their relationship with the person.
2. Ask the person for clear, revocable sharing consent.
3. Share selected summaries, distinguishing camera estimates from manual entries and showing tracking limitations.
4. Have the clinician choose and approve the plan, including instructions and when to stop or ask for help.
5. Show the plan's author, date, version, and review date in the app.
6. Let the person record entries offline and explicitly sync selected records when connected.
7. Let both sides see which plan version a record belongs to. Provide a way to revoke access and correct a plan.

This would require a separate secure service with authentication, role-based access, encrypted transport and storage, audit records, retention and deletion controls, and a carefully designed consent process. Notification text should reveal little personal information. Applicable privacy, security, professional-practice, and product requirements would need review before any real deployment. This proposal makes no claim of regulatory compliance.

The present implementation remains local. My plan is a plan the person enters on their own phone. Custom instructions are text they already have, not instructions generated or prescribed by Bearing. Local reminders are scheduled by the phone. PDF sharing remains an explicit user action.

Before deciding to build this extension, interview willing clinicians and intended users about whether summaries are useful, how plans are currently communicated, which information they actually need, and what review workload they could support. Those conversations have not been conducted in this work.


## Proposed schedule and review loop

Discussion update: October 25, 2026. The team has raised this idea again. This remains a roadmap discussion; no physician connection or prescribing feature has been implemented.

1. A verified professional sends a dated, versioned exercise plan with routines, instructions, and scheduled check-ins.
2. The person reviews and accepts the plan. The app identifies who authored it and when it changes.
3. A Today view shows the next scheduled check-in. Optional local reminders provide a nudge. Snooze, skip, and a visible completed state prevent unnecessary repeated prompts.
4. The person records a routine, reviews its tracking limits, and explicitly shares the PDF through an agreed channel. Completion records an entry; it does not establish correct performance or health status.
5. The professional reviews the information and may update the exercise plan or request a visit. The app distinguishes sent, received, and reviewed only when those events are actually confirmed.
6. New instructions identify the author and plan version. The person can accept the update and revoke future sharing.

The current app already has optional local day/time reminders, a personal weekly goal, custom routine instructions, and user-initiated PDF sharing. It does not yet have per-assignment due times, completion-aware nudges, professional authorship verification, online delivery acknowledgements, or a professional inbox.

A connected edition would change the current offline-only architecture. It would need a service and professional interface, authenticated identities, scoped sharing consent, access revocation, and secure storage and transport. The offline routine recorder could remain available without a connection. A prototype must label simulated professionals and assignments clearly and must not claim real verification or delivery.

Use the term exercise plan for routine assignments. A medication prescription is a separate medical workflow. A shared movement PDF must not automatically trigger a prescription. Any prescribing feature would require its own professional workflow, integration, and legal and security review.

## Relationship to H.R. 1107

The official record checked October 25, 2026 identifies H.R. 1107 of the 119th Congress as the Protecting Veteran Access to Telemedicine Services Act of 2025, sponsored by Steve Womack. Congress.gov lists House passage and a September 16, 2025 referral to the Senate Committee on Veterans' Affairs. It does not list enactment.

The bill addresses specified VA professionals providing controlled prescription medications through telemedicine under conditions. It retains obligations under the Controlled Substances Act. It does not authorize a general exercise app to issue prescriptions, establish a VA connection, or turn a movement report into sufficient grounds for medication.

The proposed Bearing connection is thematic: supporting continuity and access between visits, including for rural veterans. It is not a claim of compliance with the bill, VA endorsement, or a prescribing implementation.

Sources checked:

- [Congress.gov bill summary and status](https://www.congress.gov/bill/119th-congress/house-bill/1107)
- [Official referred-in-Senate text](https://www.govinfo.gov/content/pkg/BILLS-119hr1107rfs/html/BILLS-119hr1107rfs.htm)

Suggested three-sentence presentation wording:

Bearing helps people keep personal movement records between visits. People can choose reminders and share a PDF with their clinician. A future connected version could let verified professionals send exercise plans for users to accept.
