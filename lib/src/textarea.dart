part of tui;

/// Multi-line text input widget.
class TextArea extends View {
  List<String> _lns = [''];

  String get value => _lns.join('\n');

  set value(String v) {
    _lns = v.split('\n');
    if (_lns.isEmpty) _lns = [''];
    cursorX = 0;
    cursorY = 0;
    scrollOffset = 0;
    update();
  }

  int cursorX = 0;

  int cursorY = 0;

  int scrollOffset = 0;

  int scrollX = 0;

  String? placeholder;

  int? maxLines;

  String linePrefix = '';

  bool showLineNumbers = false;

  String textColor = '0';
  String placeholderColor = '90';
  String cursorColor = '7';
  String lineNumberColor = '8';

  void Function(String value)? onSubmit;
  void Function(String value)? onChange;

  TextArea({this.placeholder, this.maxLines}) {
    focusable = true;
  }

  String get _currLn => _lns[cursorY];

  int get _lnNumW => showLineNumbers ? '${_lns.length}'.length + 2 : 0;

  int get _pfxW => _lnNumW + linePrefix.length;

  int get _visLns => height;

  int get _visW => width - _pfxW - 1;

  @override
  bool onKey(String key) {
    if (key == KeyCode.UP) {
      if (cursorY > 0) {
        cursorY--;
        cursorX = cursorX.clamp(0, _currLn.length);
        _scrollY();
        update();
      }
      return true;
    }

    if (key == KeyCode.DOWN) {
      if (cursorY < _lns.length - 1) {
        cursorY++;
        cursorX = cursorX.clamp(0, _currLn.length);
        _scrollY();
        update();
      }
      return true;
    }

    if (key == KeyCode.LEFT) {
      if (cursorX > 0) {
        cursorX--;
      } else if (cursorY > 0) {
        cursorY--;
        cursorX = _currLn.length;
      }
      _scrollX();
      update();
      return true;
    }

    if (key == KeyCode.RIGHT) {
      if (cursorX < _currLn.length) {
        cursorX++;
      } else if (cursorY < _lns.length - 1) {
        cursorY++;
        cursorX = 0;
      }
      _scrollX();
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
      cursorX = _currLn.length;
      _scrollX();
      update();
      return true;
    }

    if (key == KeyCode.PAGE_UP) {
      cursorY = (cursorY - _visLns).clamp(0, _lns.length - 1);
      cursorX = cursorX.clamp(0, _currLn.length);
      _scrollY();
      update();
      return true;
    }

    if (key == KeyCode.PAGE_DOWN) {
      cursorY = (cursorY + _visLns).clamp(0, _lns.length - 1);
      cursorX = cursorX.clamp(0, _currLn.length);
      _scrollY();
      update();
      return true;
    }

    if (key == KeyCode.ENTER) {
      if (maxLines != null && _lns.length >= maxLines!) {
        return true;
      }
      var beforeCursor = _currLn.substring(0, cursorX);
      var afterCursor = _currLn.substring(cursorX);
      _lns[cursorY] = beforeCursor;
      _lns.insert(cursorY + 1, afterCursor);
      cursorY++;
      cursorX = 0;
      scrollX = 0;
      _scrollY();
      onChange?.call(value);
      update();
      return true;
    }

    if (key == KeyCode.BACKSPACE) {
      if (cursorX > 0) {
        var line = _currLn;
        _lns[cursorY] = line.substring(0, cursorX - 1) + line.substring(cursorX);
        cursorX--;
        _scrollX();
        onChange?.call(value);
        update();
      } else if (cursorY > 0) {
        var currentLineText = _currLn;
        cursorY--;
        cursorX = _currLn.length;
        _lns[cursorY] = _currLn + currentLineText;
        _lns.removeAt(cursorY + 1);
        _scrollY();
        _scrollX();
        onChange?.call(value);
        update();
      }
      return true;
    }

    if (key == KeyCode.DEL) {
      if (cursorX < _currLn.length) {
        var line = _currLn;
        _lns[cursorY] = line.substring(0, cursorX) + line.substring(cursorX + 1);
        onChange?.call(value);
        update();
      } else if (cursorY < _lns.length - 1) {
        _lns[cursorY] = _currLn + _lns[cursorY + 1];
        _lns.removeAt(cursorY + 1);
        onChange?.call(value);
        update();
      }
      return true;
    }

    if (key == '\x04') {
      onSubmit?.call(value);
      return true;
    }

    if (key.length == 1 && key.codeUnitAt(0) >= 32) {
      var line = _currLn;
      _lns[cursorY] = line.substring(0, cursorX) + key + line.substring(cursorX);
      cursorX++;
      _scrollX();
      onChange?.call(value);
      update();
      return true;
    }

    if (key == KeyCode.TAB) {
      var spaces = '  ';
      var line = _currLn;
      _lns[cursorY] = line.substring(0, cursorX) + spaces + line.substring(cursorX);
      cursorX += spaces.length;
      _scrollX();
      onChange?.call(value);
      update();
      return true;
    }

    return false;
  }

  void _scrollY() {
    if (cursorY < scrollOffset) {
      scrollOffset = cursorY;
    } else if (cursorY >= scrollOffset + _visLns) {
      scrollOffset = cursorY - _visLns + 1;
    }
  }

  void _scrollX() {
    if (cursorX < scrollX) {
      scrollX = cursorX;
    } else if (cursorX >= scrollX + _visW) {
      scrollX = cursorX - _visW + 1;
    }
  }

  @override
  void update() {
    text = [];
    if (width < 3 || height < 1) return;

    var showPlaceholder = _lns.length == 1 && _lns[0].isEmpty && placeholder != null;

    if (showPlaceholder && !focused) {
      text.add(Text(placeholder!)..color = placeholderColor);
      return;
    }

    var endLine = (scrollOffset + _visLns).clamp(0, _lns.length);

    for (var i = scrollOffset; i < endLine; i++) {
      var y = i - scrollOffset;
      var xOffset = 0;

      if (showLineNumbers) {
        var lineNum = '${i + 1}'.padLeft(_lnNumW - 1);
        text.add(Text('$lineNum ')
          ..color = lineNumberColor
          ..position = Position(0, y));
        xOffset = _lnNumW;
      }

      if (linePrefix.isNotEmpty) {
        text.add(Text(linePrefix)
          ..color = textColor
          ..position = Position(xOffset, y));
        xOffset += linePrefix.length;
      }

      var line = _lns[i];
      var visibleLine = line.length > scrollX ? line.substring(scrollX) : '';
      if (visibleLine.length > _visW) {
        visibleLine = visibleLine.substring(0, _visW);
      }

      if (focused && i == cursorY) {
        var cursorPosInVisible = cursorX - scrollX;

        if (cursorPosInVisible >= 0 && cursorPosInVisible <= visibleLine.length) {
          if (cursorPosInVisible > 0) {
            text.add(Text(visibleLine.substring(0, cursorPosInVisible))
              ..color = textColor
              ..position = Position(xOffset, y));
          }

          var cursorChar = cursorPosInVisible < visibleLine.length
              ? visibleLine[cursorPosInVisible]
              : ' ';
          text.add(Text(cursorChar)
            ..color = cursorColor
            ..position = Position(xOffset + cursorPosInVisible, y));

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

    if (_lns.length > _visLns) {
      var maxScroll = _lns.length - _visLns;
      var scrollPercent = maxScroll > 0 ? scrollOffset / maxScroll : 0.0;
      var indicatorY = (scrollPercent * (_visLns - 1)).round();
      text.add(Text('▐')
        ..color = '8'
        ..position = Position(width - 1, indicatorY));
    }
  }
}