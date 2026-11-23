# claimelens mobile architecture

Flutter -> FastAPI -> Firebase Authentication / Firestore / Firebase Storage.
FastAPI -> PaddleOCR -> extracted fields -> human correction -> claim confirmation.

The app stores Firebase access/refresh tokens in platform secure storage. The API
refreshes sessions through Firebase Secure Token, verifies ID tokens with revocation
checking, and loads each user's profile from Firestore before granting access.
Recovery uses Firebase-hosted password-reset links. API signup cannot assign roles.

Firestore collections: `profiles`, `claims`, `claim_documents`,
`claim_extracted_fields`, `claim_processing_jobs`, and `audit_events`.
The Admin SDK bypasses database rules, so the repository scopes all client access
to claim ownership and all officer access to assignment. Privileged processing is
entered only after the API authorizes the claim. Confirmation uses one transaction
to validate document ownership, duplicates, amounts, and currencies, apply human
corrections, record audit events, and submit the claim for review. Concurrent OCR
starts acquire the claim status through a transaction.

Uploads validate file signatures and limit individual documents to 10 MB and claim
packages to ten documents. Storage objects remain private. Document URLs are signed
for five minutes only after a permitted claim read. Production must use HTTPS.

Firebase project: `claimelens`; default Firestore location: `eur3`.
Storage billing and bucket creation must be completed by the project owner.
Firebase credentials are server-only and stored outside Git.

The earlier web platform, Supabase migrations, and research-only tooling were
removed from this mobile-app version. Remote legacy data was not deleted or
automatically imported. Existing production hosting is a separate deployment.
