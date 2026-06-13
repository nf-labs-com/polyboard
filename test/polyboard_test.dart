import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyboard/polyboard.dart';

void main() {
  test('controller edits the bound controller', () {
    final kb = PolyboardController(defaultMode: PolyboardMode.on);
    final tec = TextEditingController();
    kb.attach(tec);

    kb.insert('a');
    kb.insert('b');
    kb.insert('c');
    expect(tec.text, 'abc');

    kb.backspace();
    expect(tec.text, 'ab');
  });

  test('visibility follows mode and binding', () {
    final kb = PolyboardController(defaultMode: PolyboardMode.on);
    expect(kb.visible, isFalse); // nothing focused yet
    final tec = TextEditingController();
    kb.attach(tec);
    expect(kb.visible, isTrue);
    kb.dismiss();
    expect(kb.visible, isFalse);
  });

  test('auto mode needs a touch interaction', () {
    final kb = PolyboardController(defaultMode: PolyboardMode.auto);
    kb.attach(TextEditingController());
    expect(kb.visible, isFalse); // focused by mouse → hidden
    kb.notePointerKind(true); // touch
    expect(kb.visible, isTrue);
  });

  test('cycleLanguage advances through layouts', () async {
    final kb = PolyboardController();
    expect(kb.langCode, 'en');
    await kb.cycleLanguage();
    expect(kb.langCode, 'hi');
  });

  test('onKey fires for text and actions', () {
    final keys = <PolyboardKey>[];
    final kb = PolyboardController(onKey: keys.add);
    kb.attach(TextEditingController());
    kb.insert('x');
    kb.backspace();
    expect(keys.whereType<TextKey>().single.text, 'x');
    expect(keys.whereType<ActionKey>().single.action, PolyboardAction.backspace);
  });
}
