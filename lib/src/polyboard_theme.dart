import 'package:flutter/widgets.dart';

/// Visual styling for the keyboard. Fully self-contained — the package depends
/// on no app theme. Use [PolyboardTheme.light] / [PolyboardTheme.dark] or build
/// your own.
@immutable
class PolyboardTheme {
  const PolyboardTheme({
    required this.background,
    required this.keyColor,
    required this.keyBorder,
    required this.keyText,
    required this.actionKeyColor,
    required this.actionKeyText,
    required this.accentColor,
    required this.accentText,
    required this.mutedText,
    this.keyboardHeight = 330,
    this.keyHeight = 46,
    this.keyRadius = 7,
    this.elevation = 12,
    this.keyTextSize = 19,
    this.actionTextSize = 14,
  });

  /// Keyboard backdrop.
  final Color background;

  /// Character-key fill, border and glyph colours.
  final Color keyColor;
  final Color keyBorder;
  final Color keyText;

  /// Control-key (shift/backspace/?123/space) fill + glyph colours.
  final Color actionKeyColor;
  final Color actionKeyText;

  /// Accent (enter / active-shift) fill + glyph colours.
  final Color accentColor;
  final Color accentText;

  /// Secondary text (handle, hide label, language label).
  final Color mutedText;

  /// Docked keyboard height in logical pixels.
  final double keyboardHeight;

  /// Per-key height.
  final double keyHeight;
  final double keyRadius;
  final double elevation;
  final double keyTextSize;
  final double actionTextSize;

  factory PolyboardTheme.light() => const PolyboardTheme(
        background: Color(0xFFE7ECF3),
        keyColor: Color(0xFFFFFFFF),
        keyBorder: Color(0xFFE2E8F0),
        keyText: Color(0xFF0F172A),
        actionKeyColor: Color(0xFFCBD5E1),
        actionKeyText: Color(0xFF334155),
        accentColor: Color(0xFF2563EB),
        accentText: Color(0xFFFFFFFF),
        mutedText: Color(0xFF64748B),
      );

  factory PolyboardTheme.dark() => const PolyboardTheme(
        background: Color(0xFF1E293B),
        keyColor: Color(0xFF334155),
        keyBorder: Color(0xFF475569),
        keyText: Color(0xFFF1F5F9),
        actionKeyColor: Color(0xFF475569),
        actionKeyText: Color(0xFFE2E8F0),
        accentColor: Color(0xFF3B82F6),
        accentText: Color(0xFFFFFFFF),
        mutedText: Color(0xFF94A3B8),
      );

  PolyboardTheme copyWith({
    Color? background,
    Color? keyColor,
    Color? keyBorder,
    Color? keyText,
    Color? actionKeyColor,
    Color? actionKeyText,
    Color? accentColor,
    Color? accentText,
    Color? mutedText,
    double? keyboardHeight,
    double? keyHeight,
    double? keyRadius,
    double? elevation,
    double? keyTextSize,
    double? actionTextSize,
  }) {
    return PolyboardTheme(
      background: background ?? this.background,
      keyColor: keyColor ?? this.keyColor,
      keyBorder: keyBorder ?? this.keyBorder,
      keyText: keyText ?? this.keyText,
      actionKeyColor: actionKeyColor ?? this.actionKeyColor,
      actionKeyText: actionKeyText ?? this.actionKeyText,
      accentColor: accentColor ?? this.accentColor,
      accentText: accentText ?? this.accentText,
      mutedText: mutedText ?? this.mutedText,
      keyboardHeight: keyboardHeight ?? this.keyboardHeight,
      keyHeight: keyHeight ?? this.keyHeight,
      keyRadius: keyRadius ?? this.keyRadius,
      elevation: elevation ?? this.elevation,
      keyTextSize: keyTextSize ?? this.keyTextSize,
      actionTextSize: actionTextSize ?? this.actionTextSize,
    );
  }
}
