## 0.2.0

- **Key-preview popups** — an enlarged character floats above each key while
  pressed (toggle with `keyPreview`).
- **Caret-movement keys** — ◀ ▶ in the top bar move the cursor in the field
  (`moveCaret`).
- **Emoji panel** — a categorized emoji grid (toggle in the top bar).
- **Resize** — +/− keys scale the keyboard height (0.7×–1.5×, persisted).
- **Free-float positioning** — toggle between docked (full-width, top/bottom)
  and a draggable floating panel placed anywhere; position persisted.

## 0.1.0

Initial release.

- OS-independent on-screen keyboard for Flutter desktop, touch and web.
- Numeric pad, QWERTY/alphabetic and symbols layouts.
- Built-in glyph-verified layouts: English, Hindi (Devanagari), Arabic (RTL),
  Russian (Cyrillic). Bundled Noto fonts for Devanagari + Arabic.
- Bring-your-own layouts via `KbLayout` (any number of rows, optional shift
  layer, LTR/RTL).
- `off` / `on` / `auto` modes (auto shows only on touch focus).
- Drag the handle to dock top or bottom; choice persisted.
- Focus-safe: tapping a key never dismisses the focused field.
- Edits any `TextEditingController`; auto right-aligns once RTL text is typed.
- Zero dependencies beyond Flutter. Pluggable storage (`PolyboardStorage`),
  theme (`PolyboardTheme.light()/dark()`), logger, and key/visibility/language/
  mode callbacks — framework-agnostic, trivially used with Riverpod/Provider.
- IME hook (`PolyboardImeEngine`) for future CJK composition + candidate
  selection (engine/dictionaries ship separately).
