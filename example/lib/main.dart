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

  final ValueNotifier<String> _enteredCode = ValueNotifier<String>('');

  void _handleSubmit(String code) {
    _enteredCode.value = code;
    debugPrint('Entered Code: $code');
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
                    onSubmit: _handleSubmit,
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
                    onSubmit: _handleSubmit,
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
                    onSubmit: _handleSubmit,
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
              valueListenable: _enteredCode,
              builder: (context, value, child) => Text(
                'Entered Code: ${_enteredCode.value}',
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
