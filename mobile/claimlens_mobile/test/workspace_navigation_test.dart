import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:claimelens/app_theme.dart';
import 'package:claimelens/models/user_profile.dart';
import 'package:claimelens/providers/auth_provider.dart';
import 'package:claimelens/providers/claims_provider.dart';
import 'package:claimelens/screens/app_shell.dart';
import 'package:claimelens/services/api_client.dart';

class WorkspaceAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final dynamic data = options.path.endsWith('/dashboard')
        ? {
            'total_claims': 0,
            'processing': 0,
            'review_required': 0,
            'verified': 0,
            'processing_failed': 0,
            'recent_claims': [],
            'by_status': {}
          }
        : [];
    return ResponseBody.fromString(jsonEncode(data), 200, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  for (final role in [
    'client',
    'claims_officer',
    'supervisor',
    'administrator'
  ]) {
    testWidgets('$role gets the correct workspace tools without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ApiClient();
      api.dio.httpClientAdapter = WorkspaceAdapter();
      final auth = AuthProvider(api)
        ..user = UserProfile(
            id: 'test',
            displayName: 'Test Account',
            role: role,
            status: 'active');
      await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider(create: (_) => ClaimsProvider(api))
          ],
          child: MaterialApp(
              theme: claimelensTheme(Brightness.light),
              home: const AppShell())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (role == 'client') {
        expect(find.text('Review'), findsNothing);
        await tester.tap(find.text('Account'));
        await tester.pumpAndSettle();
        expect(find.text('Personal information'), findsOneWidget);
        expect(find.text('User access'), findsNothing);
      } else {
        await tester.tap(find.text('Review'));
        await tester.pumpAndSettle();
        expect(find.text('Review queue'), findsOneWidget);
        expect(find.text('Awaiting assignment'),
            findsNothing); // Dropdown is closed.
        expect(find.text('All accessible claims'), findsOneWidget);
        await tester.tap(find.text('Workspace'));
        await tester.pumpAndSettle();
        expect(find.text('Analytics'), findsOneWidget);
        expect(find.text('Audit trail'), findsOneWidget);
        expect(find.text('User access'),
            role == 'administrator' ? findsOneWidget : findsNothing);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
