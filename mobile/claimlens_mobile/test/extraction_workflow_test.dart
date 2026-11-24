import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:claimlens/providers/auth_provider.dart';
import 'package:claimlens/providers/claims_provider.dart';
import 'package:claimlens/screens/extracted_info_screen.dart';
import 'package:claimlens/services/api_client.dart';

void main() {
  for (final bottom in [0.0, 48.0]) {
    testWidgets(
        'correction requires reporting and review stays above $bottom system inset',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = FakeViewPadding(bottom: bottom);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      final api = ApiClient();
      api.dio.interceptors
          .add(InterceptorsWrapper(onRequest: (request, handler) {
        handler.resolve(Response(
            requestOptions: request,
            statusCode: 200,
            data: request.path.endsWith('/settings')
                ? {
                    'allowed_currencies': ['MUR']
                  }
                : {
                    'id': 'qa',
                    'reference': 'CLM-QA',
                    'status': 'UPLOADED',
                    'patient_name': 'QA Patient',
                    'provider_name': 'QA Clinic',
                    'created_at': '2026-11-24T00:00:00Z',
                    'currency': 'MUR',
                    'documents': [
                      {
                        'id': 'doc',
                        'original_name': 'invoice.pdf',
                        'document_type': 'INVOICE',
                        'mime_type': 'application/pdf',
                        'extraction_status': 'COMPLETED',
                        'extracted_amount': '800.00',
                        'extracted_currency': 'MUR',
                        'include_in_total': true,
                        'fields': []
                      }
                    ]
                  }));
      }));
      await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider(api)),
            ChangeNotifierProvider(create: (_) => ClaimsProvider(api)),
          ],
          child: const MaterialApp(
              home: ExtractedInfoScreen(reference: 'CLM-QA'))));
      await tester.pumpAndSettle();
      final report = find.text('Report incorrect amount');
      await tester.scrollUntilVisible(report, 150,
          scrollable: find
              .descendant(
                  of: find.byType(ListView), matching: find.byType(Scrollable))
              .first);
      final amount = find.widgetWithText(TextFormField, 'Proposed amount');
      expect(tester.widget<TextFormField>(amount).enabled, isTrue);
      final editable =
          find.descendant(of: amount, matching: find.byType(EditableText));
      expect(tester.widget<EditableText>(editable).readOnly, isTrue);
      await tester.ensureVisible(report);
      await tester.pumpAndSettle();
      await tester.tap(report);
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(editable).readOnly, isFalse);
      await tester.ensureVisible(amount);
      await tester.pumpAndSettle();
      await tester.enterText(amount, '900.00');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      final review = find.text('Review claim total');
      await tester.scrollUntilVisible(review, 150,
          scrollable: find
              .descendant(
                  of: find.byType(ListView), matching: find.byType(Scrollable))
              .first);
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(review).dy, lessThanOrEqualTo(800 - bottom));
      await tester.tap(review);
      await tester.pumpAndSettle();
      expect(find.text('Review and submit'), findsOneWidget);
      expect(find.text('MUR 900.00'), findsWidgets);
      expect(
          find.textContaining('A claims officer will compare'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
