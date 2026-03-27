# Focus System + Canvas Clipping — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix canvas clipping so content can't bleed outside widget bounds, and add automatic focus propagation to ancestor Frames.

**Architecture:** Canvas gets clip bounds (absolute screen coordinates) that are intersected when creating child canvases. View gets a parent reference set during resize(). FocusManager propagates focused state to ancestor Frames when focus changes.

**Tech Stack:** Dart, `package:test`

---

### Task 1: Canvas Clipping — Tests

**Files:**
- Modify: `test/canvas_test.dart`

- [ ] **Step 1: Add clipping test group to canvas_test.dart**

Add these tests at the end of the `'Canvas'` group, before the closing `});`:

```dart
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
});
```

- [ ] **Step 2: Update existing test that relies on negative local coords**

The test `'negative coordinates with positive offset still work'` in the `'bounds safety with offset'` group writes at (-2, -2) and expects it to work. With clipping, negative local coords are correctly rejected. Update this test:

Replace the entire `'bounds safety with offset'` group:

```dart
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
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `dart test test/canvas_test.dart -v`

Expected: New clipping tests fail (Canvas doesn't clip yet). The updated negative-coords test should actually pass already since Screen.write rejects out-of-screen-bounds.

---

### Task 2: Canvas Clipping — Implementation

**Files:**
- Modify: `lib/src/canvas.dart`

- [ ] **Step 1: Implement clipping in Canvas**

Replace the entire content of `lib/src/canvas.dart` with:

```dart
part of tui;

/// A Canvas provides constrained read/write access to the [Screen].
///
/// All writes are clipped to the canvas bounds AND the inherited
/// clip region from the parent canvas.
class Canvas with Sizable, Positionable {
  final Screen _scr;
  int _clipRight;
  int _clipBottom;

  Canvas(Size size, Position offset, this._scr, [int? clipRight, int? clipBottom]) {
    this.size = size;
    this.position = offset;
    _clipRight = clipRight ?? (offset.x + size.width);
    _clipBottom = clipBottom ?? (offset.y + size.height);
  }

  Canvas canvas(Size size, Position offset) {
    var combinedOffset = Position(offset.x + x, offset.y + y);
    return Canvas(
      size,
      combinedOffset,
      _scr,
      min(combinedOffset.x + size.width, _clipRight),
      min(combinedOffset.y + size.height, _clipBottom),
    );
  }

  bool occluded(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return true;
    var absX = position.x + x;
    var absY = position.y + y;
    if (absX >= _clipRight || absY >= _clipBottom) return true;
    return _scr.occluded(absX, absY);
  }

  void write(int x, int y, String char) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    var absX = position.x + x;
    var absY = position.y + y;
    if (absX >= _clipRight || absY >= _clipBottom) return;
    _scr.write(absX, absY, char);
  }

  String stringAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return '';
    return _scr.stringAt(position.x + x, position.y + y);
  }
}
```

- [ ] **Step 2: Run canvas tests to verify they pass**

Run: `dart test test/canvas_test.dart -v`

Expected: All tests pass, including new clipping tests.

- [ ] **Step 3: Run all tests to verify nothing broke**

Run: `dart test`

Expected: All 68 tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/src/canvas.dart test/canvas_test.dart
git commit -m "add canvas clipping"
```

---

### Task 3: Parent Reference — Tests

**Files:**
- Modify: `test/view_test.dart`

- [ ] **Step 1: Add parent reference tests to view_test.dart**

Add this group inside the `'View'` group, after the `'children'` group:

```dart
group('parent reference', () {
  test('parent is null by default', () {
    var view = TestView();
    expect(view.parent, isNull);
  });

  test('resize sets parent on children', () {
    var parent = TestView();
    var child1 = TestView();
    var child2 = TestView();
    parent.children = [child1, child2];

    parent.resize(Size(80, 40), Position(0, 0));

    expect(child1.parent, same(parent));
    expect(child2.parent, same(parent));
  });

  test('resize updates parent when children change', () {
    var parent1 = TestView();
    var parent2 = TestView();
    var child = TestView();

    parent1.children = [child];
    parent1.resize(Size(80, 40), Position(0, 0));
    expect(child.parent, same(parent1));

    parent2.children = [child];
    parent2.resize(Size(80, 40), Position(0, 0));
    expect(child.parent, same(parent2));
  });

  test('nested resize sets parent chain', () {
    var grandparent = TestView();
    var parent = TestView();
    var child = TestView();

    parent.children = [child];
    grandparent.children = [parent];

    grandparent.resize(Size(80, 40), Position(0, 0));

    expect(parent.parent, same(grandparent));
    expect(child.parent, same(parent));
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `dart test test/view_test.dart -v --name "parent reference"`

Expected: Fail — `View` has no `parent` field yet.

---

### Task 4: Parent Reference — Implementation

**Files:**
- Modify: `lib/src/view.dart`

- [ ] **Step 1: Add parent field and set it in resize**

In `lib/src/view.dart`, add `View? parent;` field after line 8 (`List<View> children = [];`) and update `resize()` to set parent on children:

Add after `List<View> children = [];`:

```dart
View? parent;
```

Replace the `resize` method:

```dart
void resize(Size size, Position position) {
  this.size = size;
  this.position = position;
  for (var child in children) {
    child.parent = this;
  }
  resizeChildren();
  update();
}
```

- [ ] **Step 2: Run view tests to verify they pass**

Run: `dart test test/view_test.dart -v`

Expected: All tests pass including new parent reference tests.

- [ ] **Step 3: Run all tests to verify nothing broke**

Run: `dart test`

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/src/view.dart test/view_test.dart
git commit -m "add parent reference to View"
```

---

### Task 5: Focus Propagation — Tests

**Files:**
- Modify: `test/focus_test.dart`

- [ ] **Step 1: Add focus propagation tests to focus_test.dart**

Add this group inside `main()`, after the `'FocusManager mixin'` group:

```dart
group('Focus propagation to Frame', () {
  late NonFocusableView root;
  late TestFocusContainer manager;

  test('Frame.focused is true when child inside it is focused', () {
    root = NonFocusableView();
    var frame = Frame();
    var child = FocusableView();
    frame.children = [child];
    root.children = [frame];
    root.resize(Size(80, 40), Position(0, 0));
    manager = TestFocusContainer(root);

    manager.focus(child);

    expect(child.focused, isTrue);
    expect(frame.focused, isTrue);
  });

  test('Frame.focused is false when focus moves outside', () {
    root = NonFocusableView();
    var frame = Frame();
    var child = FocusableView();
    var outside = FocusableView();
    frame.children = [child];
    root.children = [frame, outside];
    root.resize(Size(80, 40), Position(0, 0));
    manager = TestFocusContainer(root);

    manager.focus(child);
    expect(frame.focused, isTrue);

    manager.focus(outside);
    expect(frame.focused, isFalse);
  });

  test('Frame stays focused when focus moves between its children', () {
    root = NonFocusableView();
    var frame = Frame();
    var child1 = FocusableView();
    var child2 = FocusableView();
    frame.children = [child1, child2];
    root.children = [frame];
    root.resize(Size(80, 40), Position(0, 0));
    manager = TestFocusContainer(root);

    manager.focus(child1);
    expect(frame.focused, isTrue);

    manager.focus(child2);
    expect(frame.focused, isTrue);
  });

  test('nested Frames: both ancestor Frames get focused', () {
    root = NonFocusableView();
    var outerFrame = Frame();
    var innerFrame = Frame();
    var child = FocusableView();
    innerFrame.children = [child];
    outerFrame.children = [innerFrame];
    root.children = [outerFrame];
    root.resize(Size(80, 40), Position(0, 0));
    manager = TestFocusContainer(root);

    manager.focus(child);

    expect(innerFrame.focused, isTrue);
    expect(outerFrame.focused, isTrue);
  });

  test('nested Frames: inner unfocuses when focus moves to outer-only child', () {
    root = NonFocusableView();
    var outerFrame = Frame();
    var innerFrame = Frame();
    var innerChild = FocusableView();
    var outerChild = FocusableView();
    innerFrame.children = [innerChild];
    outerFrame.children = [innerFrame, outerChild];
    root.children = [outerFrame];
    root.resize(Size(80, 40), Position(0, 0));
    manager = TestFocusContainer(root);

    manager.focus(innerChild);
    expect(innerFrame.focused, isTrue);
    expect(outerFrame.focused, isTrue);

    manager.focus(outerChild);
    expect(innerFrame.focused, isFalse);
    expect(outerFrame.focused, isTrue);
  });

  test('focusNext propagates focus to Frames correctly', () {
    root = NonFocusableView();
    var frame = Frame();
    var child1 = FocusableView();
    var child2 = FocusableView();
    var outside = FocusableView();
    frame.children = [child1, child2];
    root.children = [frame, outside];
    root.resize(Size(80, 40), Position(0, 0));
    manager = TestFocusContainer(root);

    manager.focusFirst(); // child1
    expect(frame.focused, isTrue);

    manager.focusNext(); // child2
    expect(frame.focused, isTrue);

    manager.focusNext(); // outside
    expect(frame.focused, isFalse);

    manager.focusNext(); // back to child1
    expect(frame.focused, isTrue);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `dart test test/focus_test.dart -v --name "Focus propagation"`

Expected: Fail — `FocusManager.focus()` doesn't propagate to Frames yet.

---

### Task 6: Focus Propagation — Implementation

**Files:**
- Modify: `lib/src/focus.dart`

- [ ] **Step 1: Update FocusManager with focus propagation**

Replace the entire content of `lib/src/focus.dart` with:

```dart
part of tui;

/// Mixin that provides focus management for a container of Views.
mixin FocusManager {
  View? _focused;
  View? get focusedView => _focused;

  View get focusRoot;

  void focusFirst() {
    var views = focusRoot.focusableViews;
    if (views.isNotEmpty) {
      focus(views.first);
    }
  }

  void focus(View view) {
    if (!view.focusable) return;
    if (_focused == view) return;

    var oldFrames = _ancestorFrames(_focused);

    _focused?.focused = false;
    _focused?.onBlur();

    _focused = view;
    view.focused = true;
    view.onFocus();

    var newFrames = _ancestorFrames(view);

    for (var frame in oldFrames) {
      if (!newFrames.contains(frame)) frame.focused = false;
    }
    for (var frame in newFrames) {
      if (!oldFrames.contains(frame)) frame.focused = true;
    }
  }

  void focusNext() {
    var views = focusRoot.focusableViews;
    if (views.isEmpty) return;

    if (_focused == null) {
      focus(views.first);
      return;
    }

    var idx = views.indexOf(_focused!);
    var nextIdx = (idx + 1) % views.length;
    focus(views[nextIdx]);
  }

  void focusPrev() {
    var views = focusRoot.focusableViews;
    if (views.isEmpty) return;

    if (_focused == null) {
      focus(views.last);
      return;
    }

    var idx = views.indexOf(_focused!);
    var prevIdx = (idx - 1 + views.length) % views.length;
    focus(views[prevIdx]);
  }

  bool routeKeyToFocused(String key) {
    if (_focused != null && _focused!.onKey(key)) {
      return true;
    }
    return false;
  }

  Set<Frame> _ancestorFrames(View? view) {
    var frames = <Frame>{};
    var current = view?.parent;
    while (current != null) {
      if (current is Frame) frames.add(current);
      current = current.parent;
    }
    return frames;
  }
}
```

- [ ] **Step 2: Run focus tests to verify they pass**

Run: `dart test test/focus_test.dart -v`

Expected: All tests pass including new focus propagation tests.

- [ ] **Step 3: Run all tests to verify nothing broke**

Run: `dart test`

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/src/focus.dart test/focus_test.dart
git commit -m "add focus propagation to ancestor Frames"
```
