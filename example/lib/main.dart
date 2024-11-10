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
      home: const VerificationCodeFieldExample(),
    );
  }
}

class VerificationCodeFieldExample extends StatelessWidget {
  const VerificationCodeFieldExample({super.key});

  void _handleSubmit(String code) {
    debugPrint('Entered Code: $code');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Code Field Example'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: VerificationCodeField(
            codeDigit: CodeDigit.six,
            onSubmit: _handleSubmit,
            enabled: true,
            showCursor: true,
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            textStyle: const TextStyle(fontSize: 20, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
