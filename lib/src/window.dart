part of tui;

/// Top-level view that manages the application lifecycle.
///
/// Window is responsible for:
/// - Terminal setup/teardown
/// - Screen management and rendering loop
/// - Keyboard input routing
/// - Focus management (via FocusManager mixin)
///
/// Example:
/// ```dart
/// class MyApp extends Window {
///   MyApp() {
///     children = [MyMainView()];
///   }
///
///   @override
///   bool onKey(String key) {
///     if (key == 'q') { stop(); return true; }
///     return false;
///   }
/// }
///
/// void main() => MyApp().start();
/// ```
class Window extends View with FocusManager {
  late Screen _screen;
  late RenderLoop _loop;
  late StreamSubscription<String> _input;
  Size? _lastSize;

  @override
  View get focusRoot => this;

  /// Starts the application.
  ///
  /// Sets up the terminal, starts the render loop, and begins
  /// listening for keyboard input.
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
      if (_lastSize == null ||
          _lastSize!.width != termSize.width ||
          _lastSize!.height != termSize.height) {
        stdout.write(ANSI.ERASE_SCREEN);
        _lastSize = termSize;
      }

      _screen = Screen(termSize);
      var canvas = _screen.canvas();
      resize(canvas.size, canvas.position);
      render(canvas);
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

  /// Stops the application and restores the terminal.
  ///
  /// Uses scheduleMicrotask to defer cleanup until after
  /// the current event handler completes.
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
    stdin.echoMode = true;
    stdin.lineMode = true;
  }
}
