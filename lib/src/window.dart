part of tui;

// Window is the top-level view that contains menu, status bar, title, etc

class Window extends View {

  late Screen screen;

  late RenderLoop loop;
  late StreamSubscription<String> input;

  Size? _lastSize;

  /// Currently focused view (null if no view has focus)
  View? _focusedView;
  View? get focusedView => _focusedView;

  void start() {
    stdin.echoMode = false;
    stdin.lineMode = false;
    loop = RenderLoop();
    input = stdin.transform(ascii.decoder).listen(_handleKey);

    stdout.write(ANSI.HIDE_CURSOR);
    stdout.write(ANSI.ERASE_SCREEN);

    // Focus first focusable view
    _focusFirst();

    loop.start(() {
      var termSize = Size(stdout.terminalColumns, stdout.terminalLines);

      // Clear screen if terminal was resized
      if (_lastSize == null ||
          _lastSize!.width != termSize.width ||
          _lastSize!.height != termSize.height) {
        stdout.write(ANSI.ERASE_SCREEN);
        _lastSize = termSize;
      }

      screen = Screen(termSize);
      var canvas = screen.canvas();
      this.resize(canvas.size, canvas.position);
      this.render(canvas);
      stdout.write(ANSI.CURSOR_HOME);
      stdout.write(screen.toString());
    });
  }

  void _handleKey(String key) {
    // Tab cycles focus
    if (key == KeyCode.TAB) {
      focusNext();
      return;
    }
    // Shift+Tab cycles focus backwards
    if (key == KeyCode.SHIFT_TAB) {
      focusPrev();
      return;
    }

    // Route to focused view first
    if (_focusedView != null && _focusedView!.onKey(key)) {
      return; // Key was handled
    }

    // Otherwise let Window handle it
    onKey(key);
  }

  /// Override this to handle keys not consumed by focused view
  @override
  bool onKey(String key) => false;

  /// Focus the first focusable view
  void _focusFirst() {
    var views = focusableViews;
    if (views.isNotEmpty) {
      focus(views.first);
    }
  }

  /// Focus a specific view
  void focus(View view) {
    if (!view.focusable) return;
    if (_focusedView == view) return;

    _focusedView?.focused = false;
    _focusedView?.onBlur();

    _focusedView = view;
    view.focused = true;
    view.onFocus();
  }

  /// Focus the next focusable view
  void focusNext() {
    var views = focusableViews;
    if (views.isEmpty) return;

    if (_focusedView == null) {
      focus(views.first);
      return;
    }

    var idx = views.indexOf(_focusedView!);
    var nextIdx = (idx + 1) % views.length;
    focus(views[nextIdx]);
  }

  /// Focus the previous focusable view
  void focusPrev() {
    var views = focusableViews;
    if (views.isEmpty) return;

    if (_focusedView == null) {
      focus(views.last);
      return;
    }

    var idx = views.indexOf(_focusedView!);
    var prevIdx = (idx - 1 + views.length) % views.length;
    focus(views[prevIdx]);
  }

  void stop() {
    loop.stop();
    input.cancel();
    stdout.write(ANSI.SHOW_CURSOR);
    stdout.write(ANSI.ERASE_SCREEN);
    stdout.write(ANSI.CURSOR_HOME);
    stdin.echoMode = true;
    stdin.lineMode = true;
  }

}