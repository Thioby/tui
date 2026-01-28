part of tui;

/// Single-line text input field.
///
/// Example:
/// ```dart
/// var input = Input(placeholder: 'Enter name...')
///   ..onSubmit = (value) => print('Submitted: $value');
/// ```
class Input extends View {
  String _value = '';
  String get value => _value;
  set value(String v) {
    if (maxLength != null && v.length > maxLength!) {
      v = v.substring(0, maxLength);
    }
    _value = v;
    if (cursorPosition > _value.length) {
      cursorPosition = _value.length;
    }
    update();
  }

  int cursorPosition = 0;

  /// Placeholder text shown when value is empty.
  String? placeholder;

  /// If true, displays asterisks instead of actual characters.
  bool password = false;

  /// Maximum number of characters. Null means no limit.
  int? maxLength;

  /// Prompt displayed before the input field.
  String prompt = '> ';

  /// Color for the prompt (ANSI code).
  String promptColor = '36';

  /// Color for the text (ANSI code).
  String textColor = '0';

  /// Color for the placeholder (ANSI code).
  String placeholderColor = '90';

  /// Color for the cursor (ANSI code).
  String cursorColor = '7'; // inverted

  /// Called when Enter is pressed.
  void Function(String value)? onSubmit;

  /// Called when value changes.
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
      onSubmit?.call(_value);
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
      if (cursorPosition < _value.length) {
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
      cursorPosition = _value.length;
      update();
      return true;
    }

    if (key == KeyCode.BACKSPACE) {
      if (cursorPosition > 0) {
        _value = _value.substring(0, cursorPosition - 1) +
            _value.substring(cursorPosition);
        cursorPosition--;
        onChange?.call(_value);
        update();
      }
      return true;
    }

    if (key == KeyCode.DEL) {
      if (cursorPosition < _value.length) {
        _value = _value.substring(0, cursorPosition) +
            _value.substring(cursorPosition + 1);
        onChange?.call(_value);
        update();
      }
      return true;
    }

    // Regular character input
    if (key.length == 1 && key.codeUnitAt(0) >= 32) {
      if (maxLength == null || _value.length < maxLength!) {
        _value = _value.substring(0, cursorPosition) +
            key +
            _value.substring(cursorPosition);
        cursorPosition++;
        onChange?.call(_value);
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

    var displayText = _value;
    if (password) {
      displayText = '*' * _value.length;
    }

    var showPlaceholder = _value.isEmpty && placeholder != null;
    var contentToShow = showPlaceholder ? placeholder! : displayText;

    // Calculate available width for text
    var availableWidth = width - prompt.length;
    if (availableWidth < 1) availableWidth = 1;

    // Handle scrolling if text is longer than available width
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

    // Prompt
    text.add(Text(prompt)..color = promptColor);

    if (showPlaceholder) {
      // Show placeholder
      text.add(Text(visibleContent)
        ..color = placeholderColor
        ..position = Position(prompt.length, 0));
    } else if (focused) {
      // Show text with cursor
      var cursorPosInVisible = cursorPosition - scrollOffset;

      if (cursorPosInVisible >= 0 && cursorPosInVisible <= visibleContent.length) {
        // Text before cursor
        if (cursorPosInVisible > 0) {
          text.add(Text(visibleContent.substring(0, cursorPosInVisible))
            ..color = textColor
            ..position = Position(prompt.length, 0));
        }

        // Cursor character (inverted)
        var cursorChar = cursorPosInVisible < visibleContent.length
            ? visibleContent[cursorPosInVisible]
            : ' ';
        text.add(Text(cursorChar)
          ..color = cursorColor
          ..position = Position(prompt.length + cursorPosInVisible, 0));

        // Text after cursor
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
      // Not focused - just show text
      text.add(Text(visibleContent)
        ..color = textColor
        ..position = Position(prompt.length, 0));
    }
  }
}
