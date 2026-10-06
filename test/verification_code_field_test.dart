import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verification_code_field/verification_code_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VerificationCodeController', () {
    testWidgets('exposes the current code and clears it', (tester) async {
      final controller = VerificationCodeController(text: '12a3');
      addTearDown(controller.dispose);

      String? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(
              controller: controller,
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      );

      expect(controller.text, '123');
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '98');
      await tester.pump();

      expect(controller.text, '98');
      expect(changed, '98');

      controller.clear();
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(changed, isEmpty);
      expect(find.text('9'), findsNothing);
      expect(find.text('8'), findsNothing);
    });

    testWidgets('limits an initial value to the field length', (tester) async {
      final controller = VerificationCodeController(text: '123456');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(
              controller: controller,
              codeDigit: CodeDigit.four,
            ),
          ),
        ),
      );

      expect(controller.text, '1234');
      expect(find.text('5'), findsNothing);
    });

    testWidgets('focuses the next empty box, or the last box when full',
        (tester) async {
      final controller = VerificationCodeController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(
              controller: controller,
              clearOnTap: false,
            ),
          ),
        ),
      );

      controller.focus();
      await tester.pump();
      expect(_focusOf(tester).hasFocus, isTrue);
      expect(_selectionOf(tester).isCollapsed, isTrue);
      expect(_selectionOf(tester).baseOffset, 0);

      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();
      _focusOf(tester).unfocus();
      await tester.pump();

      controller.focus();
      await tester.pump();
      expect(controller.text, '12');
      expect(_focusOf(tester).hasFocus, isTrue);
      expect(_selectionOf(tester).isCollapsed, isTrue);
      expect(_selectionOf(tester).baseOffset, 2);

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();
      expect(_focusOf(tester).hasFocus, isFalse);

      controller.focus();
      await tester.pump();
      expect(controller.text, '1234');
      expect(_focusOf(tester).hasFocus, isTrue);
      expect(_selectionOf(tester).baseOffset, 3);
      expect(_selectionOf(tester).extentOffset, 4);
    });

    testWidgets('focus keeps a completed code when clearOnTap is enabled',
        (tester) async {
      final controller = VerificationCodeController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(controller: controller),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();
      expect(_focusOf(tester).hasFocus, isFalse);

      controller.focus();
      await tester.pump();

      expect(controller.text, '1234');
      expect(_focusOf(tester).hasFocus, isTrue);
      expect(_selectionOf(tester).isCollapsed, isTrue);
      expect(_selectionOf(tester).baseOffset, 3);
    });
  });

  group('VerificationCodeField', () {
    testWidgets('shows one box per digit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(codeDigit: CodeDigit.six),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(ValueKey('digit_box_$i')), findsOneWidget);
      }
    });

    testWidgets('submits and unfocuses when the last digit is entered',
        (tester) async {
      final submitted = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(
              onSubmit: submitted.add,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '123');
      await tester.pump();
      expect(submitted, isEmpty);
      expect(_focusOf(tester).hasFocus, isTrue);

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();

      expect(submitted, ['1234']);
      expect(_focusOf(tester).hasFocus, isFalse);
    });

    testWidgets('clearOnTap removes the tapped box and every box after it',
        (tester) async {
      final changed = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(
              onChanged: changed.add,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('digit_box_1')));
      await tester.pump();

      expect(_fieldText(tester), '1');
      expect(changed.last, '1');
      expect(_focusOf(tester).hasFocus, isTrue);
      expect(_selectionOf(tester).isCollapsed, isTrue);
      expect(_selectionOf(tester).baseOffset, 1);
    });

    testWidgets('clearOnTap false keeps the digit, overwrites it, and moves on',
        (tester) async {
      final controller = VerificationCodeController();
      addTearDown(controller.dispose);
      final submitted = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(
              controller: controller,
              clearOnTap: false,
              onSubmit: submitted.add,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();
      expect(submitted, ['1234']);
      expect(_focusOf(tester).hasFocus, isFalse);

      await tester.tap(find.byKey(const ValueKey('digit_box_1')));
      await tester.pump();

      expect(controller.text, '1234');
      expect(find.text('2'), findsOneWidget);
      expect(_focusOf(tester).hasFocus, isTrue);
      expect(_selectionOf(tester).baseOffset, 1);
      expect(_selectionOf(tester).extentOffset, 2);

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '1934',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.pump();

      expect(controller.text, '1934');
      expect(find.text('9'), findsOneWidget);
      expect(find.text('2'), findsNothing);
      expect(_focusOf(tester).hasFocus, isTrue);
      expect(_selectionOf(tester).baseOffset, 2);
      expect(_selectionOf(tester).extentOffset, 3);
      expect(submitted, ['1234']);

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '1974',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();

      expect(controller.text, '1974');
      expect(_selectionOf(tester).baseOffset, 3);
      expect(_selectionOf(tester).extentOffset, 4);
      expect(_focusOf(tester).hasFocus, isTrue);

      await tester.tap(find.byKey(const ValueKey('digit_box_3')));
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '1978',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      await tester.pump();

      expect(controller.text, '1978');
      expect(submitted, ['1234', '1978']);
      expect(_focusOf(tester).hasFocus, isFalse);
    });

    testWidgets('an inserted digit overwrites the focused box', (tester) async {
      final controller = VerificationCodeController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(
              controller: controller,
              clearOnTap: false,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('digit_box_1')));
      await tester.pump();

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '19234',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.pump();

      expect(controller.text, '1934');
      expect(_selectionOf(tester).baseOffset, 2);
      expect(_selectionOf(tester).extentOffset, 3);
      expect(_focusOf(tester).hasFocus, isTrue);
    });

    testWidgets('typing the same digit still advances to the next box',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(clearOnTap: false),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('digit_box_0')));
      await tester.pump();

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '1234',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pump();

      expect(_focusOf(tester).hasFocus, isTrue);
      expect(_selectionOf(tester).baseOffset, 1);
      expect(_selectionOf(tester).extentOffset, 2);
    });

    testWidgets('backspace removes the last digit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pump();

      expect(_fieldText(tester), '1');
      expect(_focusOf(tester).hasFocus, isTrue);
      expect(_selectionOf(tester).baseOffset, 1);
    });

    testWidgets('ignores characters that are not digits', (tester) async {
      final controller = VerificationCodeController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerificationCodeField(controller: controller),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '12a3');
      await tester.pump();

      expect(controller.text, '123');
    });
  });
}

String _fieldText(WidgetTester tester) {
  return tester.widget<TextField>(find.byType(TextField)).controller!.text;
}

FocusNode _focusOf(WidgetTester tester) {
  return tester.widget<TextField>(find.byType(TextField)).focusNode!;
}

TextSelection _selectionOf(WidgetTester tester) {
  return tester.widget<TextField>(find.byType(TextField)).controller!.selection;
}
