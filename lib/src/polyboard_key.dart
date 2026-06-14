/// A key press emitted to the `onKey` raw listener.
///
/// Sealed so callers can exhaustively switch:
/// ```dart
/// switch (key) {
///   case TextKey(:final text): ...
///   case ActionKey(:final action): ...
/// }
/// ```
sealed class PolyboardKey {
  const PolyboardKey();
}

/// A character was committed (a letter, digit, symbol, or composed glyph).
final class TextKey extends PolyboardKey {
  final String text;
  const TextKey(this.text);
}

/// A control key was pressed.
final class ActionKey extends PolyboardKey {
  final PolyboardAction action;
  const ActionKey(this.action);
}

enum PolyboardAction {
  backspace,
  enter,
  space,
  shift,
  symbols,
  language,
  hide,
  caretLeft,
  caretRight,
  emoji,
}
