import 'package:flutter/material.dart';
import 'package:verification_code_field/verification_code_field.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Verification Code Field Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: VerificationCodeFieldExample(),
    );
  }
}

class VerificationCodeFieldExample extends StatelessWidget {
  VerificationCodeFieldExample({super.key});

  final ValueNotifier<String> _enteredCode1 = ValueNotifier<String>('');
  final ValueNotifier<String> _enteredCode2 = ValueNotifier<String>('');
  final ValueNotifier<String> _enteredCode3 = ValueNotifier<String>('');

  void _handleSubmit1(String code) {
    _enteredCode1.value = code;
    debugPrint('#1 Entered Code: $code');
  }

  void _handleSubmit2(String code) {
    _enteredCode2.value = code;
    debugPrint('#2 Entered Code: $code');
  }

  void _handleSubmit3(String code) {
    _enteredCode3.value = code;
    debugPrint('#3 Entered Code: $code');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Code Field Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Example #1'),
                Center(
                  child: VerificationCodeField(
                    onSubmit: _handleSubmit1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Example #2'),
                Center(
                  child: VerificationCodeField(
                    codeDigit: CodeDigit.five,
                    onSubmit: _handleSubmit2,
                    enabled: true,
                    showCursor: true,
                    filled: true,
                    fillColor: Colors.blue.shade100,
                    cursorColor: Colors.blue,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    textStyle: const TextStyle(fontSize: 26, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Example #3'),
                Center(
                  child: VerificationCodeField(
                    codeDigit: CodeDigit.six,
                    onSubmit: _handleSubmit3,
                    enabled: true,
                    filled: true,
                    fillColor: Colors.purple.shade50,
                    defaultBorderRadius: BorderRadius.circular(100),
                    textStyle: const TextStyle(fontSize: 20, color: Colors.purple),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ValueListenableBuilder(
              valueListenable: _enteredCode1,
              builder: (context, value, child) => Text(
                '#1 Entered Code: ${_enteredCode1.value}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder(
              valueListenable: _enteredCode2,
              builder: (context, value, child) => Text(
                '#2 Entered Code: ${_enteredCode2.value}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder(
              valueListenable: _enteredCode3,
              builder: (context, value, child) => Text(
                '#3 Entered Code: ${_enteredCode3.value}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
