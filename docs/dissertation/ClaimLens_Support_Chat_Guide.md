# Support chat in ClaimLens 1.2

## Using Chats

Clients open **Chats → Ask a question**. Each client has one continuing support conversation. They can mention a claim reference when asking about a particular claim. Messages remain available when they sign in again.

Administrators, supervisors and claims officers open **Chats** to see the shared inbox. Open a client's row to read the history and reply. The preview identifies the latest sender; a badge counts messages that the signed-in staff member has not marked as read. Every bubble shows the author's name, role and time. A checkmark means the message was saved to the conversation.

Clients can see only their own conversation. The three support roles can see all client conversations. Finance accounts retain settlement access and do not receive unrestricted support-chat access. There are no private staff-only replies inside a client conversation: everything sent there is visible to that client and the support team. The existing claim review, decision and payment buttons continue to control formal claim status.

This version supports text messages up to 4,000 characters, older-message pagination, unread counts and send retries. Open chats refresh automatically; the inbox refreshes while visible. Chat-specific background push alerts, voice/video calls, attachments and private staff-to-staff conversations are not included in this version. Existing claim-update notifications continue to work.

## Persistence and permissions

- `support_threads`: one thread per client, with its subject, client identity, last sequence/preview, timestamps and per-user read positions.
- `support_messages`: immutable message records with a server-assigned sequence, conversation ID, authenticated sender ID/name/role, text, timestamp and client send key.
- `support_message_requests`: idempotency receipts scoped to sender and conversation. Retrying a send returns its existing message; changing the text under the same key returns HTTP 409.
- `audit_events`: `CHAT_MESSAGE_SENT` records identify the actor and message/conversation IDs. Audit metadata does not duplicate the message body.

Message creation, ordering, preview updates, sender read position, retry receipt and audit event are written in one Firestore transaction. Concurrent sends therefore receive distinct ordered sequence numbers. Sender names and roles are derived from the authenticated profile, never from message-body fields. Historical author snapshots remain intact if someone changes their profile name.

History uses bounded batch reads of sequence-based document IDs, rather than downloading the whole conversation. Staff inbox pagination uses timestamp and document-ID cursors. Reading an older page cannot move a user's read position backwards or mark messages newer than the requested position as read. Clients cannot query, send to, or mark another client's conversation as read.

The Flutter view pauses periodic fetching when the app is inactive or its session is locked. Draft text and the same send key are retained after a failed send while the conversation remains open. If the server saved the message but the send acknowledgement was lost, a subsequent history refresh matches its send key and clears that acknowledged draft without sending another message. Unsent drafts are not persisted across closing/restarting the app.

The operator's encrypted backup includes all three chat collections. Firebase direct-client deny rules remain in place; the mobile app accesses chat through the authenticated HTTPS API. This is shared support messaging, not end-to-end encryption between individual participants.

## Current operation

The installed test build uses the existing HTTPS development connection. The API computer must remain awake and online. Installing the Android app does not install the Python backend or PaddleOCR on the phone. Permanent backend hosting remains separate work.
