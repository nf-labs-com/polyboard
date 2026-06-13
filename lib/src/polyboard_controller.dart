import 'package:flutter/widgets.dart';

import 'keyboard_layouts.dart';
import 'polyboard_ime.dart';
import 'polyboard_key.dart';
import 'polyboard_storage.dart';
import 'polyboard_theme.dart';

/// Which on-screen layout a focused field wants.
enum PolyboardLayoutType { text, numeric }

/// How the keyboard behaves on this device.
/// * [off]  — never shown.
/// * [on]   — shown whenever a bound field is focused (mouse, touch, anything).
/// * [auto] — shown only when the field was focused by a **touch** tap (a touch
///   terminal with no physical keyboard gets it; a mouse+keyboard operator
///   doesn't).
enum PolyboardMode { off, on, auto }

/// Best-guess layout from a field's [TextInputType]: number/phone → numeric pad.
PolyboardLayoutType inferLayoutType(TextInputType? keyboardType) {
  final s = keyboardType?.toString() ?? '';
  return (s.contains('number') || s.contains('phone'))
      ? PolyboardLayoutType.numeric
      : PolyboardLayoutType.text;
}

typedef PolyboardLogger = void Function(String message);

const String _kModeKey = 'polyboard.mode';
const String _kLangKey = 'polyboard.lang';
const String _kAlignTopKey = 'polyboard.align_top';

/// The OS-independent on-screen keyboard engine. A plain [ChangeNotifier], so
/// any state-management layer can host it (Riverpod: `Provider((ref) =>
/// PolyboardController())`; Provider: `ChangeNotifierProvider`; or bare).
///
/// Fields register their [TextEditingController] on focus via [attach]; the
/// keyboard widget reads the active binding and edits it directly. Nothing here
/// depends on a specific app, theme, storage engine, or DI framework — those
/// are all injected.
class PolyboardController extends ChangeNotifier {
  PolyboardController({
    PolyboardStorage? storage,
    PolyboardTheme? theme,
    List<KbLayout> layouts = kPolyboardDefaultLayouts,
    PolyboardMode defaultMode = PolyboardMode.auto,
    this.haptics = true,
    this.onKey,
    this.onVisibilityChanged,
    this.onLanguageChanged,
    this.onModeChanged,
    this.logger,
    Map<String, PolyboardImeEngine>? imeEngines,
  })  : _storage = storage ?? InMemoryPolyboardStorage(),
        theme = theme ?? PolyboardTheme.light(),
        layouts = layouts.isEmpty ? kPolyboardDefaultLayouts : layouts,
        imeEngines = imeEngines ?? const {} {
    _mode = _readMode(defaultMode);
    _langCode = _storage.getString(_kLangKey) ?? this.layouts.first.code;
    _alignTop = _storage.getBool(_kAlignTopKey) ?? false;
  }

  final PolyboardStorage _storage;
  final PolyboardTheme theme;
  final List<KbLayout> layouts;
  final Map<String, PolyboardImeEngine> imeEngines;
  final bool haptics;

  /// Fires on every key press (the "raw key listener").
  final void Function(PolyboardKey key)? onKey;
  final void Function(bool visible)? onVisibilityChanged;
  final void Function(String langCode)? onLanguageChanged;
  final void Function(PolyboardMode mode)? onModeChanged;
  final PolyboardLogger? logger;

  late PolyboardMode _mode;
  late String _langCode;
  late bool _alignTop;
  bool _lastPointerTouch = false;
  double _dragDy = 0;
  bool _lastVisible = false;

  TextEditingController? _controller;
  PolyboardLayoutType _layout = PolyboardLayoutType.text;
  VoidCallback? _onSubmit;

  PolyboardMode _readMode(PolyboardMode fallback) {
    final s = _storage.getString(_kModeKey);
    return PolyboardMode.values.firstWhere(
      (m) => m.name == s,
      orElse: () => fallback,
    );
  }

  void _log(String m) => logger?.call(m);

  // ── Public state ────────────────────────────────────────────────────────

  PolyboardMode get mode => _mode;
  bool get bindsFields => _mode != PolyboardMode.off;
  PolyboardLayoutType get layoutType => _layout;
  String get langCode => _langCode;
  KbLayout get language => kbLayoutByCode(_langCode, layouts);
  bool get alignTop => _alignTop;
  double get dragDy => _dragDy;

  /// True when the keyboard should be on screen.
  bool get visible =>
      _controller != null &&
      (_mode == PolyboardMode.on ||
          (_mode == PolyboardMode.auto && _lastPointerTouch));

  void _notify() {
    final v = visible;
    if (v != _lastVisible) {
      _lastVisible = v;
      onVisibilityChanged?.call(v);
    }
    notifyListeners();
  }

  // ── Mode / language (persisted) ─────────────────────────────────────────

  Future<void> setMode(PolyboardMode value) async {
    if (_mode == value) return;
    _mode = value;
    if (value == PolyboardMode.off) {
      _controller = null;
      _onSubmit = null;
    }
    _storage.setString(_kModeKey, value.name);
    onModeChanged?.call(value);
    _log('mode → ${value.name}');
    _notify();
  }

  Future<void> setLanguage(String code) async {
    if (!layouts.any((l) => l.code == code) || _langCode == code) return;
    _langCode = code;
    _storage.setString(_kLangKey, code);
    onLanguageChanged?.call(code);
    _notify();
  }

  /// Advance to the next enabled language.
  Future<void> cycleLanguage() async {
    final i = layouts.indexWhere((l) => l.code == _langCode);
    await setLanguage(layouts[(i + 1) % layouts.length].code);
  }

  /// The host feeds every pointer-down here so `auto` mode can tell a touch tap
  /// from a mouse click. A scanner types into an already-focused field, so it
  /// never triggers this.
  void notePointerKind(bool isTouch) {
    if (_lastPointerTouch == isTouch) return;
    _lastPointerTouch = isTouch;
    _notify();
  }

  // ── Field binding ───────────────────────────────────────────────────────

  void attach(
    TextEditingController controller, {
    PolyboardLayoutType layout = PolyboardLayoutType.text,
    VoidCallback? onSubmit,
  }) {
    _controller = controller;
    _layout = layout;
    _onSubmit = onSubmit;
    _notify();
  }

  void detach(TextEditingController controller) {
    if (identical(_controller, controller)) {
      _controller = null;
      _onSubmit = null;
      _notify();
    }
  }

  /// Hide the keyboard without disabling touch mode.
  void dismiss() {
    if (_controller == null) return;
    _controller = null;
    _onSubmit = null;
    _notify();
  }

  // ── Drag between top/bottom docks ───────────────────────────────────────

  void dragUpdate(double dy) {
    _dragDy += dy;
    notifyListeners();
  }

  Future<void> dragEnd({
    required double screenHeight,
    required double keyboardHeight,
  }) async {
    final baseTop = _alignTop ? 0.0 : screenHeight - keyboardHeight;
    final centre = baseTop + _dragDy + keyboardHeight / 2;
    final newAlignTop = centre < screenHeight / 2;
    _dragDy = 0;
    if (newAlignTop != _alignTop) {
      _alignTop = newAlignTop;
      _storage.setBool(_kAlignTopKey, newAlignTop);
    }
    notifyListeners();
  }

  // ── Editing operations (mutate the active controller at the caret) ───────

  void insert(String s) {
    onKey?.call(TextKey(s));
    final c = _controller;
    if (c == null) return;
    final value = c.value;
    final sel = value.selection;
    if (sel.isValid) {
      final newText = value.text.replaceRange(sel.start, sel.end, s);
      c.value = value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: sel.start + s.length),
        composing: TextRange.empty,
      );
    } else {
      final newText = value.text + s;
      c.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  void backspace() {
    onKey?.call(const ActionKey(PolyboardAction.backspace));
    final c = _controller;
    if (c == null) return;
    final value = c.value;
    final sel = value.selection;
    if (!sel.isValid) {
      if (value.text.isEmpty) return;
      final newText = value.text.substring(0, value.text.length - 1);
      c.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      return;
    }
    if (sel.start != sel.end) {
      final newText = value.text.replaceRange(sel.start, sel.end, '');
      c.value = value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: sel.start),
        composing: TextRange.empty,
      );
    } else if (sel.start > 0) {
      final newText = value.text.replaceRange(sel.start - 1, sel.start, '');
      c.value = value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: sel.start - 1),
        composing: TextRange.empty,
      );
    }
  }

  /// Invoke the focused field's submit action.
  void submit() {
    onKey?.call(const ActionKey(PolyboardAction.enter));
    _onSubmit?.call();
  }
}
