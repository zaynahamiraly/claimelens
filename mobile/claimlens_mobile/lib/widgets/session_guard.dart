import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';

class SessionGuard extends StatefulWidget {
  const SessionGuard({super.key, required this.child});
  final Widget child;
  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard>
    with WidgetsBindingObserver {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 15), (_) => check());
  }

  void check() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.authenticated &&
        DateTime.now().difference(auth.lastActivity) >
            Duration(minutes: auth.user!.isClient ? 15 : 5)) {
      auth.lock();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) check();
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Listener(
        onPointerDown: (_) => auth.touch(),
        onPointerMove: (_) => auth.touch(),
        child: Stack(children: [
          widget.child,
          if (auth.authenticated && auth.locked)
            const Positioned.fill(child: _UnlockScreen())
        ]));
  }
}

class _UnlockScreen extends StatefulWidget {
  const _UnlockScreen();
  @override
  State<_UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<_UnlockScreen> {
  final password = TextEditingController();
  String? error;
  bool busy = false;
  Future<void> deviceUnlock() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await context.read<AuthProvider>().unlockWithDevice();
    } catch (e) {
      if (mounted) setState(() => error = readableApiError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  Future<void> unlock() async {
    if (password.text.isEmpty) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await context.read<AuthProvider>().unlock(password.text);
    } catch (e) {
      if (mounted) setState(() => error = readableApiError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: false,
      child: Scaffold(
          body: SafeArea(
              child: Center(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Icon(Icons.lock_outline, size: 56),
                                const SizedBox(height: 20),
                                Text('Your workspace is locked',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 10),
                                const Text('Enter your password to continue.',
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 24),
                                TextField(
                                    controller: password,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                        labelText: 'Password'),
                                    onSubmitted: (_) => busy ? null : unlock()),
                                const SizedBox(height: 16),
                                if (error != null)
                                  Text(error!,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error)),
                                FilledButton(
                                    onPressed: busy ? null : unlock,
                                    child:
                                        Text(busy ? 'Unlocking…' : 'Unlock')),
                                OutlinedButton.icon(
                                    onPressed: busy ? null : deviceUnlock,
                                    icon: const Icon(Icons.fingerprint),
                                    label: const Text(
                                        'Use fingerprint or device lock')),
                                TextButton(
                                    onPressed: busy
                                        ? null
                                        : context.read<AuthProvider>().logout,
                                    child: const Text('Sign out instead'))
                              ])))))));
}
