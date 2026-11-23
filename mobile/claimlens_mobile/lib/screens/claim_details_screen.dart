import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/claim.dart';
import '../providers/auth_provider.dart';
import '../providers/claims_provider.dart';
import '../services/api_client.dart';
import '../widgets/status_chip.dart';
import 'extracted_info_screen.dart';
import 'processing_screen.dart';
import '../services/workspace_service.dart';
import '../widgets/workspace_form.dart';
import 'staff_review_screen.dart';
import 'information_response_screen.dart';

class ClaimDetailsScreen extends StatefulWidget {
  const ClaimDetailsScreen({
    super.key,
    required this.reference,
    this.submitted = false,
  });
  final String reference;
  final bool submitted;
  @override
  State<ClaimDetailsScreen> createState() => _ClaimDetailsScreenState();
}

class _ClaimDetailsScreenState extends State<ClaimDetailsScreen> {
  ClaimDetails? claim;
  String? error;
  bool loading = true;
  Timer? refreshTimer;

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _action(String action) async {
    final current = claim!;
    if (action == 'correct') {
      final saved = await Navigator.push<bool>(context,
          MaterialPageRoute(builder: (_) => StaffReviewScreen(claim: current)));
      if (saved == true && mounted) await _load();
      return;
    }
    try {
      final api = workspaceApi(context);
      final entries = <FormEntry>[];
      if (action == 'assign') {
        final response = await api.get<List<dynamic>>('/workspace/officers');
        final options = {
          for (final row in response.data!)
            row['id'] as String: row['display_name'] as String
        };
        if (options.isEmpty) {
          throw Exception(
              'Create an active claims officer account in User access first.');
        }
        entries.add(FormEntry('assignee', 'Claims officer',
            value: current.assignedTo ?? '', options: options));
      }
      if (action == 'approve') {
        entries.add(FormEntry(
            'approved_amount', 'Approved amount (${current.currency})',
            value: current.claimedAmount?.toStringAsFixed(2) ?? '',
            numeric: true));
      }
      if (action == 'approve' || action == 'reject') {
        entries.add(const FormEntry(
            'notes', 'Decision notes (at least 5 characters)',
            lines: 4));
      }
      if (action == 'request-information') {
        entries.addAll(const [
          FormEntry('reason', 'Reason for the request'),
          FormEntry('questions', 'Questions for the client', lines: 4),
          FormEntry('required_documents', 'Required documents',
              required: false, lines: 3),
          FormEntry('response_deadline', 'Response deadline (YYYY-MM-DD)',
              required: false),
          FormEntry('internal_note', 'Internal note (staff only)',
              required: false, lines: 3)
        ]);
      }
      if (!mounted) return;
      final saved = await workspaceForm(context,
          title: friendlyLabel(action),
          fields: entries,
          explanation: switch (action) {
            'verify' =>
              'Confirm that you checked the source documents, patient, provider and payable amounts. This sends the claim for a supervisor decision.',
            'claim' =>
              'Assign this claim to yourself and begin reviewing its evidence.',
            'payment-pending' =>
              'Mark this approved claim as awaiting payment.',
            'paid' =>
              'Confirm that payment has been completed. This records settlement; it does not transfer money.',
            _ => null
          },
          button: action == 'assign'
              ? 'Save assignment'
              : friendlyLabel(action), submit: (values) async {
        final payload = <String, dynamic>{...values};
        if (payload['response_deadline'] == '') {
          payload['response_deadline'] = null;
        }
        await api.post<dynamic>('/claims/${current.reference}/actions/$action',
            data: payload);
      });
      if (saved == true && mounted) await _load();
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(readableApiError(exception))));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      claim = await context.read<ClaimsProvider>().service.details(
            widget.reference,
          );
      refreshTimer?.cancel();
      if (mounted && claim!.status == 'PROCESSING') {
        refreshTimer = Timer(const Duration(seconds: 4), _load);
      }
    } catch (exception) {
      error = readableApiError(exception);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClient = context.watch<AuthProvider>().user?.isClient ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reference),
        actions: [
          IconButton(
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : claim == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(error ?? 'Claim not found.'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (widget.submitted)
                        Card(
                          color: Colors.green.shade50,
                          child: const ListTile(
                            leading:
                                Icon(Icons.check_circle, color: Colors.green),
                            title: Text('Claim submitted'),
                            subtitle: Text(
                              'You can follow its status from this page.',
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              claim!.reference,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          StatusChip(status: claim!.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _Value(
                                label: 'Patient',
                                value: claim!.patientName.isEmpty
                                    ? 'Awaiting confirmation'
                                    : claim!.patientName,
                              ),
                              _Value(
                                label: 'Provider',
                                value: claim!.providerName.isEmpty
                                    ? 'Awaiting confirmation'
                                    : claim!.providerName,
                              ),
                              _Value(
                                label: 'Amount',
                                value: claim!.claimedAmount == null
                                    ? 'Awaiting confirmation'
                                    : '${claim!.currency} ${claim!.claimedAmount!.toStringAsFixed(2)}',
                              ),
                              _Value(
                                label: 'Client',
                                value: claim!.workflow['client_name']
                                        ?.toString() ??
                                    'Not available',
                              ),
                              _Value(
                                label: 'Officer',
                                value: claim!.workflow['assigned_officer_name']
                                        ?.toString() ??
                                    'Awaiting assignment',
                              ),
                              if (claim!.workflow['approved_amount'] != null)
                                _Value(
                                    label: 'Approved',
                                    value:
                                        '${claim!.currency} ${claim!.workflow['approved_amount']}'),
                              if (claim!.workflow['decision_notes'] != null)
                                _Value(
                                    label: 'Decision',
                                    value: claim!.workflow['decision_notes']
                                        .toString()),
                              if (claim!.workflow['paid_at'] != null)
                                _Value(
                                    label: 'Paid',
                                    value: claim!.workflow['paid_at']
                                        .toString()
                                        .substring(0, 10)),
                              _Value(
                                label: 'Created',
                                value: DateFormat(
                                  'dd MMM yyyy, HH:mm',
                                ).format(claim!.createdAt.toLocal()),
                                last: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ProgressTimeline(status: claim!.status),
                      if (!isClient && claim!.availableActions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text('Review actions',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: claim!.availableActions
                                .where((a) => a != 'respond')
                                .map((action) => FilledButton.tonalIcon(
                                    onPressed: () => _action(action),
                                    icon: Icon(switch (action) {
                                      'correct' => Icons.edit_outlined,
                                      'verify' => Icons.fact_check_outlined,
                                      'assign' ||
                                      'claim' =>
                                        Icons.person_add_alt,
                                      'approve' => Icons.check_circle_outline,
                                      'reject' => Icons.cancel_outlined,
                                      'request-information' =>
                                        Icons.help_outline,
                                      _ => Icons.payments_outlined
                                    }),
                                    label: Text(action == 'correct'
                                        ? 'Review & correct'
                                        : action == 'claim'
                                            ? 'Assign to me'
                                            : friendlyLabel(action))))
                                .toList()),
                      ],
                      for (final info in claim!.informationRequests)
                        Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Card(
                                child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(children: [
                                            const Icon(
                                                Icons.question_answer_outlined),
                                            const SizedBox(width: 10),
                                            Expanded(
                                                child: Text(
                                                    info['status'] == 'OPEN'
                                                        ? 'Information needed'
                                                        : 'Information received',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium))
                                          ]),
                                          const SizedBox(height: 12),
                                          Text(
                                              info['reason']?.toString() ?? ''),
                                          const SizedBox(height: 8),
                                          Text(info['questions']?.toString() ??
                                              ''),
                                          if ((info['required_documents'] ??
                                                  '') !=
                                              '')
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8),
                                                child: Text(
                                                    'Requested documents: ${info['required_documents']}')),
                                          if (info['response_deadline'] != null)
                                            Text(
                                                'Respond by ${info['response_deadline']}'),
                                          if (!isClient &&
                                              (info['internal_note'] ?? '') !=
                                                  '')
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 12),
                                                child: Text(
                                                    'Staff note: ${info['internal_note']}')),
                                          if (info['response_text'] != null)
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 12),
                                                child: Text(
                                                    'Client response: ${info['response_text']}')),
                                          if (isClient &&
                                              info['status'] == 'OPEN' &&
                                              claim!.availableActions
                                                  .contains('respond'))
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 12),
                                                child: FilledButton.icon(
                                                    onPressed: () async {
                                                      final saved = await Navigator.push<
                                                              bool>(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (_) =>
                                                                  InformationResponseScreen(
                                                                      reference:
                                                                          claim!
                                                                              .reference,
                                                                      request:
                                                                          info)));
                                                      if (saved == true &&
                                                          mounted) {
                                                        await _load();
                                                      }
                                                    },
                                                    icon:
                                                        const Icon(Icons.reply),
                                                    label: const Text(
                                                        'Provide information'))),
                                        ])))),
                      if (isClient && claim!.status == 'UPLOADED') ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExtractedInfoScreen(
                                  reference: claim!.reference),
                            ),
                          ),
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('Confirm extracted information'),
                        ),
                      ],
                      if (isClient &&
                          (claim!.status == 'PROCESSING_FAILED' ||
                              (claim!.status == 'UPLOADED' &&
                                  claim!.documents.any(
                                    (document) =>
                                        document.extractionStatus == 'FAILED',
                                  )))) ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProcessingScreen(reference: claim!.reference),
                            ),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry processing'),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Documents (${claim!.documents.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      ...claim!.documents.map(
                        (document) => _DocumentCard(document: document),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Audit history',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      if (claim!.auditEvents.isEmpty)
                        const Text('No audit events are available.'),
                      ...claim!.auditEvents.map(
                        (event) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.circle, size: 10),
                          title: Text(
                            (event['event_type'] as String)
                                .replaceAll('_', ' '),
                          ),
                          subtitle: Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(
                              DateTime.parse(
                                event['created_at'] as String,
                              ).toLocal(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _ProgressTimeline extends StatelessWidget {
  const _ProgressTimeline({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final stage = switch (status) {
      'UPLOADED' || 'PROCESSING' || 'PROCESSING_FAILED' => 0,
      'REVIEW_REQUIRED' ||
      'INFORMATION_REQUIRED' ||
      'INFORMATION_RECEIVED' =>
        1,
      'VERIFIED' => 2,
      'APPROVED' || 'PAYMENT_PENDING' || 'REJECTED' => 3,
      'PAID' => 4,
      _ => 0
    };
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Claim progress',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 14),
                  for (final (index, label) in [
                    'Documents uploaded',
                    'Evidence review',
                    'Verified',
                    status == 'REJECTED' ? 'Rejected' : 'Decision',
                    'Payment completed'
                  ].indexed)
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(children: [
                          Icon(
                              index < stage || status == 'PAID'
                                  ? Icons.check_circle
                                  : index == stage
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                              size: 20,
                              color: index <= stage
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(label,
                                  style: TextStyle(
                                      fontWeight: index == stage
                                          ? FontWeight.bold
                                          : FontWeight.normal)))
                        ]))
                ])));
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value, this.last = false});
  final String label;
  final String value;
  final bool last;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document});
  final ClaimDocument document;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ExpansionTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(
            document.originalName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${document.documentType.replaceAll('_', ' ')} Â· ${document.extractionStatus.replaceAll('_', ' ')}',
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            if (document.signedUrl != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(document.signedUrl!),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open private source document'),
                ),
              ),
            if (document.extractionNotes != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  document.extractionNotes!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (document.fields.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('No fields were extracted from this document.'),
              ),
            ...document.fields.map(
              (field) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(field.fieldName.replaceAll('_', ' ')),
                subtitle: Text(field.normalizedValue),
                trailing: Text('${(field.confidence * 100).round()}%'),
              ),
            ),
          ],
        ),
      );
}
