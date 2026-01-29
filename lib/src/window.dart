part of tui;

/// Top-level view that manages the application lifecycle.
class Window extends View with FocusManager {
  late Screen _screen;
  late RenderLoop _loop;
  late StreamSubscription<String> _input;
  Size? _lastSize;

  /// Show FPS meter in top-right corner.
  bool showFps = false;

  /// Access to FPS statistics.
  FpsMeter get fps => _loop.fps;

  @override
  View get focusRoot => this;

  /// Starts the application.
  void start() {
    _setupTerminal();
    _startInputListener();
    _startRenderLoop();
    focusFirst();
  }

  void _setupTerminal() {
    stdin.echoMode = false;
    stdin.lineMode = false;
    stdout.write(ANSI.HIDE_CURSOR);
    stdout.write(ANSI.ERASE_SCREEN);
  }

  void _startInputListener() {
    _input = stdin.transform(ascii.decoder).listen(_handleKey);
  }

  void _startRenderLoop() {
    _loop = RenderLoop();
    _loop.start(() {
      var termSize = Size(stdout.terminalColumns, stdout.terminalLines);

      // Clear screen if terminal was resized
      if (_lastSize == null || _lastSize!.width != termSize.width || _lastSize!.height != termSize.height) {
        stdout.write(ANSI.ERASE_SCREEN);
        _lastSize = termSize;
      }

      _screen = Screen(termSize);
      var canvas = _screen.canvas();
      resize(canvas.size, canvas.position);
      render(canvas);

      // Render FPS meter in top-right corner using direct cursor positioning
      if (showFps) {
        final fpsText = _loop.fps.compact;
        // Strip ANSI for length calculation
        final plainText = fpsText.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
        final fpsX = termSize.width - plainText.length - 1;
        if (fpsX > 0) {
          stdout.write('\x1B[1;${fpsX}H${Colors.dim}$fpsText${Colors.reset}');
        }
      }

      stdout.write(ANSI.CURSOR_HOME);
      stdout.write(_screen.toString());
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
    if (routeKeyToFocused(key)) {
      return; // Key was handled
    }

    // Otherwise let Window handle it
    onKey(key);
  }

  /// Override to handle keys not consumed by focused view.
  @override
  bool onKey(String key) => false;

  void stop() {
    _loop.stop();
    // Defer cleanup to avoid conflicts with stdin event handling
    scheduleMicrotask(() {
      _input.cancel();
      _restoreTerminal();
    });
  }

  void _restoreTerminal() {
    stdout.write(ANSI.SHOW_CURSOR);
    stdout.write(ANSI.ERASE_SCREEN);
    stdout.write(ANSI.CURSOR_HOME);
    try {
      stdin.echoMode = true;
      stdin.lineMode = true;
    } on StdinException {
      // Terminal may already be in bad state during shutdown
    }
  }
}
