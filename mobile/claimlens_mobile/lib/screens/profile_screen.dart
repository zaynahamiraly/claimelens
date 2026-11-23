import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/workspace_service.dart';
import '../widgets/workspace_form.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user!;
    Future<void> edit() async {
      await workspaceForm(context,
          title: 'Account settings',
          fields: [
            FormEntry('display_name', 'Full name', value: user.displayName),
            FormEntry('phone', 'Phone number',
                value: user.phone, required: false),
            FormEntry('theme', 'Appearance',
                value: user.theme,
                options: labelOptions(['system', 'light', 'dark'])),
            FormEntry('notifications_enabled', 'Notification badge',
                value: user.notificationsEnabled.toString(),
                options: const {
                  'true': 'Show unread updates',
                  'false': 'Hide unread badge'
                })
          ],
          submit: (v) => auth.updateProfile({
                ...v,
                'notifications_enabled': v['notifications_enabled'] == 'true'
              }));
    }

    return Scaffold(
        appBar: AppBar(title: const Text('Account & settings')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    CircleAvatar(
                        radius: 36,
                        child: Text(
                            user.displayName.isEmpty
                                ? '?'
                                : user.displayName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 28))),
                    const SizedBox(height: 16),
                    Text(user.displayName,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(user.email ?? '', textAlign: TextAlign.center),
                    Chip(label: Text(friendlyLabel(user.role))),
                    if (user.phone.isNotEmpty) Text(user.phone)
                  ]))),
          const SizedBox(height: 20),
          Card(
              child: Column(children: [
            ListTile(
                leading: const Icon(Icons.manage_accounts_outlined),
                title: const Text('Personal information'),
                subtitle: const Text('Update your name and phone number'),
                trailing: const Icon(Icons.chevron_right),
                onTap: edit),
            const Divider(height: 1),
            ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Appearance & notifications'),
                subtitle: Text('${friendlyLabel(user.theme)} theme'),
                trailing: const Icon(Icons.chevron_right),
                onTap: edit),
            const Divider(height: 1),
            ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change password'),
                subtitle: const Text('Keep your account secure'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => workspaceForm(context,
                        title: 'Change password',
                        fields: const [
                          FormEntry('current', 'Current password',
                              secret: true),
                          FormEntry('password',
                              'New password (at least 8 characters)',
                              secret: true),
                          FormEntry('confirm', 'Confirm new password',
                              secret: true)
                        ], submit: (v) async {
                      if (v['password'] != v['confirm']) {
                        throw Exception('The new passwords do not match.');
                      }
                      if (v['password']!.length < 8) {
                        throw Exception('Use at least 8 characters.');
                      }
                      await auth.changePassword(v['current']!, v['password']!);
                    }))
          ])),
          const SizedBox(height: 24),
          OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
              onPressed: auth.busy
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                                  title: const Text('Sign out?'),
                                  content: const Text(
                                      'You can sign in again to access your claims.'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(c, false),
                                        child: const Text('Cancel')),
                                    FilledButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Sign out'))
                                  ]));
                      if (confirmed == true && context.mounted) {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                        await auth.logout();
                      }
                    }),
          const SizedBox(height: 20),
          Text('claimelens\nMedical claims, clearly managed.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ]));
  }
}
