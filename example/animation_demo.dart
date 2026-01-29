import 'package:tui/tui.dart';
import 'dart:async';

class AnimationDemo extends Window {
  late AnimationController controller;
  String currentEffect = '';
  String statusText = '';
  int demoIndex = 0;

  final demos = [
    'Typewriter',
    'Glitch',
    'Pulse (loop)',
    'Pulse (pingPong)',
    'Reveal Lines',
    'Reveal Fade',
    'Shimmer',
    'Blink',
    'BigText Typewriter',
    'BigText Glitch',
    'BigText Matrix',
    'BigText Mixed',
    'Matrix Rain',
    'Particle Burst',
    'Countdown',
    'Scrolling Banner',
    'Cascade',
  ];

  AnimationDemo() {
    controller = AnimationController()..fps = 60;
    showFps = true;  // Enable FPS meter
  }

  @override
  void start() {
    super.start();
    _showMenu();
  }

  void _showMenu() {
    currentEffect = '';
    statusText = 'UP/DOWN = select, ENTER = run, F = toggle FPS, Q = quit';
  }

  void _runDemo(int index) {
    controller.clear();
    currentEffect = '';

    switch (demos[index]) {
      case 'Typewriter':
        _runTypewriter();
      case 'Glitch':
        _runGlitch();
      case 'Pulse (loop)':
        _runPulseLoop();
      case 'Pulse (pingPong)':
        _runPulsePingPong();
      case 'Reveal Lines':
        _runRevealLines();
      case 'Reveal Fade':
        _runRevealFade();
      case 'Shimmer':
        _runShimmer();
      case 'Blink':
        _runBlink();
      case 'BigText Typewriter':
        _runBigTextTypewriter();
      case 'BigText Glitch':
        _runBigTextGlitch();
      case 'BigText Matrix':
        _runBigTextMatrix();
      case 'BigText Mixed':
        _runBigTextMixed();
      case 'Matrix Rain':
        _runMatrixRain();
      case 'Particle Burst':
        _runParticleBurst();
      case 'Countdown':
        _runCountdown();
      case 'Scrolling Banner':
        _runScrollingBanner();
      case 'Cascade':
        _runCascade();
    }
  }

  void _runTypewriter() {
    statusText = 'Typewriter animation...';
    controller.add(TypewriterAnimation(
      text: 'Hello, this is a typewriter effect! Each character appears one by one.',
      duration: Duration(milliseconds: 2000),
      easing: Easing.linear,
      onUpdate: (visible) {
        currentEffect = visible;
      },
      onComplete: () {
        statusText = 'Done! Press any key to continue.';
      },
    ));
  }

  void _runGlitch() {
    statusText = 'Glitch animation...';
    currentEffect = 'SYSTEM MALFUNCTION DETECTED';
    controller.add(GlitchAnimation(
      text: 'SYSTEM MALFUNCTION DETECTED',
      duration: Duration(milliseconds: 1500),
      intensity: 0.5,
      onUpdate: (glitched) {
        currentEffect = glitched;
      },
      onComplete: () {
        currentEffect = 'SYSTEM MALFUNCTION DETECTED';
        statusText = 'Done! Press any key to continue.';
      },
    ));
  }

  void _runPulseLoop() {
    statusText = 'Pulse LOOP (runs forever, press any key to stop)...';
    currentEffect = '>>> ALERT <<<';
    controller.add(ValueAnimation(
      from: 0,
      to: 1,
      duration: Duration(milliseconds: 500),
      repeatMode: RepeatMode.loop,
      onUpdate: (value) {
        var bright = value > 0.5;
        currentEffect = bright
          ? '${Colors.brightRed}>>> ALERT <<<${Colors.reset}'
          : '${Colors.dim}>>> ALERT <<<${Colors.reset}';
      },
    ));
  }

  void _runPulsePingPong() {
    statusText = 'Pulse PING-PONG (3 cycles)...';
    currentEffect = '>>> ALERT <<<';
    controller.add(ValueAnimation(
      from: 0,
      to: 1,
      duration: Duration(milliseconds: 400),
      repeatMode: RepeatMode.pingPong,
      repeatCount: 3,
      easing: Easing.easeInOut,
      onUpdate: (value) {
        // Smooth brightness transition
        var r = (255 * value).round();
        var g = (50 * (1 - value)).round();
        currentEffect = '${Colors.fgRgb(r, g, 0)}>>> ALERT <<<${Colors.reset}';
      },
      onComplete: () {
        currentEffect = '>>> ALERT <<<';
        statusText = 'Done! Press any key to continue.';
      },
    ));
  }

  List<String> get _revealLines {
    final w = 33;
    final content = [
      '   DART TUI ANIMATION SYSTEM   ',
      '                               ',
      '   Reveal animation demo       ',
      '   Line by line effect         ',
    ];
    return [
      '${BoxChars.doubleTL}${BoxChars.doubleH * (w - 2)}${BoxChars.doubleTR}',
      ...content.map((c) => '${BoxChars.doubleV}$c${BoxChars.doubleV}'),
      '${BoxChars.doubleBL}${BoxChars.doubleH * (w - 2)}${BoxChars.doubleBR}',
    ];
  }

  void _runRevealLines() {
    statusText = 'Reveal lines (top to bottom)...';
    currentEffect = '';
    controller.add(RevealAnimation(
      lines: _revealLines,
      style: RevealStyle.linesDown,
      duration: Duration(milliseconds: 1500),
      easing: Easing.easeOut,
      onUpdate: (visible, _) {
        currentEffect = visible.map((l) => '${Colors.cyan}$l${Colors.reset}').join('\n');
      },
      onComplete: () {
        statusText = 'Done! Press any key to continue.';
      },
    ));
  }

  void _runRevealFade() {
    statusText = 'Reveal FADE (forward then reverse)...';
    controller.add(RevealAnimation(
      lines: _revealLines,
      style: RevealStyle.fade,
      duration: Duration(milliseconds: 1000),
      repeatMode: RepeatMode.reverse,
      onUpdate: (lines, opacity) {
        // Simulate fade with dim/bright colors
        var color = opacity < 0.3
          ? Colors.dim
          : opacity < 0.7
            ? Colors.cyan
            : Colors.brightCyan;
        currentEffect = lines.map((l) => '$color$l${Colors.reset}').join('\n');
      },
      onComplete: () {
        currentEffect = '';
        statusText = 'Done! Press any key to continue.';
      },
    ));
  }

  void _runShimmer() {
    statusText = 'Shimmer effect (infinite loop)...';
    final text = '████████████████████████████████████████';
    controller.add(ShimmerAnimation(
      width: text.length,
      duration: Duration(milliseconds: 1500),
      repeatMode: RepeatMode.loop,
      onUpdate: (pos) {
        var buf = StringBuffer();
        for (var i = 0; i < text.length; i++) {
          var dist = (i - pos).abs();
          if (dist < 3) {
            buf.write('${Colors.brightWhite}█');
          } else if (dist < 6) {
            buf.write('${Colors.white}█');
          } else {
            buf.write('${Colors.dim}█');
          }
        }
        buf.write(Colors.reset);
        currentEffect = buf.toString();
      },
    ));
  }

  void _runBlink() {
    statusText = 'Blink animation (cursor style, infinite)...';
    controller.add(BlinkAnimation(
      blinkRate: Duration(milliseconds: 500),
      repeatMode: RepeatMode.loop,
      onUpdate: (visible) {
        currentEffect = visible
          ? '${Colors.brightGreen}█${Colors.reset} Cursor visible'
          : '  Cursor hidden';
      },
    ));
  }

  void _runBigTextTypewriter() {
    statusText = 'BigText with TYPEWRITER reveal...';
    final lines = BigText.generateLines('TUI', font: BigTextFont.shadow);
    controller.add(BigTextAnimation(
      lines: lines,
      lineDelay: Duration(milliseconds: 150),
      defaultStyle: LineRevealConfig.typewriter,
      onUpdate: (rendered) {
        currentEffect = rendered.map((l) => '${Colors.cyan}$l${Colors.reset}').join('\n');
      },
      onComplete: () {
        statusText = 'Done! Press any key to continue.';
      },
    ));
  }

  void _runBigTextGlitch() {
    statusText = 'BigText with GLITCH reveal...';
    final lines = BigText.generateLines('GLITCH', font: BigTextFont.shadow);
    controller.add(BigTextAnimation(
      lines: lines,
      lineDelay: Duration(milliseconds: 100),
      defaultStyle: LineRevealConfig.glitch,
      onUpdate: (rendered) {
        currentEffect = rendered.map((l) => '${Colors.brightRed}$l${Colors.reset}').join('\n');
      },
      onComplete: () {
        statusText = 'Done! Press any key to continue.';
      },
    ));
  }

  void _runBigTextMatrix() {
    statusText = 'BigText with MATRIX reveal...';
    final lines = BigText.generateLines('MATRIX', font: BigTextFont.shadow);
    final maxLen = lines.map((l) => l.length).reduce((a, b) => a > b ? a : b);
    controller.add(BigTextAnimation(
      lines: lines,
      lineDelay: Duration(milliseconds: 120),
      defaultStyle: LineRevealConfig.matrix,
      onUpdate: (rendered) {
        currentEffect = rendered.join('\n');
      },
      onComplete: () {
        // Pad lines to clear any leftover matrix chars
        currentEffect = lines.map((l) => '${Colors.brightGreen}${l.padRight(maxLen + 10)}${Colors.reset}').join('\n');
        statusText = 'Done! Press any key to continue.';
      },
    ));
  }

  void _runBigTextMixed() {
    statusText = 'BigText with MIXED styles per line...';
    final lines = BigText.generateLines('MIXED', font: BigTextFont.shadow);
    controller.add(BigTextAnimation(
      lines: lines,
      lineDelay: Duration(milliseconds: 200),
      lineStyles: [
        LineRevealConfig.glitch,      // Line 1: glitch
        LineRevealConfig.matrix,      // Line 2: matrix
        LineRevealConfig.typewriter,  // Line 3: typewriter
        LineRevealConfig.fade,        // Line 4: fade
        LineRevealConfig.glitch,      // Line 5: glitch
        LineRevealConfig.matrix,      // Line 6: matrix
      ],
      onUpdate: (rendered) {
        var buf = StringBuffer();
        var colors = [Colors.red, Colors.green, Colors.cyan, Colors.yellow, Colors.magenta, Colors.brightGreen];
        for (var i = 0; i < rendered.length; i++) {
          buf.write('${colors[i % colors.length]}${rendered[i]}${Colors.reset}\n');
        }
        currentEffect = buf.toString().trimRight();
      },
      onComplete: () {
        statusText = 'Done! Press any key to continue.';
      },
    ));
  }

  void _runMatrixRain() {
    statusText = 'Matrix Rain effect...';
    controller.add(MatrixRainAnimation(
      width: 60,
      duration: Duration(milliseconds: 3000),
      onUpdate: (line) {
        currentEffect = line;
      },
      onComplete: () {
        currentEffect = '';
        statusText = 'Done! Press any key to continue.';
      },
    ));
  }

  void _runParticleBurst() {
    statusText = 'Particle Burst effect...';
    controller.add(ParticleBurstAnimation(
      width: 60,
      duration: Duration(milliseconds: 2000),
      density: 0.2,
      onUpdate: (line) {
        currentEffect = line;
      },
      onComplete: () {
        currentEffect = '${Colors.brightGreen}${Colors.bold}SUCCESS!${Colors.reset}';
        statusText = 'Done! Press any key to continue.';
      },
    ));
  }

  void _runCountdown() {
    statusText = 'Countdown animation...';
    controller.add(CountdownAnimation(
      from: 5,
      onUpdate: (remaining, display) {
        currentEffect = '${Colors.brightCyan}${Colors.bold}$display${Colors.reset}';
      },
      onComplete: () {
        statusText = 'Done! Press any key to continue.';
      },
    ));
  }

  void _runScrollingBanner() {
    statusText = 'Scrolling Banner animation...';
    controller.add(ScrollingBannerAnimation(
      text: ' DART TUI ANIMATION SYSTEM ',
      width: 40,
      iterations: 2,
      onUpdate: (visible) {
        currentEffect = '${Colors.cyan}$visible${Colors.reset}';
      },
      onComplete: () {
        currentEffect = '${Colors.cyan}     DART TUI ANIMATION SYSTEM     ${Colors.reset}';
        statusText = 'Done! Press any key to continue.';
      },
    ));
  }

  void _runCascade() {
    statusText = 'Cascade animation...';
    var items = ['Loading modules...', 'Initializing system...', 'Connecting to server...', 'Ready!'];
    controller.add(CascadeAnimation(
      items: items,
      itemDelay: Duration(milliseconds: 500),
      onUpdate: (count, visible) {
        currentEffect = visible.map((s) => '${Colors.green}> $s${Colors.reset}').join('\n');
      },
      onComplete: () {
        statusText = 'Done! Press any key to continue.';
      },
    ));
  }

  @override
  bool onKey(String key) {
    if (key == 'q' || key == KeyCode.ESCAPE) {
      controller.clear();
      stop();
      return true;
    }

    if (key == 'f' || key == 'F') {
      showFps = !showFps;
      return true;
    }

    if (key == KeyCode.UP) {
      demoIndex = (demoIndex - 1) % demos.length;
      if (demoIndex < 0) demoIndex = demos.length - 1;
      return true;
    }

    if (key == KeyCode.DOWN) {
      demoIndex = (demoIndex + 1) % demos.length;
      return true;
    }

    if (key == KeyCode.ENTER) {
      _runDemo(demoIndex);
      return true;
    }

    return super.onKey(key);
  }

  @override
  void update() {
    text = [];
    var y = 0;

    // Title
    text.add(Text('${Colors.brightCyan}${Colors.bold}Animation System Demo${Colors.reset}')
      ..position = Position(0, y++));
    text.add(Text('${BoxChars.lightH * 50}')..position = Position(0, y++));
    y++;

    // Menu
    text.add(Text('${Colors.dim}Select animation:${Colors.reset}')..position = Position(0, y++));
    for (var i = 0; i < demos.length; i++) {
      var prefix = i == demoIndex ? '${Colors.brightGreen}> ' : '  ';
      var suffix = i == demoIndex ? '${Colors.reset}' : '';
      text.add(Text('$prefix${demos[i]}$suffix')..position = Position(0, y++));
    }
    y++;

    // Divider
    text.add(Text('${BoxChars.lightH * 50}')..position = Position(0, y++));
    y++;

    // Effect display area
    text.add(Text('${Colors.dim}Output:${Colors.reset}')..position = Position(0, y++));

    // Split effect by newlines for cascade
    var effectLines = currentEffect.split('\n');
    for (var line in effectLines) {
      text.add(Text(line)..position = Position(0, y++));
    }

    // Ensure some space
    while (y < 22) y++;

    // Status
    text.add(Text('${BoxChars.lightH * 50}')..position = Position(0, y++));
    text.add(Text('${Colors.dim}$statusText${Colors.reset}')..position = Position(0, y));
  }
}

void main() {
  print('Animation System Demo');
  print('${BoxChars.lightH * 40}');
  print('');
  print('Repeat modes: once, reverse, loop, pingPong');
  print('New: Reveal, Shimmer, Blink animations');
  print('');
  print('UP/DOWN = select animation');
  print('ENTER   = run animation');
  print('F       = toggle FPS meter');
  print('Q/ESC   = quit');
  print('${BoxChars.lightH * 40}');
  print('Starting in 1 second...');

  Future.delayed(Duration(seconds: 1), () {
    AnimationDemo().start();
  });
}
