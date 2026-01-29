part of tui;

/// Single-line text input field.
class Input extends View {
  String _val = '';
  String get value => _val;
  set value(String v) {
    if (maxLength != null && v.length > maxLength!) {
      v = v.substring(0, maxLength);
    }
    _val = v;
    if (cursorPosition > _val.length) {
      cursorPosition = _val.length;
    }
    update();
  }

  int cursorPosition = 0;

  String? placeholder;

  bool password = false;

  int? maxLength;

  String prompt = '> ';

  String promptColor = '36';
  String textColor = '0';
  String placeholderColor = '90';
  String cursorColor = '7';

  void Function(String value)? onSubmit;
  void Function(String value)? onChange;

  Input({this.placeholder, this.password = false, this.maxLength}) {
    focusable = true;
  }

  @override
  void onFocus() {
    update();
  }

  @override
  void onBlur() {
    focused = false;
    update();
  }

  @override
  bool onKey(String key) {
    if (key == KeyCode.ENTER) {
      onSubmit?.call(_val);
      return true;
    }

    if (key == KeyCode.LEFT) {
      if (cursorPosition > 0) {
        cursorPosition--;
        update();
      }
      return true;
    }

    if (key == KeyCode.RIGHT) {
      if (cursorPosition < _val.length) {
        cursorPosition++;
        update();
      }
      return true;
    }

    if (key == KeyCode.HOME) {
      cursorPosition = 0;
      update();
      return true;
    }

    if (key == KeyCode.END) {
      cursorPosition = _val.length;
      update();
      return true;
    }

    if (key == KeyCode.BACKSPACE) {
      if (cursorPosition > 0) {
        _val = _val.substring(0, cursorPosition - 1) +
            _val.substring(cursorPosition);
        cursorPosition--;
        onChange?.call(_val);
        update();
      }
      return true;
    }

    if (key == KeyCode.DEL) {
      if (cursorPosition < _val.length) {
        _val = _val.substring(0, cursorPosition) +
            _val.substring(cursorPosition + 1);
        onChange?.call(_val);
        update();
      }
      return true;
    }

    if (key.length == 1 && key.codeUnitAt(0) >= 32) {
      if (maxLength == null || _val.length < maxLength!) {
        _val = _val.substring(0, cursorPosition) +
            key +
            _val.substring(cursorPosition);
        cursorPosition++;
        onChange?.call(_val);
        update();
      }
      return true;
    }

    return false;
  }

  @override
  void update() {
    text = [];
    if (width < 1 || height < 1) return;

    var displayText = _val;
    if (password) {
      displayText = '*' * _val.length;
    }

    var showPlaceholder = _val.isEmpty && placeholder != null;
    var contentToShow = showPlaceholder ? placeholder! : displayText;

    var availableWidth = width - prompt.length;
    if (availableWidth < 1) availableWidth = 1;

    var scrollOffset = 0;
    if (cursorPosition > availableWidth - 1) {
      scrollOffset = cursorPosition - availableWidth + 1;
    }

    var visibleContent = contentToShow.length > scrollOffset
        ? contentToShow.substring(scrollOffset)
        : '';
    if (visibleContent.length > availableWidth) {
      visibleContent = visibleContent.substring(0, availableWidth);
    }

    text.add(Text(prompt)..color = promptColor);

    if (showPlaceholder) {
      text.add(Text(visibleContent)
        ..color = placeholderColor
        ..position = Position(prompt.length, 0));
    } else if (focused) {
      var cursorPosInVisible = cursorPosition - scrollOffset;

      if (cursorPosInVisible >= 0 && cursorPosInVisible <= visibleContent.length) {
        if (cursorPosInVisible > 0) {
          text.add(Text(visibleContent.substring(0, cursorPosInVisible))
            ..color = textColor
            ..position = Position(prompt.length, 0));
        }

        var cursorChar = cursorPosInVisible < visibleContent.length
            ? visibleContent[cursorPosInVisible]
            : ' ';
        text.add(Text(cursorChar)
          ..color = cursorColor
          ..position = Position(prompt.length + cursorPosInVisible, 0));

        if (cursorPosInVisible < visibleContent.length - 1) {
          text.add(Text(visibleContent.substring(cursorPosInVisible + 1))
            ..color = textColor
            ..position = Position(prompt.length + cursorPosInVisible + 1, 0));
        }
      } else {
        text.add(Text(visibleContent)
          ..color = textColor
          ..position = Position(prompt.length, 0));
      }
    } else {
      text.add(Text(visibleContent)
        ..color = textColor
        ..position = Position(prompt.length, 0));
    }
  }
}