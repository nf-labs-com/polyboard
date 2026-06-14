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

  test('moveCaret clamps within the text', () {
    final kb = PolyboardController();
    final tec = TextEditingController(text: 'abc');
    kb.attach(tec);
    tec.selection = const TextSelection.collapsed(offset: 3);
    kb.moveCaret(-1);
    expect(tec.selection.baseOffset, 2);
    kb.moveCaret(-5);
    expect(tec.selection.baseOffset, 0);
    kb.moveCaret(10);
    expect(tec.selection.baseOffset, 3);
  });

  test('height scale clamps to 0.7..1.5', () {
    final kb = PolyboardController();
    kb.setHeightScale(5);
    expect(kb.heightScale, lessThanOrEqualTo(1.5));
    kb.setHeightScale(0.1);
    expect(kb.heightScale, greaterThanOrEqualTo(0.7));
  });

  test('floating toggles', () {
    final kb = PolyboardController();
    expect(kb.floating, isFalse);
    kb.toggleFloating();
    expect(kb.floating, isTrue);
  });
}
