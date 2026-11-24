import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/claims_provider.dart';
import '../services/workspace_service.dart';
import '../widgets/claim_card.dart';
import 'history_screen.dart';
import 'help_screen.dart';
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
        (_) => context.read<ClaimsProvider>().loadDashboard());
  }

  void open(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClaimsProvider>();
    final user = context.watch<AuthProvider>().user!;
    final data = provider.dashboard;
    final needed = user.isClient
        ? (data?.byStatus['INFORMATION_REQUIRED'] ?? 0) +
            (data?.byStatus['UPLOADED'] ?? 0) +
            (data?.failed ?? 0)
        : user.isFinance
            ? (data?.byStatus['PAYMENT_PENDING'] ?? 0)
            : user.isAdmin
                ? data?.unassigned ?? 0
                : (data?.reviewRequired ?? 0) +
                    (data?.byStatus['INFORMATION_RECEIVED'] ?? 0);
    final metrics = <(String, int, IconData, String?)>[
      ('All claims', data?.total ?? 0, Icons.folder_copy_outlined, null),
      (
        user.isClient
            ? 'Action needed'
            : user.isAdmin
                ? 'Unassigned'
                : user.isFinance
                    ? 'Awaiting payment'
                    : 'Needs review',
        needed,
        Icons.pending_actions_outlined,
        user.isClient
            ? 'INFORMATION_REQUIRED'
            : user.isFinance
                ? 'PAYMENT_PENDING'
                : 'REVIEW_REQUIRED'
      ),
      ('Processing', data?.processing ?? 0, Icons.sync_outlined, 'PROCESSING'),
      (
        user.isClient || user.isFinance ? 'Paid claims' : 'Awaiting decision',
        user.isClient || user.isFinance
            ? data?.byStatus['PAID'] ?? 0
            : data?.verified ?? 0,
        Icons.task_alt,
        user.isClient || user.isFinance ? 'PAID' : 'VERIFIED'
      ),
    ];
    return Scaffold(
        body: RefreshIndicator(
            onRefresh: provider.loadDashboard,
            child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                children: [
                  Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Hello, ${user.displayName.split(' ').first}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(user.isClient
                              ? 'Let’s take care of your claims.'
                              : '${friendlyLabel(user.role)} workspace')
                        ])),
                    IconButton(
                        tooltip: 'Refresh overview',
                        onPressed:
                            provider.busy ? null : provider.loadDashboard,
                        icon: const Icon(Icons.refresh))
                  ]),
                  const SizedBox(height: 22),
                  Container(
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xff006773), Color(0xff129293)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.health_and_safety_outlined,
                                size: 38, color: Colors.white),
                            const SizedBox(height: 14),
                            Text(
                                user.isClient
                                    ? 'A clearer path to your claim'
                                    : user.isAdmin
                                        ? 'A well-managed workspace'
                                        : user.isFinance
                                            ? 'Track every settlement'
                                            : 'Give every claim a clear next step',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800)),
                            const SizedBox(height: 10),
                            Text(
                                user.isClient
                                    ? 'Upload your evidence, check the details and follow every stage.'
                                    : user.isAdmin
                                        ? 'Manage people, permissions and claim operations in one place.'
                                        : user.isFinance
                                            ? 'Confirm approved amounts and record payment references.'
                                            : 'Review evidence, ask for information and record a considered decision.',
                                style: const TextStyle(
                                    color: Colors.white, height: 1.5)),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                                style: FilledButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xff006773)),
                                onPressed: () => open(user.isClient
                                    ? const NewClaimScreen()
                                    : user.isAdmin
                                        ? const UsersScreen()
                                        : HistoryScreen(
                                            reviewOnly: !user.isFinance,
                                            initialStatus: user.isFinance
                                                ? 'PAYMENT_PENDING'
                                                : null)),
                                icon: Icon(user.isClient
                                    ? Icons.add
                                    : user.isAdmin
                                        ? Icons.manage_accounts_outlined
                                        : Icons.arrow_forward),
                                label: Text(user.isClient
                                    ? 'Start a new claim'
                                    : user.isAdmin
                                        ? 'Manage user access'
                                        : user.isFinance
                                            ? 'Open payments'
                                            : 'Open review queue'))
                          ])),
                  const SizedBox(height: 22),
                  if (provider.error != null)
                    Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(children: [
                              Text(provider.error!),
                              TextButton(
                                  onPressed: provider.loadDashboard,
                                  child: const Text('Try again'))
                            ]))),
                  if (provider.busy && data == null)
                    const LinearProgressIndicator(),
                  if (data != null) ...[
                    LayoutBuilder(builder: (context, box) {
                      final single = box.maxWidth < 300 ||
                          MediaQuery.textScalerOf(context).scale(16) > 24;
                      final width =
                          single ? box.maxWidth : (box.maxWidth - 12) / 2;
                      return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: metrics
                              .map((m) => SizedBox(
                                  width: width,
                                  child: Card(
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                          onTap: () => open(HistoryScreen(
                                              initialStatus: m.$4)),
                                          child: Padding(
                                              padding: const EdgeInsets.all(18),
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(m.$3,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary),
                                                    const SizedBox(height: 14),
                                                    Text('${m.$2}',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .headlineMedium
                                                            ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800)),
                                                    const SizedBox(height: 4),
                                                    Text(m.$1)
                                                  ]))))))
                              .toList());
                    }),
                    const SizedBox(height: 20),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      if (user.isClient)
                        ActionChip(
                            avatar: const Icon(Icons.drafts_outlined),
                            label: const Text('Saved drafts'),
                            onPressed: () => open(const HistoryScreen(
                                initialStatus: 'UPLOADED'))),
                      ActionChip(
                          avatar: const Icon(Icons.help_outline),
                          label: const Text('Help & document checklist'),
                          onPressed: () => open(const HelpScreen())),
                      if (!user.isClient)
                        ActionChip(
                            avatar: const Icon(Icons.bar_chart),
                            label: const Text('Analytics'),
                            onPressed: () => open(const AnalyticsScreen()))
                    ]),
                    const SizedBox(height: 24),
                    Text('Action needed',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    if (data.actionRequired.isEmpty)
                      const Card(
                          child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Row(children: [
                                Icon(Icons.check_circle_outline,
                                    color: Color(0xff087f8c)),
                                SizedBox(width: 12),
                                Expanded(
                                    child: Text(
                                        'You’re up to date. We’ll show anything that needs your attention here.'))
                              ]))),
                    ...data.actionRequired.map((claim) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClaimCard(claim: claim))),
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(
                          child: Text('Recent claims',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800))),
                      TextButton(
                          onPressed: () => open(const HistoryScreen()),
                          child: const Text('View all'))
                    ]),
                    const SizedBox(height: 12),
                    if (data.recent.isEmpty)
                      const Card(
                          child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                  'No claims yet. Your submissions and their progress will appear here.'))),
                    ...data.recent.map((claim) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClaimCard(claim: claim))),
                  ],
                ])));
  }
}
