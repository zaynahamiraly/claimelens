import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:claimelens/models/claim.dart';
import 'package:claimelens/models/user_profile.dart';
import 'package:claimelens/providers/auth_provider.dart';
import 'package:claimelens/providers/claims_provider.dart';
import 'package:claimelens/screens/dashboard_screen.dart';
import 'package:claimelens/services/api_client.dart';

class TestClaims extends ClaimsProvider {
  TestClaims(super.client) {
    dashboard = const DashboardData(
      total: 0,
      processing: 0,
      reviewRequired: 0,
      verified: 0,
      failed: 0,
      recent: [],
    );
  }
  @override
  Future<void> loadDashboard() async {}
}

void main() {
  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('Dashboard fits width $width at text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final client = ApiClient();
        final auth = AuthProvider(client)
          ..user = const UserProfile(
            id: 'test',
            displayName: 'Salim',
            role: 'client',
            status: 'active',
          );
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: auth),
              ChangeNotifierProvider<ClaimsProvider>(
                create: (_) => TestClaims(client),
              ),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const DashboardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(find.text('Recent claims'), 400,
            scrollable: find.byType(Scrollable).first, maxScrolls: 30);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Recent claims'), findsOneWidget);
      });
    }
  }
}
