# ClaimLens scenario verification — 24 November 2026

Device: Samsung SM-A556E. API traffic used public HTTPS over mobile data; USB was used for installation and UI inspection. No USB reverse mappings were required. The API remains on the development computer behind a temporary tunnel.

## Results and evidence

| Scenario | Evidence | Result |
|---|---|---|
| Admin, officer and supervisor login | Actual phone, existing staff accounts | Passed |
| Existing and disposable client accounts | Actual phone | Passed |
| Admin creates client | Phone User access form | Passed; temporary account removed afterward |
| Temporary password replacement | Phone mandatory-password screen | Passed |
| Role navigation and administration restrictions | Phone officer/supervisor workspaces; automated role checks | Passed |
| PDF selection, upload and processing | Android document picker and generated invoice | Passed |
| Patient/provider/amount extraction | Phone: QA Patient/Clinic fixture, MUR 1,250 | Passed |
| Source preview and final submission | Phone: source preview and REVIEW_REQUIRED confirmation | Passed |
| Report incorrect amount before editing | Phone: report button, proposal MUR 900, review page | Passed |
| Reusing an already submitted receipt | Phone confirmation request | Rejected with actionable duplicate error, HTTP 409 |
| Hospital + pharmacy + doctor in one claim | Live disposable integration: 5,000 + proposed 900 + 1,500 | Proposed total 7,400; pending officer review |
| Officer checks pharmacy correction | Live integration: original 800, client 900, officer 800 | Reviewed total 7,300; original and client proposal preserved |
| Separate claim for same patient | Live integration: separate later visit for 400 | Independent ID, reference, status and total; first claim unaffected |
| Invalid negative amounts | Live API | Rejected, HTTP 422 |
| Successful-upload retry with same idempotency key | Live API | Same claim reused |
| Duplicate payable evidence across claims | Live API | Rejected, HTTP 409 |
| Offline app startup and recovery | Actual phone: data disabled, restart, restore data, Retry saved session | Existing session recovered without entering password |
| Camera and gallery cancellation | Actual Android camera/picker | Returned to empty new claim; no accidental attachment |
| Image/scanned PDF OCR, Word extraction, privacy, workflow, appeals, settlement, passwords, encryption/backups and queue recovery | Earlier complete live/API run: 78 tests passed; details in existing tests | Passed at that checkpoint |
| Current isolated API checks | pytest, live opt-ins disabled | 73 passed, 6 skipped |
| New multi-expense/dispute integration after persistence changes | Live Firebase, disposable users and documents | 1 passed, 100.44 seconds |
| Current Flutter checks | Analyzer and complete Flutter test suite | No analyzer issues; 38 tests passed |

The earlier 78-test run and the current targeted reruns are distinct checkpoints, not a claim that a new full 79-test live suite was executed after every edit.

## Fixes made

1. Added system-navigation bottom spacing to new-claim, extraction confirmation and submission pages. On the Samsung the review button's measured bounds moved above the system navigation region. Regression tests also exercise a 48-pixel bottom inset.
2. Made the claim total wrap on narrow screens instead of overflowing horizontally.
3. Removed misleading text about automatic verification. Submitted client values always enter officer review.
4. Added explicit reporting before editing an OCR amount. The client edits a proposal; the API independently detects changed amounts. The document preserves `extracted_amount`, `client_proposed_amount`, `client_proposed_currency` and `client_reported_incorrect_amount`, while `confirmed_amount` can subsequently reflect officer review. Submission audit metadata records disputed document IDs. Old documents remain compatible through optional/default fields.
5. Displayed the original OCR amount, client proposal and a dispute notice in staff review.
6. Kept saved credentials when startup or token refresh fails due to connectivity/server problems. Explicit authentication rejection still clears invalid sessions. Added Retry saved session; no offline claim editing or cached medical records are implied.
7. Added Retry loading claim and protected asynchronous extraction loading against updating a disposed screen.

## Scope still requiring further acceptance testing

- Actual camera capture and selecting a real gallery image, including permission denial/regrant, were not performed. Cancellation was tested; generated-image OCR was tested through the API.
- Upload interruption halfway through a multipart transfer, simultaneous actions on multiple physical devices, long-duration load and device-specific battery/background behavior need additional coverage. Retrying a completed upload is not evidence for every partial-upload failure.
- OCR quality on representative insurer documents and poor-quality photographs requires a labeled evaluation dataset. Synthetic test results are not an accuracy benchmark.
- Expense categories such as hospital/pharmacy/doctor are not yet a dedicated editable taxonomy. Multiple documents and independent claims work, but grouping rules and coverage rules must be agreed with the insurer.
- Permanent hosting, production signing, provider MFA and real banking integration are not certified by these tests. The temporary API connection depends on the computer remaining online.

## Cleanup

Disposable live-test accounts/data were removed by their test cleanup routines. The phone-created QA client and its two synthetic claims/documents were removed after testing. Test camera/gallery operations did not capture real surroundings or select personal images. The phone's original stay-awake setting was restored. Existing staff passwords and real claim/user records were retained.
