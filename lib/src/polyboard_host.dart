import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import 'polyboard_controller.dart';
import 'polyboard_keyboard.dart';

/// Wrap your app once with this to enable the on-screen keyboard everywhere.
///
/// ```dart
/// final keyboard = PolyboardController();
/// MaterialApp(
///   builder: Polyboard.builder(controller: keyboard),
///   home: const HomePage(),
/// );
/// ```
///
/// It renders the keyboard **above the Navigator** (so it overlays dialogs
/// too), docked to the top or bottom edge — it does NOT push page content up.
/// The keyboard is wrapped in a [TextFieldTapRegion] so tapping a key counts as
/// "inside" the focused field's tap group; without it, `TextField`'s default
/// `onTapOutside` would unfocus on every key tap and dismiss the keyboard. A
/// non-focusable [Focus] barrier stops the key buttons stealing focus too.
class Polyboard extends StatefulWidget {
  const Polyboard({super.key, required this.controller, required this.child});

  final PolyboardController controller;
  final Widget child;

  /// The nearest controller. Throws if there is no [Polyboard] ancestor.
  static PolyboardController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_PolyboardScope>();
    assert(scope != null,
        'No Polyboard ancestor found. Wrap your app with Polyboard.builder().');
    return scope!.controller;
  }

  static PolyboardController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PolyboardScope>()?.controller;

  /// Convenience for `MaterialApp.builder` / `CupertinoApp.builder`.
  static TransitionBuilder builder({required PolyboardController controller}) {
    return (context, child) => Polyboard(
          controller: controller,
          child: child ?? const SizedBox.shrink(),
        );
  }

  @override
  State<Polyboard> createState() => _PolyboardState();
}

class _PolyboardState extends State<Polyboard> {
  @override
  Widget build(BuildContext context) {
    return _PolyboardScope(
      controller: widget.controller,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final kb = widget.controller;
          // Focus-safe wrapper shared by docked + floating placement.
          final keyboard = TextFieldTapRegion(
            child: Focus(
              canRequestFocus: false,
              descendantsAreFocusable: false,
              child: PolyboardKeyboard(controller: kb),
            ),
          );
          return Stack(
            children: [
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (e) =>
                      kb.notePointerKind(e.kind == PointerDeviceKind.touch),
                  child: widget.child,
                ),
              ),
              if (kb.visible)
                if (kb.floating)
                  _floating(context, kb, keyboard)
                else
                  Positioned(
                    left: 0,
                    right: 0,
                    top: kb.alignTop ? 0 : null,
                    bottom: kb.alignTop ? null : 0,
                    child: Transform.translate(
                      offset: Offset(0, kb.dragDy),
                      child: keyboard,
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

Widget _floating(
    BuildContext context, PolyboardController kb, Widget keyboard) {
  final size = MediaQuery.of(context).size;
  final w = PolyboardController.floatingWidthFor(size.width);
  final maxX = (size.width - w).clamp(0.0, double.infinity);
  final maxY = (size.height - kb.keyboardHeight).clamp(0.0, double.infinity);
  // Default: centred horizontally, just above the bottom.
  final initial = Offset((size.width - w) / 2, maxY - 40);
  final o = kb.floatOffset ?? initial;
  return Positioned(
    left: o.dx.clamp(0.0, maxX),
    top: o.dy.clamp(0.0, maxY),
    width: w,
    child: keyboard,
  );
}

class _PolyboardScope extends InheritedWidget {
  const _PolyboardScope({required this.controller, required super.child});

  final PolyboardController controller;

  @override
  bool updateShouldNotify(_PolyboardScope oldWidget) =>
      oldWidget.controller != controller;
}
