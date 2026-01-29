part of tui;

/// Top-level view that manages the application lifecycle.
class Window extends View with FocusManager {
  late Screen _scr;
  late RenderLoop _loop;
  late StreamSubscription<String> _in;
  Size? _lastSz;

  bool showFps = false;

  FpsMeter get fps => _loop.fps;

  @override
  View get focusRoot => this;

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
  }

  void _listenInput() {
    _in = stdin.transform(ascii.decoder).listen(_onInput);
  }

  void _startLoop() {
    _loop = RenderLoop();
    _loop.start(() {
      var termSize = Size(stdout.terminalColumns, stdout.terminalLines);

      if (_lastSz == null || _lastSz!.width != termSize.width || _lastSz!.height != termSize.height) {
        stdout.write(ANSI.ERASE_SCREEN);
        _lastSz = termSize;
      }

      _scr = Screen(termSize);
      var canvas = _scr.canvas();
      resize(canvas.size, canvas.position);
      render(canvas);

      stdout.write(ANSI.CURSOR_HOME);
      stdout.write(_scr.toString());

      if (showFps) {
        final fpsText = _loop.fps.compact;
        final plainText = fpsText.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
        final fpsX = termSize.width - plainText.length - 1;
        if (fpsX > 0) {
          stdout.write('\x1B[1;${fpsX}H${Colors.dim}$fpsText${Colors.reset}');
        }
      }
    });
  }

  void _onInput(String key) {
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

  @override
  bool onKey(String key) => false;

  void stop() {
    _loop.stop();
    scheduleMicrotask(() {
      _in.cancel();
      _restoreTerm();
    });
  }

  void _restoreTerm() {
    stdout.write(ANSI.SHOW_CURSOR);
    stdout.write(ANSI.ERASE_SCREEN);
    stdout.write(ANSI.CURSOR_HOME);
    try {
      stdin.echoMode = true;
      stdin.lineMode = true;
    } on StdinException {
    }
  }
}