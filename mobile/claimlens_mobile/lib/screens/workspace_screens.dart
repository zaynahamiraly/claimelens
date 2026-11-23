import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/workspace_service.dart';
import '../widgets/workspace_form.dart';
import 'claim_details_screen.dart';
import 'profile_screen.dart';

class WorkspaceMenuScreen extends StatelessWidget {
  const WorkspaceMenuScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final entries = <(IconData, String, String, Widget)>[
      if (!user.isClient)
        (
          Icons.bar_chart_outlined,
          'Analytics',
          'Claim volumes, outcomes and amounts',
          const AnalyticsScreen()
        ),
      if (!user.isClient)
        (
          Icons.history_edu_outlined,
          'Audit trail',
          'Review claim and access activity',
          const AuditScreen()
        ),
      (
        Icons.notifications_outlined,
        'Notifications',
        'Updates on your claims and assignments',
        const NotificationsScreen()
      ),
      if (user.isAdmin)
        (
          Icons.admin_panel_settings_outlined,
          'User access',
          'Manage clients, officers and supervisors',
          const UsersScreen()
        ),
      (
        Icons.settings_outlined,
        'Account & settings',
        'Profile, password and appearance',
        const ProfileScreen()
      ),
    ];
    return Scaffold(
        appBar: AppBar(title: const Text('Workspace')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Your tools', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('Signed in as ${friendlyLabel(user.role)}'),
          const SizedBox(height: 20),
          ...entries.map((entry) => Card(
              child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(entry.$1),
                  title: Text(entry.$2),
                  subtitle: Text(entry.$3),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => entry.$4))))),
        ]));
  }
}

class WorkspaceData extends StatefulWidget {
  const WorkspaceData(
      {super.key,
      required this.title,
      required this.path,
      required this.render,
      this.actions = const []});
  final String title, path;
  final List<Widget> actions;
  final List<Widget> Function(BuildContext, dynamic, Future<void> Function())
      render;
  @override
  State<WorkspaceData> createState() => _WorkspaceDataState();
}

class _WorkspaceDataState extends State<WorkspaceData> {
  dynamic data;
  String? error;
  bool busy = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(WorkspaceData oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) load();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = await workspaceApi(context).get<dynamic>(widget.path);
      if (mounted) setState(() => data = response.data);
    } catch (exception) {
      if (mounted) setState(() => error = readableApiError(exception));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: [
        ...widget.actions,
        IconButton(
            tooltip: 'Refresh',
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh))
      ]),
      body: RefreshIndicator(
          onRefresh: load,
          child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (busy) const LinearProgressIndicator(),
                if (error != null)
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(children: [
                            Text(error!),
                            TextButton(
                                onPressed: load, child: const Text('Try again'))
                          ]))),
                if (data != null && error == null)
                  ...widget.render(context, data, load),
              ])));
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => WorkspaceData(
      title: 'Notifications',
      path: '/notifications',
      render: (context, data, reload) => [
            if ((data as List).isEmpty)
              const _Empty(
                  icon: Icons.notifications_none,
                  title: 'You’re all caught up',
                  message: 'Claim updates and assignments will appear here.'),
            ...data.map<Widget>((row) => Card(
                child: ListTile(
                    isThreeLine: true,
                    leading: Icon(
                        row['read'] == true
                            ? Icons.mark_email_read_outlined
                            : Icons.mark_email_unread_outlined,
                        color: Theme.of(context).colorScheme.primary),
                    title: Text(row['title'] as String,
                        style: TextStyle(
                            fontWeight: row['read'] == true
                                ? FontWeight.normal
                                : FontWeight.bold)),
                    subtitle:
                        Text('${row['body']}\n${_date(row['created_at'])}'),
                    onTap: () async {
                      try {
                        await workspaceApi(context)
                            .post<dynamic>('/notifications/${row['id']}/read');
                        if (!context.mounted) return;
                        if (row['reference'] != null) {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ClaimDetailsScreen(
                                      reference: row['reference'] as String)));
                        }
                        await reload();
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(readableApiError(error))));
                        }
                      }
                    }))),
          ]);
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTimeRange? range;
  @override
  Widget build(BuildContext context) => WorkspaceData(
      title: 'Analytics',
      path:
          '/workspace/analytics${range == null ? '' : '?from_date=${range!.start.toIso8601String().substring(0, 10)}&to_date=${range!.end.toIso8601String().substring(0, 10)}'}',
      actions: [
        IconButton(
            tooltip: 'Choose date range',
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final result = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: range);
              if (result != null) setState(() => range = result);
            })
      ],
      render: (context, raw, reload) {
        final data = Map<String, dynamic>.from(raw as Map);
        final total = data['total'] as int;
        List<Widget> bars(Map values) => values.entries
            .map<Widget>((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${friendlyLabel(entry.key.toString())}  •  ${entry.value}'),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                          value: total == 0 ? 0 : (entry.value as num) / total,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(6))
                    ])))
            .toList();
        return [
          Text(data['scope'] as String,
              style: Theme.of(context).textTheme.bodySmall),
          if (range != null)
            TextButton.icon(
                onPressed: () => setState(() => range = null),
                icon: const Icon(Icons.clear),
                label: Text(
                    '${_date(range!.start.toIso8601String())} – ${_date(range!.end.toIso8601String())}')),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _Total(label: 'Claims', value: '$total'),
            _Total(label: 'Awaiting assignment', value: '${data['unassigned']}')
          ]),
          if (total == 0)
            const _Empty(
                icon: Icons.query_stats,
                title: 'No claims in this period',
                message:
                    'Choose another date range or return after claims are submitted.'),
          const _Heading('Claim status'),
          ...bars(data['by_status'] as Map),
          const _Heading('Monthly submissions'),
          ...bars(data['monthly'] as Map),
          const _Heading('Amounts by currency'),
          ...(data['amounts'] as Map).entries.map<Widget>((entry) => Card(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key.toString(),
                            style: Theme.of(context).textTheme.titleLarge),
                        for (final name in ['claimed', 'approved', 'paid'])
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(friendlyLabel(name)),
                              trailing: Text('${entry.value[name]}'))
                      ])))),
        ];
      });
}

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});
  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  String search = '';
  @override
  Widget build(BuildContext context) => WorkspaceData(
      title: 'Audit trail',
      path: '/workspace/audit?search=${Uri.encodeQueryComponent(search)}',
      render: (context, data, reload) => [
            TextFormField(
                initialValue: search,
                decoration: const InputDecoration(
                    labelText: 'Search reference or event',
                    prefixIcon: Icon(Icons.search)),
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (v) => setState(() => search = v)),
            const SizedBox(height: 16),
            if ((data as List).isEmpty)
              const _Empty(
                  icon: Icons.history_edu,
                  title: 'No matching activity',
                  message: 'Recorded actions will appear here.'),
            ...data.map<Widget>((row) => Card(
                    child: ExpansionTile(
                        leading: const Icon(Icons.history),
                        title: Text(friendlyLabel(row['event_type'] as String)),
                        subtitle: Text(
                            '${row['reference']} • ${_date(row['created_at'])}'),
                        childrenPadding: const EdgeInsets.all(16),
                        children: [
                      Align(
                          alignment: Alignment.centerLeft,
                          child: SelectableText(
                              'Actor: ${row['actor_id'] ?? 'System'}\n${const JsonEncoder.withIndent('  ').convert(row['metadata'] ?? {})}'))
                    ]))),
            if (data.length == 200)
              const Text(
                  'Showing the latest 200 events. Search to narrow the results.'),
          ]);
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String search = '', role = 'all';
  int revision = 0;
  Future<void> create() async {
    final saved = await workspaceForm(context,
        title: 'Create account',
        explanation:
            'Public signup creates client accounts. Only administrators can create staff accounts.',
        fields: [
          const FormEntry('display_name', 'Full name'),
          const FormEntry('email', 'Email address'),
          FormEntry('role', 'Role',
              value: 'client', options: labelOptions(accountRoles)),
          const FormEntry(
              'password', 'Initial password (at least 8 characters)',
              secret: true)
        ], submit: (v) async {
      await workspaceApi(context).post<dynamic>('/users', data: v);
    });
    if (saved == true && mounted) setState(() => revision++);
  }

  Future<void> edit(Map row, Future<void> Function() reload) async {
    final saved =
        await workspaceForm(context, title: 'Edit user access', fields: [
      FormEntry('display_name', 'Full name',
          value: row['display_name'] as String),
      FormEntry('role', 'Role',
          value: row['role'] as String, options: labelOptions(accountRoles)),
      FormEntry('status', 'Account status',
          value: row['status'] as String,
          options: labelOptions(['active', 'inactive']))
    ], submit: (v) async {
      await workspaceApi(context).put<dynamic>('/users/${row['id']}', data: v);
    });
    if (saved == true) await reload();
  }

  Future<void> action(
      String value, Map row, Future<void> Function() reload) async {
    try {
      if (value == 'edit') {
        await edit(row, reload);
        return;
      }
      if (value == 'reset') {
        final result = await workspaceApi(context)
            .post<Map<String, dynamic>>('/users/${row['id']}/password-reset');
        if (!mounted) return;
        final link = result.data!['link'] as String;
        await showDialog<void>(
            context: context,
            builder: (c) => AlertDialog(
                    title: const Text('Private recovery link'),
                    content: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text(
                          'Share this link privately with the account owner. It has not been emailed.'),
                      const SizedBox(height: 12),
                      SelectableText(link)
                    ])),
                    actions: [
                      TextButton(
                          onPressed: () =>
                              Clipboard.setData(ClipboardData(text: link)),
                          child: const Text('Copy link')),
                      FilledButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('Done'))
                    ]));
      } else {
        final confirmed = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
                    title: const Text('Delete login account?'),
                    content: Text(
                        '${row['email']} will no longer be able to sign in. Claim and audit records are retained.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Delete account'))
                    ]));
        if (confirmed == true && mounted) {
          await workspaceApi(context).delete<dynamic>('/users/${row['id']}');
          await reload();
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(readableApiError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => WorkspaceData(
      key: ValueKey(revision),
      title: 'User access',
      path: '/users',
      actions: [
        IconButton(
            tooltip: 'Create account',
            onPressed: create,
            icon: const Icon(Icons.person_add_outlined))
      ],
      render: (context, raw, reload) {
        final data = (raw as List)
            .where((row) =>
                (role == 'all' || row['role'] == role) &&
                '${row['display_name']} ${row['email']} ${row['status']}'
                    .toLowerCase()
                    .contains(search.toLowerCase()))
            .toList();
        return [
          TextField(
              decoration: const InputDecoration(
                  labelText: 'Search name, email or status',
                  prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => search = v)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
              initialValue: role,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Role'),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All roles')),
                ...accountRoles.map((r) =>
                    DropdownMenuItem(value: r, child: Text(friendlyLabel(r))))
              ],
              onChanged: (v) => setState(() => role = v!)),
          const SizedBox(height: 12),
          if (data.isEmpty)
            const _Empty(
                icon: Icons.people_outline,
                title: 'No users match',
                message: 'Change your filters or create an account.'),
          ...data.map<Widget>((row) => Card(
              child: ListTile(
                  isThreeLine: true,
                  leading: CircleAvatar(
                      child: Icon(row['role'] == 'client'
                          ? Icons.person_outline
                          : Icons.badge_outlined)),
                  title: Text(row['display_name'] as String),
                  subtitle: Text(
                      '${row['email']}\n${friendlyLabel(row['role'] as String)} • ${friendlyLabel(row['status'] as String)}'),
                  trailing: PopupMenuButton<String>(
                      tooltip: 'Manage account',
                      onSelected: (value) => action(value, row as Map, reload),
                      itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'edit', child: Text('Edit access')),
                            PopupMenuItem(
                                value: 'reset',
                                child: Text('Password recovery')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Delete login'))
                          ]),
                  onTap: () => edit(row as Map, reload)))),
        ];
      });
}

class _Empty extends StatelessWidget {
  const _Empty(
      {required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title, message;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(children: [
        Icon(icon, size: 52, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center)
      ]));
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge));
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.headlineLarge),
                Text(label)
              ])));
}

String _date(dynamic value) =>
    DateTime.tryParse(value?.toString() ?? '')
        ?.toLocal()
        .toString()
        .substring(0, 16) ??
    '';
