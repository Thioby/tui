part of tui;

enum TableBorder {
  none,
  ascii,
  light,
  heavy,
  double,
  rounded,
}

class TableColumn {
  final String title;
  int? width;
  final TextAlign align;

  TableColumn(this.title, {this.width, this.align = TextAlign.left});
}

enum TextAlign { left, center, right }

/// Tabular data display widget.
class Table<T> extends View {
  List<TableColumn> columns;

  List<T> rows;

  List<String> Function(T) rowBuilder;

  int selectedRow = 0;

  int scrollOffset = 0;

  bool selectable;

  bool showHeader;

  TableBorder border;

  String headerColor = '1';
  String selectedColor = '7';
  String rowColor = '0';
  String borderColor = '36';

  void Function(T row)? onSelect;
  void Function(int index)? onChange;

  Table({
    required this.columns,
    required this.rows,
    required this.rowBuilder,
    this.selectable = true,
    this.showHeader = true,
    this.border = TableBorder.light,
    this.onSelect,
    this.onChange,
  }) {
    focusable = selectable;
  }

  int get _hdrH {
    if (!showHeader) return 0;
    return border != TableBorder.none ? 2 : 1;
  }

  int get _brdH => border != TableBorder.none ? 2 : 0;
  int get _visRows => height - _hdrH - _brdH;

  @override
  bool onKey(String key) {
    if (!selectable) return false;

    if (key == KeyCode.UP) {
      if (selectedRow > 0) {
        selectedRow--;
        _scroll();
        onChange?.call(selectedRow);
        update();
      }
      return true;
    }

    if (key == KeyCode.DOWN) {
      if (selectedRow < rows.length - 1) {
        selectedRow++;
        _scroll();
        onChange?.call(selectedRow);
        update();
      }
      return true;
    }

    if (key == KeyCode.HOME) {
      selectedRow = 0;
      scrollOffset = 0;
      onChange?.call(selectedRow);
      update();
      return true;
    }

    if (key == KeyCode.END) {
      selectedRow = rows.length - 1;
      _scroll();
      onChange?.call(selectedRow);
      update();
      return true;
    }

    if (key == KeyCode.PAGE_UP) {
      selectedRow = (selectedRow - _visRows).clamp(0, rows.length - 1);
      _scroll();
      onChange?.call(selectedRow);
      update();
      return true;
    }

    if (key == KeyCode.PAGE_DOWN) {
      selectedRow = (selectedRow + _visRows).clamp(0, rows.length - 1);
      _scroll();
      onChange?.call(selectedRow);
      update();
      return true;
    }

    if (key == KeyCode.ENTER) {
      if (rows.isNotEmpty) {
        onSelect?.call(rows[selectedRow]);
      }
      return true;
    }

    return false;
  }

  void _scroll() {
    if (selectedRow < scrollOffset) {
      scrollOffset = selectedRow;
    } else if (selectedRow >= scrollOffset + _visRows) {
      scrollOffset = selectedRow - _visRows + 1;
    }
  }

  void _calcWidths() {
    for (var col in columns) {
      if (col.width == null) {
        var maxWidth = col.title.length;
        for (var row in rows) {
          var cells = rowBuilder(row);
          var idx = columns.indexOf(col);
          if (idx < cells.length && cells[idx].length > maxWidth) {
            maxWidth = cells[idx].length;
          }
        }
        col.width = maxWidth + 2;
      }
    }
  }

  String _align(String text, int width, TextAlign align) {
    if (text.length >= width) return text.substring(0, width);

    switch (align) {
      case TextAlign.left:
        return text.padRight(width);
      case TextAlign.right:
        return text.padLeft(width);
      case TextAlign.center:
        var pad = (width - text.length) ~/ 2;
        return text.padLeft(text.length + pad).padRight(width);
    }
  }

  _BorderChars get _chars {
    switch (border) {
      case TableBorder.none:
        return _BorderChars(
          tl: ' ', h: ' ', tr: ' ', v: ' ',
          ml: ' ', mr: ' ', bl: ' ', br: ' ',
          tm: ' ', mm: ' ', bm: ' ',
        );
      case TableBorder.ascii:
        return _BorderChars(
          tl: BoxChars.asciiCorner, h: BoxChars.asciiH, tr: BoxChars.asciiCorner, v: BoxChars.asciiV,
          ml: BoxChars.asciiCorner, mr: BoxChars.asciiCorner, bl: BoxChars.asciiCorner, br: BoxChars.asciiCorner,
          tm: BoxChars.asciiCorner, mm: BoxChars.asciiCorner, bm: BoxChars.asciiCorner,
        );
      case TableBorder.light:
        return _BorderChars(
          tl: BoxChars.lightTL, h: BoxChars.lightH, tr: BoxChars.lightTR, v: BoxChars.lightV,
          ml: BoxChars.lightTeeR, mr: BoxChars.lightTeeL, bl: BoxChars.lightBL, br: BoxChars.lightBR,
          tm: BoxChars.lightTeeD, mm: BoxChars.lightCross, bm: BoxChars.lightTeeU,
        );
      case TableBorder.heavy:
        return _BorderChars(
          tl: BoxChars.heavyTL, h: BoxChars.heavyH, tr: BoxChars.heavyTR, v: BoxChars.heavyV,
          ml: BoxChars.heavyTeeR, mr: BoxChars.heavyTeeL, bl: BoxChars.heavyBL, br: BoxChars.heavyBR,
          tm: BoxChars.heavyTeeD, mm: BoxChars.heavyCross, bm: BoxChars.heavyTeeU,
        );
      case TableBorder.double:
        return _BorderChars(
          tl: BoxChars.doubleTL, h: BoxChars.doubleH, tr: BoxChars.doubleTR, v: BoxChars.doubleV,
          ml: BoxChars.doubleTeeR, mr: BoxChars.doubleTeeL, bl: BoxChars.doubleBL, br: BoxChars.doubleBR,
          tm: BoxChars.doubleTeeD, mm: BoxChars.doubleCross, bm: BoxChars.doubleTeeU,
        );
      case TableBorder.rounded:
        return _BorderChars(
          tl: BoxChars.roundedTL, h: BoxChars.lightH, tr: BoxChars.roundedTR, v: BoxChars.lightV,
          ml: BoxChars.lightTeeR, mr: BoxChars.lightTeeL, bl: BoxChars.roundedBL, br: BoxChars.roundedBR,
          tm: BoxChars.lightTeeD, mm: BoxChars.lightCross, bm: BoxChars.lightTeeU,
        );
    }
  }

  @override
  void update() {
    text = [];
    if (width < 5 || height < 2) return;

    _calcWidths();

    var chars = _chars;
    var y = 0;

    if (border != TableBorder.none) {
      var topLine = chars.tl +
          columns.map((c) => chars.h * c.width!).join(chars.tm) +
          chars.tr;
      if (topLine.length > width) topLine = topLine.substring(0, width);
      text.add(Text(topLine)
        ..color = borderColor
        ..position = Position(0, y++));
    }

    if (showHeader) {
      var headerLine = chars.v +
          columns.map((c) => _align(' ${c.title} ', c.width!, c.align)).join(chars.v) +
          chars.v;
      if (headerLine.length > width) headerLine = headerLine.substring(0, width);
      text.add(Text(headerLine)
        ..color = headerColor
        ..position = Position(0, y++));

      if (border != TableBorder.none) {
        var sepLine = chars.ml +
            columns.map((c) => chars.h * c.width!).join(chars.mm) +
            chars.mr;
        if (sepLine.length > width) sepLine = sepLine.substring(0, width);
        text.add(Text(sepLine)
          ..color = borderColor
          ..position = Position(0, y++));
      }
    }

    var endIdx = (scrollOffset + _visRows).clamp(0, rows.length);
    for (var i = scrollOffset; i < endIdx; i++) {
      var row = rows[i];
      var cells = rowBuilder(row);
      var isSelected = selectable && i == selectedRow;

      var rowLine = chars.v +
          columns.asMap().entries.map((e) {
            var idx = e.key;
            var col = e.value;
            var cellText = idx < cells.length ? cells[idx] : '';
            return _align(' $cellText ', col.width!, col.align);
          }).join(chars.v) +
          chars.v;

      if (rowLine.length > width) rowLine = rowLine.substring(0, width);

      text.add(Text(rowLine)
        ..color = isSelected ? selectedColor : rowColor
        ..position = Position(0, y++));
    }

    if (border != TableBorder.none) {
      var bottomLine = chars.bl +
          columns.map((c) => chars.h * c.width!).join(chars.bm) +
          chars.br;
      if (bottomLine.length > width) bottomLine = bottomLine.substring(0, width);
      text.add(Text(bottomLine)
        ..color = borderColor
        ..position = Position(0, y));
    }
  }
}

class _BorderChars {
  final String tl, h, tr, v, ml, mr, bl, br;
  final String tm, mm, bm;

  _BorderChars({
    required this.tl,
    required this.h,
    required this.tr,
    required this.v,
    required this.ml,
    required this.mr,
    required this.bl,
    required this.br,
    required this.tm,
    required this.mm,
    required this.bm,
  });
}