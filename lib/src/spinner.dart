part of tui;

/// Spinner animation styles.
enum SpinnerStyle {
  /// ⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏
  dots,

  /// ⣾⣽⣻⢿⡿⣟⣯⣷
  dots2,

  /// ◐◓◑◒
  circle,

  /// ◴◷◶◵
  circleHalf,

  /// ▁▂▃▄▅▆▇█▇▆▅▄▃▂
  line,

  /// ←↖↑↗→↘↓↙
  arrow,

  /// ▖▘▝▗
  square,

  /// ◢◣◤◥
  triangle,

  /// ⠁⠂⠄⡀⢀⠠⠐⠈
  bounce,

  /// |/-
  pipe,

  /// ◜◝◞◟
  moon,

  /// .oO@*
  pulse,
}

/// Animated loading indicator.
///
/// Frame advance is driven by the render loop via [render] when
/// the spinner is part of the view tree. A fallback Timer ensures
/// the animation also works when the spinner is used standalone
/// (e.g. in `_SpinnerShowcase` where only [update] is called).
class Spinner extends View {
  /// Label text displayed next to spinner.
  String? label;

  /// Whether the spinner is running.
  bool running = false;

  /// Animation style.
  SpinnerStyle style;

  /// Minimum milliseconds between frame changes.
  int interval;

  /// Color for the spinner (ANSI code).
  String spinnerColor = '36';

  /// Color for the label (ANSI code).
  String labelColor = '0';

  /// Position of label relative to spinner.
  bool labelOnRight;

  Timer? _timer;
  int _frame = 0;
  DateTime _lastTick = DateTime.now();

  /// Set to true once [render] is called — disables the fallback
  /// timer since the render loop drives the animation.
  bool _renderDriven = false;

  static const Map<SpinnerStyle, List<String>> _frames = {
    SpinnerStyle.dots: ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'],
    SpinnerStyle.dots2: ['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷'],
    SpinnerStyle.circle: ['◐', '◓', '◑', '◒'],
    SpinnerStyle.circleHalf: ['◴', '◷', '◶', '◵'],
    SpinnerStyle.line: [
      '▁',
      '▂',
      '▃',
      '▄',
      '▅',
      '▆',
      '▇',
      '█',
      '▇',
      '▆',
      '▅',
      '▄',
      '▃',
      '▂'
    ],
    SpinnerStyle.arrow: ['←', '↖', '↑', '↗', '→', '↘', '↓', '↙'],
    SpinnerStyle.square: ['▖', '▘', '▝', '▗'],
    SpinnerStyle.triangle: ['◢', '◣', '◤', '◥'],
    SpinnerStyle.bounce: ['⠁', '⠂', '⠄', '⡀', '⢀', '⠠', '⠐', '⠈'],
    SpinnerStyle.pipe: ['|', '/', '-', '\\'],
    SpinnerStyle.moon: ['◜', '◝', '◞', '◟'],
    SpinnerStyle.pulse: ['.', 'o', 'O', '@', '*'],
  };

  Spinner({
    this.label,
    this.style = SpinnerStyle.dots,
    this.interval = 80,
    this.labelOnRight = true,
  });

  List<String> get _currentFrames => _frames[style]!;

  String get _currentFrame => _currentFrames[_frame % _currentFrames.length];

  /// Start the spinner animation.
  void start() {
    if (running) return;
    running = true;
    _frame = 0;
    _lastTick = DateTime.now();
    _startTimer();
    update();
  }

  /// Stop the spinner animation.
  void stop() {
    running = false;
    _stopTimer();
    update();
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(Duration(milliseconds: interval), (_) {
      if (!running) return;
      // Only tick from timer if render() is NOT driving us.
      if (_renderDriven) return;
      _advanceFrame();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _advanceFrame() {
    _frame++;
    _lastTick = DateTime.now();
    update();
  }

  @override
  void render(Canvas canvas) {
    _renderDriven = true;
    // Advance frame if enough time has elapsed.
    if (running) {
      final now = DateTime.now();
      if (now.difference(_lastTick).inMilliseconds >= interval) {
        _advanceFrame();
      }
    }
    super.render(canvas);
  }

  @override
  void update() {
    text = [];
    if (width < 1 || height < 1) return;

    if (!running) {
      if (label != null) {
        text.add(Text(label!)..color = labelColor);
      }
      return;
    }

    var spinnerChar = _currentFrame;

    if (label == null || label!.isEmpty) {
      text.add(Text(spinnerChar)..color = spinnerColor);
    } else if (labelOnRight) {
      text.add(Text(spinnerChar)..color = spinnerColor);
      text.add(Text(' $label')
        ..color = labelColor
        ..position = Position(1, 0));
    } else {
      text.add(Text(label!)..color = labelColor);
      text.add(Text(' $spinnerChar')
        ..color = spinnerColor
        ..position = Position(label!.length, 0));
    }
  }
}
