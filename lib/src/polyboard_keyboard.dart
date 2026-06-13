import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'keyboard_layouts.dart';
import 'polyboard_controller.dart';
import 'polyboard_theme.dart';

/// The rendered keyboard. You normally don't use this directly — [Polyboard]
/// places it. It reads layout/language/theme from the [controller] and edits
/// the bound field through it.
class PolyboardKeyboard extends StatefulWidget {
  const PolyboardKeyboard({super.key, required this.controller});

  final PolyboardController controller;

  @override
  State<PolyboardKeyboard> createState() => _PolyboardKeyboardState();
}

class _PolyboardKeyboardState extends State<PolyboardKeyboard> {
  bool _shift = false;
  bool _symbols = false;

  static const List<String> _sym1 = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
  static const List<String> _sym2 = ['@', '#', '\$', '&', '*', '(', ')', '-', '_', '/'];
  static const List<String> _sym3 = [':', ';', '"', '\'', '?', '!', ',', '.', '%'];

  PolyboardController get _kb => widget.controller;
  PolyboardTheme get _t => _kb.theme;

  void _tap(VoidCallback fn) {
    if (_kb.haptics) HapticFeedback.selectionClick();
    fn();
  }

  void _tapChar(String ch) {
    if (_kb.haptics) HapticFeedback.selectionClick();
    _kb.insert(ch);
    if (_shift) setState(() => _shift = false);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _t.keyboardHeight,
      child: Directionality(
        textDirection: TextDirection.ltr, // keyboard always LTR
        child: Material(
          color: _t.background,
          elevation: _t.elevation,
          child: SafeArea(
            top: false,
            child: AnimatedBuilder(
              animation: _kb,
              builder: (context, _) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _topBar(),
                      const SizedBox(height: 4),
                      if (_kb.layoutType == PolyboardLayoutType.numeric)
                        _numericPad()
                      else if (_symbols)
                        _symbolsLayout()
                      else
                        _alphaLayout(_kb.language),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        // Drag handle — vertical drag snaps the keyboard to top/bottom.
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (d) => _kb.dragUpdate(d.delta.dy),
            onVerticalDragEnd: (_) => _kb.dragEnd(
              screenHeight: MediaQuery.of(context).size.height,
              keyboardHeight: _t.keyboardHeight,
            ),
            child: Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: _t.keyBorder,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        InkWell(
          onTap: () => _tap(_kb.dismiss),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.keyboard_hide_outlined,
                    size: 18, color: _t.mutedText),
                const SizedBox(width: 6),
                Text('Hide',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _t.mutedText)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Alphabetic (N rows) ───────────────────────────────────────────────────

  List<List<String>> _activeRows(KbLayout lang) {
    if (!_shift) return lang.rows;
    if (lang.shiftRows != null) return lang.shiftRows!;
    return lang.rows
        .map((r) => r.map((c) => c.toUpperCase()).toList())
        .toList();
  }

  Widget _alphaLayout(KbLayout lang) {
    final rows = _activeRows(lang);
    final children = <Widget>[];
    // All rows except the last render as plain character rows.
    for (var i = 0; i < rows.length - 1; i++) {
      children.add(_charRow(rows[i], hPad: i == 0 ? 0 : 8));
    }
    // Last row gets shift + its keys + backspace.
    children.add(Row(
      children: [
        _ctrlKey(
          flex: 15,
          active: _shift,
          onTap: () => _tap(() => setState(() => _shift = !_shift)),
          child: Icon(
            _shift
                ? Icons.keyboard_capslock_rounded
                : Icons.keyboard_arrow_up_rounded,
            size: 22,
            color: _shift ? _t.accentText : _t.actionKeyText,
          ),
        ),
        const SizedBox(width: 4),
        ..._spread(rows.last),
        const SizedBox(width: 4),
        _ctrlKey(
          flex: 15,
          onTap: () => _tap(_kb.backspace),
          child: Icon(Icons.backspace_outlined,
              size: 20, color: _t.actionKeyText),
        ),
      ],
    ));
    children.add(_bottomRow(lang));
    return Column(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _symbolsLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _charRow(_sym1),
        _charRow(_sym2, hPad: 8),
        Row(
          children: [
            const Spacer(flex: 4),
            ..._spread(_sym3),
            const SizedBox(width: 4),
            _ctrlKey(
              flex: 15,
              onTap: () => _tap(_kb.backspace),
              child: Icon(Icons.backspace_outlined,
                  size: 20, color: _t.actionKeyText),
            ),
          ],
        ),
        _bottomRow(_kb.language),
      ],
    );
  }

  Widget _bottomRow(KbLayout lang) {
    return Row(
      children: [
        _ctrlKey(
          label: _symbols ? 'ABC' : '?123',
          flex: 16,
          onTap: () => _tap(() => setState(() => _symbols = !_symbols)),
        ),
        const SizedBox(width: 4),
        if (_kb.layouts.length > 1) ...[
          _ctrlKey(
            flex: 14,
            onTap: () => _tap(_kb.cycleLanguage),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language, size: 16, color: _t.actionKeyText),
                const SizedBox(width: 4),
                Text(lang.label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _t.actionKeyText)),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
        _ctrlKey(
          label: 'space',
          flex: 40,
          onTap: () => _tap(() => _kb.insert(' ')),
        ),
        const SizedBox(width: 4),
        _charKey('.', flex: 10),
        const SizedBox(width: 4),
        _ctrlKey(
          flex: 18,
          accent: true,
          onTap: () => _tap(_kb.submit),
          child: Icon(Icons.keyboard_return_rounded,
              size: 20, color: _t.accentText),
        ),
      ],
    );
  }

  Widget _charRow(List<String> chars, {double hPad = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 3),
      child: Row(children: _spread(chars)),
    );
  }

  List<Widget> _spread(List<String> chars) {
    final out = <Widget>[];
    for (var i = 0; i < chars.length; i++) {
      if (i != 0) out.add(const SizedBox(width: 4));
      out.add(_charKey(chars[i]));
    }
    return out;
  }

  // ── Numeric ────────────────────────────────────────────────────────────────

  Widget _numericPad() {
    Widget row(List<String> a) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: _spread(a)),
        );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row(['7', '8', '9']),
          row(['4', '5', '6']),
          row(['1', '2', '3']),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                _charKey('.'),
                const SizedBox(width: 4),
                _charKey('0'),
                const SizedBox(width: 4),
                _ctrlKey(
                  flex: 10,
                  onTap: () => _tap(_kb.backspace),
                  child: Icon(Icons.backspace_outlined,
                      size: 20, color: _t.actionKeyText),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: _ctrlKey(
              label: 'Done',
              flex: 10,
              accent: true,
              onTap: () => _tap(() {
                _kb.submit();
                _kb.dismiss();
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Key primitives ──────────────────────────────────────────────────────────

  Widget _charKey(String ch, {int flex = 10}) {
    return _KeyBox(
      flex: flex,
      height: _t.keyHeight,
      radius: _t.keyRadius,
      fill: _t.keyColor,
      border: _t.keyBorder,
      onTap: () => _tapChar(ch),
      child: Text(
        ch,
        style: TextStyle(
          fontSize: _t.keyTextSize,
          color: _t.keyText,
          fontFamilyFallback: kbScriptFontFallback,
        ),
      ),
    );
  }

  Widget _ctrlKey({
    String? label,
    Widget? child,
    required int flex,
    bool accent = false,
    bool active = false,
    required VoidCallback onTap,
  }) {
    return _KeyBox(
      flex: flex,
      height: _t.keyHeight,
      radius: _t.keyRadius,
      fill: accent || active ? _t.accentColor : _t.actionKeyColor,
      border: _t.keyBorder,
      onTap: onTap,
      child: child ??
          Text(
            label ?? '',
            style: TextStyle(
              fontSize: _t.actionTextSize,
              fontWeight: FontWeight.w600,
              color: accent || active ? _t.accentText : _t.actionKeyText,
            ),
          ),
    );
  }
}

class _KeyBox extends StatelessWidget {
  const _KeyBox({
    required this.flex,
    required this.onTap,
    required this.child,
    required this.fill,
    required this.border,
    required this.height,
    required this.radius,
  });

  final int flex;
  final VoidCallback onTap;
  final Widget child;
  final Color fill;
  final Color border;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Material(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              height: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: border),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
