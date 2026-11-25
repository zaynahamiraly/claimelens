# ClaimLens cloud deployment and migration

Status: prepared, not deployed. This guide does not authorize billing. The draft
[Blueprint](../deploy/render.yaml) creates a paid service and disk only if applied.
Keep the existing API running until migration and the replacement APK are verified.

## Service proposal

Use one Docker web service in Frankfurt, one CPU / 2 GB memory (`standard`), and
a 10 GB persistent disk mounted at `/var/data`. This is a starting size for CPU
PaddleOCR; verify peak memory, concurrency and extraction times before accepting it.
Run one instance: the document store and embedded workers are designed for it.
Automatic Git deployments are disabled so a push cannot interrupt a migration.

Render's published estimate is USD 25/month for this compute size plus USD
0.25/GB/month for disk: approximately USD 27.50/month, before tax or additional
usage. Recheck the account's creation screen before approval. This is not a free
deployment. [Pricing](https://render.com/pricing),
[compute plan names](https://render.com/docs/compute-plans-update).

Free Render services sleep after inactivity and lose uploaded local files on
restart, redeploy or sleep. They cannot attach a persistent disk. They do not meet
this app's current document-retention requirements.
[Free service limits](https://render.com/docs/free),
[persistent disks](https://render.com/docs/disks).

Firebase Authentication and Firestore remain in the existing `claimelens` project.
No Firebase Storage bucket or Firebase billing change is part of this plan.
The Android app remains named **ClaimLens**.

## Create only after account connection and cost approval

1. Connect the actual GitHub repository and select `deploy/render.yaml` as the
   Blueprint path. Inspect the proposed paid resources before applying it.
2. Supply `FIREBASE_API_KEY` privately. Add the existing Firebase Admin service
   account as the secret file `firebase-admin.json`, available at
   `/etc/secrets/firebase-admin.json`. Never commit either credential file or put
   service-account contents into the APK. Verify the secret file's project ID.
3. Keep `CLAIMLENS_MAINTENANCE=true` and both worker flags false during migration.
   The health endpoint stays available, but application API requests return 503
   and cannot change the live Firebase data. Maintenance also suppresses workers
   independently of their flags.
4. Deploy and inspect logs. The image downloads public PaddleOCR models at build
   time; runtime starts only after the model engine loads. `PORT` selects the
   provider's listening port. Do not substitute an unverified service hostname.
5. Record the actual HTTPS service URL. `RENDER_EXTERNAL_URL` supplies the origin
   for private document links automatically. Do not carry the old tunnel's
   `PUBLIC_API_URL` into cloud environment variables. An explicit value overrides
   the provider URL, for example when moving to a custom domain.

## Migrate existing private documents

The Firestore database and Authentication accounts already live in Firebase;
do not import them into another project or reset staff accounts.

1. Schedule a short write freeze. Stop the old API and its processing/push workers
   so uploads, review actions and background tasks cannot change the snapshot.
2. From `services/api` with its existing private configuration, create and verify
   an encrypted backup using the existing backup utility:

   ```text
   python -m app.backups create <private-backup-file>
   python -m app.backups verify <private-backup-file>
   ```

   Enter the backup passphrase interactively; keep it separately from the backup.
   Transfer the encrypted archive through a private authenticated channel. Do not
   upload medical documents or backups to GitHub or public artifact URLs.
3. In the cloud service's private shell, restore into an empty destination:

   ```text
   python -m app.backups restore <private-backup-file> --destination /var/data/claimlens/documents
   ```

   Do **not** add `--apply-database`: this migration keeps the same live Firestore.
   Remove any empty placeholder directory only after verifying it contains no
   data; do not overwrite populated storage. Restore includes the original
   `.encryption-key`, `.signing-key`, file metadata and encrypted documents.
   If the old installation uses `DOCUMENT_ENCRYPTION_KEY` from its environment,
   transfer that exact value privately as well: it is not part of the backup.
   Generating a replacement key would make existing encrypted files unreadable.
4. Verify file counts and compare representative file hashes against the old
   installation without printing document contents. Keep the original storage
   and verified encrypted archive until migration has been accepted.
5. Set maintenance false and enable processing/push workers on the cloud service.
   Keep the old workers stopped to avoid two services processing the same queue.

## Acceptance and Android installation

Before declaring migration complete, verify all of the following against the
actual cloud URL:

- HTTPS health response and sign-in/session refresh for client and each staff role.
- Existing encrypted document retrieval, including denial for unrelated clients.
- New image/PDF upload, PaddleOCR extraction, patient/provider/amount confirmation,
  multiple expenses, correction reporting and officer verification.
- Supervisor decision, administrator user access, notifications, client chat and
  staff replies; preserve existing account roles and passwords.
- Service restart retains document access and keys; inspect OCR memory usage and
  test an interrupted upload without submitting duplicates.
- Build/install the APK with this exact HTTPS origin. Test with USB forwarding
  removed, cable unplugged, Wi-Fi and mobile data. Then switch the computer off
  and repeat login, upload, claim retrieval and chat.

The APK update may require the USB cable once. Running the hosted backend does
not require COM5, a desktop tunnel, or the development computer remaining on.

## Operations and rollback

Keep encrypted backups outside the service disk, with separately secured
passphrases. Test restoration periodically. Monitor disk usage, OCR queue age,
memory, failed requests, authentication errors and billing. Provider snapshots
are additional protection, not the only backup.

The single instance with an attached disk can have deployment downtime. Keep
maintenance windows short and explicit. Before rollback after cloud writes,
freeze cloud writes and copy its latest files/keys back through a verified backup;
the old local disk alone is stale. Keep only one active worker instance. Do not
delete the cloud service until the replacement endpoint and latest documents are
verified. Deleting/recreating a service may also change its URL.

## Verification limits before launch

Startup, URL selection and maintenance behavior have local automated tests.
The Docker build, provider configuration, migration and phone checks must still
run on the connected account/device. Local checks cannot establish cloud OCR
capacity or prove that a deployment already exists.
