import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:claimlens/providers/auth_provider.dart';
import 'package:claimlens/screens/login_screen.dart';
import 'package:claimlens/screens/signup_screen.dart';
import 'package:claimlens/services/api_client.dart';

void main() {
  testWidgets('A new client can sign up and return to sign in with their email',
      (tester) async {
    final requests = <RequestOptions>[];
    final client = ApiClient();
    client.dio.interceptors
        .add(InterceptorsWrapper(onRequest: (request, handler) {
      requests.add(request);
      handler.resolve(Response(
          requestOptions: request,
          statusCode: 200,
          data: {'message': 'Account created. Check your email.'}));
    }));
    final auth = AuthProvider(client)..error = 'Previous login error';
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: auth, child: const MaterialApp(home: LoginScreen())));
    await tester.enterText(
        find.byType(TextFormField).first, 'newclient@example.com');
    await tester.ensureVisible(find.text('New client? Sign up'));
    await tester.tap(find.text('New client? Sign up'));
    await tester.pumpAndSettle();
    expect(find.byType(SignupScreen), findsOneWidget);
    expect(auth.error, isNull);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        'newclient@example.com');
    await tester.enterText(find.byType(TextFormField).at(0), 'New Client');
    await tester.enterText(find.byType(TextFormField).at(2), 'a-long-password');
    await tester.enterText(find.byType(TextFormField).at(3), 'a-long-password');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(requests.single.path, '/auth/signup');
    expect(requests.single.data.containsKey('role'), isFalse);
    expect(find.text('Your account is ready'), findsOneWidget);
    await tester.tap(find.text('Back to sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'newclient@example.com');
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).last)
            .controller!
            .text,
        isEmpty);
  });
}
