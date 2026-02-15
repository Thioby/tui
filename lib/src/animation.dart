part of tui;

/// Easing functions for animations.
abstract class Easing {
  static double linear(double t) => t;

  static double easeIn(double t) => t * t;
  static double easeOut(double t) => 1 - (1 - t) * (1 - t);
  static double easeInOut(double t) =>
      t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2).toDouble() / 2;

  static double easeInCubic(double t) => t * t * t;
  static double easeOutCubic(double t) => 1 - pow(1 - t, 3).toDouble();
  static double easeInOutCubic(double t) =>
      t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3).toDouble() / 2;

  static double easeInElastic(double t) {
    if (t == 0 || t == 1) return t;
    return -pow(2, 10 * t - 10).toDouble() *
        sin((t * 10 - 10.75) * (2 * pi / 3));
  }

  static double easeOutElastic(double t) {
    if (t == 0 || t == 1) return t;
    return pow(2, -10 * t).toDouble() * sin((t * 10 - 0.75) * (2 * pi / 3)) + 1;
  }

  static double easeOutBounce(double t) {
    const n1 = 7.5625;
    const d1 = 2.75;
    if (t < 1 / d1) {
      return n1 * t * t;
    } else if (t < 2 / d1) {
      t -= 1.5 / d1;
      return n1 * t * t + 0.75;
    } else if (t < 2.5 / d1) {
      t -= 2.25 / d1;
      return n1 * t * t + 0.9375;
    } else {
      t -= 2.625 / d1;
      return n1 * t * t + 0.984375;
    }
  }
}

/// How the animation should repeat.
enum RepeatMode {
  /// Play once and stop.
  once,

  /// Play forward, then reverse, then stop.
  reverse,

  /// Loop forever in one direction.
  loop,

  /// Loop forever, alternating forward and reverse.
  pingPong,
}

/// Base class for all animations.
abstract class Animation {
  final Duration duration;
  final double Function(double) easing;
  final void Function()? onComplete;

  /// How the animation repeats.
  final RepeatMode repeatMode;

  /// Number of times to repeat (0 = use repeatMode, >0 = repeat N times then stop).
  final int repeatCount;

  bool _running = false;
  bool _completed = false;
  Stopwatch? _stopwatch;
  int _currentIteration = 0;
  bool _reversed = false;

  bool get running => _running;
  bool get completed => _completed;

  /// Current iteration (0-based).
  int get currentIteration => _currentIteration;

  /// Whether currently playing in reverse.
  bool get reversed => _reversed;

  Animation({
    required this.duration,
    this.easing = Easing.linear,
    this.onComplete,
    this.repeatMode = RepeatMode.once,
    this.repeatCount = 0,
  });

  /// Start the animation.
  void start() {
    _running = true;
    _completed = false;
    _currentIteration = 0;
    _reversed = false;
    _stopwatch = Stopwatch()..start();
  }

  /// Stop the animation.
  void stop() {
    _running = false;
    _stopwatch?.stop();
  }

  /// Reset the animation.
  void reset() {
    _running = false;
    _completed = false;
    _currentIteration = 0;
    _reversed = false;
    _stopwatch?.reset();
  }

  /// Get current progress (0.0 to 1.0), handling repeat modes.
  double get progress {
    if (_stopwatch == null || !_running) return 0;

    final elapsed = _stopwatch!.elapsedMilliseconds;
    final totalDuration = duration.inMilliseconds;

    // Guard against zero duration - complete immediately
    if (totalDuration <= 0) {
      _complete();
      return easing(1.0);
    }

    // Calculate raw progress including iterations
    var totalElapsed = elapsed;
    var iterationProgress = (totalElapsed % totalDuration) / totalDuration;
    var iteration = totalElapsed ~/ totalDuration;

    // Handle different repeat modes
    switch (repeatMode) {
      case RepeatMode.once:
        if (iteration >= 1) {
          _complete();
          return easing(1.0);
        }
        return easing(iterationProgress);

      case RepeatMode.reverse:
        // Forward then reverse = 2 iterations total
        if (iteration >= 2) {
          _complete();
          return easing(0.0);
        }
        _currentIteration = iteration;
        _reversed = iteration == 1;
        var t = _reversed ? 1.0 - iterationProgress : iterationProgress;
        return easing(t);

      case RepeatMode.loop:
        if (repeatCount > 0 && iteration >= repeatCount) {
          _complete();
          return easing(1.0);
        }
        _currentIteration = iteration;
        return easing(iterationProgress);

      case RepeatMode.pingPong:
        if (repeatCount > 0 && iteration >= repeatCount * 2) {
          _complete();
          return easing(0.0);
        }
        _currentIteration = iteration ~/ 2;
        _reversed = iteration.isOdd;
        var t = _reversed ? 1.0 - iterationProgress : iterationProgress;
        return easing(t);
    }
  }

  void _complete() {
    if (!_completed) {
      _completed = true;
      _running = false;
      onComplete?.call();
    }
  }

  /// Update the animation. Called each frame.
  void update();
}

/// Interpolates between two values over time.
class Tween<T> {
  final T begin;
  final T end;
  final T Function(T, T, double) lerp;

  Tween({required this.begin, required this.end, required this.lerp});

  T evaluate(double t) => lerp(begin, end, t);

  /// Common tweens.
  static Tween<double> number(double begin, double end) => Tween(
        begin: begin,
        end: end,
        lerp: (a, b, t) => a + (b - a) * t,
      );

  static Tween<int> integer(int begin, int end) => Tween(
        begin: begin,
        end: end,
        lerp: (a, b, t) => (a + (b - a) * t).round(),
      );

  static Tween<RGB> color(RGB begin, RGB end) => Tween(
        begin: begin,
        end: end,
        lerp: (a, b, t) => a.lerp(b, t),
      );
}

/// Animation controller to manage multiple animations.
///
/// Two modes of operation:
/// - **Self-ticking** (default): owns a `Timer.periodic` that calls
///   [tick] automatically. Used when the controller lives outside
///   the render tree (e.g. as a field on a Window subclass).
/// - **Externally-ticked**: set `selfTick = false` and call [tick]
///   manually from `render()`. Used by the [Animated] mixin and
///   [AnimatedBigText] to stay synchronised with the frame clock.
class AnimationController {
  final List<Animation> _animations = [];
  Timer? _timer;
  int _fps;
  final bool selfTick;

  int get fps => _fps;
  set fps(int value) {
    _fps = value.clamp(1, 120);
    if (selfTick && _timer != null) {
      _stopTimer();
      _startTimer();
    }
  }

  /// Whether there are running animations.
  bool get hasAnimations => _animations.isNotEmpty;

  AnimationController({int fps = 30, this.selfTick = true}) : _fps = fps;

  /// Add an animation.
  void add(Animation animation) {
    _animations.add(animation);
    animation.start();
    if (selfTick) _ensureRunning();
  }

  /// Remove an animation.
  void remove(Animation animation) {
    _animations.remove(animation);
    if (selfTick && _animations.isEmpty) _stopTimer();
  }

  /// Remove all animations.
  void clear() {
    for (var anim in _animations) {
      anim.stop();
    }
    _animations.clear();
    if (selfTick) _stopTimer();
  }

  /// Advance all animations by one frame.
  ///
  /// Returns true if any animation is still running.
  bool tick() {
    if (_animations.isEmpty) return false;

    var completed = <Animation>[];
    for (var anim in _animations) {
      anim.update();
      if (anim.completed) {
        completed.add(anim);
      }
    }
    for (var anim in completed) {
      _animations.remove(anim);
    }
    if (selfTick && _animations.isEmpty) _stopTimer();
    return _animations.isNotEmpty;
  }

  void _ensureRunning() {
    if (_timer == null && _animations.isNotEmpty) _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(
      Duration(milliseconds: 1000 ~/ _fps),
      (_) => tick(),
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TEXT ANIMATIONS
// ═══════════════════════════════════════════════════════════════════════════

/// Typewriter effect - reveals text character by character.
class TypewriterAnimation extends Animation {
  final String text;
  final void Function(String visible) onUpdate;
  final String? color;

  int _visibleChars = 0;

  TypewriterAnimation({
    required this.text,
    required this.onUpdate,
    this.color,
    Duration? duration,
    super.easing,
    super.onComplete,
  }) : super(duration: duration ?? Duration(milliseconds: text.length * 30));

  @override
  void update() {
    var p = progress;
    var newVisible = (text.length * p).floor();
    if (newVisible != _visibleChars) {
      _visibleChars = newVisible;
      onUpdate(text.substring(0, _visibleChars));
    }
  }
}

/// Glitch effect - randomly replaces characters.
class GlitchAnimation extends Animation {
  final String text;
  final void Function(String glitched) onUpdate;
  final String glitchChars;
  final double intensity;
  final Random _random = Random();

  GlitchAnimation({
    required this.text,
    required this.onUpdate,
    this.glitchChars = '!@#\$%\^&*<>[]{}|/\\~`',
    this.intensity = 0.3,
    Duration duration = const Duration(milliseconds: 500),
    super.onComplete,
  }) : super(duration: duration);

  @override
  void update() {
    var p = progress;
    // Intensity decreases as we approach the end
    var currentIntensity = intensity * (1 - p);

    var glitched = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (_random.nextDouble() < currentIntensity) {
        glitched.write(glitchChars[_random.nextInt(glitchChars.length)]);
      } else {
        glitched.write(text[i]);
      }
    }
    onUpdate(glitched.toString());
  }
}

/// Pulse effect - alternates between two states.
class PulseAnimation extends Animation {
  final void Function(bool bright) onUpdate;
  final int pulses;

  int _lastPulse = -1;

  PulseAnimation({
    required this.onUpdate,
    this.pulses = 3,
    Duration? duration,
    super.onComplete,
  }) : super(duration: duration ?? Duration(milliseconds: pulses * 400));

  @override
  void update() {
    var p = progress;
    var pulse = (p * pulses * 2).floor();
    if (pulse != _lastPulse) {
      _lastPulse = pulse;
      onUpdate(pulse.isEven);
    }
  }
}

/// Fade animation - interpolates opacity/visibility.
class FadeAnimation extends Animation {
  final void Function(double opacity) onUpdate;
  final double from;
  final double to;

  FadeAnimation({
    required this.onUpdate,
    this.from = 0.0,
    this.to = 1.0,
    Duration duration = const Duration(milliseconds: 300),
    super.easing = Easing.easeOut,
    super.onComplete,
  }) : super(duration: duration);

  @override
  void update() {
    var p = progress;
    var opacity = from + (to - from) * p;
    onUpdate(opacity);
  }
}

/// Slide animation - moves position over time.
class SlideAnimation extends Animation {
  final void Function(int x, int y) onUpdate;
  final int fromX, fromY;
  final int toX, toY;

  SlideAnimation({
    required this.onUpdate,
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    Duration duration = const Duration(milliseconds: 300),
    super.easing = Easing.easeOut,
    super.onComplete,
  }) : super(duration: duration);

  @override
  void update() {
    var p = progress;
    var x = (fromX + (toX - fromX) * p).round();
    var y = (fromY + (toY - fromY) * p).round();
    onUpdate(x, y);
  }
}

/// Cascade animation - reveals items in sequence.
class CascadeAnimation extends Animation {
  final List<String> items;
  final void Function(int visibleCount, List<String> visibleItems) onUpdate;
  final Duration itemDelay;

  int _lastCount = 0;

  CascadeAnimation({
    required this.items,
    required this.onUpdate,
    this.itemDelay = const Duration(milliseconds: 100),
    super.onComplete,
  }) : super(
            duration: Duration(
                milliseconds: items.length * itemDelay.inMilliseconds));

  @override
  void update() {
    var p = progress;
    var count = (items.length * p).ceil();
    if (count != _lastCount) {
      _lastCount = count;
      onUpdate(count, items.take(count).toList());
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VISUAL EFFECTS
// ═══════════════════════════════════════════════════════════════════════════

/// Matrix rain effect characters.
class MatrixRainAnimation extends Animation {
  final void Function(String line) onUpdate;
  final int width;
  final String chars;
  final Random _random = Random();
  late List<int> _columns;

  MatrixRainAnimation({
    required this.onUpdate,
    this.width = 60,
    this.chars = 'ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ0123456789',
    Duration duration = const Duration(milliseconds: 800),
    super.onComplete,
  }) : super(duration: duration) {
    _columns = List.generate(width, (_) => _random.nextInt(5));
  }

  @override
  void update() {
    progress; // Advances time

    var line = StringBuffer();
    for (var i = 0; i < width; i++) {
      if (_random.nextDouble() < 0.3) {
        _columns[i] = (_columns[i] + 1) % 5;
      }
      var brightness = _columns[i];
      var char = chars[_random.nextInt(chars.length)];

      // Encode brightness in output (0=bright, 1-2=medium, 3-4=dim)
      if (brightness == 0) {
        line.write('${Colors.brightGreen}$char');
      } else if (brightness < 3) {
        line.write('${Colors.green}$char');
      } else {
        line.write('${Colors.dim}$char');
      }
    }
    line.write(Colors.reset);
    onUpdate(line.toString());
  }
}

/// Particle burst effect.
class ParticleBurstAnimation extends Animation {
  final void Function(String line) onUpdate;
  final int width;
  final List<String> particles;
  final List<String> colors;
  final double density;
  final Random _random = Random();

  ParticleBurstAnimation({
    required this.onUpdate,
    this.width = 50,
    this.particles = const ['✦', '✧', '★', '☆', '◆', '◇', '●', '○', '◈', '✴'],
    this.colors = const [
      Colors.brightGreen,
      Colors.brightCyan,
      Colors.brightYellow,
      Colors.brightMagenta
    ],
    this.density = 0.15,
    Duration duration = const Duration(milliseconds: 500),
    super.onComplete,
  }) : super(duration: duration);

  @override
  void update() {
    progress; // Advances time

    var line = StringBuffer();
    for (var i = 0; i < width; i++) {
      if (_random.nextDouble() < density) {
        var particle = particles[_random.nextInt(particles.length)];
        var color = colors[_random.nextInt(colors.length)];
        line.write('$color$particle${Colors.reset}');
      } else {
        line.write(' ');
      }
    }
    onUpdate(line.toString());
  }
}

/// Countdown animation.
class CountdownAnimation extends Animation {
  final void Function(int remaining, String display) onUpdate;
  final int from;

  int _lastValue = -1;

  CountdownAnimation({
    required this.onUpdate,
    this.from = 3,
    super.onComplete,
  }) : super(duration: Duration(seconds: from));

  @override
  void update() {
    var p = progress;
    var remaining = from - (from * p).floor();
    if (remaining < 0) remaining = 0;

    if (remaining != _lastValue) {
      _lastValue = remaining;
      if (remaining > 0) {
        onUpdate(remaining, '$remaining');
      } else {
        onUpdate(0, 'GO!');
      }
    }
  }
}

/// Scrolling banner animation.
class ScrollingBannerAnimation extends Animation {
  final String text;
  final void Function(String visible) onUpdate;
  final int width;
  final int iterations;

  late String _paddedText;

  ScrollingBannerAnimation({
    required this.text,
    required this.onUpdate,
    this.width = 40,
    this.iterations = 2,
    super.onComplete,
  }) : super(
            duration: Duration(
                milliseconds: (text.length + width * 2) * 50 * iterations)) {
    _paddedText = '${'─' * width}$text${'─' * width}';
  }

  @override
  void update() {
    var p = progress;
    var totalSteps = (_paddedText.length - width) * iterations;
    var step = (totalSteps * p).floor() % (_paddedText.length - width);
    var visible = _paddedText.substring(step, step + width);
    onUpdate(visible);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED VIEW WRAPPER
// ═══════════════════════════════════════════════════════════════════════════

/// Mixin that adds animation capabilities to a View.
///
/// Ticks the animation controller during [render], so animations
/// advance in sync with the render loop — no independent timer.
mixin Animated on View {
  final AnimationController _animController =
      AnimationController(selfTick: false);

  AnimationController get animations => _animController;

  @override
  void render(Canvas canvas) {
    _animController.tick();
    super.render(canvas);
  }

  /// Run a typewriter animation on text content.
  void animateTypewriter(String text,
      {Duration? charDelay, void Function()? onComplete}) {
    var anim = TypewriterAnimation(
      text: text,
      duration: charDelay != null
          ? Duration(milliseconds: text.length * charDelay.inMilliseconds)
          : null,
      onUpdate: (visible) {
        // Subclass should override to update view
      },
      onComplete: onComplete,
    );
    _animController.add(anim);
  }

  /// Run a glitch animation.
  void animateGlitch(String text,
      {Duration? duration, void Function()? onComplete}) {
    var anim = GlitchAnimation(
      text: text,
      duration: duration ?? const Duration(milliseconds: 500),
      onUpdate: (glitched) {
        // Subclass should override to update view
      },
      onComplete: onComplete,
    );
    _animController.add(anim);
  }

  /// Dispose animations when view is removed.
  void disposeAnimations() {
    _animController.clear();
  }
}

/// Widget that displays animated text effects.
class AnimatedText extends View with Animated {
  String _displayText = '';
  String _fullText;
  String color;
  AnimationType type;
  bool autoStart;
  void Function()? onComplete;

  String get fullText => _fullText;
  set fullText(String value) {
    _fullText = value;
    if (autoStart) start();
  }

  AnimatedText(
    this._fullText, {
    this.color = '0',
    this.type = AnimationType.typewriter,
    this.autoStart = true,
    this.onComplete,
  }) {
    if (autoStart) {
      // Delay to allow widget to be added to tree
      Future.microtask(() => start());
    }
  }

  void start() {
    _displayText = '';
    animations.clear();

    switch (type) {
      case AnimationType.typewriter:
        animations.add(TypewriterAnimation(
          text: _fullText,
          onUpdate: (visible) {
            _displayText = visible;
            update();
          },
          onComplete: onComplete,
        ));
      case AnimationType.glitch:
        _displayText = _fullText; // Start with full text
        animations.add(GlitchAnimation(
          text: _fullText,
          onUpdate: (glitched) {
            _displayText = glitched;
            update();
          },
          onComplete: onComplete,
        ));
      case AnimationType.pulse:
        _displayText = _fullText;
        animations.add(PulseAnimation(
          onUpdate: (bright) {
            // Toggle color brightness
            color = bright ? '1' : '8';
            update();
          },
          onComplete: onComplete,
        ));
      case AnimationType.cascade:
        // For single text, just use typewriter
        animations.add(TypewriterAnimation(
          text: _fullText,
          onUpdate: (visible) {
            _displayText = visible;
            update();
          },
          onComplete: onComplete,
        ));
    }
  }

  void stop() {
    animations.clear();
    _displayText = _fullText;
    update();
  }

  @override
  void update() {
    text = [
      Text(_displayText)
        ..color = color
        ..position = Position(0, 0),
    ];
  }
}

/// Types of text animations.
enum AnimationType {
  typewriter,
  glitch,
  pulse,
  cascade,
}

// ═══════════════════════════════════════════════════════════════════════════
// REVEAL ANIMATIONS
// ═══════════════════════════════════════════════════════════════════════════

/// How to reveal multi-line content.
enum RevealStyle {
  /// Reveal all lines at once, character by character.
  characters,

  /// Reveal line by line from top.
  linesDown,

  /// Reveal line by line from bottom.
  linesUp,

  /// Reveal from center outward.
  centerOut,

  /// Fade in (opacity simulation via brightness).
  fade,
}

/// Reveals multi-line content progressively.
class RevealAnimation extends Animation {
  final List<String> lines;
  final void Function(List<String> visibleLines, double opacity) onUpdate;
  final RevealStyle style;

  int _lastLineCount = -1;
  double _lastOpacity = -1;

  RevealAnimation({
    required this.lines,
    required this.onUpdate,
    this.style = RevealStyle.linesDown,
    Duration duration = const Duration(milliseconds: 500),
    super.easing = Easing.easeOut,
    super.repeatMode,
    super.repeatCount,
    super.onComplete,
  }) : super(duration: duration);

  @override
  void update() {
    var p = progress;

    switch (style) {
      case RevealStyle.characters:
        // Reveal all characters across all lines
        var totalChars = lines.fold<int>(0, (sum, line) => sum + line.length);
        var visibleChars = (totalChars * p).round();
        var result = <String>[];
        var remaining = visibleChars;

        for (var line in lines) {
          if (remaining <= 0) {
            result.add('');
          } else if (remaining >= line.length) {
            result.add(line);
            remaining -= line.length;
          } else {
            result.add(line.substring(0, remaining));
            remaining = 0;
          }
        }
        onUpdate(result, 1.0);

      case RevealStyle.linesDown:
        var visibleCount = (lines.length * p).ceil();
        if (visibleCount != _lastLineCount) {
          _lastLineCount = visibleCount;
          onUpdate(lines.take(visibleCount).toList(), 1.0);
        }

      case RevealStyle.linesUp:
        var visibleCount = (lines.length * p).ceil();
        if (visibleCount != _lastLineCount) {
          _lastLineCount = visibleCount;
          var startIdx = lines.length - visibleCount;
          var visible = List<String>.generate(lines.length, (i) {
            return i >= startIdx ? lines[i] : '';
          });
          onUpdate(visible, 1.0);
        }

      case RevealStyle.centerOut:
        var visibleCount = (lines.length * p).ceil();
        if (visibleCount != _lastLineCount) {
          _lastLineCount = visibleCount;
          var center = lines.length ~/ 2;
          var halfVisible = (visibleCount / 2).ceil();
          var visible = List<String>.generate(lines.length, (i) {
            var distFromCenter = (i - center).abs();
            return distFromCenter < halfVisible ? lines[i] : '';
          });
          onUpdate(visible, 1.0);
        }

      case RevealStyle.fade:
        if (p != _lastOpacity) {
          _lastOpacity = p;
          onUpdate(lines, p);
        }
    }
  }
}

/// Simple value animation with repeat support.
class ValueAnimation extends Animation {
  final double from;
  final double to;
  final void Function(double value) onUpdate;

  double _lastValue = double.nan;

  ValueAnimation({
    this.from = 0.0,
    this.to = 1.0,
    required this.onUpdate,
    Duration duration = const Duration(milliseconds: 300),
    super.easing = Easing.easeInOut,
    super.repeatMode,
    super.repeatCount,
    super.onComplete,
  }) : super(duration: duration);

  @override
  void update() {
    var p = progress;
    var value = from + (to - from) * p;
    if (value != _lastValue) {
      _lastValue = value;
      onUpdate(value);
    }
  }
}

/// Shimmer/scan line effect that moves across text.
class ShimmerAnimation extends Animation {
  final int width;
  final void Function(int position) onUpdate;

  int _lastPos = -1;

  ShimmerAnimation({
    required this.width,
    required this.onUpdate,
    Duration duration = const Duration(milliseconds: 1000),
    super.repeatMode = RepeatMode.loop,
    super.repeatCount,
    super.onComplete,
  }) : super(duration: duration);

  @override
  void update() {
    var p = progress;
    var pos = (width * p).round();
    if (pos != _lastPos) {
      _lastPos = pos;
      onUpdate(pos);
    }
  }
}

/// Blink animation for cursors or alerts.
class BlinkAnimation extends Animation {
  final void Function(bool visible) onUpdate;
  final Duration blinkRate;

  bool _lastVisible = true;

  BlinkAnimation({
    required this.onUpdate,
    this.blinkRate = const Duration(milliseconds: 500),
    super.repeatMode = RepeatMode.loop,
    super.repeatCount,
    super.onComplete,
  }) : super(duration: blinkRate);

  @override
  void update() {
    var p = progress;
    var visible = p < 0.5;
    if (visible != _lastVisible) {
      _lastVisible = visible;
      onUpdate(visible);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BIGTEXT ANIMATION
// ═══════════════════════════════════════════════════════════════════════════

/// Style for revealing each line in BigTextAnimation.
enum LineRevealStyle {
  /// Instant reveal - line appears immediately.
  instant,

  /// Typewriter - characters appear left to right.
  typewriter,

  /// Glitch - random characters that resolve to final text.
  glitch,

  /// Matrix - matrix rain characters that resolve.
  matrix,

  /// Fade - line fades in (dim to bright).
  fade,

  /// Slide - line slides in from the side.
  slide,
}

/// Configuration for a single line's reveal animation.
class LineRevealConfig {
  final LineRevealStyle style;
  final Duration duration;
  final double Function(double) easing;

  const LineRevealConfig({
    this.style = LineRevealStyle.typewriter,
    this.duration = const Duration(milliseconds: 300),
    this.easing = Easing.easeOut,
  });

  static const instant = LineRevealConfig(
    style: LineRevealStyle.instant,
    duration: Duration.zero,
  );

  static const typewriter = LineRevealConfig(
    style: LineRevealStyle.typewriter,
    duration: Duration(milliseconds: 400),
  );

  static const glitch = LineRevealConfig(
    style: LineRevealStyle.glitch,
    duration: Duration(milliseconds: 500),
  );

  static const matrix = LineRevealConfig(
    style: LineRevealStyle.matrix,
    duration: Duration(milliseconds: 600),
  );

  static const fade = LineRevealConfig(
    style: LineRevealStyle.fade,
    duration: Duration(milliseconds: 300),
  );
}

/// Animates BigText line by line with different reveal styles per line.
class BigTextAnimation extends Animation {
  final List<String> lines;
  final void Function(List<String> renderedLines) onUpdate;

  /// Delay between starting each line's animation.
  final Duration lineDelay;

  /// Reveal style for each line. If shorter than lines, last style repeats.
  final List<LineRevealConfig> lineStyles;

  /// Default style if lineStyles is empty.
  final LineRevealConfig defaultStyle;

  final Random _random = Random();
  static const _glitchChars = r'!@#$%^&*()_+-=[]{}|;:,.<>?/\~`░▒▓█▀▄';
  static const _matrixChars = 'ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄ0123456789';

  List<String> _currentLines = [];
  int _lastLineIndex = -1;

  BigTextAnimation({
    required this.lines,
    required this.onUpdate,
    this.lineDelay = const Duration(milliseconds: 100),
    this.lineStyles = const [],
    this.defaultStyle = const LineRevealConfig(),
    super.easing,
    super.repeatMode,
    super.repeatCount,
    super.onComplete,
  }) : super(
          duration: Duration(
            milliseconds: lines.length * lineDelay.inMilliseconds +
                (lineStyles.isNotEmpty
                    ? lineStyles.last.duration.inMilliseconds
                    : const LineRevealConfig().duration.inMilliseconds),
          ),
        ) {
    _currentLines = List.filled(lines.length, '');
  }

  LineRevealConfig _getStyleForLine(int index) {
    if (lineStyles.isEmpty) return defaultStyle;
    if (index < lineStyles.length) return lineStyles[index];
    return lineStyles.last;
  }

  @override
  void update() {
    var p = progress;
    var elapsed = p * duration.inMilliseconds;

    for (var i = 0; i < lines.length; i++) {
      var lineStartTime = i * lineDelay.inMilliseconds;
      var style = _getStyleForLine(i);
      var lineDuration = style.duration.inMilliseconds;

      if (elapsed < lineStartTime) {
        // Line hasn't started yet
        _currentLines[i] = '';
      } else if (lineDuration == 0 || elapsed >= lineStartTime + lineDuration) {
        // Line is complete
        _currentLines[i] = lines[i];
      } else {
        // Line is animating
        var lineProgress = (elapsed - lineStartTime) / lineDuration;
        lineProgress = style.easing(lineProgress.clamp(0.0, 1.0));
        _currentLines[i] = _renderLine(lines[i], lineProgress, style.style);
      }
    }

    onUpdate(List.from(_currentLines));
  }

  String _renderLine(String line, double progress, LineRevealStyle style) {
    if (line.isEmpty) return '';

    switch (style) {
      case LineRevealStyle.instant:
        return line;

      case LineRevealStyle.typewriter:
        var visibleChars = (line.length * progress).round();
        return line.substring(0, visibleChars).padRight(line.length);

      case LineRevealStyle.glitch:
        var buf = StringBuffer();
        var resolveThreshold = progress;
        for (var i = 0; i < line.length; i++) {
          var charProgress = i / line.length;
          if (charProgress < resolveThreshold - 0.1) {
            // Resolved
            buf.write(line[i]);
          } else if (charProgress < resolveThreshold + 0.2) {
            // Glitching - mix of correct and random
            if (_random.nextDouble() < progress * 0.7) {
              buf.write(line[i]);
            } else {
              buf.write(_glitchChars[_random.nextInt(_glitchChars.length)]);
            }
          } else {
            // Not yet revealed
            buf.write(' ');
          }
        }
        return buf.toString();

      case LineRevealStyle.matrix:
        var buf = StringBuffer();
        var resolveThreshold = progress;
        for (var i = 0; i < line.length; i++) {
          var charProgress = i / line.length;
          if (charProgress < resolveThreshold - 0.15) {
            // Resolved
            buf.write(line[i]);
          } else if (charProgress < resolveThreshold + 0.3) {
            // Matrix effect - cycling through characters
            if (_random.nextDouble() < progress * 0.6) {
              buf.write(line[i]);
            } else {
              var matrixChar =
                  _matrixChars[_random.nextInt(_matrixChars.length)];
              buf.write('${Colors.green}$matrixChar${Colors.reset}');
            }
          } else {
            // Not yet revealed - dim matrix chars
            if (_random.nextDouble() < 0.3) {
              var matrixChar =
                  _matrixChars[_random.nextInt(_matrixChars.length)];
              buf.write('${Colors.dim}$matrixChar${Colors.reset}');
            } else {
              buf.write(' ');
            }
          }
        }
        return buf.toString();

      case LineRevealStyle.fade:
        // Simulate fade with dim/normal/bright
        if (progress < 0.33) {
          return '${Colors.dim}$line${Colors.reset}';
        } else if (progress < 0.66) {
          return line;
        } else {
          return '${Colors.bold}$line${Colors.reset}';
        }

      case LineRevealStyle.slide:
        // Slide in from right
        var offset = ((1 - progress) * line.length).round();
        var visible = line.length - offset;
        if (visible <= 0) return ' ' * line.length;
        return '${' ' * offset}${line.substring(0, visible)}';
    }
  }
}

/// Animated wrapper for BigText that plays reveal animation on start.
///
/// When [autoStart] is true (default) the animation begins
/// automatically on the first [resize] with a non-zero size.
/// You can also call [startAnimation] manually — if the widget
/// has no size yet the start is deferred until the next [resize].
class AnimatedBigText extends View {
  final BigText _bigText;
  final BigTextFont _font;
  final String _text;
  final AnimationController _controller = AnimationController(selfTick: false);
  final Duration lineDelay;
  final List<LineRevealConfig> lineStyles;
  final LineRevealConfig defaultStyle;
  final void Function()? onComplete;

  /// Whether to start animating on first resize automatically.
  final bool autoStart;

  List<String> _animatedLines = [];
  bool _animationComplete = false;
  bool _started = false;
  bool _pendingStart = false;

  AnimatedBigText(
    String text, {
    BigTextFont font = BigTextFont.shadow,
    List<RGB>? gradient,
    String? subtitle,
    bool showBorder = false,
    this.lineDelay = const Duration(milliseconds: 80),
    this.lineStyles = const [],
    this.defaultStyle = const LineRevealConfig(),
    this.onComplete,
    this.autoStart = true,
  })  : _text = text,
        _font = font,
        _bigText = BigText(text,
            font: font,
            gradient: gradient,
            subtitle: subtitle,
            showBorder: showBorder);

  /// Start the reveal animation.
  ///
  /// Safe to call before the widget has been sized — the actual
  /// start is deferred until [resize] provides a non-zero size.
  void startAnimation() {
    if (width == 0 || height == 0) {
      _pendingStart = true;
      return;
    }
    _doStart();
  }

  void _doStart() {
    _pendingStart = false;
    _started = true;
    _animationComplete = false;
    _animatedLines = [];
    _controller.clear();

    // Generate lines statically — no dependency on widget size.
    var lines = BigText.generateLines(_text, font: _font);
    if (lines.isEmpty) return;

    _controller.add(BigTextAnimation(
      lines: lines,
      lineDelay: lineDelay,
      lineStyles: lineStyles,
      defaultStyle: defaultStyle,
      onUpdate: (rendered) {
        _animatedLines = rendered;
      },
      onComplete: () {
        _animationComplete = true;
        onComplete?.call();
      },
    ));
  }

  /// Skip animation and show final state.
  void skipAnimation() {
    _controller.clear();
    _animationComplete = true;
    _animatedLines = [];
    _pendingStart = false;
  }

  @override
  void resize(Size size, Position offset) {
    super.resize(size, offset);
    _bigText.resize(size, offset);

    if (width > 0 && height > 0) {
      if (_pendingStart) {
        _doStart();
      } else if (autoStart && !_started) {
        _doStart();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    _controller.tick();
    update();
    super.render(canvas);
  }

  @override
  void update() {
    if (_animationComplete || _animatedLines.isEmpty) {
      _bigText.update();
      text = _bigText.text;
    } else {
      text = [];
      final grad = _bigText.gradient;
      for (var i = 0; i < _animatedLines.length; i++) {
        var line = _animatedLines[i];
        var x = _bigText.centered ? (width - line.length) ~/ 2 : 0;
        if (x < 0) x = 0;

        if (grad != null && grad.isNotEmpty) {
          // Per-character gradient — same as BigText.
          for (var c = 0; c < line.length; c++) {
            var ch = line[c];
            if (ch == ' ') continue;
            var rgb = BigText.interpolateGradient(grad, c, line.length);
            text.add(Text(ch)
              ..color = rgb.toAnsi()
              ..position = Position(x + c, i));
          }
        } else {
          text.add(Text(line)
            ..color = _bigText.color
            ..position = Position(x, i));
        }
      }
    }
  }

  void dispose() {
    _controller.clear();
  }
}
