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
      home: const VerificationCodeFieldExample(),
    );
  }
}

class VerificationCodeFieldExample extends StatefulWidget {
  const VerificationCodeFieldExample({super.key});

  @override
  State<VerificationCodeFieldExample> createState() => _VerificationCodeFieldExampleState();
}

class _VerificationCodeFieldExampleState extends State<VerificationCodeFieldExample> {
  final VerificationCodeController _controller1 = VerificationCodeController();
  final VerificationCodeController _controller2 = VerificationCodeController();
  final VerificationCodeController _controller3 = VerificationCodeController();
  final ValueNotifier<String> _enteredCode1 = ValueNotifier<String>('');
  final ValueNotifier<String> _enteredCode2 = ValueNotifier<String>('');
  final ValueNotifier<String> _enteredCode3 = ValueNotifier<String>('');

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _enteredCode1.dispose();
    _enteredCode2.dispose();
    _enteredCode3.dispose();
    super.dispose();
  }

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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verification Code Field'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Example #1'),
                  Center(
                    child: VerificationCodeField(
                      controller: _controller1,
                      clearOnTap: false,
                      autoFocus: true,
                      fieldSize: 48,
                      cleanAllAtOnce: false,
                      onSubmit: _handleSubmit1,
                      showCursor: true,
                      cursorColor: Colors.blue,
                      focusedFillColor: Colors.blue.shade50,
                      textStyle: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.blue),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey, width: 2),
                      ),
                      onChanged: (p0) {
                        debugPrint(p0);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ControllerActions(controller: _controller1),
                ],
              ),
              const SizedBox(height: 30),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Example #2 — overwrite on tap'),
                  Center(
                    child: VerificationCodeField(
                      controller: _controller2,
                      clearOnTap: false,
                      tripleSeparated: true,
                      codeDigit: CodeDigit.six,
                      onSubmit: _handleSubmit2,
                      onChanged: (p0) {
                        debugPrint(p0);
                      },
                      enabled: true,
                      showCursor: true,
                      filled: true,
                      fillColor: Colors.blue.shade100,
                      cursorColor: Colors.blue,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide.none),
                      textStyle: const TextStyle(fontSize: 26, color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ControllerActions(controller: _controller2),
                ],
              ),
              const SizedBox(height: 30),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Example #3'),
                  Center(
                    child: VerificationCodeField(
                      controller: _controller3,
                      tripleSeparated: true,
                      codeDigit: CodeDigit.six,
                      onSubmit: _handleSubmit3,
                      enabled: true,
                      border: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.green, width: 1.5),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.green, width: 1.5),
                      ),
                      textStyle: const TextStyle(fontSize: 20, color: Colors.green),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ControllerActions(controller: _controller3),
                ],
              ),
              const SizedBox(height: 50),
              ValueListenableBuilder(
                valueListenable: _enteredCode1,
                builder: (context, value, child) => Text(
                  '#1 Entered Code: ${_enteredCode1.value}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              ValueListenableBuilder(
                valueListenable: _enteredCode2,
                builder: (context, value, child) => Text(
                  '#2 Entered Code: ${_enteredCode2.value}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 50),
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
      ),
    );
  }
}

class _ControllerActions extends StatelessWidget {
  const _ControllerActions({required this.controller});

  final VerificationCodeController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Row(
          children: [
            Expanded(child: Text('Current value: ${controller.text}')),
            TextButton(
              onPressed: controller.focus,
              child: const Text('Focus'),
            ),
            TextButton(
              onPressed: controller.clear,
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}
