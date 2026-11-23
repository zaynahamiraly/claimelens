import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/claims_provider.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';
import 'app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
                  title: 'claimelens',
                  debugShowCheckedModeBanner: false,
                  theme: claimelensTheme(Brightness.light),
                  darkTheme: claimelensTheme(Brightness.dark),
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
    return auth.authenticated ? const AppShell() : const LoginScreen();
  }
}
