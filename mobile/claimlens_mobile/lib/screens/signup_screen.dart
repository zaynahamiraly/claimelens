import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_client.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.initialEmail = ''});
  final String initialEmail;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  late final email = TextEditingController(text: widget.initialEmail);
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool busy = false, hidden = true;
  String? error, success;

  @override
  void dispose() {
    for (final controller in [name, email, password, confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  void backToLogin() =>
      Navigator.pop(context, success == null ? null : email.text.trim());

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
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
        '/auth/signup',
        data: {
          'display_name': name.text.trim(),
          'email': email.text.trim(),
          'password': password.text,
        },
      );
      if (!mounted) return;
      setState(() {
        success = response.data?['message'] as String? ??
            'Account created. You can now sign in.';
        password.clear();
        confirm.clear();
      });
    } catch (exception) {
      if (mounted) setState(() => error = readableApiError(exception));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('Sign up'),
            leading: IconButton(
              tooltip: 'Back to sign in',
              onPressed: busy ? null : backToLogin,
              icon: const Icon(Icons.arrow_back),
            )),
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
                      Icon(
                          success == null
                              ? Icons.person_add_alt_1
                              : Icons.check_circle_outline,
                          size: 54,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                          success == null
                              ? 'Join claimelens'
                              : 'Your account is ready',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      if (success == null) ...[
                        const Text(
                            'Create a client account to submit and track your medical claims.',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        TextFormField(
                            controller: name,
                            enabled: !busy,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            decoration: const InputDecoration(
                                labelText: 'Full name',
                                prefixIcon: Icon(Icons.person_outline)),
                            validator: (v) => (v?.trim().length ?? 0) < 2 ||
                                    (v?.trim().length ?? 0) > 120
                                ? 'Enter a name between 2 and 120 characters.'
                                : null),
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: email,
                            enabled: !busy,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            autocorrect: false,
                            decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined)),
                            validator: (v) =>
                                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                        .hasMatch(v?.trim() ?? '')
                                    ? null
                                    : 'Enter a valid email.'),
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: password,
                            enabled: !busy,
                            obscureText: hidden,
                            autofillHints: const [AutofillHints.newPassword],
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: InputDecoration(
                                labelText: 'Password',
                                helperText: 'Use 12 to 128 characters.',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                    tooltip: hidden
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () =>
                                        setState(() => hidden = !hidden),
                                    icon: Icon(hidden
                                        ? Icons.visibility
                                        : Icons.visibility_off))),
                            validator: (v) =>
                                (v?.length ?? 0) < 8 || (v?.length ?? 0) > 128
                                    ? 'Use 12 to 128 characters.'
                                    : null),
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: confirm,
                            enabled: !busy,
                            obscureText: true,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: const InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon: Icon(Icons.lock_outline)),
                            validator: (v) => v != password.text
                                ? 'Passwords do not match.'
                                : null),
                        const SizedBox(height: 20),
                        if (error != null)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(error!,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error))),
                        FilledButton(
                            onPressed: busy ? null : submit,
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: busy
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Text('Create account'))),
                        const SizedBox(height: 16),
                        const Text(
                            'Administrator, claims officer, and supervisor accounts are provided by your organisation. Staff use the same sign-in page.',
                            textAlign: TextAlign.center),
                      ] else ...[
                        const SizedBox(height: 16),
                        Text(success!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                      ],
                      TextButton(
                          onPressed: busy ? null : backToLogin,
                          child: Text(success == null
                              ? 'Already have an account? Sign in'
                              : 'Back to sign in')),
                    ]),
              )),
        ))),
      );
}
