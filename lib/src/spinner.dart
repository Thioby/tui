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
/// Example:
/// ```dart
/// var spinner = Spinner(label: 'Loading...')
///   ..start();
/// // Later:
/// spinner.stop();
/// ```
class Spinner extends View {
  /// Label text displayed next to spinner.
  String? label;

  /// Whether the spinner is running.
  bool running = false;

  /// Animation style.
  SpinnerStyle style;

  /// Animation speed in milliseconds.
  int interval;

  /// Color for the spinner (ANSI code).
  String spinnerColor = '36';

  /// Color for the label (ANSI code).
  String labelColor = '0';

  /// Position of label relative to spinner.
  bool labelOnRight;

  Timer? _timer;
  int _frame = 0;

  static const Map<SpinnerStyle, List<String>> _frames = {
    SpinnerStyle.dots: ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'],
    SpinnerStyle.dots2: ['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷'],
    SpinnerStyle.circle: ['◐', '◓', '◑', '◒'],
    SpinnerStyle.circleHalf: ['◴', '◷', '◶', '◵'],
    SpinnerStyle.line: ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█', '▇', '▆', '▅', '▄', '▃', '▂'],
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
    _timer = Timer.periodic(Duration(milliseconds: interval), (_) {
      _frame++;
      update();
    });
    update();
  }

  /// Stop the spinner animation.
  void stop() {
    running = false;
    _timer?.cancel();
    _timer = null;
    update();
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