import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/workspace_service.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'new_claim_screen.dart';
import 'profile_screen.dart';
import 'workspace_screens.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0, unread = 0;
  Timer? timer;
  final Map<int, Widget> pages = {};
  @override
  void initState() {
    super.initState();
    refreshBadge();
    timer = Timer.periodic(const Duration(seconds: 30), (_) => refreshBadge());
  }

  Future<void> refreshBadge() async {
    try {
      final result =
          await workspaceApi(context).get<List<dynamic>>('/notifications');
      if (mounted) {
        setState(
            () => unread = result.data!.where((r) => r['read'] != true).length);
      }
    } catch (_) {/* The notifications page provides errors and retry. */}
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final client = user.isClient;
    pages.putIfAbsent(
        index,
        () => switch (index) {
              0 => const DashboardScreen(),
              1 => const HistoryScreen(),
              2 => client
                  ? const NotificationsScreen()
                  : const HistoryScreen(reviewOnly: true),
              _ => client ? const ProfileScreen() : const WorkspaceMenuScreen()
            });
    return Scaffold(
      appBar: AppBar(
          title: Row(children: [
            Icon(Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            const Flexible(
                child: Text('claimelens',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w900)))
          ]),
          actions: [
            if (MediaQuery.sizeOf(context).width >= 390 &&
                MediaQuery.textScalerOf(context).scale(14) < 20)
              Tooltip(
                  message: friendlyLabel(user.role),
                  child: Chip(
                      label: Text(client ? 'Client' : friendlyLabel(user.role),
                          style: Theme.of(context).textTheme.labelSmall))),
            IconButton(
                tooltip: 'Notifications',
                icon: Badge(
                    isLabelVisible: unread > 0 && user.notificationsEnabled,
                    label: Text('$unread'),
                    child: const Icon(Icons.notifications_outlined)),
                onPressed: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()));
                  await refreshBadge();
                })
          ]),
      body: IndexedStack(
          index: index,
          children:
              List.generate(4, (i) => pages[i] ?? const SizedBox.shrink())),
      floatingActionButton: client && index < 2
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NewClaimScreen()));
                if (mounted) {
                  setState(() {
                    pages.remove(0);
                    pages.remove(1);
                  });
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('New claim'))
          : null,
      bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (v) => setState(() {
                index = v;
                pages.remove(v);
              }),
          destinations: [
            const NavigationDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard),
                label: 'Overview'),
            const NavigationDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: 'Claims'),
            NavigationDestination(
                icon: Icon(client
                    ? Icons.notifications_outlined
                    : Icons.fact_check_outlined),
                label: client ? 'Updates' : 'Review'),
            NavigationDestination(
                icon: Icon(
                    client ? Icons.person_outline : Icons.grid_view_outlined),
                label: client ? 'Account' : 'Workspace')
          ]),
    );
  }
}
