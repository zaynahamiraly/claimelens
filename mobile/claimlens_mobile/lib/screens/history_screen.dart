import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/claim.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/workspace_service.dart';
import '../widgets/claim_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.reviewOnly = false, this.initialStatus});
  final bool reviewOnly;
  final String? initialStatus;
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final search = TextEditingController();
  late String? status = widget.initialStatus;
  String scope = 'all';
  Timer? debounce;
  List<ClaimSummary> claims = [];
  bool busy = true;
  String? error;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final current = ++generation;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await workspaceApi(context)
          .get<List<dynamic>>('/claims', queryParameters: {
        'search': search.text,
        if (status != null) 'status': status,
        'scope': scope,
        'view': widget.reviewOnly ? 'review' : 'all',
        'limit': 200
      });
      if (mounted && current == generation) {
        setState(() => claims = result.data!
            .map((r) =>
                ClaimSummary.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList());
      }
    } catch (exception) {
      if (mounted && current == generation) {
        setState(() => error = readableApiError(exception));
      }
    } finally {
      if (mounted && current == generation) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = context.watch<AuthProvider>().user!.isClient;
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.reviewOnly
                ? 'Review queue'
                : client
                    ? 'My claims'
                    : 'Claims queue'),
            actions: [
              IconButton(
                  tooltip: 'Refresh claims',
                  onPressed: busy ? null : _load,
                  icon: const Icon(Icons.refresh))
            ]),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                TextField(
                    controller: search,
                    decoration: const InputDecoration(
                        labelText: 'Search claims',
                        hintText: 'Reference, patient or provider',
                        prefixIcon: Icon(Icons.search)),
                    onChanged: (_) {
                      debounce?.cancel();
                      debounce =
                          Timer(const Duration(milliseconds: 350), _load);
                    }),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                    initialValue: status ?? '',
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Claim status'),
                    items: [
                      const DropdownMenuItem(
                          value: '', child: Text('All statuses')),
                      ...claimStatuses.map((v) => DropdownMenuItem(
                          value: v, child: Text(friendlyLabel(v))))
                    ],
                    onChanged: (v) {
                      setState(() => status = v == '' ? null : v);
                      _load();
                    }),
                if (!client) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                      initialValue: scope,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Assignment'),
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All accessible claims')),
                        DropdownMenuItem(
                            value: 'mine', child: Text('Assigned to me')),
                        DropdownMenuItem(
                            value: 'unassigned',
                            child: Text('Awaiting assignment'))
                      ],
                      onChanged: (v) {
                        setState(() => scope = v!);
                        _load();
                      })
                ],
              ])),
          if (busy) const LinearProgressIndicator(),
          Expanded(
              child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (error != null)
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(children: [
                                    Text(error!),
                                    TextButton(
                                        onPressed: _load,
                                        child: const Text('Try again'))
                                  ]))),
                        if (!busy && error == null && claims.isEmpty)
                          const Card(
                              child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Column(children: [
                                    Icon(Icons.folder_open, size: 48),
                                    SizedBox(height: 12),
                                    Text('No claims match your filters.')
                                  ]))),
                        ...claims.map((claim) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ClaimCard(claim: claim))),
                        if (claims.length == 200)
                          const Text(
                              'Showing the latest 200 matches. Use search and filters to narrow the list.'),
                      ]))),
        ]));
  }
}
