import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:claimlens/widgets/claimlens_logo.dart';

void main() {
  testWidgets('logo stays square inside a stretched sign-in column',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [ClaimLensLogo(size: 72)]))));
    final paint = find.descendant(
        of: find.byType(ClaimLensLogo), matching: find.byType(CustomPaint));
    expect(tester.getSize(paint), const Size(72, 72));
    expect(tester.takeException(), isNull);
  });
}
