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

    _focused?.focused = false;
    _focused?.onBlur();

    _focused = view;
    view.focused = true;
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

  bool routeKeyToFocused(String key) {
    if (_focused != null && _focused!.onKey(key)) {
      return true;
    }
    return false;
  }
}