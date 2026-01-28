part of tui;

/// Table border styles.
enum TableBorder {
  /// No border.
  none,

  /// Simple ASCII: +, -, |
  ascii,

  /// Light lines: ┌─┐│└┘
  light,

  /// Heavy lines: ┏━┓┃┗┛
  heavy,

  /// Double lines: ╔═╗║╚╝
  double,

  /// Rounded corners: ╭─╮│╰╯
  rounded,
}

/// Column definition for Table.
class TableColumn {
  /// Column header text.
  final String title;

  /// Column width. If null, auto-calculated.
  int? width;

  /// Text alignment within column.
  final TextAlign align;

  TableColumn(this.title, {this.width, this.align = TextAlign.left});
}

/// Text alignment options.
enum TextAlign { left, center, right }

/// Tabular data display widget.
///
/// Example:
/// ```dart
/// var table = Table<Map<String, String>>(
///   columns: [
///     TableColumn('Name', width: 20),
///     TableColumn('Email', width: 30),
///   ],
///   rows: [
///     {'Name': 'Alice', 'Email': 'alice@example.com'},
///     {'Name': 'Bob', 'Email': 'bob@example.com'},
///   ],
///   rowBuilder: (item) => [item['Name']!, item['Email']!],
///   onSelect: (item) => print('Selected: ${item['Name']}'),
/// );
/// ```
class Table<T> extends View {
  /// Column definitions.
  List<TableColumn> columns;

  /// Row data.
  List<T> rows;

  /// Function to convert row data to list of cell strings.
  List<String> Function(T) rowBuilder;

  /// Currently selected row index.
  int selectedRow = 0;

  /// Scroll offset for long tables.
  int scrollOffset = 0;

  /// Whether rows are selectable.
  bool selectable;

  /// Show header row.
  bool showHeader;

  /// Border style.
  TableBorder border;

  /// Color for header (ANSI code).
  String headerColor = '1';

  /// Color for selected row (ANSI code).
  String selectedColor = '7';

  /// Color for normal rows (ANSI code).
  String rowColor = '0';

  /// Color for border (ANSI code).
  String borderColor = '8';

  /// Called when Enter is pressed on a row.
  void Function(T row)? onSelect;

  /// Called when selection changes.
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

  int get _headerHeight {
    if (!showHeader) return 0;
    // Header line + separator line (if bordered)
    return border != TableBorder.none ? 2 : 1;
  }

  int get _borderHeight => border != TableBorder.none ? 2 : 0;
  int get _visibleRows => height - _headerHeight - _borderHeight;

  @override
  bool onKey(String key) {
    if (!selectable) return false;

    if (key == KeyCode.UP) {
      if (selectedRow > 0) {
        selectedRow--;
        _adjustScroll();
        onChange?.call(selectedRow);
        update();
      }
      return true;
    }

    if (key == KeyCode.DOWN) {
      if (selectedRow < rows.length - 1) {
        selectedRow++;
        _adjustScroll();
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
      _adjustScroll();
      onChange?.call(selectedRow);
      update();
      return true;
    }

    if (key == KeyCode.PAGE_UP) {
      selectedRow = (selectedRow - _visibleRows).clamp(0, rows.length - 1);
      _adjustScroll();
      onChange?.call(selectedRow);
      update();
      return true;
    }

    if (key == KeyCode.PAGE_DOWN) {
      selectedRow = (selectedRow + _visibleRows).clamp(0, rows.length - 1);
      _adjustScroll();
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

  void _adjustScroll() {
    if (selectedRow < scrollOffset) {
      scrollOffset = selectedRow;
    } else if (selectedRow >= scrollOffset + _visibleRows) {
      scrollOffset = selectedRow - _visibleRows + 1;
    }
  }

  void _calculateColumnWidths() {
    // Calculate widths for columns without explicit width
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
        col.width = maxWidth + 2; // +2 for cell padding (space on each side)
      }
    }
  }

  String _alignText(String text, int width, TextAlign align) {
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

  _BorderChars get _borderChars {
    switch (border) {
      case TableBorder.none:
        return _BorderChars(
          tl: ' ', h: ' ', tr: ' ', v: ' ',
          ml: ' ', mr: ' ', bl: ' ', br: ' ',
          tm: ' ', mm: ' ', bm: ' ',
        );
      case TableBorder.ascii:
        return _BorderChars(
          tl: '+', h: '-', tr: '+', v: '|',
          ml: '+', mr: '+', bl: '+', br: '+',
          tm: '+', mm: '+', bm: '+',
        );
      case TableBorder.light:
        return _BorderChars(
          tl: '┌', h: '─', tr: '┐', v: '│',
          ml: '├', mr: '┤', bl: '└', br: '┘',
          tm: '┬', mm: '┼', bm: '┴',
        );
      case TableBorder.heavy:
        return _BorderChars(
          tl: '┏', h: '━', tr: '┓', v: '┃',
          ml: '┣', mr: '┫', bl: '┗', br: '┛',
          tm: '┳', mm: '╋', bm: '┻',
        );
      case TableBorder.double:
        return _BorderChars(
          tl: '╔', h: '═', tr: '╗', v: '║',
          ml: '╠', mr: '╣', bl: '╚', br: '╝',
          tm: '╦', mm: '╬', bm: '╩',
        );
      case TableBorder.rounded:
        return _BorderChars(
          tl: '╭', h: '─', tr: '╮', v: '│',
          ml: '├', mr: '┤', bl: '╰', br: '╯',
          tm: '┬', mm: '┼', bm: '┴',
        );
    }
  }

  @override
  void update() {
    text = [];
    if (width < 5 || height < 2) return;

    _calculateColumnWidths();

    var chars = _borderChars;
    var y = 0;

    // Top border with T-pieces at column intersections
    if (border != TableBorder.none) {
      var topLine = chars.tl +
          columns.map((c) => chars.h * c.width!).join(chars.tm) +
          chars.tr;
      if (topLine.length > width) topLine = topLine.substring(0, width);
      text.add(Text(topLine)
        ..color = borderColor
        ..position = Position(0, y++));
    }

    // Header
    if (showHeader) {
      var headerLine = chars.v +
          columns.map((c) => _alignText(' ${c.title} ', c.width!, c.align)).join(chars.v) +
          chars.v;
      if (headerLine.length > width) headerLine = headerLine.substring(0, width);
      text.add(Text(headerLine)
        ..color = headerColor
        ..position = Position(0, y++));

      // Header separator with cross pieces at intersections
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

    // Rows
    var endIdx = (scrollOffset + _visibleRows).clamp(0, rows.length);
    for (var i = scrollOffset; i < endIdx; i++) {
      var row = rows[i];
      var cells = rowBuilder(row);
      var isSelected = selectable && i == selectedRow;

      var rowLine = chars.v +
          columns.asMap().entries.map((e) {
            var idx = e.key;
            var col = e.value;
            var cellText = idx < cells.length ? cells[idx] : '';
            return _alignText(' $cellText ', col.width!, col.align);
          }).join(chars.v) +
          chars.v;

      if (rowLine.length > width) rowLine = rowLine.substring(0, width);

      text.add(Text(rowLine)
        ..color = isSelected ? selectedColor : rowColor
        ..position = Position(0, y++));
    }

    // Bottom border with T-pieces at column intersections
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
  final String tm, mm, bm; // T-pieces: top-middle, middle-middle (cross), bottom-middle

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
