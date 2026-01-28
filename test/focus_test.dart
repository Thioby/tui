import 'package:test/test.dart';
import 'package:tui/tui.dart';

/// Focusable test view that tracks callbacks
class FocusableView extends View {
  bool onFocusCalled = false;
  bool onBlurCalled = false;
  List<String> keysReceived = [];

  FocusableView() {
    focusable = true;
  }

  @override
  void onFocus() {
    onFocusCalled = true;
  }

  @override
  void onBlur() {
    onBlurCalled = true;
  }

  @override
  bool onKey(String key) {
    keysReceived.add(key);
    return true;
  }
}

/// Non-focusable test view
class NonFocusableView extends View {}

void main() {
  group('View focus properties', () {
    test('focusable defaults to false', () {
      var view = NonFocusableView();
      expect(view.focusable, isFalse);
    });

    test('focused defaults to false', () {
      var view = FocusableView();
      expect(view.focused, isFalse);
    });

    test('focusable can be set to true', () {
      var view = FocusableView();
      expect(view.focusable, isTrue);
    });
  });

  group('focusableViews collection', () {
    test('returns empty list for non-focusable view without children', () {
      var view = NonFocusableView();
      expect(view.focusableViews, isEmpty);
    });

    test('returns self if focusable', () {
      var view = FocusableView();
      var focusable = view.focusableViews;
      expect(focusable.length, equals(1));
      expect(focusable[0], same(view));
    });

    test('collects focusable children recursively', () {
      var parent = NonFocusableView();
      var child1 = FocusableView();
      var child2 = FocusableView();
      parent.children = [child1, child2];

      var focusable = parent.focusableViews;
      expect(focusable.length, equals(2));
      expect(focusable[0], same(child1));
      expect(focusable[1], same(child2));
    });

    test('includes self and children if both focusable', () {
      var parent = FocusableView();
      var child = FocusableView();
      parent.children = [child];

      var focusable = parent.focusableViews;
      expect(focusable.length, equals(2));
      expect(focusable[0], same(parent));
      expect(focusable[1], same(child));
    });

    test('collects deeply nested focusable views in tree order', () {
      // Build tree:
      //   root (non-focusable)
      //   ├── branch1 (non-focusable)
      //   │   ├── leaf1 (focusable)
      //   │   └── leaf2 (focusable)
      //   └── branch2 (focusable)
      //       └── leaf3 (focusable)
      var root = NonFocusableView();
      var branch1 = NonFocusableView();
      var branch2 = FocusableView();
      var leaf1 = FocusableView();
      var leaf2 = FocusableView();
      var leaf3 = FocusableView();

      branch1.children = [leaf1, leaf2];
      branch2.children = [leaf3];
      root.children = [branch1, branch2];

      var focusable = root.focusableViews;
      expect(focusable.length, equals(4));
      expect(focusable[0], same(leaf1));
      expect(focusable[1], same(leaf2));
      expect(focusable[2], same(branch2));
      expect(focusable[3], same(leaf3));
    });

    test('skips non-focusable views in tree', () {
      var root = NonFocusableView();
      var nonFocusable = NonFocusableView();
      var focusableChild = FocusableView();
      root.children = [nonFocusable, focusableChild];

      var focusable = root.focusableViews;
      expect(focusable.length, equals(1));
      expect(focusable[0], same(focusableChild));
    });
  });

  group('onFocus and onBlur callbacks', () {
    test('onFocus is called when focused', () {
      var view = FocusableView();
      expect(view.onFocusCalled, isFalse);
      view.focused = true;
      view.onFocus();
      expect(view.onFocusCalled, isTrue);
    });

    test('onBlur is called when focus is lost', () {
      var view = FocusableView();
      view.focused = true;
      expect(view.onBlurCalled, isFalse);
      view.onBlur();
      expect(view.onBlurCalled, isTrue);
    });
  });

  group('onKey handling', () {
    test('onKey receives key and returns handled status', () {
      var view = FocusableView();
      var handled = view.onKey('a');
      expect(handled, isTrue);
      expect(view.keysReceived, contains('a'));
    });

    test('default onKey returns false (not handled)', () {
      var view = NonFocusableView();
      var handled = view.onKey('a');
      expect(handled, isFalse);
    });
  });

  group('SplitView with focusable children', () {
    test('collects focusable views through SplitView', () {
      var split = SplitView(horizontal: true);
      var left = FocusableView();
      var right = FocusableView();
      split.children = [left, right];

      var focusable = split.focusableViews;
      expect(focusable.length, equals(2));
      expect(focusable[0], same(left));
      expect(focusable[1], same(right));
    });

    test('nested SplitViews collect all focusable views', () {
      var outer = SplitView(horizontal: true);
      var inner = SplitView(horizontal: false);
      var view1 = FocusableView();
      var view2 = FocusableView();
      var view3 = FocusableView();

      inner.children = [view1, view2];
      outer.children = [inner, view3];

      var focusable = outer.focusableViews;
      expect(focusable.length, equals(3));
      expect(focusable[0], same(view1));
      expect(focusable[1], same(view2));
      expect(focusable[2], same(view3));
    });
  });
}
