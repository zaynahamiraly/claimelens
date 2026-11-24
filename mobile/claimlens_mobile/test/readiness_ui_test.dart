import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:claimlens/app_theme.dart';
import 'package:claimlens/models/claim.dart';
import 'package:claimlens/models/user_profile.dart';
import 'package:claimlens/providers/auth_provider.dart';
import 'package:claimlens/screens/required_password_screen.dart';
import 'package:claimlens/screens/workspace_screens.dart';
import 'package:claimlens/widgets/claim_card.dart';
import 'package:claimlens/services/api_client.dart';
import 'package:claimlens/services/workspace_service.dart';

class PasswordAuth extends AuthProvider {
  PasswordAuth(super.client);
  String? previous, replacement;
  @override
  Future<void> changePassword(String current, String password) async {
    previous = current;
    replacement = password;
  }
}

void main() {
  testWidgets('Temporary password must be replaced and confirmed',
      (tester) async {
    final auth = PasswordAuth(ApiClient());
    await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(
            theme: claimLensTheme(Brightness.light),
            home: const RequiredPasswordScreen())));
    await tester.enterText(
        find.byType(TextFormField).at(0), 'Temporary-synthetic-291!');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'Personal-synthetic-292!');
    await tester.enterText(
        find.byType(TextFormField).at(2), 'Different-synthetic-293!');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(auth.replacement, isNull);
    expect(find.text('Passwords do not match'), findsOneWidget);
    await tester.enterText(
        find.byType(TextFormField).at(2), 'Personal-synthetic-292!');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(auth.previous, 'Temporary-synthetic-291!');
    expect(auth.replacement, 'Personal-synthetic-292!');
  });

  testWidgets(
      'Administrator can set a temporary user password with reauthentication',
      (tester) async {
    final calls = <RequestOptions>[];
    final api = ApiClient();
    api.dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      calls.add(request);
      handler.resolve(Response(
          requestOptions: request,
          statusCode: 200,
          data: request.path == '/users'
              ? [
                  {
                    'id': 'other',
                    'display_name': 'Synthetic Client',
                    'email': 'synthetic@example.com',
                    'role': 'client',
                    'status': 'active'
                  }
                ]
              : {'message': 'Saved'}));
    }));
    final auth = AuthProvider(api)
      ..user = const UserProfile(
          id: 'admin',
          displayName: 'Administrator',
          role: 'administrator',
          status: 'active');
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(
            theme: claimLensTheme(Brightness.light),
            home: const UsersScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set temporary password'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Temporary-synthetic-291!');
    await tester.enterText(fields.at(1), 'Temporary-synthetic-291!');
    await tester.enterText(fields.at(2), 'Administrator-synthetic-292!');
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    final reset = calls.singleWhere((call) => call.path.endsWith('/password'));
    expect(reset.data['admin_password'], 'Administrator-synthetic-292!');
    expect(reset.data['new_password'], 'Temporary-synthetic-291!');
    expect((reset.data as Map).containsKey('confirm'), isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final status in claimStatuses) {
    testWidgets('$status claim card fits small screens and large text',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final claim = ClaimSummary(
          id: 'synthetic',
          reference: 'CLM-20261124-SYNTHETIC',
          patientName: 'Synthetic Patient',
          providerName: 'Synthetic Medical Provider',
          currency: 'MUR',
          status: status,
          warningCount: 0,
          createdAt: DateTime(2026, 11, 24),
          claimedAmount: 1250);
      await tester.pumpWidget(MaterialApp(
          theme: claimLensTheme(Brightness.light),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(2)),
              child: child!),
          home: Scaffold(
              body: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [ClaimCard(claim: claim)]))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
