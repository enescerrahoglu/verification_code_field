import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// A widget for entering a Verification Code, consisting of separate TextField
/// widgets for each character. Each character is displayed in an individual box.
class VerificationCodeField extends StatefulWidget {
  /// Specifies the number of digits in the Verification Code. Default is 4.
  final CodeDigit codeDigit;

  /// Callback function that returns the completed code once all digits are entered.
  final ValueChanged<String>? onSubmit;

  /// Whether the TextField widgets are enabled for input.
  final bool? enabled;

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

  /// Border style for each focused TextField box.
  final InputBorder? focusedBorder;

  /// Color of the cursor when `showCursor` is true.
  final Color? cursorColor;

  /// A single field deletion gesture clears all fields and focuses on the first field. Default is false.
  final bool cleanAllAtOnce;

  /// Divides 6-digit fields into two groups of three. Default is false.
  final bool tripleSeparated;

  const VerificationCodeField({
    super.key,
    this.codeDigit = CodeDigit.four,
    this.onSubmit,
    this.enabled,
    this.textStyle,
    this.showCursor = false,
    this.filled,
    this.fillColor,
    this.border,
    this.focusedBorder,
    this.cursorColor,
    this.cleanAllAtOnce = false,
    this.tripleSeparated = false,
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

  /// Handles text changes in each TextField.
  void _handleTextChanged(String value, int index) {
    if (value.trim().length >= widget.codeDigit.digit) {
      _handlePaste(value);
    } else if (value.trim().isEmpty) {
      if (widget.cleanAllAtOnce) {
        _controllers.map((controller) => controller.text = ' ').toList();
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      } else {
        _controllers[index].text = ' ';
        if (index > 0) {
          FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
        }
      }
    } else {
      _controllers[index].text = value.substring(value.length - 1);
      if (index == _controllers.length - 1) {
        final code =
            _controllers.map((controller) => controller.text.trim()).join();
        if (code.length == widget.codeDigit.digit) {
          widget.onSubmit?.call(code);
          FocusManager.instance.primaryFocus?.unfocus();
        }
      } else {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      }
    }
  }

  /// Handles pasted text and distributes digits across fields, triggering submit if completed.
  void _handlePaste(String value) {
    _controllers.map((controller) => controller.text = ' ').toList();
    FocusScope.of(context).requestFocus(_focusNodes[0]);

    final digits = RegExp(r'\d')
        .allMatches(value)
        .map((match) => match.group(0)!)
        .toList();

    final limitedDigits = digits.length > widget.codeDigit.digit
        ? digits.sublist(digits.length - widget.codeDigit.digit)
        : digits;

    for (int i = 0;
        i < widget.codeDigit.digit && i < limitedDigits.length;
        i++) {
      _controllers[i].text = limitedDigits[i];
    }

    if (limitedDigits.length == widget.codeDigit.digit) {
      widget.onSubmit
          ?.call(_controllers.map((controller) => controller.text).join());
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (MediaQuery.of(context).size.width / 6) - 24,
      child: ListView.separated(
        itemCount: widget.codeDigit.digit,
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) => SizedBox(
            width: (widget.codeDigit == CodeDigit.six &&
                    widget.tripleSeparated &&
                    index == 2)
                ? 20
                : widget.tripleSeparated
                    ? 5
                    : 10),
        itemBuilder: (context, index) {
          return Center(
            child: SizedBox(
              width: (MediaQuery.of(context).size.width / 6) - 24,
              child: TextField(
                enabled: widget.enabled,
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                showCursor: widget.showCursor,
                cursorColor: widget.cursorColor,
                enableInteractiveSelection: false,
                contextMenuBuilder: (context, editableTextState) {
                  List<ContextMenuButtonItem> items = editableTextState
                      .contextMenuButtonItems
                      .where((element) =>
                          element.type == ContextMenuButtonType.paste)
                      .toList();
                  return AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: editableTextState.contextMenuAnchors,
                    buttonItems: items,
                  );
                },
                spellCheckConfiguration: SpellCheckConfiguration(
                  spellCheckSuggestionsToolbarBuilder:
                      (context, editableTextState) {
                    List<ContextMenuButtonItem> items = editableTextState
                        .contextMenuButtonItems
                        .where((element) =>
                            element.type == ContextMenuButtonType.paste)
                        .toList();
                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: editableTextState.contextMenuAnchors,
                      buttonItems: items,
                    );
                  },
                ),
                onTapAlwaysCalled: true,
                style: widget.textStyle ??
                    TextStyle(
                      fontSize: 26,
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
                  focusedBorder: widget.focusedBorder,
                  border: widget.border ??
                      OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                ),
                onChanged: (value) => _handleTextChanged(value, index),
                onTap: () {
                  _controllers[index].selection = TextSelection(
                      baseOffset: 1,
                      extentOffset: _controllers[index].text.length);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Enum to represent the number of digits for the Verification Code.
enum CodeDigit {
  four(4),
  five(5),
  six(6),
  ;

  const CodeDigit(this.digit);
  final int digit;
}
