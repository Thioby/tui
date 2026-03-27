# Focus System + Canvas Clipping — Design Spec

**Date:** 2026-03-27
**Scope:** Fix the two biggest pain points from user feedback — focus propagation in Frame and content clipping.
**Approach:** Canvas-level clipping + hierarchical focus traversal (Approach 1)
**Files changed:** `canvas.dart`, `focus.dart`, `view.dart` (3 files total)
**Files unchanged:** `window.dart`, `widgets.dart`, all widgets

---

## 1. Canvas Clipping

### Problem

`Canvas.write()` delegates directly to `Screen.write()`, which only checks screen bounds. Content longer than a widget's allocated space bleeds through Frame borders and corrupts adjacent widgets. Example: a markdown table with pipe `|` characters or long text lines inside a Frame.

### Root Cause

`Canvas` has `width`/`height` (from `Sizable`) but never checks writes against them. Child canvases created via `canvas(Size, Position)` inherit the parent's `Screen` reference with a combined offset, but no clipping region.

### Solution

Canvas stores absolute clip bounds (`_clipRight`, `_clipBottom`). Every `write()`, `occluded()`, and `stringAt()` checks both local bounds AND clip bounds. Child canvases inherit the intersection of parent clip bounds and their own bounds.

### Design

```dart
class Canvas with Sizable, Positionable {
  final Screen _scr;
  int _clipRight;   // absolute screen X limit (exclusive)
  int _clipBottom;  // absolute screen Y limit (exclusive)

  Canvas(Size size, Position offset, this._scr, [int? clipRight, int? clipBottom]) {
    this.size = size;
    this.position = offset;
    _clipRight = clipRight ?? (offset.x + size.width);
    _clipBottom = clipBottom ?? (offset.y + size.height);
  }

  Canvas canvas(Size size, Position offset) {
    var combined = Position(offset.x + x, offset.y + y);
    return Canvas(
      size, combined, _scr,
      min(combined.x + size.width, _clipRight),
      min(combined.y + size.height, _clipBottom),
    );
  }

  void write(int x, int y, String char) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    var absX = position.x + x;
    var absY = position.y + y;
    if (absX >= _clipRight || absY >= _clipBottom) return;
    _scr.write(absX, absY, char);
  }

  bool occluded(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return true;
    var absX = position.x + x;
    var absY = position.y + y;
    if (absX >= _clipRight || absY >= _clipBottom) return true;
    return _scr.occluded(absX, absY);
  }

  String stringAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return '';
    return _scr.stringAt(position.x + x, position.y + y);
  }
}
```

### Behavior

- Root canvas (from `Screen.canvas()`) has clip bounds = screen size
- Frame creates child canvas → child inherits `min(own bounds, Frame bounds)`
- Nested Frames correctly intersect clip regions
- Text that overflows a widget silently stops rendering at the boundary
- Zero changes to any widget code — clipping is enforced at the Canvas layer

---

## 2. Focus System

### Problem 1: No Focus Propagation

When a child inside a Frame receives focus, `Frame.focused` stays `false`. The border doesn't change to double-line style. Users must manually sync `frame.focused = child.focused`.

### Problem 2: No Focus Group

Frame + its children can't be treated as a single focus unit. There's no way to say "highlight this Frame when anything inside it is focused."

### Root Cause

- `View` has no `parent` reference — the tree is traversable only top-down
- `FocusManager.focus()` sets `focused = true` only on the target view, not on ancestor containers

### Solution

Two changes:
1. Add `View? parent` — set automatically during `resize()` before `resizeChildren()`
2. `FocusManager.focus()` propagates focus state to ancestor Frames via parent chain

### Design

#### Parent Reference (view.dart)

```dart
abstract class View with Sizable, Positionable {
  View? parent;
  // ... existing fields unchanged

  void resize(Size size, Position position) {
    this.size = size;
    this.position = position;
    for (var child in children) {
      child.parent = this;
    }
    resizeChildren();
    update();
  }
}
```

Setting parent in `resize()` means:
- No API changes — `frame.children = [a, b]` still works
- Parent is refreshed every frame, so dynamic child changes are handled
- No need to modify any `resizeChildren()` override

#### Focus Propagation (focus.dart)

When focus moves from viewA to viewB:
- Ancestor Frames of viewA that are NOT ancestors of viewB → `focused = false`
- Ancestor Frames of viewB that were NOT ancestors of viewA → `focused = true`

This correctly handles: nested Frames, focus moving within the same Frame (border doesn't flicker), and focus leaving a Frame.

```dart
mixin FocusManager {
  View? _focused;
  View? get focusedView => _focused;
  View get focusRoot;

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

  Set<Frame> _ancestorFrames(View? view) {
    var frames = <Frame>{};
    var current = view?.parent;
    while (current != null) {
      if (current is Frame) frames.add(current);
      current = current.parent;
    }
    return frames;
  }

  // focusFirst(), focusNext(), focusPrev(), routeKeyToFocused() — unchanged
}
```

### Focus Traversal

Tab traversal is unchanged. `focusableViews` already returns children in depth-first order, which gives natural tab flow:

- Frame with children A, B + standalone C → tab order: A → B → C
- Focus on A: Frame.focused = true (double border)
- Focus on B: Frame stays focused (same ancestor)
- Focus on C: Frame.focused = false (single border)

### Behavior Summary

| Action | Before | After |
|--------|--------|-------|
| Focus child in Frame | Frame.focused = false, must sync manually | Frame.focused = true automatically |
| Tab through Frame children | Works (flat list) | Works (unchanged) |
| Tab out of Frame | Works | Works + Frame.focused auto-resets |
| Nested Frames | Not supported | Inner Frame focused when its child focused, outer Frame also focused |

---

## Backward Compatibility

- **Canvas clipping:** Fully backward compatible. Existing widgets render the same, they just can't overflow anymore.
- **Parent reference:** New `View? parent` field, defaults to null. Set automatically. No API breakage.
- **Focus propagation:** Automatic. Code that manually syncs `frame.focused` will still work but becomes unnecessary.

## Testing Strategy

- **Clipping:** Unit test that writes beyond canvas bounds and verifies Screen cells outside bounds are empty.
- **Focus propagation:** Unit test that focuses a child in a Frame and verifies Frame.focused is true; then focuses outside and verifies it's false.
- **Nested clipping:** Test with Frame-in-Frame, verify inner content doesn't bleed through outer Frame.
- **Nested focus:** Test with Frame-in-Frame, verify both ancestor Frames get focused state.
