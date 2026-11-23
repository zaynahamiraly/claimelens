import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/claims_provider.dart';
import '../widgets/claim_card.dart';
import '../services/workspace_service.dart';
import 'history_screen.dart';
import 'new_claim_screen.dart';
import 'workspace_screens.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ClaimsProvider>().loadDashboard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<ClaimsProvider>();
    final user = context.watch<AuthProvider>().user!;
    final dashboard = data.dashboard;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        actions: [
          IconButton(
            onPressed: data.busy ? null : data.loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: data.loadDashboard,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Text(
              'Hello, ${user.displayName}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              user.isClient
                  ? 'Track your submissions and complete any required action.'
                  : 'Your role-based operational view.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            if (data.error != null)
              _ErrorCard(message: data.error!, retry: data.loadDashboard),
            Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                              user.isClient
                                  ? Icons.health_and_safety_outlined
                                  : Icons.assignment_turned_in_outlined,
                              size: 36),
                          const SizedBox(height: 12),
                          Text(
                              user.isClient
                                  ? 'Your claims, in one place'
                                  : '${friendlyLabel(user.role)} workspace',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(user.isClient
                              ? 'Upload evidence, follow progress and respond to your review team.'
                              : 'Review evidence, keep clients informed and move claims through each stage.'),
                          const SizedBox(height: 16),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            FilledButton.icon(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => user.isClient
                                            ? const NewClaimScreen()
                                            : const HistoryScreen(
                                                reviewOnly: true))),
                                icon: Icon(user.isClient
                                    ? Icons.add
                                    : Icons.fact_check_outlined),
                                label: Text(user.isClient
                                    ? 'Submit a claim'
                                    : 'Open review queue')),
                            OutlinedButton(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => user.isClient
                                            ? const HistoryScreen()
                                            : const AnalyticsScreen())),
                                child: Text(user.isClient
                                    ? 'My claims'
                                    : 'View analytics'))
                          ]),
                        ]))),
            const SizedBox(height: 20),
            if (data.dashboard == null && data.busy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (dashboard != null) ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth < 300 ||
                          MediaQuery.textScalerOf(context).scale(16) > 24
                      ? 1
                      : 2;
                  final cardWidth =
                      (constraints.maxWidth - (columns - 1) * 12) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _Metric(
                        label: 'All claims',
                        value: dashboard.total,
                        icon: Icons.folder_copy_outlined,
                      ),
                      _Metric(
                        label: 'Processing',
                        value: dashboard.processing,
                        icon: Icons.sync,
                      ),
                      _Metric(
                        label: 'Needs review',
                        value: dashboard.reviewRequired,
                        icon: Icons.fact_check_outlined,
                      ),
                      _Metric(
                        label: 'Verified',
                        value: dashboard.verified,
                        icon: Icons.verified_outlined,
                      ),
                      _Metric(
                        label: 'Failed',
                        value: dashboard.failed,
                        icon: Icons.error_outline,
                      ),
                      for (final status in [
                        'INFORMATION_REQUIRED',
                        'INFORMATION_RECEIVED',
                        'APPROVED',
                        'REJECTED',
                        'PAYMENT_PENDING',
                        'PAID'
                      ])
                        _Metric(
                            label: friendlyLabel(status),
                            value: dashboard.byStatus[status] ?? 0,
                            icon: switch (status) {
                              'INFORMATION_REQUIRED' => Icons.help_outline,
                              'PAID' => Icons.paid_outlined,
                              'REJECTED' => Icons.cancel_outlined,
                              _ => Icons.assignment_outlined
                            }),
                    ]
                        .map(
                          (metric) => SizedBox(
                              width: cardWidth,
                              child: GestureDetector(
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => HistoryScreen(
                                                  initialStatus: switch (
                                                      metric.label) {
                                                'Processing' => 'PROCESSING',
                                                'Needs review' =>
                                                  'REVIEW_REQUIRED',
                                                'Verified' => 'VERIFIED',
                                                'Failed' => 'PROCESSING_FAILED',
                                                'All claims' => null,
                                                _ => metric.label
                                                    .toUpperCase()
                                                    .replaceAll(' ', '_')
                                              }))),
                                  child: metric)),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Recent claims',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (dashboard.recent.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No claims yet. Use New claim to upload your first documents.',
                    ),
                  ),
                ),
              ...dashboard.recent.map(
                (claim) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClaimCard(claim: claim),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final int value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                '$value',
                style: Theme.of(
                  context,
                )
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(label),
            ],
          ),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: Text(message)),
              TextButton(onPressed: retry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
