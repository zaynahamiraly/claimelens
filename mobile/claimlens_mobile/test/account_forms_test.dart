import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:claimelens/providers/auth_provider.dart';
import 'package:claimelens/screens/signup_screen.dart';
import 'package:claimelens/screens/password_recovery_screen.dart';
import 'package:claimelens/services/api_client.dart';

void main() {
  Future<void> open(
    WidgetTester tester,
    bool signup,
    List<RequestOptions> calls,
  ) async {
    final client = ApiClient();
    client.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          calls.add(request);
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: 200,
              data: {'message': 'Request completed.'},
            ),
          );
        },
      ),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(client),
        child: MaterialApp(
            home:
                signup ? const SignupScreen() : const PasswordRecoveryScreen()),
      ),
    );
  }

  testWidgets('Signup validates confirmation and submits client details', (
    tester,
  ) async {
    final calls = <RequestOptions>[];
    await open(tester, true, calls);
    await tester.enterText(find.byType(TextFormField).at(0), 'Test Client');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'client@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'test-password');
    await tester.enterText(find.byType(TextFormField).at(3), 'different');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(calls, isEmpty);
    await tester.enterText(find.byType(TextFormField).at(3), 'test-password');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(calls.single.path, '/auth/signup');
    expect(calls.single.data['display_name'], 'Test Client');
    expect(find.text('Request completed.'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('Recovery sends a reset link and returns to sign in', (
    tester,
  ) async {
    final calls = <RequestOptions>[];
    await open(tester, false, calls);
    await tester.enterText(
      find.byType(TextFormField).first,
      'client@example.com',
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(calls.single.path, '/auth/forgot-password');
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Back to sign in'), findsOneWidget);
  });
}
