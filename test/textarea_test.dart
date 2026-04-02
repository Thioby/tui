import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('TextArea', () {
    late TextArea ta;
    late List<String> changes;

    setUp(() {
      ta = TextArea();
      ta.focused = true;
      ta.resize(Size(40, 10), Position(0, 0));
      changes = [];
      ta.onChange = (v) => changes.add(v);
    });

    group('onPaste', () {
      test('inserts single line at cursor', () {
        ta.onPaste('hello');
        expect(ta.value, equals('hello'));
        expect(ta.cursorX, equals(5));
        expect(ta.cursorY, equals(0));
      });

      test('inserts multi-line paste', () {
        ta.onPaste('line1\nline2\nline3');
        expect(ta.value, equals('line1\nline2\nline3'));
        expect(ta.cursorY, equals(2));
        expect(ta.cursorX, equals(5));
      });

      test('inserts at cursor in middle of existing text', () {
        ta.value = 'hello world';
        ta.cursorX = 5;
        ta.cursorY = 0;
        ta.onPaste(' beautiful');
        expect(ta.value, equals('hello beautiful world'));
      });

      test('multi-line paste splits existing line', () {
        ta.value = 'AABB';
        ta.cursorX = 2;
        ta.cursorY = 0;
        ta.onPaste('X\nY');
        expect(ta.value, equals('AAX\nYBB'));
        expect(ta.cursorY, equals(1));
        expect(ta.cursorX, equals(1));
      });

      test('respects maxLines', () {
        ta = TextArea(maxLines: 3);
        ta.focused = true;
        ta.resize(Size(40, 10), Position(0, 0));
        ta.onPaste('1\n2\n3\n4\n5');
        expect(ta.value.split('\n').length, lessThanOrEqualTo(3));
      });

      test('fires onChange', () {
        ta.onPaste('text');
        expect(changes, isNotEmpty);
      });

      test('returns true', () {
        expect(ta.onPaste('x'), isTrue);
      });

      test('handles carriage returns', () {
        ta.onPaste('win\r\nlines');
        expect(ta.value, equals('win\nlines'));
      });
    });

    group('onKey printable char', () {
      test('accepts regular ASCII', () {
        ta.onKey('a');
        expect(ta.value, equals('a'));
      });

      test('rejects control characters', () {
        ta.onKey('\x01');
        expect(ta.value, equals(''));
      });
    });
  });
}
