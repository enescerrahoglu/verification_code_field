import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('OTP page shows verification copy and code field',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Enter verification code'), findsOneWidget);
    expect(find.textContaining('+90'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
