import 'dart:async';

import 'package:flutter/material.dart';
import 'package:verification_code_field/verification_code_field.dart';

void main() {
  runApp(const MyApp());
}

/// Seed for [ColorScheme.fromSeed]. All accents on the OTP screen derive
/// from this primary and its Material 3 roles.
const Color _seedPrimary = Color(0xFF1B6EF3);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = ColorScheme.fromSeed(
      seedColor: _seedPrimary,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'OTP Verification',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colors,
        useMaterial3: true,
        scaffoldBackgroundColor: colors.surface,
        textTheme: Typography.blackMountainView.apply(
          bodyColor: colors.onSurface,
          displayColor: colors.onSurface,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      home: const OtpVerificationPage(),
    );
  }
}

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  static const int _codeLength = 6;
  static const int _resendSeconds = 45;
  static const String _maskedDestination = '+90 ••• ••• 12 34';

  final VerificationCodeController _controller = VerificationCodeController();

  Timer? _resendTimer;
  int _secondsLeft = _resendSeconds;
  bool _isVerifying = false;
  bool _codeComplete = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onCodeChanged);
    _startResendCountdown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _controller.removeListener(_onCodeChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    final bool complete = _controller.text.length == _codeLength;
    if (complete != _codeComplete || _errorText != null) {
      setState(() {
        _codeComplete = complete;
        _errorText = null;
      });
    }
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  Future<void> _verify() async {
    if (!_codeComplete || _isVerifying) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    // Demo rule: any code ending with an even digit succeeds.
    final String code = _controller.text;
    final bool success = int.parse(code[_codeLength - 1]).isEven;

    setState(() => _isVerifying = false);

    if (success) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          final ColorScheme colors = Theme.of(context).colorScheme;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon: Icon(
              Icons.check_circle_rounded,
              color: colors.primary,
              size: 40,
            ),
            title: const Text('Verified'),
            content: const Text(
              'Phone number $_maskedDestination is confirmed.',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    } else {
      setState(() {
        _errorText = 'That code is incorrect. Try again.';
      });
      _controller.clear();
      _controller.focus();
    }
  }

  void _resendCode() {
    if (_secondsLeft > 0) return;
    _controller.clear();
    _startResendCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: const Text('A new code was sent to $_maskedDestination'),
      ),
    );
    _controller.focus();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextTheme text = theme.textTheme;
    final MediaQueryData media = MediaQuery.of(context);
    final double bottomInset = media.viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.primaryContainer.withValues(alpha: 0.55),
                colors.surface,
                colors.surface,
              ],
              stops: const [0, 0.38, 1],
            ),
          ),
          child: SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomInset > 0 ? 8 : 0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: colors.primary,
                          content: const Text('Back to sign in'),
                        ),
                      ),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: colors.primary,
                      ),
                      tooltip: 'Back',
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          _OtpMark(colors: colors),
                          const SizedBox(height: 28),
                          Text(
                            'Enter verification code',
                            textAlign: TextAlign.center,
                            style: text.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text.rich(
                            TextSpan(
                              style: text.bodyLarge?.copyWith(
                                height: 1.45,
                                color: colors.onSurfaceVariant,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'We sent a 6-digit code to\n',
                                ),
                                TextSpan(
                                  text: _maskedDestination,
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 36),
                          VerificationCodeField(
                            controller: _controller,
                            codeDigit: CodeDigit.six,
                            autoFocus: true,
                            clearOnTap: false,
                            fieldSize: 48,
                            showCursor: true,
                            cursorColor: colors.primary,
                            fillColor: colors.surface,
                            focusedFillColor:
                                colors.primaryContainer.withValues(alpha: 0.45),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors.outlineVariant,
                                width: 1.4,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors.primary,
                                width: 2,
                              ),
                            ),
                            textStyle: text.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                              letterSpacing: 1,
                            ),
                            onSubmit: (_) => _verify(),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: _errorText == null
                                ? const SizedBox(height: 16)
                                : Padding(
                                    padding: const EdgeInsets.only(
                                      top: 14,
                                      bottom: 2,
                                    ),
                                    child: Text(
                                      _errorText!,
                                      textAlign: TextAlign.center,
                                      style: text.bodyMedium?.copyWith(
                                        color: colors.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          _ResendRow(
                            secondsLeft: _secondsLeft,
                            onResend: _resendCode,
                          ),
                          const SizedBox(height: 28),
                          FilledButton(
                            onPressed:
                                _codeComplete && !_isVerifying ? _verify : null,
                            child: _isVerifying
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: colors.onPrimary,
                                    ),
                                  )
                                : const Text('Verify'),
                          ),
                          const SizedBox(height: 18),
                          TextButton(
                            onPressed: () {
                              _controller.clear();
                              _controller.focus();
                            },
                            child: Text(
                              'Clear code',
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Text(
                      'Demo tip: codes ending with an even digit succeed.',
                      textAlign: TextAlign.center,
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpMark extends StatelessWidget {
  const _OtpMark({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colors.primary.withValues(alpha: 0.18),
            colors.primaryContainer.withValues(alpha: 0.55),
          ],
        ),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Icon(
        Icons.lock_outline_rounded,
        size: 36,
        color: colors.primary,
      ),
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({
    required this.secondsLeft,
    required this.onResend,
  });

  final int secondsLeft;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool canResend = secondsLeft == 0;
    final String clock = '0:${secondsLeft.toString().padLeft(2, '0')}';

    if (canResend) {
      return TextButton(
        onPressed: onResend,
        child: Text(
          'Resend code',
          style: text.titleSmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Text.rich(
      TextSpan(
        style: text.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        children: [
          const TextSpan(text: 'Resend code in '),
          TextSpan(
            text: clock,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
