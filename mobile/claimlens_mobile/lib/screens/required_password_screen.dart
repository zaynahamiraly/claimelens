import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';

class RequiredPasswordScreen extends StatefulWidget {
  const RequiredPasswordScreen({super.key});
  @override
  State<RequiredPasswordScreen> createState() => _RequiredPasswordScreenState();
}

class _RequiredPasswordScreenState extends State<RequiredPasswordScreen> {
  final key = GlobalKey<FormState>();
  final current = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    current.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!key.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await context
          .read<AuthProvider>()
          .changePassword(current.text, password.text);
    } catch (e) {
      if (mounted) setState(() => error = readableApiError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Secure your account')),
      body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Form(
                          key: key,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Icon(Icons.lock_reset, size: 56),
                                const SizedBox(height: 20),
                                Text('Choose your own password',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall),
                                const SizedBox(height: 12),
                                const Text(
                                    'Your administrator set a temporary password. Change it before continuing to your workspace.'),
                                const SizedBox(height: 24),
                                TextFormField(
                                    controller: current,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                        labelText: 'Temporary password'),
                                    validator: (v) => (v ?? '').isEmpty
                                        ? 'Enter your temporary password'
                                        : null),
                                const SizedBox(height: 16),
                                TextFormField(
                                    controller: password,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                        labelText: 'New password'),
                                    validator: (v) => (v ?? '').length < 12
                                        ? 'Use at least 12 characters'
                                        : v == current.text
                                            ? 'Choose a different password'
                                            : null),
                                const SizedBox(height: 16),
                                TextFormField(
                                    controller: confirm,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                        labelText: 'Confirm new password'),
                                    validator: (v) => v != password.text
                                        ? 'Passwords do not match'
                                        : null),
                                const SizedBox(height: 20),
                                if (error != null)
                                  Text(error!,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error)),
                                FilledButton(
                                    onPressed: busy ? null : save,
                                    child: Text(busy
                                        ? 'Saving…'
                                        : 'Save password & continue')),
                                TextButton(
                                    onPressed: busy
                                        ? null
                                        : context.read<AuthProvider>().logout,
                                    child: const Text('Sign out'))
                              ])))))));
}
