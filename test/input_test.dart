import 'dart:math';
import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('Input', () {
    late Input input;
    late List<String> changes;

    setUp(() {
      input = Input();
      input.focusable = true;
      input.focused = true;
      input.resize(Size(40, 1), Position(0, 0));
      changes = [];
      input.onChange = (v) => changes.add(v);
    });

    group('onPaste', () {
      test('inserts pasted text at cursor position', () {
        input.onPaste('hello');
        expect(input.value, equals('hello'));
        expect(input.cursorPosition, equals(5));
      });

      test('inserts at cursor in middle of text', () {
        input.value = 'ac';
        input.cursorPosition = 1;
        input.onPaste('b');
        expect(input.value, equals('abc'));
        expect(input.cursorPosition, equals(2));
      });

      test('replaces newlines with spaces', () {
        input.onPaste('line1\nline2\nline3');
        expect(input.value, equals('line1 line2 line3'));
      });

      test('respects maxLength', () {
        input = Input(maxLength: 5);
        input.focused = true;
        input.resize(Size(40, 1), Position(0, 0));
        input.onPaste('hello world');
        expect(input.value, equals('hello'));
      });

      test('respects remaining maxLength with existing text', () {
        input = Input(maxLength: 8);
        input.focused = true;
        input.resize(Size(40, 1), Position(0, 0));
        input.value = 'abc';
        input.cursorPosition = 3;
        input.onPaste('defghij');
        expect(input.value, equals('abcdefgh'));
      });

      test('fires onChange', () {
        input.onPaste('text');
        expect(changes, equals(['text']));
      });

      test('returns true (handled)', () {
        expect(input.onPaste('x'), isTrue);
      });

      test('strips carriage returns', () {
        input.onPaste('win\r\nlines');
        expect(input.value, equals('win lines'));
      });
    });

    group('onKey printable char', () {
      test('accepts regular ASCII', () {
        input.onKey('a');
        expect(input.value, equals('a'));
      });

      test('rejects control characters', () {
        input.onKey('\x01');
        expect(input.value, equals(''));
      });
    });
  });
}
