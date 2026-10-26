# Bearing: privacy and connected-workflow review

Prepared October 25, 2026. These are product recommendations and a legal-review map, not a compliance certification. Before a real connected pilot, involve a qualified health-privacy lawyer, a clinician partner, and security reviewers. This document does not add a connected service to the app.

## Recommended loop

Verified professional drafts an exercise plan → user reviews and accepts a dated version → optional private reminders → guided check-in → user previews the exact report → user chooses a verified recipient → authenticated delivery → professional acknowledges review → professional sends a new plan version → user reviews the update.

Medication prescribing should remain a separate professional workflow. Finishing a routine or receiving a PDF must not automatically authorize a prescription or a plan change.

## What changes I recommend

| Area | Product behavior to design | Why it matters |
| --- | --- | --- |
| Professional verification | Confirm identity, active professional credentials, scope, organization, and the care relationship. An email address or provider number alone is insufficient verification. | Prevents impersonation and mistaken recipients. |
| User control | Show who is requesting access, exactly what they can see, for what purpose, and for how long. Separate accepting a plan from sharing records. | Consent should be understandable and specific. |
| Separate permissions | Separate permissions for viewing selected reports, receiving future reports, assigning plans, and accessing history. Do not enable all access by default. | Reduces unnecessary exposure. |
| Report preview | Preview the actual PDF, including timestamps, custom instructions, and history. Let the person change the selection or cancel before sending. | A report can contain identifying and sensitive information even without video. |
| Plan provenance | Save the author, plan ID, version, effective date, review date, and instructions. Record which version a check-in follows. | Prevents silent changes and misleading historical comparisons. |
| Acceptance | Display changes between plan versions and ask the user to acknowledge them. Keep prior versions read-only. | The user should know which instructions are current. |
| Reminder privacy | Use generic lock-screen wording, such as Time for your Bearing check-in. Offer quiet hours, snooze, skip, and completion-aware suppression in the future. | Avoids exposing health details and repeated pressure. These extra reminder controls are not built yet. |
| Delivery states | Distinguish saved locally, queued, sent, received, and reviewed. Show reviewed only after a genuine professional acknowledgment. | Prevents a false sense of supervision. |
| Offline behavior | Keep local recording available. Let the person see and cancel queued uploads. Handle retries without duplicate reports. | Supports unreliable connectivity without silent disclosure. |
| Account security | Use strong authentication, professional MFA, short-lived sessions, secure recovery, device credential storage, and server-side authorization. Test access across accounts. | A hidden button or an unguessable record ID is not an access-control system. |
| Encryption and vendors | Protect transport and stored records. Control keys, backups, support access, and service providers. Document data locations and vendor relationships. | A secure database product alone does not establish a compliant service. |
| Data minimization | Continue avoiding saved camera frames and video. Send selected numeric summaries rather than all available records. Keep ads and tracking SDKs out. | Minimizes sensitive data collection and exposure. |
| Audit history | Log access, exports, consent changes, plan changes, and professional actions with minimal sensitive content. Protect logs from alteration. | Supports accountability without creating another uncontrolled health-data store. |
| Revocation | Stop future access and queued sharing when the user revokes it. Explain that already downloaded PDFs cannot be recalled automatically. | Revocation must not promise the impossible. |
| Deletion and retention | Explain app deletion, server deletion, backup retention, and any records a professional must retain separately. Set a written retention policy. | Delete all must not imply deletion from every recipient and backup. |
| Clinical responsibility | Explain response expectations and that reports are not continuously monitored. Keep interpretation, exercise suitability, and prescribing with qualified professionals. | Completion and movement estimates cannot establish health status or medication need. |
| Minors and caregivers | Define the intended age group, proxy access, permission, and revocation before accepting minors or family access. An adults-only label is not a universal legal exemption. | Avoids ambiguous access and consent. |
| Incident response | Establish security monitoring, incident triage, breach assessment, contacts, and legally required notification procedures before live use. | Privacy includes what happens after something goes wrong. |

These safeguards are design recommendations. Exact legal duties depend on the service, relationships, users, jurisdictions, and data flows.

## Legal questions that need qualified review

**HIPAA is role-dependent.** HHS distinguishes an independently chosen consumer app from a service operating on behalf of a covered provider. A connected service offered for a clinic may create business-associate duties and agreement requirements. Do not claim HIPAA compliance from encryption, a consent checkbox, or offline operation alone. [HHS app and business-associate guidance](https://www.hhs.gov/hipaa/for-professionals/faq/does-hipaa-require-a-covered-entity-to-enter-into-a-business-associate-agreement.html)

**Non-HIPAA does not mean unregulated.** Assess the FTC Act, the Health Breach Notification Rule, and applicable state privacy and breach laws. FTC guidance describes coverage and notification obligations for qualifying personal-health-record products and related services. Do not assume every app has the same status. [FTC health breach guidance](https://www.ftc.gov/business-guidance/resources/complying-ftcs-health-breach-notification-rule-0)

**Review FDA status against actual functions and intended use.** Camera measurements used in medical decision-making deserve careful review. Calling a product personal tracking or adding a disclaimer does not independently settle its regulatory status. Avoid clearance, accuracy, or treatment claims without a proper basis. [FDA software guidance overview](https://www.fda.gov/medical-devices/digital-health-center-excellence/device-software-functions-including-mobile-medical-applications)

**Exercise assignments and medication prescriptions are different.** For any future prescribing feature, review professional licensing, telehealth, prescribing, and pharmacy requirements for the relevant locations. Controlled-substance e-prescribing has specific identity, authentication, and application requirements. Use an appropriate established prescribing workflow rather than making a movement PDF into a prescription. [DEA prescribing guidance](https://www.deadiversion.usdoj.gov/faq/epcs-faq.html), [DEA application audit/certification requirements](https://deadiversion.usdoj.gov/ecomm/thirdparty.html)

**Review children's privacy if the product includes children.** COPPA can apply to child-directed services and general-audience services with the relevant actual knowledge of collection from children under thirteen. Review the actual product and practices rather than treating an age statement as a complete solution. [FTC COPPA guidance](https://www.ftc.gov/business-guidance/resources/childrens-online-privacy-protection-rule-not-just-kids-sites)

**Review local and contractual duties.** State professional-practice, privacy, consumer-protection, retention, consent, and school rules may matter. This document is not a state-by-state legal analysis. H.R. 1107 is not an app authorization, a privacy certification, or a substitute for these reviews.

## Current-build privacy statements to preserve accurately

- Bearing processes movement on the phone and does not save video or images.
- It saves local numeric records, preferences, custom instructions, plans, and recording metadata.
- PDFs are created on request, and sharing is explicit.
- Device backups and copies shared elsewhere are separate from deleting local app data.
- A future connected version would change the current no-account, no-app-server data flow. Notices and consent would need updating before that change.
- Future connection claims, such as doctor linked or report reviewed, must never appear as working functionality in the contest demo.

## Video and school privacy

Use synthetic reports and consenting demonstrators. Do not upload actual medical records, identifying symptom histories, contact lists, or private messages to WeVideo. WeVideo and the public video host are separate services from Bearing. A screen recording made for the contest can save the camera preview even though Bearing itself does not save video. Obtain permission for that separate recording and public use, including guardian permission for minors where required.

Use original footage or properly licensed media. Check school account rules and music rights for public publication. Give only the identifying details needed for the contest; do not show home addresses, personal emails, birthdays, phone numbers, or account credentials.

## Suggested public language

Use: personal movement tracking; compare matching personal records; share a report with a clinician; future exercise-plan connection.

Avoid unsupported claims: HIPAA certified; FDA approved; medically accurate; detects illness; tells a doctor what to prescribe; replaces visits; guarantees better health; officially partnered with VA or endorsed by a public official.

## Priority before a real connected pilot

1. Define intended users, functions, and data flows.
2. Obtain legal classification and relationship review with a clinician partner.
3. Design authentication, recipient verification, scoped consent, and plan versioning.
4. Establish secure infrastructure, vendor arrangements, retention, and incident procedures.
5. Test unauthorized access, wrong recipients, revocation, failed delivery, and backups.
6. Have users and professionals review the consent, report, and workflow with synthetic data.
7. Start any real-data pilot only after the responsible team has addressed the applicable requirements.

This is a readiness sequence, not a guarantee that every applicable rule has been identified.
