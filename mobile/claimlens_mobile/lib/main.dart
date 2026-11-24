import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/claims_provider.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';
import 'app_theme.dart';
import 'screens/required_password_screen.dart';
import 'widgets/session_guard.dart';
import 'services/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(claimLensBackgroundMessage);
  } catch (_) {/* Sign-in and in-app updates remain available. */}
  final client = ApiClient();
  runApp(ClaimLensApp(client: client));
}

class ClaimLensApp extends StatelessWidget {
  const ClaimLensApp({super.key, required this.client});
  final ApiClient client;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => AuthProvider(client)..initialise()),
          ChangeNotifierProvider(create: (_) => ClaimsProvider(client)),
        ],
        child: Consumer<AuthProvider>(
            builder: (context, auth, _) => MaterialApp(
                  key: ValueKey(auth.user?.id ?? 'guest'),
                  builder: (context, child) => SessionGuard(child: child!),
                  title: 'ClaimLens',
                  debugShowCheckedModeBanner: false,
                  theme: claimLensTheme(Brightness.light),
                  darkTheme: claimLensTheme(Brightness.dark),
                  themeMode: switch (auth.user?.theme) {
                    'light' => ThemeMode.light,
                    'dark' => ThemeMode.dark,
                    _ => ThemeMode.system
                  },
                  home: const AuthGate(),
                )),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.initialising) {
      return const SplashScreen();
    }
    if (auth.user?.mustChangePassword == true) {
      return const RequiredPasswordScreen();
    }
    return auth.authenticated ? const AppShell() : const LoginScreen();
  }
}
