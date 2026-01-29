part of tui;

/// Navigation bar with Prev/Next buttons for PageView.
class NavigationBar extends View {
  final Page page;
  String? prevLabel;
  String nextLabel;

  late Button? _btnPrev;
  late Button _btnNext;

  NavigationBar(
    this.page, {
    this.prevLabel = "← Wstecz",
    this.nextLabel = "Dalej →",
  }) {
    _initBtns();
  }

  void _initBtns() {
    if (prevLabel != null) {
      _btnPrev = Button(prevLabel!, onPressed: _prev);
      children.add(_btnPrev!);
    } else {
      _btnPrev = null;
    }

    _btnNext = Button(nextLabel, onPressed: _next);
    children.add(_btnNext);
  }

  void _prev() {
    page.pageView.goPrev();
  }

  void _next() {
    page.pageView.goNext();
  }

  @override
  void resizeChildren() {
    int x = width;

    x -= _btnNext.displayWidth;
    _btnNext.resize(Size(_btnNext.displayWidth, 1), Position(x, 0));

    if (_btnPrev != null) {
      x -= _btnPrev!.displayWidth + 1;
      _btnPrev!.resize(Size(_btnPrev!.displayWidth, 1), Position(x, 0));
    }
  }
}

/// A focusable button widget.
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

  int get displayWidth => label.length + 4;
}