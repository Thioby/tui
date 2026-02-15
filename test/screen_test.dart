import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('Screen', () {
    late Screen screen;

    setUp(() {
      screen = Screen(Size(10, 5));
    });

    group('initialization', () {
      test('has correct dimensions', () {
        expect(screen.width, equals(10));
        expect(screen.height, equals(5));
      });

      test('starts with empty buffer', () {
        expect(screen.stringAt(0, 0), equals(''));
        expect(screen.stringAt(5, 2), equals(''));
      });

      test('all cells are not occluded initially', () {
        expect(screen.occluded(0, 0), isFalse);
        expect(screen.occluded(9, 4), isFalse);
      });
    });

    group('write and read', () {
      test('write stores character at position', () {
        screen.write(3, 2, 'X');
        expect(screen.stringAt(3, 2), equals('X'));
      });

      test('written cell is occluded', () {
        expect(screen.occluded(3, 2), isFalse);
        screen.write(3, 2, 'X');
        expect(screen.occluded(3, 2), isTrue);
      });

      test('write overwrites previous value', () {
        screen.write(0, 0, 'A');
        screen.write(0, 0, 'B');
        expect(screen.stringAt(0, 0), equals('B'));
      });
    });

    group('bounds checking', () {
      test('occluded returns true for negative x', () {
        expect(screen.occluded(-1, 0), isTrue);
      });

      test('occluded returns true for negative y', () {
        expect(screen.occluded(0, -1), isTrue);
      });

      test('occluded returns true for x >= width', () {
        expect(screen.occluded(10, 0), isTrue);
        expect(screen.occluded(100, 0), isTrue);
      });

      test('occluded returns true for y >= height', () {
        expect(screen.occluded(0, 5), isTrue);
        expect(screen.occluded(0, 100), isTrue);
      });

      test('write ignores out of bounds negative x', () {
        screen.write(-1, 0, 'X');
        // Should not throw, just ignore
        expect(screen.stringAt(0, 0), equals(''));
      });

      test('write ignores out of bounds negative y', () {
        screen.write(0, -1, 'X');
        expect(screen.stringAt(0, 0), equals(''));
      });

      test('write ignores out of bounds x >= width', () {
        screen.write(10, 0, 'X');
        expect(screen.stringAt(9, 0), equals(''));
      });

      test('write ignores out of bounds y >= height', () {
        screen.write(0, 5, 'X');
        expect(screen.stringAt(0, 4), equals(''));
      });

      test('stringAt returns empty for out of bounds', () {
        expect(screen.stringAt(-1, 0), equals(''));
        expect(screen.stringAt(0, -1), equals(''));
        expect(screen.stringAt(10, 0), equals(''));
        expect(screen.stringAt(0, 5), equals(''));
      });
    });

    group('resize', () {
      test('resize changes dimensions', () {
        screen.resize(Size(20, 10));
        expect(screen.width, equals(20));
        expect(screen.height, equals(10));
      });

      test('resize clears buffer', () {
        screen.write(0, 0, 'X');
        screen.resize(Size(20, 10));
        expect(screen.stringAt(0, 0), equals(''));
      });
    });

    group('clear', () {
      test('clear resets all cells', () {
        screen.write(0, 0, 'A');
        screen.write(5, 2, 'B');
        screen.clear();
        expect(screen.stringAt(0, 0), equals(''));
        expect(screen.stringAt(5, 2), equals(''));
        expect(screen.occluded(0, 0), isFalse);
      });
    });

    group('toString', () {
      test('renders empty screen as spaces', () {
        var small = Screen(Size(3, 2));
        expect(small.toString(), equals('   \n   '));
      });

      test('renders written characters', () {
        var small = Screen(Size(3, 2));
        small.write(0, 0, 'A');
        small.write(2, 1, 'B');
        expect(small.toString(), equals('A  \n  B'));
      });
    });

    group('canvas', () {
      test('creates canvas with screen size by default', () {
        var canvas = screen.canvas();
        expect(canvas.width, equals(10));
        expect(canvas.height, equals(5));
        expect(canvas.x, equals(0));
        expect(canvas.y, equals(0));
      });

      test('creates canvas with custom size and offset', () {
        var canvas = screen.canvas(Size(5, 3), Position(2, 1));
        expect(canvas.width, equals(5));
        expect(canvas.height, equals(3));
        expect(canvas.x, equals(2));
        expect(canvas.y, equals(1));
      });
    });

    group('double-buffering', () {
      test('hasWrites is false on fresh screen', () {
        expect(screen.hasWrites, isFalse);
      });

      test('hasWrites is true after write', () {
        screen.write(0, 0, 'A');
        expect(screen.hasWrites, isTrue);
      });

      test('hasWrites resets after clear', () {
        screen.write(0, 0, 'A');
        screen.clear();
        expect(screen.hasWrites, isFalse);
      });

      test('diff returns empty when buffers match', () {
        // Both buffers start empty — diff should be empty.
        expect(screen.diff(), equals(''));
      });

      test('diff returns ANSI-positioned lines for changed rows', () {
        screen.write(0, 0, 'A');
        final patch = screen.diff();
        // Line 1 changed, expect ANSI cursor move + rendered line.
        expect(patch, contains('\x1B[1;1H'));
        expect(patch, contains('A'));
      });

      test('diff skips unchanged lines', () {
        // Write only to row 2 (index 1).
        screen.write(0, 1, 'B');
        final patch = screen.diff();
        // Should contain row 2 cursor move, not row 1.
        expect(patch, contains('\x1B[2;1H'));
        expect(patch, isNot(contains('\x1B[1;1H')));
      });

      test('swapBuffers makes diff return empty', () {
        screen.write(0, 0, 'X');
        screen.swapBuffers();
        // After swap, front == back, diff should be empty.
        expect(screen.diff(), equals(''));
      });

      test('clear + write + diff + swap cycle works', () {
        // Frame 1: write A at (0,0).
        screen.write(0, 0, 'A');
        screen.swapBuffers();

        // Frame 2: clear, write B at (0,0).
        screen.clear();
        screen.write(0, 0, 'B');
        final patch = screen.diff();
        expect(patch, contains('B'));
        screen.swapBuffers();

        // Frame 3: same content — no diff.
        screen.clear();
        screen.write(0, 0, 'B');
        expect(screen.diff(), equals(''));
      });
    });
  });
}
