import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_client.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key, this.initialEmail = ''});
  final String initialEmail;
  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final form = GlobalKey<FormState>();
  late final email = TextEditingController(text: widget.initialEmail);
  bool busy = false;
  String? error, message;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = await context
          .read<AuthProvider>()
          .client
          .dio
          .post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email.text.trim()},
      );
      if (mounted) {
        setState(() => message = response.data?['message'] as String? ??
            'Check your email for a password reset link.');
      }
    } catch (exception) {
      if (mounted) setState(() => error = readableApiError(exception));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Reset password')),
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: form,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.lock_reset,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 16),
                      Text('Recover your account',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      const Text(
                          'We will email you a secure link to choose a new password.',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      if (message == null) ...[
                        TextFormField(
                            controller: email,
                            enabled: !busy,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                            validator: (v) =>
                                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                        .hasMatch(v?.trim() ?? '')
                                    ? null
                                    : 'Enter a valid email.'),
                        const SizedBox(height: 24),
                        FilledButton(
                            onPressed: busy ? null : submit,
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: busy
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Text('Send reset link'))),
                      ] else
                        Text(message!),
                      if (error != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(error!,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error))),
                      TextButton(
                          onPressed: busy ? null : () => Navigator.pop(context),
                          child: const Text('Back to sign in')),
                    ]),
              )),
        ))),
      );
}
