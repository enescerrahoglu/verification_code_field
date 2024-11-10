library verification_code_field;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class VerificationCodeField extends StatefulWidget {
  final CodeDigit codeDigit;
  final ValueChanged<String>? onSubmit;
  final bool? enabled;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;
  final bool? showCursor;
  final bool? filled;
  final Color? fillColor;
  final InputBorder? border;

  const VerificationCodeField({
    super.key,
    this.codeDigit = CodeDigit.four,
    this.onSubmit,
    this.enabled,
    this.borderRadius,
    this.textStyle,
    this.showCursor = false,
    this.filled,
    this.fillColor,
    this.border,
  });

  @override
  State<VerificationCodeField> createState() => _VerificationCodeFieldState();
}

class _VerificationCodeFieldState extends State<VerificationCodeField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    _controllers = List.generate(
      widget.codeDigit.digit,
      (index) => TextEditingController(text: ' '),
    );
    _focusNodes = List.generate(widget.codeDigit.digit, (index) => FocusNode());
    super.initState();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _handleTextChanged(String value, int index) {
    if (value.length > 1) {
      _controllers[index].text = value.substring(value.length - 1);
      _controllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: _controllers[index].text.length),
      );
    }

    if (_controllers[index].text.isNotEmpty) {
      if (index == _controllers.length - 1) {
        final code = _controllers.map((controller) => controller.text.trim()).join();
        if (code.length == widget.codeDigit.digit) {
          widget.onSubmit?.call(code);
          FocusManager.instance.primaryFocus?.unfocus();
        }
      } else {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      }
    } else if (index > 0) {
      _controllers[index].text = ' ';
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                      fontFamily: GoogleFonts.sourceCodePro(fontWeight: FontWeight.bold).fontFamily,
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
                        borderRadius: widget.borderRadius ?? BorderRadius.circular(10.0),
                      ),
                ),
                onChanged: (value) => _handleTextChanged(value, index),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum CodeDigit {
  four(4),
  five(5),
  six(6),
  ;

  const CodeDigit(this.digit);
  final int digit;
}
