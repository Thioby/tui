part of tui;

/// List selection widget.
class Select<T> extends View {
  List<T> options;

  int selectedIndex = 0;

  int scrollOffset = 0;

  String Function(T)? labelBuilder;

  bool multiSelect;

  Set<int> selectedIndices = {};

  int limit;

  String cursor = '> ';

  String selectedPrefix = '✓ ';
  String unselectedPrefix = '  ';

  String cursorColor = '36';
  String selectedColor = '32';
  String itemColor = '0';

  String? header;
  String headerColor = '33';

  void Function(T value)? onSelect;
  void Function(List<T> values)? onSelectMultiple;
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

  String _lbl(T option) {
    return labelBuilder?.call(option) ?? option.toString();
  }

  int get _hdrOff => header != null ? 1 : 0;

  int get _visCnt => height - _hdrOff;

  @override
  bool onKey(String key) {
    if (key == KeyCode.UP) {
      if (selectedIndex > 0) {
        selectedIndex--;
        _scroll();
        onChange?.call(selectedIndex);
        update();
      }
      return true;
    }

    if (key == KeyCode.DOWN) {
      if (selectedIndex < options.length - 1) {
        selectedIndex++;
        _scroll();
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
      _scroll();
      onChange?.call(selectedIndex);
      update();
      return true;
    }

    if (key == KeyCode.PAGE_UP) {
      selectedIndex = (selectedIndex - _visCnt).clamp(0, options.length - 1);
      _scroll();
      onChange?.call(selectedIndex);
      update();
      return true;
    }

    if (key == KeyCode.PAGE_DOWN) {
      selectedIndex = (selectedIndex + _visCnt).clamp(0, options.length - 1);
      _scroll();
      onChange?.call(selectedIndex);
      update();
      return true;
    }

    if (key == KeyCode.SPACE && multiSelect) {
      _toggle(selectedIndex);
      update();
      return true;
    }

    if (key == KeyCode.ENTER) {
      if (multiSelect) {
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

  void _toggle(int index) {
    if (selectedIndices.contains(index)) {
      selectedIndices.remove(index);
    } else {
      if (limit == 0 || selectedIndices.length < limit) {
        selectedIndices.add(index);
      }
    }
  }

  void _scroll() {
    if (selectedIndex < scrollOffset) {
      scrollOffset = selectedIndex;
    } else if (selectedIndex >= scrollOffset + _visCnt) {
      scrollOffset = selectedIndex - _visCnt + 1;
    }
  }

  @override
  void update() {
    text = [];
    if (width < 3 || height < 1) return;

    var y = 0;

    if (header != null) {
      text.add(Text(header!)
        ..color = headerColor
        ..position = Position(0, y++));
    }

    var endIndex = (scrollOffset + _visCnt).clamp(0, options.length);
    for (var i = scrollOffset; i < endIndex; i++) {
      var option = options[i];
      var label = _lbl(option);
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

    if (options.length > _visCnt) {
      var scrollPercent = scrollOffset / (options.length - _visCnt);
      var indicatorY = _hdrOff + (scrollPercent * (_visCnt - 1)).round();
      text.add(Text('│')
        ..color = '8'
        ..position = Position(width - 1, indicatorY));
    }
  }
}

/// Yes/No confirmation dialog.
class Confirm extends View {
  String message;

  bool selected;

  String yesLabel;
  String noLabel;

  String messageColor = '0';
  String selectedColor = '7';
  String unselectedColor = '0';

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

    text.add(Text(message)..color = messageColor);

    var yesText = selected ? '[$yesLabel]' : ' $yesLabel ';
    var noText = selected ? ' $noLabel ' : '[$noLabel]';

    if (height == 1) {
      var fullText = '$message  $yesText  $noText';
      text = [Text(fullText)..color = messageColor];

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