# Chat and workflow follow-up — 24 November 2026

Version: ClaimLens mobile 1.2.0+3 and API 1.2.0. Device: Samsung SM-A556E, with API traffic over mobile data and no USB reverse mappings.

## Automated verification

- Flutter analyzer: no issues. Complete Flutter suite: **44 passed**.
- Isolated API suite: **85 passed, 8 skipped**. Skips are opt-in external/model scenarios, not failures.
- Chat unit + live Firebase integration: **13 passed** at the final integration checkpoint. This run includes 12 unit cases also counted in the isolated suite; the counts must not be added as if they were disjoint.
- Public HTTPS interrupted-upload test: **1 passed in 25.78 seconds**. A socket was closed after sending only part of a multipart body. No claim was created; retrying the complete body with the same idempotency key created one claim, replay returned that claim, and draft deletion removed it.

The live chat scenario checks all three support roles, client isolation, finance denial, immutable author attribution, forged author-field rejection, blank/oversized text validation, retry deduplication, conflicting-key rejection, independent unread counters, read-position bounds, message and inbox pagination, concurrent sends and profile-name changes without rewriting earlier authors.

Flutter checks cover starting a conversation, sender display, failed-send draft retention, reuse of the send key, deduplication of a replay, recovery when a message was saved but its send acknowledgement was lost, large-text layouts, bottom system insets, and finance navigation.

## Physical-device verification

1. A disposable client started a conversation and a synthetic claim through the public API.
2. The administrator read the conversation and replied on the Samsung.
3. The claims officer and supervisor opened the same conversation on the phone and could follow the attributed history.
4. The client signed in on the Samsung, read the staff reply and replied back. The admin inbox showed the new preview and an unread count of two.
5. On the phone, the officer assigned the synthetic claim, opened/saved the reviewed information and verified it. The supervisor approved it. A disposable finance account recorded payment pending, then paid with a synthetic payment reference. The API accepted each transition and the phone displayed PAID.

The synthetic claim was MUR 1,200. This records workflow and settlement data only; no banking transfer was performed. Initial creation/submission in this particular staff hand-off scenario was through the API. Client PDF selection, upload, preview, extraction and submission on the actual phone were covered in the earlier report.

## Fixes and adjustments

- Added the Chats tab, private client conversations, shared support inbox, authors/roles/timestamps, unread counts, bounded history and safe send retries.
- Added persistence and backup support for threads, messages and idempotency receipts.
- Fixed the officer review Save button's overlap with Android navigation; added a layout regression test. Added bottom safe spacing to shared workflow forms.
- Finance Payments now starts with all settlement-accessible statuses, so newly approved claims are visible before payment-pending is recorded.
- Paid claim details display payment method/reference.
- Removed a malformed separator in document status text.
- Avoided repeatedly scrolling an unchanged conversation to the bottom during polling.

## Test boundaries and cleanup

This extends [the earlier report](ClaimLens_QA_Report.md). The previously pending public multipart interruption and staff phone hand-off have now been exercised. A server crash between database/file operations, simultaneous use on several physical phones, long-duration load, real insurer coverage rules and production hosting/signing still need separate acceptance work. Camera/gallery cancellation was tested earlier; real camera capture, permission denial/regrant and a representative OCR-quality study remain outside these checks.

Disposable integration accounts, threads/messages, retry receipts and synthetic claim data are removed after verification. Existing users, passwords, claims and real conversations are retained. The phone is returned to the administrator account and its original stay-awake setting. The temporary HTTPS API still depends on the development computer remaining online.
