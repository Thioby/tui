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
  bool horizontal;
  List<int>? ratios;

  SplitView({this.horizontal = true, this.ratios});

  @override
  void resizeChildren() {
    if (children.isEmpty) return;

    int totalRatio = 0;
    for (int i = 0; i < children.length; i++) {
      totalRatio += (ratios != null && i < ratios!.length) ? ratios![i] : 1;
    }

    final avail = horizontal ? width : height;

    int offset = 0;
    for (int i = 0; i < children.length; i++) {
      final ratio = ratios != null && i < ratios!.length ? ratios![i] : 1;
      final dim = (avail * ratio / totalRatio).floor();

      if (horizontal) {
        children[i].resize(Size(dim, height), Position(offset, 0));
      } else {
        children[i].resize(Size(width, dim), Position(0, offset));
      }

      offset += dim;
    }
  }
}

/// A frame with Unicode border and optional title.
class Frame extends View {
  String? title;
  String color;
  String? focusColor;
  int padding;

  Frame({this.title, this.color = '36', this.focusColor, this.padding = 1});

  @override
  void update() {
    if (width < 4 || height < 3) {
      text = [];
      return;
    }

    var innerWidth = width - 2;
    var borderColor = focused && focusColor != null ? focusColor! : color;

    var h = focused && focusColor != null ? BoxChars.doubleH : BoxChars.lightH;
    var v = focused && focusColor != null ? BoxChars.doubleV : BoxChars.lightV;
    var tl = focused && focusColor != null ? BoxChars.doubleTL : BoxChars.lightTL;
    var tr = focused && focusColor != null ? BoxChars.doubleTR : BoxChars.lightTR;
    var bl = focused && focusColor != null ? BoxChars.doubleBL : BoxChars.lightBL;
    var br = focused && focusColor != null ? BoxChars.doubleBR : BoxChars.lightBR;

    String topBorder;
    if (title != null && title!.isNotEmpty) {
      var titleText = ' $title ';
      var remaining = innerWidth - titleText.length - 1;
      if (remaining < 0) remaining = 0;
      topBorder = '$tl$h$titleText${h * remaining}$tr';
    } else {
      topBorder = '$tl${h * innerWidth}$tr';
    }

    text = [Text(topBorder)..color = borderColor];

    for (var i = 1; i < height - 1; i++) {
      text.add(Text(v)
        ..color = borderColor
        ..position = Position(0, i));
      text.add(Text(v)
        ..color = borderColor
        ..position = Position(width - 1, i));
    }

    text.add(Text('$bl${h * innerWidth}$br')
      ..color = borderColor
      ..position = Position(0, height - 1));
  }

  @override
  void resizeChildren() {
    var innerWidth = width - 2 - (padding * 2);
    var innerHeight = height - 2 - (padding * 2);
    if (innerWidth < 1) innerWidth = 1;
    if (innerHeight < 1) innerHeight = 1;

    for (var child in children) {
      child.resize(
        Size(innerWidth, innerHeight),
        Position(1 + padding, 1 + padding),
      );
    }
  }
}

/// A progress bar widget.
class ProgressBar extends View {
  double _val = 0.0;
  double get value => _val;
  set value(double v) => _val = v.clamp(0.0, 1.0);

  bool showPercent = true;

  String color = "2";
  String emptyColor = "8";
  String filledChar = BoxChars.progressFull;
  String emptyChar = BoxChars.progressEmpty;
  String? label;

  static const List<String> _blocks = [" ", "▏", "▎", "▍", "▌", "▋", "▊", "▉", BoxChars.progressFull];

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

    double filledExact = barWidth * _val;
    int filledFull = filledExact.floor();
    double remainder = filledExact - filledFull;
    int partialIndex = (remainder * 8).round();

    var bar = StringBuffer();
    bar.write("[");
    bar.write(filledChar * filledFull);

    if (filledFull < barWidth) {
      if (partialIndex > 0 && partialIndex < 8) {
        bar.write(_blocks[partialIndex]);
        bar.write(emptyChar * (barWidth - filledFull - 1));
      } else {
        bar.write(emptyChar * (barWidth - filledFull));
      }
    }
    bar.write("]");

    if (showPercent) {
      int pct = (_val * 100).round();
      bar.write(pct.toString().padLeft(4));
      bar.write("%");
    }

    text.add(Text(bar.toString())
      ..color = color
      ..position = Position(labelWidth, 0));
  }
}