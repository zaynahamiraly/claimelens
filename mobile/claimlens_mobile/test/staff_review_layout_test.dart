import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:claimlens/models/claim.dart';
import 'package:claimlens/screens/staff_review_screen.dart';

void main() {
  testWidgets('staff save action stays above Android system navigation',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final claim = ClaimDetails.fromJson({
      'id': 'qa',
      'reference': 'CLM-QA',
      'status': 'REVIEW_REQUIRED',
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
          'confirmed_amount': '900.00',
          'client_proposed_amount': '900.00',
          'client_reported_incorrect_amount': true,
          'include_in_total': true,
          'fields': [],
        }
      ],
    });
    await tester.pumpWidget(MaterialApp(home: StaffReviewScreen(claim: claim)));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1800));
    await tester.pumpAndSettle();
    final button = find.ancestor(
        of: find.text('Save reviewed information'),
        matching: find.byWidgetPredicate((w) => w is FilledButton));
    expect(tester.getBottomLeft(button).dy, lessThanOrEqualTo(752));
    expect(tester.takeException(), isNull);
  });
}
