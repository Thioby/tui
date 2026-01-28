part of tui;

abstract class View extends Object with Sizable, Positionable {

  bool get hasChildren => children.isNotEmpty;

  List<Text> text = [];
  List<View> children = [];

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

  /// Collects all focusable views in tree order
  List<View> get focusableViews {
    var result = <View>[];
    if (focusable) result.add(this);
    for (var child in children) {
      result.addAll(child.focusableViews);
    }
    return result;
  }

  // The update() method is called by resize() or from your
  // own code when something about the data this view represents
  // changes. Common thing is to use this in callbacks for async
  // events that modify data
  //
  //  async_op().then((data) { view.data = data; view.update() }
  //
  // If update() is of any complexity and you have multiples async calls then
  // reduce the number of calls to update() by waiting for all operations to finish,
  // on the other hand if the async operations will take a long time and you want
  // the screen to update with at least partial results, then go ahead and call update()
  // with each async completion.
  //
  // var async1 = async_op();
  // var async2 = async_op2();
  // new Future.wait([async1,async2]).then(update);
  //
  void update() {
    // called when resize happens or new data is available for this view
    // update text objects
  }

  // passed in Size with available size
  // the View should save the size
  // a parent View will use this to get an idea of what the size requirements
  // are of its child elements, after all children have been resized
  // it will then pass in Canvas object of that size to render()
  // it is okay to modify the size during this function call,
  // the parent will check for changes in size (making it smaller)
  // to adjust other children or do something else

  // called when:
  // 1. app is initially loaded
  // 2. this view is added to another view
  // 3. the parent view changes size
  void resize(Size size, Position position) {
    this.size = size;
    this.position = position;
    resize_children();
    update();
  }

  void render(Canvas canvas) {
    render_texts(canvas);
    render_children(canvas);
  }

  void render_texts(Canvas canvas) {
    for (var line in text) {
      render_text(line, canvas);
    }
  }

  // 1. Writes the text object to Canvas
  void render_text(Text text, Canvas canvas) {

    var iter = text.iterator;
    var x = text.x;
    var y = text.y;

    var opened = false;
    var last_x;
    var last_y;

    for (;x < canvas.width; x++) {

      if (iter.moveNext()) {

        if (!canvas.occluded(x, y)) {

          var value = iter.current;

          if (!opened) {
            // need to figure out where we left off from before
            // open() might take into account the entire stack, just like close does
            value = iter.stack.last.node.open() + value;
            opened = true;
          }

          canvas.write(x, y, value);

          last_x = x;
          last_y = y;

        } else if (opened) {

          opened = false;
          String last = canvas.stringAt(last_x, last_y);
          canvas.write(last_x, last_y, last + iter.last_stack.map((t)=>t.close()).join());

        }
      }
    }
    if (opened && last_x != null && last_y != null) {
      String last = canvas.stringAt(last_x, last_y);
      canvas.write(last_x, last_y, last + iter.last_stack.map((t)=>t.close()).join());
    }
  }

  // default implementation passes parent's size to children
  void resize_children() {
    for (var view in children) {
      view.resize(Size.from(size), view.position);
    }
  }

  void render_children(Canvas canvas) {
    for (var view in children) {
      render_child(view, canvas);
    }
  }

  // calls view.render() with new canvas
  void render_child(View view, Canvas canvas) {
    view.render(canvas.canvas(view.size, view.position));
  }

}



class Box extends View {

  String border;
  String color;

  Box(this.border, this.color);

  void update() {
    text = [];
    text.addAll([
    new Text(border*width)..color = color,
    new Text(border*width)..color = color..position = new Position(0, 1)]);
    for (int i = 1; i < height-1; i++) {
      text.add(new Text(border*2)..color = color..position = new Position(0, i));
      text.add(new Text(border*2)..color = color..position = new Position(width-2, i));
    }
    text.addAll([
    new Text(border*width)..color = color..position = new Position(0, height-1),
    new Text(border*width)..color = color..position = new Position(0, height-2),
    ]);
  }

  void resize_children() {
    for (var view in children) {
      var child_size = new Size.from(size);
      child_size.height -= 4;
      child_size.width -= 4;
      var child_position = new Position(2, 2);
      view.resize(child_size, child_position);
    }
  }

}

class CenteredText extends View {
  String content;
  CenteredText(this.content);
  void update() {
    var x = ((width/2)-(content.length/2)).toInt();
    var y = (height/2).toInt()-1;
    text = [new Text(content)..position=new Position(x,y)];
  }
}

/// Splits available space between children horizontally or vertically.
///
/// Example:
/// ```dart
/// // Equal horizontal split (side by side)
/// var split = SplitView(horizontal: true);
/// split.children = [leftPanel, rightPanel];
///
/// // Vertical split with custom ratios (1:2 ratio)
/// var split = SplitView(horizontal: false, ratios: [1, 2]);
/// split.children = [topPanel, bottomPanel];
/// ```
class SplitView extends View {

  /// If true, children are placed side by side (horizontal).
  /// If false, children are stacked vertically.
  bool horizontal;

  /// Optional ratios for sizing children.
  /// If null, space is divided equally.
  /// Example: [1, 2, 1] gives 25%, 50%, 25% to three children.
  List<int>? ratios;

  SplitView({this.horizontal = true, this.ratios});

  @override
  void resize_children() {
    if (children.isEmpty) return;

    // Calculate total ratio including implicit 1s for children without explicit ratios
    int totalRatio = 0;
    for (int i = 0; i < children.length; i++) {
      totalRatio += (ratios != null && i < ratios!.length) ? ratios![i] : 1;
    }

    final availableSize = horizontal ? width : height;

    int offset = 0;
    for (int i = 0; i < children.length; i++) {
      final ratio = ratios != null && i < ratios!.length
                    ? ratios![i]
                    : 1;
      final childSize = (availableSize * ratio / totalRatio).floor();

      if (horizontal) {
        children[i].resize(
          Size(childSize, height),
          Position(offset, 0)
        );
      } else {
        children[i].resize(
          Size(width, childSize),
          Position(0, offset)
        );
      }

      offset += childSize;
    }
  }
}

/// A progress bar widget.
///
/// Example:
/// ```dart
/// var progress = ProgressBar()
///   ..value = 0.75  // 75%
///   ..showPercent = true
///   ..color = "2";  // green
/// ```
class ProgressBar extends View {

  /// Progress value from 0.0 to 1.0
  double _value = 0.0;
  double get value => _value;
  set value(double v) => _value = v.clamp(0.0, 1.0);

  /// Whether to show percentage text
  bool showPercent = true;

  /// Color for filled portion (ANSI color code)
  String color = "2";

  /// Color for empty portion
  String emptyColor = "8";

  /// Characters for rendering
  String filledChar = "█";
  String emptyChar = "░";

  /// Optional label shown before the bar
  String? label;

  // Partial block characters for smooth progress
  static const List<String> _partialBlocks = [
    " ", "▏", "▎", "▍", "▌", "▋", "▊", "▉", "█"
  ];

  @override
  void update() {
    text = [];
    if (width < 3 || height < 1) return;

    int labelWidth = 0;
    if (label != null) {
      labelWidth = label!.length + 1;
      text.add(Text(label!)..color = color);
    }

    int percentWidth = showPercent ? 5 : 0; // " 99%"
    int barWidth = width - labelWidth - percentWidth - 2; // -2 for [ ]
    if (barWidth < 1) barWidth = 1;

    double filledExact = barWidth * _value;
    int filledFull = filledExact.floor();
    double remainder = filledExact - filledFull;
    int partialIndex = (remainder * 8).round();

    // Build bar content
    var bar = StringBuffer();
    bar.write("[");
    bar.write(filledChar * filledFull);

    if (filledFull < barWidth) {
      if (partialIndex > 0 && partialIndex < 8) {
        bar.write(_partialBlocks[partialIndex]);
        bar.write(emptyChar * (barWidth - filledFull - 1));
      } else {
        bar.write(emptyChar * (barWidth - filledFull));
      }
    }
    bar.write("]");

    if (showPercent) {
      int pct = (_value * 100).round();
      bar.write(pct.toString().padLeft(4));
      bar.write("%");
    }

    text.add(Text(bar.toString())
      ..color = color
      ..position = Position(labelWidth, 0));
  }
}