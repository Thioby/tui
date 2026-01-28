part of tui;

/// Multi-line text input widget.
///
/// Example:
/// ```dart
/// var textarea = TextArea(placeholder: 'Enter description...')
///   ..onSubmit = (value) => print('Submitted: $value');
/// ```
class TextArea extends View {
  List<String> _lines = [''];

  /// Get all text as a single string.
  String get value => _lines.join('\n');

  /// Set all text from a single string.
  set value(String v) {
    _lines = v.split('\n');
    if (_lines.isEmpty) _lines = [''];
    cursorX = 0;
    cursorY = 0;
    scrollOffset = 0;
    update();
  }

  /// Cursor X position within current line.
  int cursorX = 0;

  /// Cursor Y position (line number).
  int cursorY = 0;

  /// Vertical scroll offset.
  int scrollOffset = 0;

  /// Horizontal scroll offset.
  int scrollX = 0;

  /// Placeholder text shown when empty.
  String? placeholder;

  /// Maximum number of lines. Null means no limit.
  int? maxLines;

  /// Prompt displayed at line start.
  String linePrefix = '';

  /// Show line numbers.
  bool showLineNumbers = false;

  /// Color for the text (ANSI code).
  String textColor = '0';

  /// Color for the placeholder (ANSI code).
  String placeholderColor = '90';

  /// Color for the cursor (ANSI code).
  String cursorColor = '7'; // inverted

  /// Color for line numbers (ANSI code).
  String lineNumberColor = '8';

  /// Called when Ctrl+D or designated submit key is pressed.
  void Function(String value)? onSubmit;

  /// Called when value changes.
  void Function(String value)? onChange;

  TextArea({this.placeholder, this.maxLines}) {
    focusable = true;
  }

  String get _currentLine => _lines[cursorY];

  int get _lineNumberWidth => showLineNumbers ? '${_lines.length}'.length + 2 : 0;

  int get _prefixWidth => _lineNumberWidth + linePrefix.length;

  int get _visibleLines => height;

  int get _visibleWidth => width - _prefixWidth - 1;

  @override
  bool onKey(String key) {
    // Navigation
    if (key == KeyCode.UP) {
      if (cursorY > 0) {
        cursorY--;
        cursorX = cursorX.clamp(0, _currentLine.length);
        _adjustScroll();
        update();
      }
      return true;
    }

    if (key == KeyCode.DOWN) {
      if (cursorY < _lines.length - 1) {
        cursorY++;
        cursorX = cursorX.clamp(0, _currentLine.length);
        _adjustScroll();
        update();
      }
      return true;
    }

    if (key == KeyCode.LEFT) {
      if (cursorX > 0) {
        cursorX--;
      } else if (cursorY > 0) {
        // Move to end of previous line
        cursorY--;
        cursorX = _currentLine.length;
      }
      _adjustScrollX();
      update();
      return true;
    }

    if (key == KeyCode.RIGHT) {
      if (cursorX < _currentLine.length) {
        cursorX++;
      } else if (cursorY < _lines.length - 1) {
        // Move to start of next line
        cursorY++;
        cursorX = 0;
      }
      _adjustScrollX();
      update();
      return true;
    }

    if (key == KeyCode.HOME) {
      cursorX = 0;
      scrollX = 0;
      update();
      return true;
    }

    if (key == KeyCode.END) {
      cursorX = _currentLine.length;
      _adjustScrollX();
      update();
      return true;
    }

    if (key == KeyCode.PAGE_UP) {
      cursorY = (cursorY - _visibleLines).clamp(0, _lines.length - 1);
      cursorX = cursorX.clamp(0, _currentLine.length);
      _adjustScroll();
      update();
      return true;
    }

    if (key == KeyCode.PAGE_DOWN) {
      cursorY = (cursorY + _visibleLines).clamp(0, _lines.length - 1);
      cursorX = cursorX.clamp(0, _currentLine.length);
      _adjustScroll();
      update();
      return true;
    }

    // Editing
    if (key == KeyCode.ENTER) {
      if (maxLines != null && _lines.length >= maxLines!) {
        return true; // Can't add more lines
      }
      // Split current line at cursor
      var beforeCursor = _currentLine.substring(0, cursorX);
      var afterCursor = _currentLine.substring(cursorX);
      _lines[cursorY] = beforeCursor;
      _lines.insert(cursorY + 1, afterCursor);
      cursorY++;
      cursorX = 0;
      scrollX = 0;
      _adjustScroll();
      onChange?.call(value);
      update();
      return true;
    }

    if (key == KeyCode.BACKSPACE) {
      if (cursorX > 0) {
        // Delete character before cursor
        var line = _currentLine;
        _lines[cursorY] = line.substring(0, cursorX - 1) + line.substring(cursorX);
        cursorX--;
        _adjustScrollX();
        onChange?.call(value);
        update();
      } else if (cursorY > 0) {
        // Merge with previous line
        var currentLineText = _currentLine;
        cursorY--;
        cursorX = _currentLine.length;
        _lines[cursorY] = _currentLine + currentLineText;
        _lines.removeAt(cursorY + 1);
        _adjustScroll();
        _adjustScrollX();
        onChange?.call(value);
        update();
      }
      return true;
    }

    if (key == KeyCode.DEL) {
      if (cursorX < _currentLine.length) {
        // Delete character at cursor
        var line = _currentLine;
        _lines[cursorY] = line.substring(0, cursorX) + line.substring(cursorX + 1);
        onChange?.call(value);
        update();
      } else if (cursorY < _lines.length - 1) {
        // Merge with next line
        _lines[cursorY] = _currentLine + _lines[cursorY + 1];
        _lines.removeAt(cursorY + 1);
        onChange?.call(value);
        update();
      }
      return true;
    }

    // Ctrl+D to submit
    if (key == '\x04') {
      onSubmit?.call(value);
      return true;
    }

    // Regular character input
    if (key.length == 1 && key.codeUnitAt(0) >= 32) {
      var line = _currentLine;
      _lines[cursorY] = line.substring(0, cursorX) + key + line.substring(cursorX);
      cursorX++;
      _adjustScrollX();
      onChange?.call(value);
      update();
      return true;
    }

    // Tab - insert spaces
    if (key == KeyCode.TAB) {
      var spaces = '  '; // 2 spaces
      var line = _currentLine;
      _lines[cursorY] = line.substring(0, cursorX) + spaces + line.substring(cursorX);
      cursorX += spaces.length;
      _adjustScrollX();
      onChange?.call(value);
      update();
      return true;
    }

    return false;
  }

  void _adjustScroll() {
    // Vertical scrolling
    if (cursorY < scrollOffset) {
      scrollOffset = cursorY;
    } else if (cursorY >= scrollOffset + _visibleLines) {
      scrollOffset = cursorY - _visibleLines + 1;
    }
  }

  void _adjustScrollX() {
    // Horizontal scrolling
    if (cursorX < scrollX) {
      scrollX = cursorX;
    } else if (cursorX >= scrollX + _visibleWidth) {
      scrollX = cursorX - _visibleWidth + 1;
    }
  }

  @override
  void update() {
    text = [];
    if (width < 3 || height < 1) return;

    var showPlaceholder = _lines.length == 1 && _lines[0].isEmpty && placeholder != null;

    if (showPlaceholder && !focused) {
      text.add(Text(placeholder!)..color = placeholderColor);
      return;
    }

    var endLine = (scrollOffset + _visibleLines).clamp(0, _lines.length);

    for (var i = scrollOffset; i < endLine; i++) {
      var y = i - scrollOffset;
      var xOffset = 0;

      // Line number
      if (showLineNumbers) {
        var lineNum = '${i + 1}'.padLeft(_lineNumberWidth - 1);
        text.add(Text('$lineNum ')
          ..color = lineNumberColor
          ..position = Position(0, y));
        xOffset = _lineNumberWidth;
      }

      // Line prefix
      if (linePrefix.isNotEmpty) {
        text.add(Text(linePrefix)
          ..color = textColor
          ..position = Position(xOffset, y));
        xOffset += linePrefix.length;
      }

      // Line content
      var line = _lines[i];
      var visibleLine = line.length > scrollX ? line.substring(scrollX) : '';
      if (visibleLine.length > _visibleWidth) {
        visibleLine = visibleLine.substring(0, _visibleWidth);
      }

      if (focused && i == cursorY) {
        // Line with cursor
        var cursorPosInVisible = cursorX - scrollX;

        if (cursorPosInVisible >= 0 && cursorPosInVisible <= visibleLine.length) {
          // Text before cursor
          if (cursorPosInVisible > 0) {
            text.add(Text(visibleLine.substring(0, cursorPosInVisible))
              ..color = textColor
              ..position = Position(xOffset, y));
          }

          // Cursor
          var cursorChar = cursorPosInVisible < visibleLine.length
              ? visibleLine[cursorPosInVisible]
              : ' ';
          text.add(Text(cursorChar)
            ..color = cursorColor
            ..position = Position(xOffset + cursorPosInVisible, y));

          // Text after cursor
          if (cursorPosInVisible < visibleLine.length - 1) {
            text.add(Text(visibleLine.substring(cursorPosInVisible + 1))
              ..color = textColor
              ..position = Position(xOffset + cursorPosInVisible + 1, y));
          }
        } else {
          text.add(Text(visibleLine)
            ..color = textColor
            ..position = Position(xOffset, y));
        }
      } else {
        text.add(Text(visibleLine)
          ..color = textColor
          ..position = Position(xOffset, y));
      }
    }

    // Scroll indicator
    if (_lines.length > _visibleLines) {
      var maxScroll = _lines.length - _visibleLines;
      var scrollPercent = maxScroll > 0 ? scrollOffset / maxScroll : 0.0;
      var indicatorY = (scrollPercent * (_visibleLines - 1)).round();
      text.add(Text('▐')
        ..color = '8'
        ..position = Position(width - 1, indicatorY));
    }
  }
}
