part of tui;

/// Base class for all UI components.
///
/// Provides size/position management, hierarchy handling, layout,
/// rendering, and focus support.
abstract class View with Sizable, Positionable {
  bool get hasChildren => children.isNotEmpty;

  List<Text> text = [];
  List<View> children = [];

  bool focusable = false;
  bool focused = false;

  void onFocus() {}
  void onBlur() {}

  /// Called when a key is pressed while focused.
  /// Returns true if handled.
  bool onKey(String key) => false;

  List<View> get focusableViews {
    final result = <View>[];
    if (focusable) result.add(this);
    for (var child in children) {
      result.addAll(child.focusableViews);
    }
    return result;
  }

  void resize(Size size, Position position) {
    this.size = size;
    this.position = position;
    resizeChildren();
    update();
  }

  /// Update text content. Called automatically after resize.
  void update() {}

  void resizeChildren() {
    for (var view in children) {
      view.resize(Size.from(size), view.position);
    }
  }

  void render(Canvas canvas) {
    renderTexts(canvas);
    renderChildren(canvas);
  }

  void renderTexts(Canvas canvas) {
    for (var line in text) {
      _renderText(line, canvas);
    }
  }

  void _renderText(Text text, Canvas canvas) {
    var iter = text.iterator;
    var x = text.x;
    var y = text.y;

    var opened = false;
    int? lastX;
    int? lastY;

    for (; x < canvas.width; x++) {
      if (iter.moveNext()) {
        if (!canvas.occluded(x, y)) {
          var value = iter.current;

          if (!opened) {
            value = iter.stack.last.node.open() + value;
            opened = true;
          }

          canvas.write(x, y, value);
          lastX = x;
          lastY = y;
        } else if (opened) {
          opened = false;
          final last = canvas.stringAt(lastX!, lastY!);
          canvas.write(lastX, lastY, last + iter.lastStack.map((t) => t.close()).join());
        }
      }
    }
    if (opened && lastX != null && lastY != null) {
      final last = canvas.stringAt(lastX, lastY);
      canvas.write(lastX, lastY, last + iter.lastStack.map((t) => t.close()).join());
    }
  }

  void renderChildren(Canvas canvas) {
    for (var view in children) {
      renderChild(view, canvas);
    }
  }

  void renderChild(View view, Canvas canvas) {
    view.render(canvas.canvas(view.size, view.position));
  }
}
