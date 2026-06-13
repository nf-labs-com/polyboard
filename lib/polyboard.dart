/// Polyboard — a multilingual, draggable on-screen keyboard for Flutter
/// desktop, touch and web.
///
/// Wrap your app with [Polyboard.builder] and use [PolyboardTextField] (or call
/// `Polyboard.of(context).attach(controller)` on any field). See the README for
/// Riverpod/Provider wiring, custom layouts, themes, and the IME hook.
library polyboard;

export 'src/keyboard_layouts.dart'
    show
        KbLayout,
        kbEnglish,
        kbHindi,
        kbArabic,
        kbRussian,
        kPolyboardDefaultLayouts,
        kbScriptFontFallback,
        firstStrongTextDirection;
export 'src/polyboard_controller.dart';
export 'src/polyboard_host.dart' show Polyboard;
export 'src/polyboard_ime.dart';
export 'src/polyboard_key.dart';
export 'src/polyboard_keyboard.dart' show PolyboardKeyboard;
export 'src/polyboard_storage.dart';
export 'src/polyboard_text_field.dart' show PolyboardTextField;
export 'src/polyboard_theme.dart';
