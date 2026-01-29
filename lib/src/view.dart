part of tui;

/// Base class for all UI components.
abstract class View with Sizable, Positionable {
  bool get hasChildren => children.isNotEmpty;

  List<Text> text = [];
  List<View> children = [];

  bool focusable = false;
  bool focused = false;

  void onFocus() {}
  void onBlur() {}

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
      _drawTxt(line, canvas);
    }
  }

  void _drawTxt(Text text, Canvas canvas) {
    var it = text.iterator;
    var x = text.x;
    var y = text.y;

    var opened = false;
    int? prevX;
    int? prevY;

    for (; x < canvas.width; x++) {
      if (it.moveNext()) {
        if (!canvas.occluded(x, y)) {
          var val = it.current;

          if (!opened) {
            val = it.stack.last.node.open() + val;
            opened = true;
          }

          canvas.write(x, y, val);
          prevX = x;
          prevY = y;
        } else if (opened) {
          opened = false;
          final last = canvas.stringAt(prevX!, prevY!);
          canvas.write(prevX, prevY, last + it.lastStack.map((t) => t.close()).join());
        }
      }
    }
    if (opened && prevX != null && prevY != null) {
      final last = canvas.stringAt(prevX, prevY);
      canvas.write(prevX, prevY, last + it.lastStack.map((t) => t.close()).join());
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