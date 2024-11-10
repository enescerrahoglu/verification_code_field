library verification_code_field;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// A widget for entering a verification code, consisting of separate TextField
/// widgets for each character. Each character is displayed in an individual box.
class VerificationCodeField extends StatefulWidget {
  /// Specifies the number of digits in the verification code. Default is 4.
  final CodeDigit codeDigit;

  /// Callback function that returns the completed code once all digits are entered.
  final ValueChanged<String>? onSubmit;

  /// Whether the TextField widgets are enabled for input.
  final bool? enabled;

  /// Default border radius for each TextField box.
  final BorderRadius? defaultBorderRadius;

  /// Text style for the input digits.
  final TextStyle? textStyle;

  /// Whether to display the cursor in the TextFields. Default is false.
  final bool? showCursor;

  /// Whether each TextField box should be filled with a background color.
  final bool? filled;

  /// Background color for each TextField box when `filled` is true.
  final Color? fillColor;

  /// Border style for each TextField box.
  final InputBorder? border;

  /// Color of the cursor when `showCursor` is true.
  final Color? cursorColor;

  const VerificationCodeField({
    super.key,
    this.codeDigit = CodeDigit.four,
    this.onSubmit,
    this.enabled,
    this.defaultBorderRadius,
    this.textStyle,
    this.showCursor = false,
    this.filled,
    this.fillColor,
    this.border,
    this.cursorColor,
  });

  @override
  State<VerificationCodeField> createState() => _VerificationCodeFieldState();
}

class _VerificationCodeFieldState extends State<VerificationCodeField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    // Initializes the controllers and focus nodes based on the number of digits.
    _controllers = List.generate(
      widget.codeDigit.digit,
      (index) => TextEditingController(text: ' '),
    );
    _focusNodes = List.generate(widget.codeDigit.digit, (index) => FocusNode());
    super.initState();
  }

  @override
  void dispose() {
    // Disposes of controllers and focus nodes to free resources.
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  /// Handles text changes in each TextField. If a digit is entered, it moves to the next field.
  /// If backspace is pressed and the field is empty, it moves to the previous field.
  void _handleTextChanged(String value, int index) {
    // If multiple characters are entered, keep only the last one.
    if (value.length > 1) {
      _controllers[index].text = value.substring(value.length - 1);
      _controllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: _controllers[index].text.length),
      );
    }

    if (_controllers[index].text.isNotEmpty) {
      // When last field is filled, calls `onSubmit` with the full code.
      if (index == _controllers.length - 1) {
        final code =
            _controllers.map((controller) => controller.text.trim()).join();
        if (code.length == widget.codeDigit.digit) {
          widget.onSubmit?.call(code);
          FocusManager.instance.primaryFocus?.unfocus();
        }
      } else {
        // Moves focus to the next field if current field is not the last one.
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      }
    } else if (index > 0) {
      // Moves focus to the previous field if backspace is pressed.
      _controllers[index].text = ' ';
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Sets height based on the device's screen width, keeping a responsive layout.
      height: (MediaQuery.of(context).size.width / 6) - 10,
      child: ListView.separated(
        itemCount: widget.codeDigit.digit,
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Center(
            child: SizedBox(
              width: (MediaQuery.of(context).size.width / 6) - 24,
              child: TextField(
                cursorColor: widget.cursorColor,
                enabled: widget.enabled,
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                showCursor: widget.showCursor,
                contextMenuBuilder: null,
                enableInteractiveSelection: false,
                style: widget.textStyle ??
                    TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily:
                          GoogleFonts.sourceCodePro(fontWeight: FontWeight.bold)
                              .fontFamily,
                    ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  filled: widget.filled,
                  fillColor: widget.fillColor,
                  contentPadding: const EdgeInsetsDirectional.all(0),
                  border: widget.border ??
                      OutlineInputBorder(
                        borderRadius: widget.defaultBorderRadius ??
                            BorderRadius.circular(10.0),
                      ),
                ),
                // Calls _handleTextChanged for each text change in a TextField.
                onChanged: (value) => _handleTextChanged(value, index),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Enum to represent the number of digits for the verification code.
enum CodeDigit {
  four(4),
  five(5),
  six(6),
  ;

  const CodeDigit(this.digit);
  final int digit;
}
