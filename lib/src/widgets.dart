part of tui;

/// A box with a border that contains children.
class Box extends View {
  String border;
  String color;

  Box(this.border, this.color);

  @override
  void update() {
    text = [];
    if (width < 2 || height < 2) return;

    text.addAll([
      Text(border * width)..color = color,
      Text(border * width)
        ..color = color
        ..position = Position(0, 1)
    ]);
    for (int i = 1; i < height - 1; i++) {
      text.add(Text(border * 2)
        ..color = color
        ..position = Position(0, i));
      text.add(Text(border * 2)
        ..color = color
        ..position = Position(width - 2, i));
    }
    text.addAll([
      Text(border * width)
        ..color = color
        ..position = Position(0, height - 1),
      Text(border * width)
        ..color = color
        ..position = Position(0, height - 2),
    ]);
  }

  @override
  void resizeChildren() {
    for (var view in children) {
      var childSize = Size.from(size);
      childSize.height -= 4;
      childSize.width -= 4;
      var childPosition = Position(2, 2);
      view.resize(childSize, childPosition);
    }
  }
}

/// Displays text centered within the view.
class CenteredText extends View {
  String content;

  CenteredText(this.content);

  @override
  void update() {
    var x = ((width / 2) - (content.length / 2)).toInt();
    var y = (height / 2).toInt() - 1;
    text = [Text(content)..position = Position(x, y)];
  }
}

/// Splits available space between children horizontally or vertically.
class SplitView extends View {
  /// If true, children are placed side by side (horizontal).
  bool horizontal;

  /// Optional ratios for sizing children. If null, space is divided equally.
  List<int>? ratios;

  SplitView({this.horizontal = true, this.ratios});

  @override
  void resizeChildren() {
    if (children.isEmpty) return;

    int totalRatio = 0;
    for (int i = 0; i < children.length; i++) {
      totalRatio += (ratios != null && i < ratios!.length) ? ratios![i] : 1;
    }

    final availableSize = horizontal ? width : height;

    int offset = 0;
    for (int i = 0; i < children.length; i++) {
      final ratio = ratios != null && i < ratios!.length ? ratios![i] : 1;
      final childDimension = (availableSize * ratio / totalRatio).floor();

      if (horizontal) {
        children[i].resize(Size(childDimension, height), Position(offset, 0));
      } else {
        children[i].resize(Size(width, childDimension), Position(0, offset));
      }

      offset += childDimension;
    }
  }
}

/// A progress bar widget.
class ProgressBar extends View {
  double _value = 0.0;
  double get value => _value;
  set value(double v) => _value = v.clamp(0.0, 1.0);

  bool showPercent = true;

  String color = "2"; // green
  String emptyColor = "8";
  String filledChar = "█";
  String emptyChar = "░";
  String? label;

  static const List<String> _partialBlocks = [" ", "▏", "▎", "▍", "▌", "▋", "▊", "▉", "█"];

  @override
  void update() {
    text = [];
    if (width < 3 || height < 1) return;

    int labelWidth = 0;
    if (label != null) {
      labelWidth = label!.length + 1;
      text.add(Text(label!)..color = color);
    }

    int percentWidth = showPercent ? 5 : 0;
    int barWidth = width - labelWidth - percentWidth - 2;
    if (barWidth < 1) barWidth = 1;

    double filledExact = barWidth * _value;
    int filledFull = filledExact.floor();
    double remainder = filledExact - filledFull;
    int partialIndex = (remainder * 8).round();

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
