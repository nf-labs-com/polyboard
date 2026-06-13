import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'keyboard_layouts.dart';
import 'polyboard_controller.dart';
import 'polyboard_host.dart';

/// A drop-in [TextField] that drives the on-screen keyboard. Identical to a
/// normal `TextField`, plus: on focus it registers its controller with the
/// nearest [Polyboard], and it auto-flips to right-aligned once RTL text is
/// typed. The field stays editable, so physical keyboards and barcode scanners
/// keep working — the on-screen keyboard is additive.
///
/// You don't have to use this — any field works if you call
/// `Polyboard.of(context).attach(controller)` on focus yourself — but this
/// wires it up for you.
class PolyboardTextField extends StatefulWidget {
  const PolyboardTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.layout,
    this.readOnly = false,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.decoration,
    this.style,
    this.textAlign = TextAlign.start,
    this.keyboardType,
    this.inputFormatters,
    this.autofocus = false,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Explicit layout; when null it's inferred from [keyboardType].
  final PolyboardLayoutType? layout;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final InputDecoration? decoration;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final bool enabled;
  final TextCapitalization textCapitalization;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;

  @override
  State<PolyboardTextField> createState() => _PolyboardTextFieldState();
}

class _PolyboardTextFieldState extends State<PolyboardTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _ownsController = false;
  bool _ownsFocus = false;
  String _lastText = '';
  TextDirection? _dir;

  PolyboardController? get _kb => Polyboard.maybeOf(context);

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _ownsController = widget.controller == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _ownsFocus = widget.focusNode == null;
    _lastText = _controller.text;
    _dir = firstStrongTextDirection(_lastText);
    _controller.addListener(_onControllerChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _focusNode.removeListener(_onFocusChanged);
    _kb?.detach(_controller);
    if (_ownsController) _controller.dispose();
    if (_ownsFocus) _focusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_controller.text != _lastText) {
      _lastText = _controller.text;
      widget.onChanged?.call(_lastText);
      final d = firstStrongTextDirection(_lastText);
      if (d != _dir) setState(() => _dir = d);
    }
  }

  void _onFocusChanged() {
    final kb = _kb;
    if (kb == null) return;
    if (_focusNode.hasFocus) {
      if (kb.bindsFields) {
        kb.attach(
          _controller,
          layout: widget.layout ?? inferLayoutType(widget.keyboardType),
          onSubmit: _submit,
        );
      }
    } else {
      kb.detach(_controller);
    }
  }

  void _submit() => widget.onSubmitted?.call(_controller.text);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: widget.readOnly,
      showCursor: true,
      enableInteractiveSelection: true,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      textCapitalization: widget.textCapitalization,
      style: widget.style,
      textAlign: widget.textAlign,
      textDirection: _dir,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      decoration: widget.decoration,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
    );
  }
}
