import 'package:test/test.dart';
import 'package:tui/tui.dart';

/// Simple concrete View for testing
class TestView extends View {
  bool updateCalled = false;

  @override
  void update() {
    updateCalled = true;
  }
}

void main() {
  group('View', () {
    group('resize', () {
      test('sets size and position', () {
        var view = TestView();
        view.resize(Size(100, 50), Position(10, 5));

        expect(view.width, equals(100));
        expect(view.height, equals(50));
        expect(view.x, equals(10));
        expect(view.y, equals(5));
      });

      test('calls update after resize', () {
        var view = TestView();
        expect(view.updateCalled, isFalse);
        view.resize(Size(100, 50), Position(0, 0));
        expect(view.updateCalled, isTrue);
      });

      test('resizes children with parent size', () {
        var parent = TestView();
        var child = TestView();
        parent.children = [child];

        parent.resize(Size(80, 40), Position(0, 0));

        // Default resize_children passes parent size to children
        expect(child.width, equals(80));
        expect(child.height, equals(40));
      });
    });

    group('children', () {
      test('hasChildren returns false when empty', () {
        var view = TestView();
        expect(view.hasChildren, isFalse);
      });

      test('hasChildren returns true with children', () {
        var view = TestView();
        view.children = [TestView()];
        expect(view.hasChildren, isTrue);
      });
    });
  });

  group('SplitView', () {
    group('horizontal split', () {
      test('divides width equally by default', () {
        var split = SplitView(horizontal: true);
        var child1 = TestView();
        var child2 = TestView();
        split.children = [child1, child2];

        split.resize(Size(100, 50), Position(0, 0));

        expect(child1.width, equals(50));
        expect(child2.width, equals(50));
        expect(child1.height, equals(50));
        expect(child2.height, equals(50));
      });

      test('positions children side by side', () {
        var split = SplitView(horizontal: true);
        var child1 = TestView();
        var child2 = TestView();
        split.children = [child1, child2];

        split.resize(Size(100, 50), Position(0, 0));

        expect(child1.x, equals(0));
        expect(child2.x, equals(50));
        expect(child1.y, equals(0));
        expect(child2.y, equals(0));
      });

      test('respects custom ratios', () {
        var split = SplitView(horizontal: true, ratios: [1, 2, 1]);
        var child1 = TestView();
        var child2 = TestView();
        var child3 = TestView();
        split.children = [child1, child2, child3];

        split.resize(Size(100, 50), Position(0, 0));

        // 1:2:1 ratio of 100 = 25:50:25
        expect(child1.width, equals(25));
        expect(child2.width, equals(50));
        expect(child3.width, equals(25));

        expect(child1.x, equals(0));
        expect(child2.x, equals(25));
        expect(child3.x, equals(75));
      });

      test('handles three equal children', () {
        var split = SplitView(horizontal: true);
        var children = [TestView(), TestView(), TestView()];
        split.children = children;

        split.resize(Size(90, 30), Position(0, 0));

        expect(children[0].width, equals(30));
        expect(children[1].width, equals(30));
        expect(children[2].width, equals(30));

        expect(children[0].x, equals(0));
        expect(children[1].x, equals(30));
        expect(children[2].x, equals(60));
      });
    });

    group('vertical split', () {
      test('divides height equally by default', () {
        var split = SplitView(horizontal: false);
        var child1 = TestView();
        var child2 = TestView();
        split.children = [child1, child2];

        split.resize(Size(100, 50), Position(0, 0));

        expect(child1.height, equals(25));
        expect(child2.height, equals(25));
        expect(child1.width, equals(100));
        expect(child2.width, equals(100));
      });

      test('positions children stacked vertically', () {
        var split = SplitView(horizontal: false);
        var child1 = TestView();
        var child2 = TestView();
        split.children = [child1, child2];

        split.resize(Size(100, 50), Position(0, 0));

        expect(child1.x, equals(0));
        expect(child2.x, equals(0));
        expect(child1.y, equals(0));
        expect(child2.y, equals(25));
      });

      test('respects custom ratios vertically', () {
        var split = SplitView(horizontal: false, ratios: [1, 3]);
        var child1 = TestView();
        var child2 = TestView();
        split.children = [child1, child2];

        split.resize(Size(100, 80), Position(0, 0));

        // 1:3 ratio of 80 = 20:60
        expect(child1.height, equals(20));
        expect(child2.height, equals(60));

        expect(child1.y, equals(0));
        expect(child2.y, equals(20));
      });
    });

    group('edge cases', () {
      test('handles empty children', () {
        var split = SplitView(horizontal: true);
        // Should not throw
        split.resize(Size(100, 50), Position(0, 0));
      });

      test('handles single child', () {
        var split = SplitView(horizontal: true);
        var child = TestView();
        split.children = [child];

        split.resize(Size(100, 50), Position(0, 0));

        expect(child.width, equals(100));
        expect(child.height, equals(50));
        expect(child.x, equals(0));
      });

      test('handles more children than ratios', () {
        var split = SplitView(horizontal: true, ratios: [2, 1]);
        var children = [TestView(), TestView(), TestView()];
        split.children = children;

        split.resize(Size(100, 50), Position(0, 0));

        // First two use ratios 2:1, third defaults to 1
        // Total ratio: 2+1+1 = 4, so 50:25:25
        expect(children[0].width, equals(50));
        expect(children[1].width, equals(25));
        expect(children[2].width, equals(25));
      });
    });
  });

  group('ProgressBar', () {
    group('value clamping', () {
      test('clamps value to 0-1 range', () {
        var bar = ProgressBar();

        bar.value = 0.5;
        expect(bar.value, equals(0.5));

        bar.value = 1.5;
        expect(bar.value, equals(1.0));

        bar.value = -0.5;
        expect(bar.value, equals(0.0));
      });

      test('accepts boundary values', () {
        var bar = ProgressBar();

        bar.value = 0.0;
        expect(bar.value, equals(0.0));

        bar.value = 1.0;
        expect(bar.value, equals(1.0));
      });
    });

    group('properties', () {
      test('has default properties', () {
        var bar = ProgressBar();
        expect(bar.showPercent, isTrue);
        expect(bar.color, equals('2'));
        expect(bar.filledChar, equals('█'));
        expect(bar.emptyChar, equals('░'));
      });

      test('allows customization', () {
        var bar = ProgressBar()
          ..showPercent = false
          ..color = '1'
          ..label = 'Test';

        expect(bar.showPercent, isFalse);
        expect(bar.color, equals('1'));
        expect(bar.label, equals('Test'));
      });
    });
  });

  group('Box', () {
    test('reduces child size by 4 in each dimension', () {
      var box = Box('*', '1');
      var child = TestView();
      box.children = [child];

      box.resize(Size(20, 10), Position(0, 0));

      expect(child.width, equals(16));  // 20 - 4
      expect(child.height, equals(6));   // 10 - 4
    });

    test('positions child at offset 2,2', () {
      var box = Box('*', '1');
      var child = TestView();
      box.children = [child];

      box.resize(Size(20, 10), Position(0, 0));

      expect(child.x, equals(2));
      expect(child.y, equals(2));
    });
  });

  group('CenteredText', () {
    test('creates text at centered position', () {
      var centered = CenteredText('Hello');
      centered.resize(Size(20, 10), Position(0, 0));

      expect(centered.text.length, equals(1));
      // "Hello" is 5 chars, width is 20
      // x = (20/2) - (5/2) = 10 - 2.5 = 7
      expect(centered.text[0].x, equals(7));
      // y = (10/2) - 1 = 4
      expect(centered.text[0].y, equals(4));
    });
  });
}
