/// Input-Method-Editor hook for scripts that need phonetic composition +
/// candidate selection (Chinese Pinyin → Hanzi, Japanese Rōmaji/Kana → Kanji).
///
/// Polyboard ships the *architecture* — a composition buffer and a candidate
/// strip — but no conversion dictionary (those are megabytes). To enable a
/// CJK language, attach a [PolyboardImeEngine] that turns the in-progress
/// composition string into a ranked list of candidate strings. A companion
/// package (or your own dictionary) provides the engine; without one, IME
/// languages simply aren't offered.
///
/// Contract:
/// * The keyboard accumulates Latin/phonetic key presses into a composition
///   string and calls [candidates] on each change.
/// * The candidate strip shows the returned list; tapping one commits it and
///   clears the composition.
abstract class PolyboardImeEngine {
  /// Ranked candidate strings for the current [composition] (most-likely
  /// first). Return empty when there's nothing to suggest.
  List<String> candidates(String composition);

  /// Optional: the raw composition to show inline while composing (e.g. the
  /// Pinyin/Rōmaji itself). Defaults to the composition string.
  String displayComposition(String composition) => composition;
}
