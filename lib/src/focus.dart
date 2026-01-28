part of tui;

/// Mixin that provides focus management for a container of Views.
///
/// Use this mixin in classes that need to manage focus across
/// multiple focusable child views.
mixin FocusManager {
  /// Currently focused view (null if no view has focus)
  View? _focusedView;
  View? get focusedView => _focusedView;

  /// Override to provide the root view for focus traversal
  View get focusRoot;

  /// Focus the first focusable view
  void focusFirst() {
    var views = focusRoot.focusableViews;
    if (views.isNotEmpty) {
      focus(views.first);
    }
  }

  /// Focus a specific view
  void focus(View view) {
    if (!view.focusable) return;
    if (_focusedView == view) return;

    _focusedView?.focused = false;
    _focusedView?.onBlur();

    _focusedView = view;
    view.focused = true;
    view.onFocus();
  }

  /// Focus the next focusable view (cycles to first after last)
  void focusNext() {
    var views = focusRoot.focusableViews;
    if (views.isEmpty) return;

    if (_focusedView == null) {
      focus(views.first);
      return;
    }

    var idx = views.indexOf(_focusedView!);
    var nextIdx = (idx + 1) % views.length;
    focus(views[nextIdx]);
  }

  /// Focus the previous focusable view (cycles to last after first)
  void focusPrev() {
    var views = focusRoot.focusableViews;
    if (views.isEmpty) return;

    if (_focusedView == null) {
      focus(views.last);
      return;
    }

    var idx = views.indexOf(_focusedView!);
    var prevIdx = (idx - 1 + views.length) % views.length;
    focus(views[prevIdx]);
  }

  /// Route a key event to the focused view.
  /// Returns true if the key was handled.
  bool routeKeyToFocused(String key) {
    if (_focusedView != null && _focusedView!.onKey(key)) {
      return true;
    }
    return false;
  }
}
