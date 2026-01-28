part of tui;

/// List selection widget.
///
/// Example:
/// ```dart
/// var select = Select<String>(
///   options: ['Red', 'Green', 'Blue'],
///   onSelect: (value) => print('Selected: $value'),
/// );
/// ```
class Select<T> extends View {
  /// Options to choose from.
  List<T> options;

  /// Currently highlighted index.
  int selectedIndex = 0;

  /// Scroll offset for long lists.
  int scrollOffset = 0;

  /// Function to convert option to display string.
  String Function(T)? labelBuilder;

  /// If true, allows multiple selections with Space key.
  bool multiSelect;

  /// Set of selected indices (for multiSelect mode).
  Set<int> selectedIndices = {};

  /// Maximum number of selections (0 = unlimited).
  int limit;

  /// Cursor prefix for highlighted item.
  String cursor = '> ';

  /// Prefix for selected items (multiSelect mode).
  String selectedPrefix = '✓ ';

  /// Prefix for unselected items.
  String unselectedPrefix = '  ';

  /// Color for cursor (ANSI code).
  String cursorColor = '36';

  /// Color for selected items (ANSI code).
  String selectedColor = '32';

  /// Color for normal items (ANSI code).
  String itemColor = '0';

  /// Optional header text.
  String? header;

  /// Color for header (ANSI code).
  String headerColor = '33';

  /// Called when Enter is pressed (single select mode).
  void Function(T value)? onSelect;

  /// Called when Enter is pressed (multiSelect mode).
  void Function(List<T> values)? onSelectMultiple;

  /// Called when selection changes.
  void Function(int index)? onChange;

  Select({
    required this.options,
    this.labelBuilder,
    this.multiSelect = false,
    this.limit = 0,
    this.onSelect,
    this.onSelectMultiple,
    this.onChange,
    this.header,
  }) {
    focusable = true;
  }

  String _getLabel(T option) {
    return labelBuilder?.call(option) ?? option.toString();
  }

  int get _headerOffset => header != null ? 1 : 0;

  int get _visibleCount => height - _headerOffset;

  @override
  bool onKey(String key) {
    if (key == KeyCode.UP) {
      if (selectedIndex > 0) {
        selectedIndex--;
        _adjustScroll();
        onChange?.call(selectedIndex);
        update();
      }
      return true;
    }

    if (key == KeyCode.DOWN) {
      if (selectedIndex < options.length - 1) {
        selectedIndex++;
        _adjustScroll();
        onChange?.call(selectedIndex);
        update();
      }
      return true;
    }

    if (key == KeyCode.HOME) {
      selectedIndex = 0;
      scrollOffset = 0;
      onChange?.call(selectedIndex);
      update();
      return true;
    }

    if (key == KeyCode.END) {
      selectedIndex = options.length - 1;
      _adjustScroll();
      onChange?.call(selectedIndex);
      update();
      return true;
    }

    if (key == KeyCode.PAGE_UP) {
      selectedIndex = (selectedIndex - _visibleCount).clamp(0, options.length - 1);
      _adjustScroll();
      onChange?.call(selectedIndex);
      update();
      return true;
    }

    if (key == KeyCode.PAGE_DOWN) {
      selectedIndex = (selectedIndex + _visibleCount).clamp(0, options.length - 1);
      _adjustScroll();
      onChange?.call(selectedIndex);
      update();
      return true;
    }

    if (key == KeyCode.SPACE && multiSelect) {
      _toggleSelection(selectedIndex);
      update();
      return true;
    }

    if (key == KeyCode.ENTER) {
      if (multiSelect) {
        // In multiSelect mode, select current if nothing selected
        if (selectedIndices.isEmpty) {
          selectedIndices.add(selectedIndex);
        }
        var selected = selectedIndices.toList()
          ..sort()
          ..map((i) => options[i]).toList();
        onSelectMultiple?.call(selected.map((i) => options[i]).toList());
      } else {
        onSelect?.call(options[selectedIndex]);
      }
      return true;
    }

    return false;
  }

  void _toggleSelection(int index) {
    if (selectedIndices.contains(index)) {
      selectedIndices.remove(index);
    } else {
      if (limit == 0 || selectedIndices.length < limit) {
        selectedIndices.add(index);
      }
    }
  }

  void _adjustScroll() {
    // Ensure selected item is visible
    if (selectedIndex < scrollOffset) {
      scrollOffset = selectedIndex;
    } else if (selectedIndex >= scrollOffset + _visibleCount) {
      scrollOffset = selectedIndex - _visibleCount + 1;
    }
  }

  @override
  void update() {
    text = [];
    if (width < 3 || height < 1) return;

    var y = 0;

    // Header
    if (header != null) {
      text.add(Text(header!)
        ..color = headerColor
        ..position = Position(0, y++));
    }

    // Options
    var endIndex = (scrollOffset + _visibleCount).clamp(0, options.length);
    for (var i = scrollOffset; i < endIndex; i++) {
      var option = options[i];
      var label = _getLabel(option);
      var isHighlighted = i == selectedIndex;
      var isSelected = selectedIndices.contains(i);

      String prefix;
      String color;

      if (isHighlighted) {
        prefix = cursor;
        color = cursorColor;
      } else if (multiSelect && isSelected) {
        prefix = selectedPrefix;
        color = selectedColor;
      } else {
        prefix = unselectedPrefix;
        color = itemColor;
      }

      var displayText = '$prefix$label';
      if (displayText.length > width) {
        displayText = displayText.substring(0, width);
      }

      text.add(Text(displayText)
        ..color = color
        ..position = Position(0, y++));
    }

    // Scroll indicator
    if (options.length > _visibleCount) {
      var scrollPercent = scrollOffset / (options.length - _visibleCount);
      var indicatorY = _headerOffset + (scrollPercent * (_visibleCount - 1)).round();
      text.add(Text('│')
        ..color = '8'
        ..position = Position(width - 1, indicatorY));
    }
  }
}

/// Yes/No confirmation dialog.
///
/// Example:
/// ```dart
/// var confirm = Confirm(
///   message: 'Are you sure?',
///   onConfirm: (result) => print(result ? 'Yes' : 'No'),
/// );
/// ```
class Confirm extends View {
  /// Question to display.
  String message;

  /// Currently selected option (true = Yes).
  bool selected;

  /// Label for "Yes" option.
  String yesLabel;

  /// Label for "No" option.
  String noLabel;

  /// Color for message (ANSI code).
  String messageColor = '0';

  /// Color for selected option (ANSI code).
  String selectedColor = '7'; // inverted

  /// Color for unselected option (ANSI code).
  String unselectedColor = '0';

  /// Called when Enter is pressed.
  void Function(bool result)? onConfirm;

  Confirm({
    required this.message,
    this.selected = true,
    this.yesLabel = 'Yes',
    this.noLabel = 'No',
    this.onConfirm,
  }) {
    focusable = true;
  }

  @override
  bool onKey(String key) {
    if (key == KeyCode.LEFT || key == 'y' || key == 'Y') {
      selected = true;
      update();
      return true;
    }

    if (key == KeyCode.RIGHT || key == 'n' || key == 'N') {
      selected = false;
      update();
      return true;
    }

    if (key == KeyCode.TAB) {
      selected = !selected;
      update();
      return true;
    }

    if (key == KeyCode.ENTER) {
      onConfirm?.call(selected);
      return true;
    }

    return false;
  }

  @override
  void update() {
    text = [];
    if (width < 10 || height < 1) return;

    // Message
    text.add(Text(message)..color = messageColor);

    // Options on second line (or after message if single line)
    var yesText = selected ? '[$yesLabel]' : ' $yesLabel ';
    var noText = selected ? ' $noLabel ' : '[$noLabel]';

    var optionsLine = '$yesText  $noText';
    var optionsY = height > 1 ? 1 : 0;
    var optionsX = height > 1 ? 0 : message.length + 2;

    if (height == 1) {
      // Single line mode
      var fullText = '$message  $yesText  $noText';
      text = [Text(fullText)..color = messageColor];

      // Highlight selected
      var yesStart = message.length + 2;
      var noStart = yesStart + yesText.length + 2;

      if (selected) {
        text.add(Text(yesText)
          ..color = selectedColor
          ..position = Position(yesStart, 0));
      } else {
        text.add(Text(noText)
          ..color = selectedColor
          ..position = Position(noStart, 0));
      }
    } else {
      // Two line mode
      text.add(Text(message)
        ..color = messageColor
        ..position = Position(0, 0));

      text.add(Text(yesText)
        ..color = selected ? selectedColor : unselectedColor
        ..position = Position(0, 1));

      text.add(Text(noText)
        ..color = selected ? unselectedColor : selectedColor
        ..position = Position(yesText.length + 2, 1));
    }
  }
}
