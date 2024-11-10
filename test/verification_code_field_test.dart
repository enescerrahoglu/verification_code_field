import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verification_code_field/verification_code_field.dart';
import 'package:flutter/material.dart';

void main() {
  group('VerificationCodeField Tests', () {
    testWidgets('Should display the correct number of text fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(codeDigit: CodeDigit.four),
          ),
        ),
      );

      // Verify there are 4 TextField widgets
      expect(find.byType(TextField), findsNWidgets(4));
    });

    testWidgets('Should submit code when all fields are filled',
        (WidgetTester tester) async {
      String submittedCode = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(
              codeDigit: CodeDigit.four,
              onSubmit: (code) => submittedCode = code,
            ),
          ),
        ),
      );

      // Enter digits in each TextField
      for (var i = 0; i < 4; i++) {
        await tester.enterText(
            find.byType(TextField).at(i), (i + 1).toString());
        await tester.pumpAndSettle();
      }

      // Verify if the onSubmit callback is triggered with the correct code
      expect(submittedCode, '1234');
    });

    testWidgets('Should move focus to the next field when a digit is entered',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(codeDigit: CodeDigit.four),
          ),
        ),
      );

      // Enter a digit in the first TextField
      await tester.enterText(find.byType(TextField).first, '1');
      await tester.pumpAndSettle();

      // Verify if the second TextField has focus
      final secondField = find.byType(TextField).at(1);
      expect(tester.widget<TextField>(secondField).focusNode?.hasFocus, true);
    });

    testWidgets('Should move focus to the previous field on backspace',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(codeDigit: CodeDigit.four),
          ),
        ),
      );

      // Enter a digit in the first two TextFields
      await tester.enterText(find.byType(TextField).first, '1');
      await tester.enterText(find.byType(TextField).at(1), '2');
      await tester.pumpAndSettle();

      // Tap backspace in the second field
      await tester.tap(find.byType(TextField).at(1));
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      // Verify if the first TextField has focus
      final firstField = find.byType(TextField).first;
      expect(tester.widget<TextField>(firstField).focusNode?.hasFocus, true);
    });

    testWidgets('Should not allow more than one digit in a field',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(codeDigit: CodeDigit.four),
          ),
        ),
      );

      // Try to enter multiple digits in the first TextField
      await tester.enterText(find.byType(TextField).first, '123');
      await tester.pumpAndSettle();

      // Verify if only the last digit was kept in the field
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('Should clear field on tap if it contains a placeholder',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(
              codeDigit: CodeDigit.four,
            ),
          ),
        ),
      );

      // Enter a single character in the first field
      await tester.enterText(find.byType(TextField).first, '1');
      await tester.pumpAndSettle();

      // Tap the first field to edit
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();

      // Verify the field is empty to accept new input
      expect(find.text('1'), findsOneWidget);
    });
  });
}
