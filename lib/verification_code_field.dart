import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Controls the value shown by a [VerificationCodeField].
///
/// A controller can be shared with the field to read the current code, clear
/// every digit, or move focus. Dispose the controller when it is no longer needed.
class VerificationCodeController extends ChangeNotifier {
  /// Creates a controller with an optional initial [text].
  ///
  /// Characters that are not digits are removed from [text].
  VerificationCodeController({String text = ''})
      : _editable = TextEditingController(text: _digitsOnly(text)),
        _lastText = _digitsOnly(text) {
    _editable.addListener(_handleEditable);
  }

  final TextEditingController _editable;
  String _lastText;

  VoidCallback? _onClear;
  VoidCallback? _onFocus;
  ValueChanged<String>? _onSetText;

  /// The digits currently entered in the field.
  String get text => _editable.text;

  /// Replaces the current code.
  ///
  /// Characters that are not digits are ignored. When the controller is
  /// attached to a field, the value is also limited to that field's length.
  set text(String value) {
    final String sanitized = _digitsOnly(value);
    if (_onSetText != null) {
      _onSetText!(sanitized);
      return;
    }
    _setEditableText(sanitized);
  }

  /// Removes every digit from the field.
  void clear() {
    if (_onClear != null) {
      _onClear!();
      return;
    }
    _setEditableText('');
  }

  /// Focuses the empty box after the last entered digit.
  ///
  /// When every box already has a digit, the last box is focused instead.
  void focus() {
    _onFocus?.call();
  }

  void _setEditableText(String value) {
    if (_editable.text == value &&
        _editable.selection == TextSelection.collapsed(offset: value.length)) {
      return;
    }
    _editable.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _handleEditable() {
    if (_editable.text == _lastText) return;
    _lastText = _editable.text;
    notifyListeners();
  }

  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  @override
  void dispose() {
    _onClear = null;
    _onFocus = null;
    _onSetText = null;
    _editable.removeListener(_handleEditable);
    _editable.dispose();
    super.dispose();
  }
}

/// A widget for entering a Verification Code, consisting of separate boxes
/// for each digit.
class VerificationCodeField extends StatefulWidget {
  /// Specifies the number of digits in the Verification Code. Default is 4.
  final CodeDigit codeDigit;

  /// Controls the current code. When omitted, the field creates its own.
  final VerificationCodeController? controller;

  /// Callback function that returns the completed code once all digits are entered.
  final ValueChanged<String>? onSubmit;

  /// Called when the user initiates a change to the TextField's value: when they have inserted or deleted text.
  final void Function(String)? onChanged;

  /// Whether the TextField widgets are enabled for input.
  final bool? enabled;

  /// Text style for the input digits, including font family.
  final TextStyle? textStyle;

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

  /// When true, tapping a filled box clears that box and every box after it.
  ///
  /// When false, tapping a box focuses it and keeps its digit. The next digit
  /// overwrites the focused box, then focus moves to the following box.
  /// Defaults to true.
  final bool clearOnTap;

  /// Divides 6-digit fields into two groups of three. Default is false.
  final bool tripleSeparated;

  /// Whether the first TextField should automatically gain focus when the widget is built. Default is false.
  final bool autoFocus;

  /// The size of each digit field. Default is 36.
  final double fieldSize;

  const VerificationCodeField({
    super.key,
    this.codeDigit = CodeDigit.four,
    this.controller,
    this.onSubmit,
    this.onChanged,
    this.enabled,
    this.textStyle,
    this.showCursor = false,
    this.filled,
    this.fillColor,
    this.focusedFillColor,
    this.border,
    this.focusedBorder,
    this.cursorColor,
    this.cleanAllAtOnce = false,
    this.clearOnTap = true,
    this.tripleSeparated = false,
    this.autoFocus = false,
    this.fieldSize = 36,
  });

  @override
  State<VerificationCodeField> createState() => _VerificationCodeFieldState();
}

class _VerificationCodeFieldState extends State<VerificationCodeField>
    with SingleTickerProviderStateMixin {
  VerificationCodeController? _ownedController;
  VerificationCodeController? _boundController;

  late FocusNode _focusNode;
  late AnimationController _cursorController;
  late final _CodeInputFormatter _formatter;

  // Suppresses handling of programmatic editing-value updates.
  bool _updating = false;
  String _previousText = '';
  int _activeIndex = 0;

  VerificationCodeController get _codeController => _boundController!;

  @override
  void initState() {
    super.initState();
    _formatter = _CodeInputFormatter(this);
    _focusNode = FocusNode();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _syncCursorAnimation();

    if (widget.controller == null) {
      _ownedController = VerificationCodeController();
    }
    _bindController(widget.controller ?? _ownedController!);

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(VerificationCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      final VerificationCodeController? previousOwned = _ownedController;
      if (widget.controller == null) {
        _ownedController ??= VerificationCodeController();
      } else {
        _ownedController = null;
      }
      _bindController(widget.controller ?? _ownedController!);
      previousOwned?.dispose();
    } else if (oldWidget.codeDigit != widget.codeDigit) {
      _trimToLength(notify: false);
    }
    if (oldWidget.showCursor != widget.showCursor) {
      _syncCursorAnimation();
    }
    if (oldWidget.clearOnTap != widget.clearOnTap) {
      if (widget.clearOnTap) {
        _activeIndex = _codeController.text.length;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_focusNode.hasFocus) return;
        _placeCaret();
      });
    }
  }

  void _syncCursorAnimation() {
    if (widget.showCursor == true) {
      if (!_cursorController.isAnimating) {
        _cursorController.repeat(reverse: true);
      }
    } else {
      _cursorController.stop();
    }
  }

  void _bindController(VerificationCodeController controller) {
    if (!identical(_boundController, controller)) {
      _boundController?._editable.removeListener(_handleEditableChanged);
      _boundController?._onClear = null;
      _boundController?._onFocus = null;
      _boundController?._onSetText = null;
      _boundController = controller;
      controller._editable.addListener(_handleEditableChanged);
    }
    controller._onClear = _handleClear;
    controller._onFocus = _handleFocus;
    controller._onSetText = _handleSetText;
    _trimToLength(notify: false);
  }

  void _trimToLength({required bool notify}) {
    final int max = widget.codeDigit.digit;
    String text = _codeController.text;
    if (text.length > max) {
      text = text.substring(0, max);
      _writeValue(
        text,
        TextSelection.collapsed(offset: text.length),
        notifyChanged: notify,
      );
      _activeIndex = text.length;
      return;
    }
    _previousText = text;
    _activeIndex = text.length.clamp(0, max);
  }

  @override
  void dispose() {
    _codeController._editable.removeListener(_handleEditableChanged);
    _codeController._onClear = null;
    _codeController._onFocus = null;
    _codeController._onSetText = null;
    _boundController = null;
    _cursorController.dispose();
    _focusNode.dispose();
    _ownedController?.dispose();
    _ownedController = null;
    super.dispose();
  }

  void _handleEditableChanged() {
    if (_updating) return;

    final TextEditingValue value = _codeController._editable.value;
    final String text = value.text;
    final String previous = _previousText;
    final bool textChanged = text != previous;
    final bool isDeletion = text.length < previous.length;
    final int caret = value.selection.isValid
        ? value.selection.extentOffset.clamp(0, text.length)
        : text.length;

    _previousText = text;
    _activeIndex = caret.clamp(0, widget.codeDigit.digit);

    if (textChanged) {
      widget.onChanged?.call(text);
    }

    final int max = widget.codeDigit.digit;
    final bool enteredLastDigit = !isDeletion &&
        text.length == max &&
        value.selection.isCollapsed &&
        caret >= max;

    if (enteredLastDigit) {
      widget.onSubmit?.call(text);
      _focusNode.unfocus();
      return;
    }

    if (_focusNode.hasFocus) {
      _scheduleCaret();
    }
  }

  void _handleClear() {
    final bool hadText = _previousText.isNotEmpty;
    _writeValue(
      '',
      const TextSelection.collapsed(offset: 0),
      notifyChanged: hadText,
    );
    _activeIndex = 0;
    if (mounted) setState(() {});
  }

  void _handleFocus() {
    if (!mounted || widget.enabled == false) return;
    final int max = widget.codeDigit.digit;
    final int length = _codeController.text.length.clamp(0, max);
    _activeIndex = length < max ? length : max - 1;
    _focusNode.requestFocus();
    _placeCaret();
    setState(() {});
  }

  void _handleSetText(String sanitized) {
    final int max = widget.codeDigit.digit;
    final String text =
        sanitized.length > max ? sanitized.substring(0, max) : sanitized;
    final bool changed = text != _previousText;
    _writeValue(
      text,
      TextSelection.collapsed(offset: text.length),
      notifyChanged: changed,
    );
    _activeIndex = text.length;
    if (mounted) setState(() {});
  }

  void _writeValue(
    String text,
    TextSelection selection, {
    required bool notifyChanged,
  }) {
    _updating = true;
    _previousText = text;
    _codeController._editable.value = TextEditingValue(
      text: text,
      selection: selection,
    );
    _updating = false;
    if (notifyChanged) {
      widget.onChanged?.call(text);
    }
  }

  void _scheduleCaret() {
    if (_caretMatchesDesired()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusNode.hasFocus || _updating) return;
      _placeCaret();
    });
  }

  bool _caretMatchesDesired() {
    return _codeController._editable.selection == _desiredSelection();
  }

  TextSelection _desiredSelection() {
    final String text = _codeController.text;
    final int index = _activeIndex.clamp(0, text.length);
    if (!widget.clearOnTap && index < text.length) {
      return TextSelection(baseOffset: index, extentOffset: index + 1);
    }
    return TextSelection.collapsed(offset: index);
  }

  void _placeCaret() {
    final TextSelection desired = _desiredSelection();
    if (_codeController._editable.selection == desired) return;
    _updating = true;
    _codeController._editable.selection = desired;
    _updating = false;
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
                      if (data?.text == null || data!.text!.isEmpty) return;
                      final String pasted =
                          data.text!.replaceAll(RegExp(r'[^0-9]'), '');
                      if (pasted.isEmpty || !mounted) return;
                      _applyPaste(pasted);
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

  void _applyPaste(String pasted) {
    final int max = widget.codeDigit.digit;
    final String current = _codeController.text;

    if (widget.clearOnTap) {
      final String next = (current + pasted);
      _codeController._editable.value = TextEditingValue(
        text: next.length > max ? next.substring(0, max) : next,
        selection: TextSelection.collapsed(
          offset: next.length > max ? max : next.length,
        ),
      );
      return;
    }

    final int start = _activeIndex.clamp(0, current.length);
    final List<String> buffer = current.split('');
    for (int i = 0; i < pasted.length; i++) {
      final int position = start + i;
      if (position >= max) break;
      if (position < buffer.length) {
        buffer[position] = pasted[i];
      } else {
        buffer.add(pasted[i]);
      }
    }
    final String next = buffer.join();
    final int caret = (start + pasted.length).clamp(0, next.length);
    _codeController._editable.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: caret),
    );
  }

  /// Tapping a box either trims the code to that index or focuses it.
  void _handleBoxTap(int index) {
    if (widget.enabled == false) return;
    final String current = _codeController.text;
    final int target = index.clamp(0, current.length);

    _focusNode.requestFocus();

    if (widget.clearOnTap && index < current.length) {
      final String trimmed = current.substring(0, index);
      _writeValue(
        trimmed,
        TextSelection.collapsed(offset: trimmed.length),
        notifyChanged: true,
      );
      _activeIndex = trimmed.length;
    } else {
      _updating = true;
      _activeIndex = target;
      _codeController._editable.selection = _desiredSelection();
      _updating = false;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.enabled != false;
    final double fieldSize = widget.fieldSize;

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
                  controller: _codeController._editable,
                  focusNode: _focusNode,
                  enabled: isEnabled,
                  showCursor: widget.showCursor,
                  cursorColor: widget.cursorColor,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  enableInteractiveSelection: true,
                  contextMenuBuilder: (context, editableTextState) =>
                      const SizedBox.shrink(),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _formatter,
                  ],
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _codeController._editable,
            builder: (context, value, _) {
              final String code = value.text;

              final List<Widget> boxes = [];
              for (int i = 0; i < widget.codeDigit.digit; i++) {
                final bool isActiveBox = _focusNode.hasFocus &&
                    _activeIndex < widget.codeDigit.digit &&
                    i == _activeIndex;
                final bool isFilled = i < code.length;

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
                    behavior: HitTestBehavior.opaque,
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
                                        fontFamily:
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

/// Keeps the hidden field to digits and applies overwrite-or-append editing.
class _CodeInputFormatter extends TextInputFormatter {
  _CodeInputFormatter(this.state);

  final _VerificationCodeFieldState state;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final int max = state.widget.codeDigit.digit;
    final String oldText = oldValue.text;
    final String raw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (state.widget.cleanAllAtOnce && raw.length < oldText.length) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    if (state.widget.clearOnTap) {
      final String text = raw.length > max ? raw.substring(0, max) : raw;
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    if (raw == oldText) {
      final int caret = newValue.selection.isValid
          ? newValue.selection.extentOffset.clamp(0, raw.length)
          : raw.length;
      return TextEditingValue(
        text: raw,
        selection: TextSelection.collapsed(offset: caret),
      );
    }

    final TextSelection selection = oldValue.selection;
    final int start = selection.isValid
        ? selection.start.clamp(0, oldText.length)
        : oldText.length;
    final int end = selection.isValid
        ? selection.end.clamp(0, oldText.length)
        : oldText.length;

    // A digit typed into an existing box may arrive as an insertion in front
    // of that box instead of a replacement. Collapse it to a single overwrite.
    final int focused = state._activeIndex.clamp(0, oldText.length);
    if (focused < oldText.length &&
        raw.length == oldText.length + 1 &&
        raw.startsWith(oldText.substring(0, focused)) &&
        raw.substring(focused + 1) == oldText.substring(focused)) {
      final String updated =
          oldText.replaceRange(focused, focused + 1, raw[focused]);
      final int caret = (focused + 1).clamp(0, updated.length);
      return TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: caret),
      );
    }

    if (raw.length < oldText.length) {
      final int caret = selection.isCollapsed
          ? (newValue.selection.isValid
              ? newValue.selection.extentOffset.clamp(0, raw.length)
              : raw.length)
          : start.clamp(0, raw.length);
      final String text = raw.length > max ? raw.substring(0, max) : raw;
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: caret.clamp(0, text.length)),
      );
    }

    if (_isLocalEdit(oldText, raw, start, end)) {
      final int tailLength = oldText.length - end;
      final int insertedEnd = (raw.length - tailLength).clamp(start, raw.length);
      final String inserted = raw.substring(start, insertedEnd);
      final StringBuffer buffer = StringBuffer()
        ..write(oldText.substring(0, start))
        ..write(inserted);
      final int tailStart = start + inserted.length;
      if (tailStart < oldText.length) {
        buffer.write(oldText.substring(tailStart));
      }
      String text = buffer.toString();
      if (text.length > max) text = text.substring(0, max);
      final int caret = (start + inserted.length).clamp(0, text.length);
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: caret),
      );
    }

    final String text = raw.length > max ? raw.substring(0, max) : raw;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  bool _isLocalEdit(String oldText, String raw, int start, int end) {
    if (start > oldText.length || end > oldText.length || start > end) {
      return false;
    }
    if (start > raw.length || !raw.startsWith(oldText.substring(0, start))) {
      return false;
    }
    final String tail = oldText.substring(end);
    if (tail.isEmpty) return raw.length >= start;
    return raw.endsWith(tail) && raw.length >= start + tail.length;
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
