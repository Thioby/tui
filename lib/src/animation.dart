part of tui;

/// Easing functions for animations.
abstract class Easing {
  static double linear(double t) => t;

  static double easeIn(double t) => t * t;
  static double easeOut(double t) => 1 - (1 - t) * (1 - t);
  static double easeInOut(double t) => t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2).toDouble() / 2;

  static double easeInCubic(double t) => t * t * t;
  static double easeOutCubic(double t) => 1 - pow(1 - t, 3).toDouble();
  static double easeInOutCubic(double t) => t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3).toDouble() / 2;

  static double easeInElastic(double t) {
    if (t == 0 || t == 1) return t;
    return -pow(2, 10 * t - 10).toDouble() * sin((t * 10 - 10.75) * (2 * pi / 3));
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
class AnimationController {
  final List<Animation> _animations = [];
  Timer? _timer;
  int _fps = 30;

  int get fps => _fps;
  set fps(int value) {
    _fps = value.clamp(1, 120);
    if (_timer != null) {
      _stop();
      _start();
    }
  }

  /// Add an animation.
  void add(Animation animation) {
    _animations.add(animation);
    animation.start();
    _ensureRunning();
  }

  /// Remove an animation.
  void remove(Animation animation) {
    _animations.remove(animation);
    if (_animations.isEmpty) {
      _stop();
    }
  }

  /// Remove all animations.
  void clear() {
    for (var anim in _animations) {
      anim.stop();
    }
    _animations.clear();
    _stop();
  }

  void _ensureRunning() {
    if (_timer == null && _animations.isNotEmpty) {
      _start();
    }
  }

  void _start() {
    _timer = Timer.periodic(Duration(milliseconds: 1000 ~/ _fps), (_) {
      _tick();
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
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
    if (_animations.isEmpty) {
      _stop();
    }
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
    this.glitchChars = '!@#\$%^&*<>[]{}|/\\~`',
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
  }) : super(duration: Duration(milliseconds: items.length * itemDelay.inMilliseconds));

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
    this.colors = const [Colors.brightGreen, Colors.brightCyan, Colors.brightYellow, Colors.brightMagenta],
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
  }) : super(duration: Duration(milliseconds: (text.length + width * 2) * 50 * iterations)) {
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
mixin Animated on View {
  final AnimationController _animController = AnimationController();

  AnimationController get animations => _animController;

  /// Run a typewriter animation on text content.
  void animateTypewriter(String text, {Duration? charDelay, void Function()? onComplete}) {
    var anim = TypewriterAnimation(
      text: text,
      duration: charDelay != null ? Duration(milliseconds: text.length * charDelay.inMilliseconds) : null,
      onUpdate: (visible) {
        // Subclass should override to update view
      },
      onComplete: onComplete,
    );
    _animController.add(anim);
  }

  /// Run a glitch animation.
  void animateGlitch(String text, {Duration? duration, void Function()? onComplete}) {
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
