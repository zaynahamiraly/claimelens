# Mobile roles and workflows

The Flutter app is the active user interface. Firebase Authentication provides
accounts, Firestore stores application data, and FastAPI enforces authorization
and runs PaddleOCR. Uploaded documents stay in the configured private local folder;
Firebase Storage and billing are not required for this development setup.

## Claim lifecycle

1. A client uploads PDF, JPEG, PNG, or DOCX evidence. Camera and gallery are available
   on the new claim screen. Maximum: ten documents per claim, 10 MB per document.
2. The API extracts document text. The client compares the source, confirms identity
   and payable document amounts, then submits the claim for review.
3. An officer takes an unassigned review claim, or a supervisor/administrator assigns
   it. Officers access their own assignments and unassigned review claims.
4. Reviewers compare source evidence, correct identity/fields/document totals, and
   verify the claim. Human corrections remain in the audit trail.
5. Reviewers can request more information, including questions, requested documents,
   an optional deadline and a private staff note. Clients see the request without
   its internal note and can reply with text and supporting files.
6. Additional files are extracted without overwriting previously reviewed document
   fields. The reviewer must reconfirm document totals before verification.
7. A supervisor/administrator approves or rejects a verified claim with decision
   notes. The approved amount cannot exceed the claimed amount.
8. An approved claim can move to payment pending, then paid. These actions record
   settlement status; they do not initiate a financial transfer.

Statuses: uploaded, processing, review required, information required, information
received, verified, approved, rejected, payment pending, paid, processing failed.
Draft extraction failures can be retried from the claim details screen.

## Workspace tools

- Claims: search reference/patient/provider, filter every status, filter assignment,
  and use a separate review queue. Lists show up to 200 matching claims.
- Analytics: date range, status counts, monthly volumes and claimed/approved/paid
  totals grouped by currency. Officers see only their accessible claims.
- Audit: searchable claim/account events. Latest 200 matching events are displayed.
- Notifications: in-app updates for submissions, assignments, requests, verification,
  decisions and settlement. The app checks unread counts every 30 seconds while the
  workspace is open; remote OS push notifications are not configured.
- Account: name, phone, appearance, notification badge preference, password change
  with current-password verification, and sign out.
- User access (administrator): create accounts, edit roles/status, create private
  Firebase recovery links, and delete logins without deleting claim/audit history.
  Administrators cannot disable/demote/delete themselves or remove the last active
  administrator. Passwords and recovery tokens are excluded from audit records.

## Local development limits

The phone can use Wi-Fi or mobile data through `services/api/start-internet.ps1`.
Build with its generated HTTPS endpoint; the cable is then unnecessary. The API
computer must remain awake and online. The temporary tunnel address changes when
the tunnel is recreated; a stable deployment is needed for independent use while
the computer is off. For USB development, run `adb reverse tcp:8000 tcp:8000` after
reconnecting the phone.
Notifications are in-app, and payment status is entered by staff. No paid service
has been enabled by these screens.

## Verification

`services/api/tests/test_workflow.py` checks role boundaries and state transitions.
The opt-in Firebase integration test creates disposable accounts and walks through
upload, extraction, confirmation, assignment, information response with evidence,
correction, verification, approval and settlement, checking privacy along the way.
It removes only its own records and does not email users.

Flutter tests cover signup/recovery, role-specific navigation, and dashboard layout
at 320–412 logical pixels with text scaling up to 200 percent. Tests should run from
a local build copy outside OneDrive if Windows locks generated test assets.

PaddlePaddle is pinned to 3.2.2 because Windows Smart App Control blocks the
`common.dll` shipped with 3.3.1 on the development computer. The compatible runtime
passes real image and scanned-PDF extraction without changing Windows security
policy. Model-host connectivity probing is skipped; missing official models still
download normally.
