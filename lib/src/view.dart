part of tui;

/// Base class for all UI components.
///
/// View provides:
/// - Size and position management (via Sizable, Positionable mixins)
/// - Child view hierarchy
/// - Layout through resize() and resize_children()
/// - Rendering through render()
/// - Focus support (focusable, focused, onFocus, onBlur, onKey)
///
/// To create a custom view, extend View and override:
/// - update() to generate text content
/// - resize_children() to customize child layout
/// - onKey() to handle keyboard input when focused
abstract class View extends Object with Sizable, Positionable {
  bool get hasChildren => children.isNotEmpty;

  List<Text> text = [];
  List<View> children = [];

  // ─────────────────────────────────────────────────────────────
  // Focus support
  // ─────────────────────────────────────────────────────────────

  /// Whether this view can receive focus
  bool focusable = false;

  /// Whether this view currently has focus
  bool focused = false;

  /// Called when this view receives focus
  void onFocus() {}

  /// Called when this view loses focus
  void onBlur() {}

  /// Called when a key is pressed while this view has focus.
  /// Return true if the key was handled, false to propagate to parent.
  bool onKey(String key) => false;

  /// Collects all focusable views in tree order (depth-first)
  List<View> get focusableViews {
    var result = <View>[];
    if (focusable) result.add(this);
    for (var child in children) {
      result.addAll(child.focusableViews);
    }
    return result;
  }

  // ─────────────────────────────────────────────────────────────
  // Layout
  // ─────────────────────────────────────────────────────────────

  /// Called when the view is resized.
  ///
  /// This happens when:
  /// 1. App is initially loaded
  /// 2. This view is added to another view
  /// 3. The parent view changes size
  void resize(Size size, Position position) {
    this.size = size;
    this.position = position;
    resize_children();
    update();
  }

  /// Override to update text content when size changes or data updates.
  ///
  /// Called automatically after resize(). Call manually when your
  /// view's data changes and needs to be re-rendered.
  void update() {
    // Override in subclasses
  }

  /// Override to customize how children are sized and positioned.
  ///
  /// Default implementation passes parent's size to all children.
  void resize_children() {
    for (var view in children) {
      view.resize(Size.from(size), view.position);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Rendering
  // ─────────────────────────────────────────────────────────────

  /// Renders this view and its children to the canvas.
  void render(Canvas canvas) {
    render_texts(canvas);
    render_children(canvas);
  }

  /// Renders all text objects to the canvas.
  void render_texts(Canvas canvas) {
    for (var line in text) {
      _render_text(line, canvas);
    }
  }

  /// Renders a single Text object to the canvas with formatting.
  void _render_text(Text text, Canvas canvas) {
    var iter = text.iterator;
    var x = text.x;
    var y = text.y;

    var opened = false;
    var last_x;
    var last_y;

    for (; x < canvas.width; x++) {
      if (iter.moveNext()) {
        if (!canvas.occluded(x, y)) {
          var value = iter.current;

          if (!opened) {
            value = iter.stack.last.node.open() + value;
            opened = true;
          }

          canvas.write(x, y, value);
          last_x = x;
          last_y = y;
        } else if (opened) {
          opened = false;
          String last = canvas.stringAt(last_x, last_y);
          canvas.write(
              last_x, last_y, last + iter.last_stack.map((t) => t.close()).join());
        }
      }
    }
    if (opened && last_x != null && last_y != null) {
      String last = canvas.stringAt(last_x, last_y);
      canvas.write(
          last_x, last_y, last + iter.last_stack.map((t) => t.close()).join());
    }
  }

  /// Renders all child views.
  void render_children(Canvas canvas) {
    for (var view in children) {
      render_child(view, canvas);
    }
  }

  /// Renders a single child view with its own canvas.
  void render_child(View view, Canvas canvas) {
    view.render(canvas.canvas(view.size, view.position));
  }
}
