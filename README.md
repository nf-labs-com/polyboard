# polyboard

A **multilingual, draggable on-screen keyboard** for Flutter — desktop, touch
and web. Built for kiosks, POS terminals and any touchscreen without a physical
keyboard.

- ⌨️ Numeric pad, QWERTY/alphabetic and symbols.
- 🌍 **English · हिन्दी · العربية (RTL) · Русский** out of the box — and any
  non-CJK script via a few lines of layout data. Bundled Noto fonts so
  Devanagari/Arabic render everywhere.
- 🖱️ **Drag** the handle to dock the keyboard to the top or bottom; remembered
  per device.
- 🎯 **Focus-safe** — tapping a key never dismisses the field (the usual
  `onTapOutside` trap is handled for you).
- 🔌 **Zero dependencies beyond Flutter.** Pluggable storage, theme, logger and
  callbacks — works with Riverpod, Provider, or nothing.
- ✍️ Drives **any** `TextEditingController`; auto right-aligns once RTL text is
  typed.

> Chinese & Japanese need an IME (phonetic → candidate selection), not a key
> layout. polyboard ships the **IME hook** (`PolyboardImeEngine`) so a
> conversion engine can be attached; the engine/dictionaries ship separately.

## Install

```yaml
dependencies:
  polyboard: ^0.1.0
```

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:polyboard/polyboard.dart';

final keyboard = PolyboardController();

void main() => runApp(MaterialApp(
      builder: Polyboard.builder(controller: keyboard),
      home: const Demo(),
    ));

class Demo extends StatelessWidget {
  const Demo({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: PolyboardTextField(
              decoration: const InputDecoration(hintText: 'Type here'),
            ),
          ),
        ),
      );
}
```

Any field works — `PolyboardTextField` just wires focus for you. To use your
own field, call `Polyboard.of(context).attach(controller)` on focus and
`detach(controller)` on blur.

## Modes

```dart
PolyboardController(defaultMode: PolyboardMode.auto); // off | on | auto
```

- **off** — never shown.
- **on** — shown whenever a bound field is focused.
- **auto** — shown only when the field was focused by a **touch** tap (a touch
  terminal gets it; a mouse+keyboard operator doesn't).

## Theme

```dart
PolyboardController(theme: PolyboardTheme.dark());
// or PolyboardTheme.light().copyWith(accentColor: Colors.teal)
```

## Custom layouts & languages

A language is just data — any number of rows, an optional shift layer, and an
`rtl` flag:

```dart
const swedish = KbLayout(
  code: 'sv',
  label: 'SV',
  rtl: false,
  rows: [
    ['q','w','e','r','t','y','u','i','o','p','å'],
    ['a','s','d','f','g','h','j','k','l','ö','ä'],
    ['z','x','c','v','b','n','m'],
  ],
);

PolyboardController(layouts: const [kbEnglish, swedish]);
```

## Callbacks, logging & Riverpod

No state-management dependency. Hook events directly:

```dart
PolyboardController(
  logger: (m) => debugPrint('[polyboard] $m'),
  onKey: (key) => switch (key) {
    TextKey(:final text) => print('typed $text'),
    ActionKey(:final action) => print('action $action'),
  },
  onVisibilityChanged: (v) {},
  onLanguageChanged: (code) {},
);
```

Riverpod is a one-liner — the controller is a `ChangeNotifier`:

```dart
final keyboardProvider = Provider((ref) {
  final c = PolyboardController();
  ref.onDispose(c.dispose);
  return c;
});
// MaterialApp(builder: Polyboard.builder(controller: ref.read(keyboardProvider)))
```

## Persistence

By default preferences (mode/language/dock) last only for the session. Persist
them by passing a `PolyboardStorage` adapter (wrap `shared_preferences`, Hive,
etc.):

```dart
class PrefsStorage implements PolyboardStorage {
  PrefsStorage(this.prefs);
  final SharedPreferences prefs;
  @override String? getString(String k) => prefs.getString(k);
  @override void setString(String k, String v) => prefs.setString(k, v);
  @override bool? getBool(String k) => prefs.getBool(k);
  @override void setBool(String k, bool v) => prefs.setBool(k, v);
}
```

## Roadmap

Long-press accents (unlocks Portuguese/Spanish/French/German), Thai (4-row
Kedmanee), key-preview popups, caret-movement keys, emoji panel, resizable /
free-float positioning, and the CJK IME engine.

## License

MIT. Bundled Noto fonts are under the SIL Open Font License 1.1
(`assets/fonts/OFL.txt`).
