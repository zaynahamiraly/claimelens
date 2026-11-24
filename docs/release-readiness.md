# ClaimLens release work

This checklist distinguishes implemented code from services that are actually
connected and tested. A development tunnel is not permanent hosting.

## Implementation scope

- Correct ClaimLens branding; keep existing Firebase project ID and Android ID.
- Separate administration, review, decisions, and finance permissions.
- Prevent the same person reviewing and approving a claim.
- Email verification, staff invitations, sensitive-action reauthentication,
  optional authenticator MFA and session locking.
- Focused dashboards, action-needed lists, accessible layouts, source preview,
  saved drafts, upload progress and retry.
- Policy/member details, required-document configuration, duplicate prevention,
  submission receipts, appeals, and payment references.
- Persistent OCR jobs, private storage, deployment container, backup/restore,
  operational health and redacted logging.
- Push notification registration/delivery, preference controls and safe payloads.
- Signed release configuration, automated checks, device verification.

## External prerequisites

- A hosting account and persistent private storage must be connected before
  claiming that the app works independently of the development computer.
- Real staff mailboxes are needed for invitations and recovery.
- Coverage and approval rules must be supplied by the insurer; the app must not
  invent coverage or automatically approve medical claims based on OCR.
- Production signing credentials must be created/stored privately.
- No billing plan may be enabled without the user's explicit authorization.

The Firebase project identifier `claimelens` and existing private runtime folder
are legacy technical identifiers, not the app's display name. They stay stable
to preserve accounts, documents and existing installation compatibility.
