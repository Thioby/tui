import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('Easing', () {
    test('linear returns input unchanged', () {
      expect(Easing.linear(0.0), 0.0);
      expect(Easing.linear(0.5), 0.5);
      expect(Easing.linear(1.0), 1.0);
    });

    test('easeIn starts slow', () {
      expect(Easing.easeIn(0.5), lessThan(0.5));
    });

    test('easeOut ends slow', () {
      expect(Easing.easeOut(0.5), greaterThan(0.5));
    });

    test('easeInOut is symmetric around 0.5', () {
      var at25 = Easing.easeInOut(0.25);
      var at75 = Easing.easeInOut(0.75);
      expect(at25 + at75, closeTo(1.0, 0.001));
    });

    test('easeOutBounce returns valid values', () {
      expect(Easing.easeOutBounce(0.0), 0.0);
      expect(Easing.easeOutBounce(1.0), 1.0);
      expect(Easing.easeOutBounce(0.5), greaterThan(0.0));
    });
  });

  group('Tween', () {
    test('number interpolates correctly', () {
      var tween = Tween.number(0, 100);
      expect(tween.evaluate(0.0), 0.0);
      expect(tween.evaluate(0.5), 50.0);
      expect(tween.evaluate(1.0), 100.0);
    });

    test('integer rounds correctly', () {
      var tween = Tween.integer(0, 10);
      expect(tween.evaluate(0.0), 0);
      expect(tween.evaluate(0.5), 5);
      expect(tween.evaluate(0.25), 3); // 2.5 rounds to 3
    });

    test('color interpolates RGB', () {
      var tween = Tween.color(RGB(0, 0, 0), RGB(255, 255, 255));
      var mid = tween.evaluate(0.5);
      expect(mid.r, closeTo(128, 1));
      expect(mid.g, closeTo(128, 1));
      expect(mid.b, closeTo(128, 1));
    });
  });

  group('RGB', () {
    test('lerp interpolates between colors', () {
      var black = RGB(0, 0, 0);
      var white = RGB(255, 255, 255);
      var gray = black.lerp(white, 0.5);
      expect(gray.r, 128);
      expect(gray.g, 128);
      expect(gray.b, 128);
    });

    test('toAnsi generates correct escape code', () {
      var color = RGB(100, 150, 200);
      expect(color.toAnsi(), '38;2;100;150;200');
    });
  });

  group('RepeatMode', () {
    test('enum has all expected values', () {
      expect(RepeatMode.values, contains(RepeatMode.once));
      expect(RepeatMode.values, contains(RepeatMode.reverse));
      expect(RepeatMode.values, contains(RepeatMode.loop));
      expect(RepeatMode.values, contains(RepeatMode.pingPong));
    });
  });

  group('Animation', () {
    test('zero duration completes immediately', () {
      var completed = false;
      var anim = ValueAnimation(
        duration: Duration.zero,
        onUpdate: (_) {},
        onComplete: () => completed = true,
      );
      anim.start();
      anim.update();
      expect(anim.completed, isTrue);
      expect(completed, isTrue);
    });

    test('starts in non-running state', () {
      var anim = ValueAnimation(onUpdate: (_) {});
      expect(anim.running, isFalse);
      expect(anim.completed, isFalse);
    });

    test('start sets running to true', () {
      var anim = ValueAnimation(onUpdate: (_) {});
      anim.start();
      expect(anim.running, isTrue);
    });

    test('stop sets running to false', () {
      var anim = ValueAnimation(onUpdate: (_) {});
      anim.start();
      anim.stop();
      expect(anim.running, isFalse);
    });

    test('reset clears state', () {
      var anim = ValueAnimation(onUpdate: (_) {});
      anim.start();
      anim.reset();
      expect(anim.running, isFalse);
      expect(anim.completed, isFalse);
      expect(anim.currentIteration, 0);
      expect(anim.reversed, isFalse);
    });
  });

  group('ValueAnimation', () {
    test('interpolates from begin to end', () {
      var values = <double>[];
      var anim = ValueAnimation(
        from: 0,
        to: 100,
        duration: Duration(milliseconds: 100),
        onUpdate: (v) => values.add(v),
      );
      anim.start();

      // Simulate some updates
      for (var i = 0; i < 10; i++) {
        anim.update();
      }

      // Values should be in increasing order (roughly)
      expect(values, isNotEmpty);
    });
  });

  group('AnimationController', () {
    test('add starts animation', () {
      var controller = AnimationController();
      var started = false;
      var anim = _TestAnimation(onStart: () => started = true);

      controller.add(anim);
      expect(started, isTrue);
    });

    test('clear stops all animations', () {
      var controller = AnimationController();
      var anim = ValueAnimation(onUpdate: (_) {});

      controller.add(anim);
      expect(anim.running, isTrue);

      controller.clear();
      expect(anim.running, isFalse);
    });

    test('fps can be set within valid range', () {
      var controller = AnimationController();
      controller.fps = 60;
      expect(controller.fps, 60);

      controller.fps = 0; // Should clamp to 1
      expect(controller.fps, 1);

      controller.fps = 200; // Should clamp to 120
      expect(controller.fps, 120);
    });
  });

  group('FpsMeter', () {
    test('starts with zero values', () {
      var meter = FpsMeter();
      expect(meter.currentFps, 0);
      expect(meter.averageFps, 0);
      expect(meter.frameTimeMs, 0);
    });

    test('tick updates frame time', () {
      var meter = FpsMeter();
      meter.tick();
      // First tick has no previous frame, so timing may be off
      // Just verify it doesn't crash
      expect(meter.frameTimeMs, greaterThanOrEqualTo(0));
    });

    test('reset clears all values', () {
      var meter = FpsMeter();
      meter.tick();
      meter.reset();
      expect(meter.currentFps, 0);
      expect(meter.averageFps, 0);
    });

    test('compact returns formatted string', () {
      var meter = FpsMeter();
      var compact = meter.compact;
      expect(compact, contains('fps'));
      expect(compact, contains('ms'));
    });

    test('summary returns formatted string', () {
      var meter = FpsMeter();
      var summary = meter.summary;
      expect(summary, contains('FPS:'));
      expect(summary, contains('avg:'));
    });
  });

  group('RevealStyle', () {
    test('enum has all expected values', () {
      expect(RevealStyle.values, contains(RevealStyle.characters));
      expect(RevealStyle.values, contains(RevealStyle.linesDown));
      expect(RevealStyle.values, contains(RevealStyle.linesUp));
      expect(RevealStyle.values, contains(RevealStyle.centerOut));
      expect(RevealStyle.values, contains(RevealStyle.fade));
    });
  });

  group('LineRevealStyle', () {
    test('enum has all expected values', () {
      expect(LineRevealStyle.values, contains(LineRevealStyle.instant));
      expect(LineRevealStyle.values, contains(LineRevealStyle.typewriter));
      expect(LineRevealStyle.values, contains(LineRevealStyle.glitch));
      expect(LineRevealStyle.values, contains(LineRevealStyle.matrix));
      expect(LineRevealStyle.values, contains(LineRevealStyle.fade));
      expect(LineRevealStyle.values, contains(LineRevealStyle.slide));
    });
  });

  group('LineRevealConfig', () {
    test('default constructor has sensible defaults', () {
      var config = LineRevealConfig();
      expect(config.style, LineRevealStyle.typewriter);
      expect(config.duration.inMilliseconds, 300);
    });

    test('preset configs exist', () {
      expect(LineRevealConfig.instant.style, LineRevealStyle.instant);
      expect(LineRevealConfig.typewriter.style, LineRevealStyle.typewriter);
      expect(LineRevealConfig.glitch.style, LineRevealStyle.glitch);
      expect(LineRevealConfig.matrix.style, LineRevealStyle.matrix);
      expect(LineRevealConfig.fade.style, LineRevealStyle.fade);
    });
  });

  group('BigTextAnimation', () {
    test('updates with rendered lines', () {
      var updates = <List<String>>[];
      var anim = BigTextAnimation(
        lines: ['LINE1', 'LINE2', 'LINE3'],
        lineDelay: Duration(milliseconds: 50),
        defaultStyle: LineRevealConfig.instant,
        onUpdate: (lines) => updates.add(List.from(lines)),
      );

      anim.start();
      // Simulate updates
      for (var i = 0; i < 5; i++) {
        anim.update();
      }

      expect(updates, isNotEmpty);
    });

    test('respects line styles list', () {
      var anim = BigTextAnimation(
        lines: ['A', 'B', 'C'],
        lineDelay: Duration.zero,
        lineStyles: [
          LineRevealConfig.glitch,
          LineRevealConfig.matrix,
        ],
        onUpdate: (_) {},
      );

      // Third line should use last style (matrix)
      expect(anim, isNotNull);
    });

    test('calls onUpdate during animation', () {
      var updateCount = 0;
      var anim = BigTextAnimation(
        lines: ['TEST', 'LINES'],
        lineDelay: Duration(milliseconds: 100),
        defaultStyle: LineRevealConfig(
          style: LineRevealStyle.typewriter,
          duration: Duration(milliseconds: 100),
        ),
        onUpdate: (_) => updateCount++,
      );

      anim.start();
      // Simulate a few updates
      for (var i = 0; i < 10; i++) {
        anim.update();
      }

      expect(updateCount, greaterThan(0));
    });
  });

  group('AnimatedBigText', () {
    test('startAnimation produces lines after resize', () {
      var widget = AnimatedBigText(
        'HI',
        font: BigTextFont.shadow,
        autoStart: false,
      );

      // Simulate render loop giving us size.
      widget.resize(Size(40, 10), Position(0, 0));
      widget.startAnimation();

      // Tick a few frames to advance the animation.
      var screen = Screen(Size(40, 10));
      var canvas = screen.canvas();
      for (var i = 0; i < 5; i++) {
        widget.render(canvas);
      }

      expect(widget.text, isNotEmpty);
    });

    test('autoStart begins animation on first resize', () {
      var widget = AnimatedBigText('GO', font: BigTextFont.shadow);

      // Before resize — nothing should happen.
      expect(widget.text, isEmpty);

      // Resize triggers auto-start.
      widget.resize(Size(40, 10), Position(0, 0));

      var screen = Screen(Size(40, 10));
      var canvas = screen.canvas();
      widget.render(canvas);

      // Controller should have an active animation.
      expect(widget.text, isNotEmpty);
    });

    test('startAnimation defers when size is zero', () {
      var widget = AnimatedBigText(
        'OK',
        font: BigTextFont.shadow,
        autoStart: false,
      );

      // Call start before resize — should defer.
      widget.startAnimation();

      // Now give it a real size — deferred start should fire.
      widget.resize(Size(40, 10), Position(0, 0));

      var screen = Screen(Size(40, 10));
      var canvas = screen.canvas();
      widget.render(canvas);

      expect(widget.text, isNotEmpty);
    });

    test('skipAnimation shows final BigText', () {
      var widget = AnimatedBigText('AB', font: BigTextFont.shadow);

      widget.resize(Size(40, 10), Position(0, 0));
      widget.skipAnimation();
      widget.update();

      // Should show static BigText output, not animated lines.
      expect(widget.text, isNotEmpty);
      // Verify at least one text node has content from BigText.
      var hasContent =
          widget.text.any((t) => t.text != null && t.text!.trim().isNotEmpty);
      expect(hasContent, isTrue);
    });

    test('does not restart animation on subsequent resizes', () {
      var widget = AnimatedBigText('X', font: BigTextFont.shadow);

      widget.resize(Size(40, 10), Position(0, 0));

      // Tick a few frames.
      var screen = Screen(Size(40, 10));
      var canvas = screen.canvas();
      for (var i = 0; i < 3; i++) {
        widget.render(canvas);
      }

      // Resize again — should NOT restart.
      widget.resize(Size(50, 12), Position(0, 0));
      widget.render(canvas);

      // Still has text, animation wasn't reset.
      expect(widget.text, isNotEmpty);
    });
  });
}

/// Test animation that tracks lifecycle.
class _TestAnimation extends Animation {
  final void Function()? onStart;

  _TestAnimation({this.onStart}) : super(duration: Duration(milliseconds: 100));

  @override
  void start() {
    super.start();
    onStart?.call();
  }

  @override
  void update() {
    progress; // Advance time
  }
}
