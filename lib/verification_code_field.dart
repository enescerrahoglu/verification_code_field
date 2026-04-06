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

  /// Called when the user initiates a change to the TextField's value: when they have inserted or deleted text.
  final void Function(String)? onChanged;

  /// Whether the TextField widgets are enabled for input.
  final bool? enabled;

  /// Text style for the input digits.
  final TextStyle? textStyle;

  /// Font family for the input digits text.
  final String? fontFamily;

  /// Whether to display the cursor in the TextFields. Default is false.
  final bool? showCursor;

  /// Whether each TextField box should be filled with a background color.
  final bool? filled;

  /// Background color for each TextField box when `filled` is true.
  final Color? fillColor;

  /// Background color for the active focused TextField box.
  final Color? focusedFillColor;

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

  /// Whether the first TextField should automatically gain focus when the widget is built. Default is false.
  final bool autoFocus;

  /// The size of each digit field. Default is 36.
  final double fieldSize;

  const VerificationCodeField({
    super.key,
    this.codeDigit = CodeDigit.four,
    this.onSubmit,
    this.onChanged,
    this.enabled,
    this.textStyle,
    this.fontFamily,
    this.showCursor = false,
    this.filled,
    this.fillColor,
    this.focusedFillColor,
    this.border,
    this.focusedBorder,
    this.cursorColor,
    this.cleanAllAtOnce = false,
    this.tripleSeparated = false,
    this.autoFocus = false,
    this.fieldSize = 36,
  });

  @override
  State<VerificationCodeField> createState() => _VerificationCodeFieldState();
}

class _VerificationCodeFieldState extends State<VerificationCodeField>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _cursorController;

  // Track previous length to detect deletions for cleanAllAtOnce
  int _previousLength = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    // Rebuild when focus changes so the active-box border updates
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _cursorController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChanged(String value) {
    final bool isDeletion = value.length < _previousLength;

    // cleanAllAtOnce: any deletion clears everything and re-focuses first box
    if (isDeletion && widget.cleanAllAtOnce) {
      _controller.text = '';
      _controller.selection = const TextSelection.collapsed(offset: 0);
      _previousLength = 0;
      widget.onChanged?.call('');
      return;
    }

    // Clamp to max digits (handles paste)
    if (value.length > widget.codeDigit.digit) {
      value = value.substring(0, widget.codeDigit.digit);
    }

    if (_controller.text != value) {
      _controller.text = value;
      _controller.selection = TextSelection.collapsed(offset: value.length);
    }

    _previousLength = value.length;
    widget.onChanged?.call(value);

    if (value.length == widget.codeDigit.digit) {
      widget.onSubmit?.call(value);
      _focusNode.unfocus();
    }
  }

  void _showPasteMenu(Offset globalPosition) {
    if (widget.enabled == false) return;
    final OverlayState? overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => entry?.remove(),
                  behavior: HitTestBehavior.opaque,
                ),
              ),
              AdaptiveTextSelectionToolbar.buttonItems(
                anchors: TextSelectionToolbarAnchors(
                  primaryAnchor: globalPosition,
                ),
                buttonItems: [
                  ContextMenuButtonItem(
                    onPressed: () async {
                      entry?.remove();
                      final ClipboardData? data =
                          await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null && data!.text!.isNotEmpty) {
                        String pasted =
                            data.text!.replaceAll(RegExp(r'[^0-9]'), '');
                        String newText = _controller.text + pasted;
                        _handleTextChanged(newText);
                      }
                    },
                    type: ContextMenuButtonType.paste,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(entry);
  }

  /// Tapping a specific box trims the code to that index so the next
  /// keypress lands on the tapped box.
  void _handleBoxTap(int index) {
    if (widget.enabled == false) return;
    _focusNode.requestFocus();

    final String current = _controller.text;
    if (index < current.length) {
      _controller.text = current.substring(0, index);
      _controller.selection = TextSelection.collapsed(offset: index);
      _previousLength = index;
      widget.onChanged?.call(_controller.text);
    } else {
      _controller.selection = TextSelection.collapsed(offset: current.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.enabled != false;
    final double fieldSize = widget.fieldSize;
    final bool isFocused = _focusNode.hasFocus;

    final InputBorder defaultBorder = widget.border ??
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        );
    final InputBorder activeBorder = widget.focusedBorder ?? defaultBorder;

    return Container(
      color: Colors.transparent,
      height: fieldSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0,
                alwaysIncludeSemantics: true,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: isEnabled,
                  showCursor: widget.showCursor,
                  cursorColor: widget.cursorColor,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.codeDigit.digit),
                  ],
                  onChanged: _handleTextChanged,
                ),
              ),
            ),
          ),

          // Visual digit boxes painted with CustomPaint so border switching
          // is reliable regardless of InputDecorator internal state.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final String code = value.text;

              final List<Widget> boxes = [];
              for (int i = 0; i < widget.codeDigit.digit; i++) {
                final bool isActiveBox = isFocused && i == code.length;
                final bool isFilled = i < code.length;

                // Separator
                if (i > 0) {
                  final bool isTripleSep = widget.codeDigit == CodeDigit.six &&
                      widget.tripleSeparated &&
                      i == 3;
                  boxes.add(
                    SizedBox(
                        width: isTripleSep
                            ? 20
                            : (widget.tripleSeparated ? 5 : 10)),
                  );
                }

                boxes.add(
                  GestureDetector(
                    key: ValueKey('digit_box_$i'),
                    onTap: () => _handleBoxTap(i),
                    child: SizedBox(
                      width: fieldSize,
                      height: fieldSize,
                      child: CustomPaint(
                        painter: _DigitBoxPainter(
                          border: isActiveBox ? activeBorder : defaultBorder,
                          filled: widget.filled ??
                              (widget.fillColor != null ||
                                  widget.focusedFillColor != null),
                          fillColor: isActiveBox
                              ? (widget.focusedFillColor ?? widget.fillColor)
                              : widget.fillColor,
                        ),
                        child: Center(
                          child: isFilled
                              ? Text(
                                  code[i],
                                  style: widget.textStyle ??
                                      TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontFamily: widget.fontFamily ??
                                            GoogleFonts.firaCode().fontFamily,
                                      ),
                                  textAlign: TextAlign.center,
                                )
                              : (widget.showCursor == true && isActiveBox)
                                  ? FadeTransition(
                                      opacity: _cursorController,
                                      child: Container(
                                        width: 2,
                                        height:
                                            widget.textStyle?.fontSize ?? 26.0,
                                        color: widget.cursorColor ??
                                            Theme.of(context)
                                                .colorScheme
                                                .primary,
                                      ),
                                    )
                                  : null,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPressStart: (details) =>
                    _showPasteMenu(details.globalPosition),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: boxes,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Paints a digit box using the provided [InputBorder] directly via its
/// [InputBorder.paint] method — bypassing [InputDecorator]'s internal
/// animation/state so border switching is always immediate and correct.
class _DigitBoxPainter extends CustomPainter {
  const _DigitBoxPainter({
    required this.border,
    required this.filled,
    this.fillColor,
  });

  final InputBorder border;
  final bool filled;
  final Color? fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    // Fill background if requested
    if (filled && fillColor != null) {
      final paint = Paint()..color = fillColor!;
      if (border is OutlineInputBorder) {
        final rrect = (border as OutlineInputBorder)
            .borderRadius
            .resolve(TextDirection.ltr)
            .toRRect(rect);
        canvas.drawRRect(rrect, paint);
      } else {
        canvas.drawRect(rect, paint);
      }
    }

    // Paint the border itself
    border.paint(canvas, rect, textDirection: TextDirection.ltr);
  }

  @override
  bool shouldRepaint(_DigitBoxPainter old) =>
      old.border != border ||
      old.filled != filled ||
      old.fillColor != fillColor;
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
