import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('Canvas', () {
    late Screen screen;
    late Canvas canvas;

    setUp(() {
      screen = Screen(Size(20, 10));
      canvas = screen.canvas();
    });

    group('initialization', () {
      test('has correct size from screen', () {
        expect(canvas.width, equals(20));
        expect(canvas.height, equals(10));
      });

      test('has zero position by default', () {
        expect(canvas.x, equals(0));
        expect(canvas.y, equals(0));
      });

      test('custom canvas has specified size and position', () {
        var custom = screen.canvas(Size(10, 5), Position(3, 2));
        expect(custom.width, equals(10));
        expect(custom.height, equals(5));
        expect(custom.x, equals(3));
        expect(custom.y, equals(2));
      });
    });

    group('write delegation', () {
      test('write at 0,0 writes to screen at canvas position', () {
        var offsetCanvas = screen.canvas(Size(10, 5), Position(5, 3));
        offsetCanvas.write(0, 0, 'X');
        expect(screen.stringAt(5, 3), equals('X'));
      });

      test('write adds canvas offset to coordinates', () {
        var offsetCanvas = screen.canvas(Size(10, 5), Position(2, 1));
        offsetCanvas.write(3, 2, 'Y');
        expect(screen.stringAt(5, 3), equals('Y')); // 2+3=5, 1+2=3
      });

      test('write at origin canvas goes to screen origin', () {
        canvas.write(0, 0, 'A');
        expect(screen.stringAt(0, 0), equals('A'));
      });
    });

    group('occluded delegation', () {
      test('occluded checks screen with offset applied', () {
        var offsetCanvas = screen.canvas(Size(10, 5), Position(5, 3));
        expect(offsetCanvas.occluded(0, 0), isFalse);
        screen.write(5, 3, 'X');
        expect(offsetCanvas.occluded(0, 0), isTrue);
      });

      test('occluded returns true for out of bounds via screen', () {
        // Canvas at offset 15,8 on 20x10 screen
        var edgeCanvas = screen.canvas(Size(10, 5), Position(15, 8));
        // Writing at 5,2 would be 20,10 on screen - out of bounds
        expect(edgeCanvas.occluded(5, 2), isTrue);
      });
    });

    group('stringAt delegation', () {
      test('stringAt reads from screen with offset', () {
        screen.write(7, 4, 'Z');
        var offsetCanvas = screen.canvas(Size(10, 5), Position(5, 3));
        expect(offsetCanvas.stringAt(2, 1), equals('Z')); // 5+2=7, 3+1=4
      });
    });

    group('nested canvas', () {
      test('canvas creates child canvas with combined offset', () {
        var parent = screen.canvas(Size(15, 8), Position(2, 1));
        var child = parent.canvas(Size(10, 5), Position(3, 2));

        expect(child.width, equals(10));
        expect(child.height, equals(5));
        expect(child.x, equals(5)); // 2+3
        expect(child.y, equals(3)); // 1+2
      });

      test('nested canvas write goes to correct screen position', () {
        var parent = screen.canvas(Size(15, 8), Position(2, 1));
        var child = parent.canvas(Size(10, 5), Position(3, 2));
        child.write(1, 1, 'N');
        expect(screen.stringAt(6, 4), equals('N')); // 2+3+1=6, 1+2+1=4
      });

      test('deeply nested canvas accumulates offsets', () {
        var level1 = screen.canvas(Size(18, 9), Position(1, 0));
        var level2 = level1.canvas(Size(15, 7), Position(1, 1));
        var level3 = level2.canvas(Size(10, 5), Position(2, 1));

        expect(level3.x, equals(4)); // 1+1+2
        expect(level3.y, equals(2)); // 0+1+1

        level3.write(0, 0, 'D');
        expect(screen.stringAt(4, 2), equals('D'));
      });
    });

    group('bounds safety with offset', () {
      test('negative local coordinates are clipped', () {
        var offsetCanvas = screen.canvas(Size(10, 5), Position(5, 5));
        offsetCanvas.write(-2, -2, 'V');
        // Negative local coords should be rejected
        expect(screen.stringAt(3, 3), equals(''));
      });

      test('out of screen bounds is handled gracefully', () {
        var offsetCanvas = screen.canvas(Size(10, 5), Position(18, 8));
        // Writing at 5,5 would be 23,13 - out of bounds, should be ignored
        offsetCanvas.write(5, 5, 'X');
        // Should not throw
        expect(screen.occluded(19, 9), isFalse);
      });
    });

    group('clipping', () {
      test('rejects write at negative local x', () {
        var child = screen.canvas(Size(10, 5), Position(5, 5));
        child.write(-1, 0, 'X');
        expect(screen.stringAt(4, 5), equals(''));
      });

      test('rejects write at negative local y', () {
        var child = screen.canvas(Size(10, 5), Position(5, 5));
        child.write(0, -1, 'X');
        expect(screen.stringAt(5, 4), equals(''));
      });

      test('rejects write at x >= width', () {
        var child = screen.canvas(Size(5, 5), Position(0, 0));
        child.write(5, 0, 'X');
        expect(screen.stringAt(5, 0), equals(''));
      });

      test('rejects write at y >= height', () {
        var child = screen.canvas(Size(5, 5), Position(0, 0));
        child.write(0, 5, 'X');
        expect(screen.stringAt(0, 5), equals(''));
      });

      test('allows write within local bounds', () {
        var child = screen.canvas(Size(5, 5), Position(2, 2));
        child.write(4, 4, 'V');
        expect(screen.stringAt(6, 6), equals('V'));
      });

      test('child canvas clips to parent bounds', () {
        // Parent occupies screen columns 2-11 (width 10 at offset 2)
        var parent = screen.canvas(Size(10, 5), Position(2, 0));
        // Child thinks it has width 8 starting at offset 5 within parent
        // Absolute: 2+5=7, so child occupies screen columns 7-14
        // But parent ends at column 11, so writes at x>=5 should be clipped
        var child = parent.canvas(Size(8, 3), Position(5, 0));
        child.write(0, 0, 'A'); // abs 7 — within parent, OK
        child.write(4, 0, 'B'); // abs 11 — within parent (< clipRight 12), OK
        child.write(5, 0, 'C'); // abs 12 — clipped (>= clipRight 12)

        expect(screen.stringAt(7, 0), equals('A'));
        expect(screen.stringAt(11, 0), equals('B'));
        expect(screen.stringAt(12, 0), equals(''));
      });

      test('nested canvases intersect clip bounds', () {
        // Screen is 20x10
        // Level 1: width 15 at offset 0 → clipRight=15
        var level1 = screen.canvas(Size(15, 8), Position(0, 0));
        // Level 2: width 12 at offset 5 within level1 → abs 5, clipRight=min(17,15)=15
        var level2 = level1.canvas(Size(12, 6), Position(5, 0));
        // Level 3: width 10 at offset 3 within level2 → abs 8, clipRight=min(18,15)=15
        var level3 = level2.canvas(Size(10, 4), Position(3, 0));

        level3.write(0, 0, 'X'); // abs 8 — OK
        level3.write(6, 0, 'Y'); // abs 14 — OK (< 15)
        level3.write(7, 0, 'Z'); // abs 15 — clipped (>= 15)

        expect(screen.stringAt(8, 0), equals('X'));
        expect(screen.stringAt(14, 0), equals('Y'));
        expect(screen.stringAt(15, 0), equals(''));
      });

      test('occluded returns true for out-of-bounds local coords', () {
        var child = screen.canvas(Size(5, 5), Position(0, 0));
        expect(child.occluded(-1, 0), isTrue);
        expect(child.occluded(0, -1), isTrue);
        expect(child.occluded(5, 0), isTrue);
        expect(child.occluded(0, 5), isTrue);
      });

      test('occluded respects clip bounds', () {
        var parent = screen.canvas(Size(10, 5), Position(0, 0));
        var child = parent.canvas(Size(15, 3), Position(5, 0));
        // child at abs 5, clipRight=min(20,10)=10
        // Local x=5 → abs 10, which is >= clipRight
        expect(child.occluded(5, 0), isTrue);
        // Local x=4 → abs 9, which is < clipRight
        expect(child.occluded(4, 0), isFalse);
      });

      test('stringAt returns empty for out-of-bounds local coords', () {
        var child = screen.canvas(Size(5, 5), Position(0, 0));
        expect(child.stringAt(-1, 0), equals(''));
        expect(child.stringAt(5, 0), equals(''));
        expect(child.stringAt(0, -1), equals(''));
        expect(child.stringAt(0, 5), equals(''));
      });

      test('stringAt respects clip bounds', () {
        var parent = screen.canvas(Size(10, 5), Position(0, 0));
        screen.write(12, 0, 'Z');
        var child = parent.canvas(Size(15, 3), Position(5, 0));
        // child at abs 5, clipRight=min(20,10)=10
        // Local x=7 → abs 12, which is >= clipRight
        expect(child.stringAt(7, 0), equals(''));
        // Local x=4 → abs 9, which is < clipRight
        expect(child.stringAt(4, 0), equals(''));
      });
    });

    group('position immutability', () {
      test('canvas() does not mutate passed Position object', () {
        var parent = screen.canvas(Size(15, 8), Position(2, 1));
        var childOffset = Position(3, 2);

        // Store original values
        var originalX = childOffset.x;
        var originalY = childOffset.y;

        // Create child canvas
        parent.canvas(Size(10, 5), childOffset);

        // Verify passed Position was not mutated
        expect(childOffset.x, equals(originalX));
        expect(childOffset.y, equals(originalY));
      });

      test('nested canvas calls do not accumulate mutations', () {
        var level1 = screen.canvas(Size(18, 9), Position(1, 0));
        var offset = Position(2, 2);

        level1.canvas(Size(15, 7), offset);
        level1.canvas(Size(15, 7), offset);

        // If mutations accumulated, offset would be wrong
        expect(offset.x, equals(2));
        expect(offset.y, equals(2));
      });
    });
  });
}
