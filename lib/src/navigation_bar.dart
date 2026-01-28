part of tui;

/// A focusable button widget.
///
/// Renders as `[ Label ]` with highlight when focused.
/// Calls [onPressed] when Enter is pressed while focused.
class Button extends View {
  String label;
  void Function()? onPressed;

  String normalColor;
  String focusedColor;

  Button(
    this.label, {
    this.onPressed,
    this.normalColor = "7",
    this.focusedColor = "32",
  }) {
    focusable = true;
  }

  @override
  void update() {
    var display = "[ $label ]";
    var color = focused ? focusedColor : normalColor;
    text = [Text(display)..color = color];
  }

  @override
  void onFocus() {
    update();
  }

  @override
  void onBlur() {
    update();
  }

  @override
  bool onKey(String key) {
    if (key == KeyCode.ENTER || key == " ") {
      onPressed?.call();
      return true;
    }
    return false;
  }

  int get displayWidth => label.length + 4; // "[ " + label + " ]"
}

/// Navigation bar with Prev/Next buttons for PageView.
///
/// Buttons are right-aligned. Prev button is optional (pass null for prevLabel).
class NavigationBar extends View {
  final Page page;
  String? prevLabel;
  String nextLabel;

  late Button? _prevButton;
  late Button _nextButton;

  NavigationBar(
    this.page, {
    this.prevLabel = "← Wstecz",
    this.nextLabel = "Dalej →",
  }) {
    _setupButtons();
  }

  void _setupButtons() {
    if (prevLabel != null) {
      _prevButton = Button(prevLabel!, onPressed: _onPrev);
      children.add(_prevButton!);
    } else {
      _prevButton = null;
    }

    _nextButton = Button(nextLabel, onPressed: _onNext);
    children.add(_nextButton);
  }

  void _onPrev() {
    page.pageView.goPrev();
  }

  void _onNext() {
    page.pageView.goNext();
  }

  @override
  void resizeChildren() {
    // Right-align buttons
    int x = width;

    // Next button (rightmost)
    x -= _nextButton.displayWidth;
    _nextButton.resize(Size(_nextButton.displayWidth, 1), Position(x, 0));

    // Prev button (if exists)
    if (_prevButton != null) {
      x -= _prevButton!.displayWidth + 1; // +1 for spacing
      _prevButton!.resize(Size(_prevButton!.displayWidth, 1), Position(x, 0));
    }
  }
}
