import 'package:flutter/material.dart';
import '../widgets/claimlens_logo.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'password_recovery_screen.dart';
import 'signup_screen.dart';
import '../widgets/workspace_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool hidden = true;

  Future<void> openSignup() async {
    context.read<AuthProvider>().clearError();
    final registeredEmail = await Navigator.push<String>(
        context,
        MaterialPageRoute(
            builder: (_) => SignupScreen(initialEmail: email.text.trim())));
    if (!mounted || registeredEmail == null) return;
    email.text = registeredEmail;
    password.clear();
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ClaimLensLogo(size: 72),
                    const SizedBox(height: 16),
                    Text(
                      'ClaimLens',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Clients and staff sign in here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) => value != null && value.contains('@')
                          ? null
                          : 'Enter your email.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: password,
                      obscureText: hidden,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => hidden = !hidden),
                          icon: Icon(
                            hidden ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your password.'
                          : null,
                    ),
                    if (auth.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          auth.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: auth.busy
                          ? null
                          : () {
                              if (formKey.currentState!.validate()) {
                                auth.login(email.text, password.text);
                              }
                            },
                      icon: auth.busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Sign in'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: auth.busy
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => PasswordRecoveryScreen(
                                    initialEmail: email.text.trim(),
                                  ),
                                ),
                              ),
                      child: const Text('Forgot password?'),
                    ),
                    OutlinedButton(
                      onPressed: auth.busy ? null : openSignup,
                      child: const Text('New client? Sign up'),
                    ),
                    if (kDebugMode)
                      TextButton.icon(
                          onPressed: auth.busy
                              ? null
                              : () => workspaceForm(context,
                                  title: 'Development connection',
                                  explanation:
                                      'For USB debugging use http://127.0.0.1:8000. For a hotspot or Wi-Fi connection, enter the API computer’s local address. A hosted server must use HTTPS.',
                                  fields: [
                                    FormEntry('url', 'API server URL',
                                        value: auth.client.dio.options.baseUrl)
                                  ],
                                  button: 'Check & save connection',
                                  submit: (v) => auth.changeServer(v['url']!)),
                          icon: const Icon(Icons.settings_ethernet),
                          label: const Text('Development connection')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
