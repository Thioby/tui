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
    var oldFocused = _focused;

    _focused?.focused = false;
    _focused = view;
    view.focused = true;

    var newFrames = _ancestorFrames(view);
    for (var frame in oldFrames) {
      if (!newFrames.contains(frame)) frame.focused = false;
    }
    for (var frame in newFrames) {
      if (!oldFrames.contains(frame)) frame.focused = true;
    }

    oldFocused?.onBlur();
    view.onFocus();
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

  bool routeKeyToFocused(String key) => _focused?.onKey(key) ?? false;

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
