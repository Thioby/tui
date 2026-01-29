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
    'Pulse',
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
      case 'Pulse':
        _runPulse();
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

  void _runPulse() {
    statusText = 'Pulse animation (3 pulses)...';
    currentEffect = '>>> ALERT <<<';
    controller.add(PulseAnimation(
      pulses: 5,
      onUpdate: (bright) {
        // We'll indicate brightness in the effect string
        currentEffect = bright ? '${Colors.brightRed}>>> ALERT <<<${Colors.reset}' : '${Colors.dim}>>> ALERT <<<${Colors.reset}';
      },
      onComplete: () {
        currentEffect = '>>> ALERT <<<';
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
