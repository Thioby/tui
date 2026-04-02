part of tui;

/// Top-level view that manages the application lifecycle.
class Window extends View with FocusManager {
  static final _ansiPattern = RegExp(r'\x1B\[[0-9;]*m');

  late Screen _scr;
  late RenderLoop _loop;
  late StreamSubscription<String> _in;
  late InputParser _parser;
  Size? _lastSz;

  bool showFps = false;

  /// Set to true when any state changed and a repaint is needed.
  bool _needsRepaint = true;

  /// Whether this is the very first frame (forces full write).
  bool _firstFrame = true;

  FpsMeter get fps => _loop.fps;

  @override
  View get focusRoot => this;

  /// Mark the window as needing a repaint on the next frame.
  void markDirty() {
    _needsRepaint = true;
  }

  void start() {
    _initTerm();
    _listenInput();
    _startLoop();
    focusFirst();
  }

  void _initTerm() {
    stdin.echoMode = false;
    stdin.lineMode = false;
    stdout.write(ANSI.HIDE_CURSOR);
    stdout.write(ANSI.ERASE_SCREEN);
    stdout.write(ANSI.BRACKETED_PASTE_ON);
  }

  void _listenInput() {
    _parser = InputParser(
      onKey: _onKey,
      onPaste: _onPaste,
    );
    _in = stdin.transform(utf8.decoder).listen(_parser.feed);
  }

  void _startLoop() {
    _loop = RenderLoop();
    _loop.start(() {
      final termSize = Size(
        stdout.terminalColumns,
        stdout.terminalLines,
      );

      // Handle terminal resize — reallocate buffers.
      final resized = _lastSz == null ||
          _lastSz!.width != termSize.width ||
          _lastSz!.height != termSize.height;

      if (resized) {
        stdout.write(ANSI.ERASE_SCREEN);
        _lastSz = termSize;
        _scr = Screen(termSize);
        _firstFrame = true;
        _needsRepaint = true;
      }

      _needsRepaint = true;

      _scr.clear();
      final canvas = _scr.canvas();
      resize(canvas.size, canvas.position);
      render(canvas);

      if (_firstFrame) {
        // First frame: write everything.
        stdout.write(ANSI.CURSOR_HOME);
        stdout.write(_scr.toString());
        _scr.swapBuffers();
        _firstFrame = false;
      } else {
        // Subsequent frames: write only changed lines.
        final patch = _scr.diff();
        if (patch.isNotEmpty) {
          stdout.write(patch);
        }
        _scr.swapBuffers();
      }

      _needsRepaint = false;

      if (showFps) {
        final fpsText = _loop.fps.compact;
        final plainText = fpsText.replaceAll(_ansiPattern, '');
        final fpsX = termSize.width - plainText.length - 1;
        if (fpsX > 0) {
          stdout.write(
            '\x1B[1;${fpsX}H${Colors.dim}$fpsText${Colors.reset}',
          );
        }
      }
    });
  }

  void _onKey(String key) {
    if (key == KeyCode.TAB) {
      focusNext();
      return;
    }
    if (key == KeyCode.SHIFT_TAB) {
      focusPrev();
      return;
    }

    if (routeKeyToFocused(key)) {
      return;
    }

    onKey(key);
  }

  void _onPaste(String text) {
    if (routePasteToFocused(text)) {
      return;
    }
    onPaste(text);
  }

  @override
  bool onKey(String key) => false;

  @override
  bool onPaste(String text) => false;

  void stop() {
    _loop.stop();
    _parser.dispose();
    scheduleMicrotask(() {
      _in.cancel();
      _restoreTerm();
    });
  }

  void _restoreTerm() {
    stdout.write(ANSI.BRACKETED_PASTE_OFF);
    stdout.write(ANSI.SHOW_CURSOR);
    stdout.write(ANSI.ERASE_SCREEN);
    stdout.write(ANSI.CURSOR_HOME);
    try {
      stdin.echoMode = true;
      stdin.lineMode = true;
    } on StdinException {}
  }
}
