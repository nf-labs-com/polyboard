import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'emoji_data.dart';
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
  bool _emoji = false;

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
      height: _kb.keyboardHeight,
      child: Directionality(
        textDirection: TextDirection.ltr, // keyboard always LTR
        child: Material(
          color: _t.background,
          elevation: _t.elevation,
          borderRadius: _kb.floating ? BorderRadius.circular(14) : null,
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: AnimatedBuilder(
              animation: _kb,
              builder: (context, _) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _topBar(),
                      const SizedBox(height: 2),
                      Expanded(child: _bodyForState()),
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

  Widget _bodyForState() {
    if (_emoji) return _emojiPanel();
    final Widget pad;
    if (_kb.layoutType == PolyboardLayoutType.numeric) {
      pad = _numericPad();
    } else if (_symbols) {
      pad = _symbolsLayout();
    } else {
      pad = _alphaLayout(_kb.language);
    }
    return Center(child: pad);
  }

  // ── Top bar: caret · drag handle · emoji/resize/float/hide ──────────────────

  Widget _topBar() {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          _miniIcon(Icons.chevron_left, () => _kb.moveCaret(-1)),
          _miniIcon(Icons.chevron_right, () => _kb.moveCaret(1)),
          // Drag handle — moves the keyboard (dock snap, or free 2D when float).
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) {
                if (_kb.floating) {
                  _kb.floatMove(d.delta);
                } else {
                  _kb.dragUpdate(d.delta.dy);
                }
              },
              onPanEnd: (_) {
                final size = MediaQuery.of(context).size;
                if (_kb.floating) {
                  final w = PolyboardController.floatingWidthFor(size.width);
                  _kb.floatEnd(Rect.fromLTRB(
                      0, 0, size.width - w, size.height - _kb.keyboardHeight));
                } else {
                  _kb.dragEnd(
                      screenHeight: size.height,
                      keyboardHeight: _kb.keyboardHeight);
                }
              },
              child: Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _t.keyBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          _miniIcon(
              _emoji ? Icons.keyboard_alt_outlined : Icons.emoji_emotions_outlined,
              () => setState(() => _emoji = !_emoji)),
          _miniIcon(Icons.remove, () => _kb.nudgeHeight(-0.1)),
          _miniIcon(Icons.add, () => _kb.nudgeHeight(0.1)),
          _miniIcon(
              _kb.floating ? Icons.vertical_align_bottom : Icons.open_in_full,
              _kb.toggleFloating),
          _miniIcon(Icons.keyboard_hide_outlined, _kb.dismiss),
        ],
      ),
    );
  }

  Widget _miniIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: () => _tap(onTap),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Icon(icon, size: 19, color: _t.mutedText),
      ),
    );
  }

  // ── Emoji ───────────────────────────────────────────────────────────────────

  Widget _emojiPanel() {
    final entries = kPolyboardEmoji.entries.toList();
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final cat = entries[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
              child: Text(cat.key,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _t.mutedText)),
            ),
            Wrap(
              children: [
                for (final e in cat.value)
                  InkWell(
                    onTap: () => _tapChar(e),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
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
    for (var i = 0; i < rows.length - 1; i++) {
      children.add(_charRow(rows[i], hPad: i == 0 ? 0 : 8));
    }
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
      previewChar: _kb.keyPreview ? ch : null,
      previewTheme: _t,
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
      previewTheme: _t,
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

/// A single key. Shows an enlarged-character popup above itself while pressed
/// when [previewChar] is set.
class _KeyBox extends StatefulWidget {
  const _KeyBox({
    required this.flex,
    required this.onTap,
    required this.child,
    required this.fill,
    required this.border,
    required this.height,
    required this.radius,
    required this.previewTheme,
    this.previewChar,
  });

  final int flex;
  final VoidCallback onTap;
  final Widget child;
  final Color fill;
  final Color border;
  final double height;
  final double radius;
  final PolyboardTheme previewTheme;
  final String? previewChar;

  @override
  State<_KeyBox> createState() => _KeyBoxState();
}

class _KeyBoxState extends State<_KeyBox> {
  OverlayEntry? _entry;

  void _showPreview() {
    if (widget.previewChar == null) return;
    final box = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.maybeOf(context);
    if (box == null || overlay == null || !box.hasSize) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    _entry = OverlayEntry(
      builder: (_) => Positioned(
        left: pos.dx + size.width / 2 - 28,
        top: pos.dy - 56,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.previewTheme.accentColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: Text(
                widget.previewChar!,
                style: TextStyle(
                  fontSize: 26,
                  color: widget.previewTheme.accentText,
                  fontFamilyFallback: kbScriptFontFallback,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_entry!);
  }

  void _hidePreview() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _hidePreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: widget.flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Material(
          color: widget.fill,
          borderRadius: BorderRadius.circular(widget.radius),
          child: InkWell(
            onTapDown: (_) => _showPreview(),
            onTapCancel: _hidePreview,
            onTap: () {
              _hidePreview();
              widget.onTap();
            },
            borderRadius: BorderRadius.circular(widget.radius),
            child: Container(
              height: widget.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                border: Border.all(color: widget.border),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
