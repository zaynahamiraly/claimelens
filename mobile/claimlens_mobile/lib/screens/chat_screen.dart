import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/workspace_service.dart';

bool canUseChat(String role) =>
    ['client', 'administrator', 'supervisor', 'claims_officer'].contains(role);

String chatTime(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '';
  final today = DateTime.now();
  final time =
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day
      ? time
      : '${date.day}/${date.month}/${date.year} $time';
}

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key, this.active = true});
  final bool active;
  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen>
    with WidgetsBindingObserver {
  final List<Map<String, dynamic>> rows = [];
  String? cursor, error;
  bool loading = false, ready = false, creating = false, resumed = true;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.active) load();
    timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (widget.active &&
          resumed &&
          ModalRoute.of(context)?.isCurrent == true) {
        load();
      }
    });
  }

  @override
  void didUpdateWidget(ChatInboxScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    resumed = state == AppLifecycleState.resumed;
    if (resumed && widget.active) load();
  }

  Future<void> load({bool more = false}) async {
    if (loading || !mounted || context.read<AuthProvider>().locked) return;
    setState(() => loading = true);
    try {
      final response = await workspaceApi(context).get<Map<String, dynamic>>(
          '/chat/conversations',
          queryParameters: {if (more && cursor != null) 'before': cursor});
      if (!mounted) return;
      final incoming = (response.data!['conversations'] as List)
          .map((x) => Map<String, dynamic>.from(x as Map))
          .toList();
      setState(() {
        if (!more) rows.clear();
        for (final row in incoming) {
          rows.removeWhere((old) => old['id'] == row['id']);
          rows.add(row);
        }
        cursor = response.data!['next_before'] as String?;
        error = null;
        ready = true;
      });
    } catch (e) {
      if (mounted) setState(() => error = readableApiError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> open(Map<String, dynamic> row) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => ChatThreadScreen(conversation: row)));
    if (mounted) await load();
  }

  Future<void> start() async {
    if (creating) return;
    setState(() => creating = true);
    try {
      final response = await workspaceApi(context).post<Map<String, dynamic>>(
          '/chat/conversations',
          data: {'subject': 'Claim questions'});
      if (mounted) await open(response.data!);
    } catch (e) {
      if (mounted) setState(() => error = readableApiError(e));
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = context.watch<AuthProvider>().user!.isClient;
    return Scaffold(
      appBar: AppBar(title: const Text('Chats'), actions: [
        IconButton(
            tooltip: 'Refresh conversations',
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh)),
      ]),
      body: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 100 + MediaQuery.paddingOf(context).bottom),
            children: [
              Text(client ? 'Ask your support team' : 'Shared support inbox',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(client
                  ? 'Only you and the support team can view your conversation. Include your claim reference when asking about a claim.'
                  : 'Administrators, supervisors and claims officers can follow and reply to client conversations. Every message identifies its author.'),
              if (loading && !ready)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator())),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                TextButton.icon(
                    onPressed: () => load(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry conversations')),
              ],
              if (ready && rows.isEmpty)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(client
                        ? 'No messages yet. Start a conversation with your support team.'
                        : 'No client conversations yet. New requests will appear here.')),
              const SizedBox(height: 12),
              for (final row in rows)
                Card(
                    child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                      child: Icon(
                          client ? Icons.support_agent : Icons.person_outline)),
                  title: Text(client
                      ? 'ClaimLens support'
                      : row['client_name']?.toString() ?? 'Client'),
                  subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row['subject']?.toString() ?? 'Claim questions'),
                        const SizedBox(height: 4),
                        Text(
                            row['last_message']?.toString().isNotEmpty == true
                                ? '${row['last_sender_name'] ?? ''}: ${row['last_message']}'
                                : 'Start the conversation',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        Text(chatTime(row['updated_at']),
                            style: Theme.of(context).textTheme.labelSmall),
                      ]),
                  trailing: (row['unread_count'] as num? ?? 0) > 0
                      ? Badge(
                          label: Text('${row['unread_count']}'),
                          child: const Icon(Icons.chat_bubble_outline))
                      : const Icon(Icons.chevron_right),
                  onTap: () => open(row),
                )),
              if (cursor != null)
                TextButton(
                    onPressed: loading ? null : () => load(more: true),
                    child: const Text('Load older conversations')),
            ],
          )),
      floatingActionButton: client
          ? FloatingActionButton.extended(
              onPressed: creating ? null : start,
              icon: creating
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chat_outlined),
              label:
                  Text(rows.isEmpty ? 'Ask a question' : 'Open support chat'),
            )
          : null,
    );
  }
}

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key, required this.conversation});
  final Map<String, dynamic> conversation;
  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen>
    with WidgetsBindingObserver {
  final input = TextEditingController();
  final scroll = ScrollController();
  final List<Map<String, dynamic>> messages = [];
  Timer? timer;
  bool loading = false,
      initial = true,
      sending = false,
      older = false,
      resumed = true;
  int fetched = 0, read = 0;
  String? error, pendingText, pendingKey;
  String? confirmedKey;
  CancelToken? sendCancel;
  String get path => '/chat/conversations/${widget.conversation['id']}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (resumed && ModalRoute.of(context)?.isCurrent == true) load();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    resumed = state == AppLifecycleState.resumed;
    if (resumed) load();
  }

  void merge(Iterable<Map<String, dynamic>> incoming) {
    final map = {for (final row in messages) row['id']: row};
    for (final row in incoming) {
      map[row['id']] = row;
    }
    messages
      ..clear()
      ..addAll(map.values);
    messages
        .sort((a, b) => (a['sequence'] as num).compareTo(b['sequence'] as num));
  }

  void bottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scroll.hasClients && scroll.position.extentAfter > 1) {
        scroll.jumpTo(scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> load({bool previous = false}) async {
    if (loading || !mounted || context.read<AuthProvider>().locked) return;
    final first = initial;
    final follow =
        first || !scroll.hasClients || scroll.position.extentAfter < 120;
    final oldExtent = scroll.hasClients ? scroll.position.maxScrollExtent : 0.0;
    final oldOffset = scroll.hasClients ? scroll.offset : 0.0;
    setState(() => loading = true);
    bool moreNew = false;
    try {
      final api = workspaceApi(context);
      final result = await api
          .get<Map<String, dynamic>>('$path/messages', queryParameters: {
        if (previous && messages.isNotEmpty)
          'before': messages.first['sequence']
        else if (!first)
          'after': fetched,
      });
      if (!mounted) return;
      final incoming = (result.data!['messages'] as List)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
      setState(() {
        merge(incoming);
        for (final message in incoming) {
          if (pendingKey != null &&
              message['sender_id'] == context.read<AuthProvider>().user?.id &&
              message['client_message_id'] == pendingKey) {
            confirmedKey = pendingKey;
            if (input.text.trim() == pendingText) input.clear();
            pendingText = pendingKey = null;
            sendCancel?.cancel('Message confirmed in conversation');
          }
        }
        if (first || previous) older = result.data!['has_more'] == true;
        if (!previous && incoming.isNotEmpty) {
          fetched = (incoming.last['sequence'] as num).toInt();
        }
        moreNew = !first && !previous && result.data!['has_more'] == true;
        initial = false;
        error = null;
      });
      if (previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && scroll.hasClients) {
            scroll.jumpTo(
                (oldOffset + scroll.position.maxScrollExtent - oldExtent)
                    .clamp(0.0, scroll.position.maxScrollExtent));
          }
        });
      } else if (follow && (first || incoming.isNotEmpty)) {
        bottom();
      }
      if (fetched > read &&
          resumed &&
          !context.read<AuthProvider>().locked &&
          ModalRoute.of(context)?.isCurrent == true) {
        try {
          await api
              .post<dynamic>('$path/read', data: {'through_sequence': fetched});
          read = fetched;
        } catch (_) {/* Retry read receipt on the next successful poll. */}
      }
    } catch (e) {
      if (mounted) setState(() => error = readableApiError(e));
    } finally {
      if (mounted) {
        setState(() => loading = false);
        if (moreNew) scheduleMicrotask(() => load());
      }
    }
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (sending || text.isEmpty) return;
    if (text.length > 4000) {
      setState(() => error = 'Messages can contain up to 4,000 characters.');
      return;
    }
    if (pendingText != text || pendingKey == null) {
      pendingText = text;
      final random = Random.secure();
      pendingKey =
          List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join();
    }
    setState(() => sending = true);
    final requestKey = pendingKey!;
    final cancellation = CancelToken();
    sendCancel = cancellation;
    try {
      final result = await workspaceApi(context).post<Map<String, dynamic>>(
          '$path/messages',
          data: {'text': text, 'client_message_id': requestKey},
          cancelToken: cancellation);
      if (!mounted) return;
      setState(() {
        merge([result.data!]);
        confirmedKey = requestKey;
        if (input.text.trim() == text) input.clear();
        pendingKey = pendingText = null;
        error = null;
      });
      bottom();
      await load();
    } catch (e) {
      if (mounted && confirmedKey != requestKey) {
        setState(() => error =
            '${readableApiError(e)} Your message is kept below; tap Send to retry.');
      }
    } finally {
      if (identical(sendCancel, cancellation)) sendCancel = null;
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    sendCancel?.cancel('Conversation closed');
    WidgetsBinding.instance.removeObserver(this);
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
          title: Text(user.isClient
              ? 'ClaimLens support'
              : widget.conversation['client_name']?.toString() ??
                  'Client chat'),
          actions: [
            IconButton(
                tooltip: 'Refresh messages',
                onPressed: loading ? null : load,
                icon: const Icon(Icons.refresh)),
          ]),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
                user.isClient
                    ? 'Your conversation is shared with administrators, supervisors and claims officers.'
                    : 'Shared client conversation. Replies show the staff member’s name and role.',
                style: Theme.of(context).textTheme.bodySmall)),
        if (error != null)
          Material(
              color: colors.errorContainer,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    Text(error!,
                        style: TextStyle(color: colors.onErrorContainer)),
                    TextButton(
                        onPressed: () => load(),
                        child: const Text('Retry messages')),
                  ]))),
        Expanded(
            child: initial && loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    controller: scroll,
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (older)
                        Center(
                            child: TextButton(
                                onPressed:
                                    loading ? null : () => load(previous: true),
                                child: const Text('Load earlier messages'))),
                      if (!initial && messages.isEmpty)
                        const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                                'Ask a question about your claim. Your support team can reply here.')),
                      for (final message in messages)
                        Align(
                          alignment: message['sender_id'] == user.id
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * .85),
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: message['sender_id'] == user.id
                                    ? colors.primaryContainer
                                    : colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16)),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${message['sender_name']} · ${friendlyLabel(message['sender_role'] as String)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  SelectableText(message['text'] as String),
                                  const SizedBox(height: 5),
                                  Wrap(
                                      spacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(chatTime(message['sent_at']),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall),
                                        if (message['sender_id'] == user.id)
                                          const Tooltip(
                                              message:
                                                  'Saved to the conversation',
                                              child:
                                                  Icon(Icons.check, size: 15)),
                                      ]),
                                ]),
                          ),
                        ),
                    ],
                  )),
        SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                  child: TextField(
                      controller: input,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 4000,
                      decoration: InputDecoration(
                          hintText: user.isClient
                              ? 'Message your support team'
                              : 'Reply to the client',
                          labelText: 'Message',
                          counterText: ''),
                      keyboardType: TextInputType.multiline)),
              const SizedBox(width: 8),
              IconButton.filled(
                  tooltip: 'Send message',
                  onPressed: sending ? null : send,
                  icon: sending
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send)),
            ])),
      ]),
    );
  }
}
