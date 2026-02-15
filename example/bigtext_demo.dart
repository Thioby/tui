import 'package:tui/tui.dart';

class BigTextDemo extends Window {
  int currentPage = 0;
  final pages = <String>[
    'Fonts',
    'Gradients',
    'Borders',
    'Showcase',
    'Animated'
  ];
  late Frame mainFrame;

  BigTextDemo() {
    showFps = true;
    mainFrame = Frame(title: 'BigText Demo - Fonts [1/4]', color: '36');
    children = [mainFrame];
    _showPage();
  }

  void _showPage() {
    mainFrame.title =
        'BigText Demo - ${pages[currentPage]} [${currentPage + 1}/${pages.length}]';

    switch (pages[currentPage]) {
      case 'Fonts':
        _showFonts();
      case 'Gradients':
        _showGradients();
      case 'Borders':
        _showBorders();
      case 'Showcase':
        _showShowcase();
      case 'Animated':
        _showAnimated();
    }
  }

  void _showFonts() {
    var block = BigText('BLOCK', font: BigTextFont.block)
      ..gradient = Gradients.cyan;

    var slim = BigText('SLIM', font: BigTextFont.slim)
      ..gradient = Gradients.purple;

    var chunky = BigText('CHUNKY', font: BigTextFont.chunky)
      ..gradient = Gradients.fire;

    var shadow = BigText('SHADOW', font: BigTextFont.shadow)
      ..gradient = Gradients.matrix;

    mainFrame.children = [
      SplitView(horizontal: false, ratios: [1, 1, 1, 1])
        ..children = [block, slim, chunky, shadow],
    ];
  }

  void _showGradients() {
    var rainbow = BigText('RAINBOW', font: BigTextFont.block)
      ..gradient = Gradients.rainbow;

    var sunset = BigText('SUNSET', font: BigTextFont.block)
      ..gradient = Gradients.sunset;

    var ocean = BigText('OCEAN', font: BigTextFont.slim)
      ..gradient = Gradients.ocean;

    var matrix = BigText('MATRIX', font: BigTextFont.shadow)
      ..gradient = Gradients.matrix;

    var fire = BigText('FIRE', font: BigTextFont.chunky)
      ..gradient = Gradients.fire;

    mainFrame.children = [
      SplitView(horizontal: false, ratios: [1, 1, 1, 1, 1])
        ..children = [rainbow, sunset, ocean, matrix, fire],
    ];
  }

  void _showBorders() {
    // Simple border
    var simple = BigText('HELLO', font: BigTextFont.block)
      ..gradient = Gradients.cyan
      ..showBorder = true
      ..borderColor = '36';

    // Border with subtitle
    var withSubtitle = BigText('DART', font: BigTextFont.shadow)
      ..gradient = Gradients.gemini
      ..showBorder = true
      ..borderColor = '35'
      ..subtitle = 'Terminal User Interface Library'
      ..subtitleColor = '37';

    // Another with subtitle
    var welcome = BigText('WELCOME', font: BigTextFont.slim)
      ..gradient = Gradients.rainbow
      ..showBorder = true
      ..borderColor = '33'
      ..subtitle = 'Press any key to continue...'
      ..subtitleColor = '8';

    mainFrame.children = [
      SplitView(horizontal: false, ratios: [1, 1, 1])
        ..children = [simple, withSubtitle, welcome],
    ];
  }

  void _showShowcase() {
    // Epic banner with everything
    var banner = BigText('TUI', font: BigTextFont.shadow)
      ..gradient = Gradients.gemini
      ..showBorder = true
      ..borderColor = '38;2;100;130;255'
      ..subtitle = 'Beautiful Terminal Interfaces in Dart'
      ..subtitleColor = '38;2;150;120;200';

    // Matrix style
    var matrix = BigText('MATRIX', font: BigTextFont.shadow)
      ..gradient = Gradients.matrix
      ..showBorder = true
      ..borderColor = '32'
      ..subtitle = 'Follow the white rabbit'
      ..subtitleColor = '32';

    // Fire warning
    var warning = BigText('WARNING', font: BigTextFont.chunky)
      ..gradient = Gradients.fire
      ..showBorder = true
      ..borderColor = '31'
      ..subtitle = 'System overheating!'
      ..subtitleColor = '33';

    mainFrame.children = [
      SplitView(horizontal: false, ratios: [2, 2, 1])
        ..children = [banner, matrix, warning],
    ];
  }

  void _showAnimated() {
    var typewriter = AnimatedBigText(
      'HELLO',
      font: BigTextFont.shadow,
      gradient: Gradients.cyan,
      defaultStyle: LineRevealConfig.typewriter,
      lineDelay: Duration(milliseconds: 120),
    );

    var glitch = AnimatedBigText(
      'GLITCH',
      font: BigTextFont.shadow,
      gradient: Gradients.fire,
      defaultStyle: LineRevealConfig.glitch,
      lineDelay: Duration(milliseconds: 100),
    );

    var matrix = AnimatedBigText(
      'MATRIX',
      font: BigTextFont.shadow,
      gradient: Gradients.matrix,
      defaultStyle: LineRevealConfig.matrix,
      lineDelay: Duration(milliseconds: 150),
    );

    mainFrame.children = [
      SplitView(horizontal: false, ratios: [1, 1, 1])
        ..children = [typewriter, glitch, matrix],
    ];
  }

  @override
  bool onKey(String key) {
    if (key == 'q' || key == KeyCode.ESCAPE) {
      stop();
      return true;
    }

    if (key == KeyCode.LEFT || key == 'h') {
      currentPage = (currentPage - 1) % pages.length;
      if (currentPage < 0) currentPage = pages.length - 1;
      _showPage();
      return true;
    }

    if (key == KeyCode.RIGHT || key == 'l') {
      currentPage = (currentPage + 1) % pages.length;
      _showPage();
      return true;
    }

    if (key == 'f' || key == 'F') {
      showFps = !showFps;
      return true;
    }

    return super.onKey(key);
  }
}

void main() {
  print('BigText Demo - ASCII Art Banners');
  print('${BoxChars.lightH * 40}');
  print('');
  print('Pages:');
  print('  1. Fonts    - block, slim, chunky, shadow');
  print('  2. Gradients - rainbow, sunset, ocean, matrix, fire');
  print('  3. Borders  - with subtitle support');
  print('  4. Showcase - combined features');
  print('  5. Animated - AnimatedBigText reveal effects');
  print('');
  print('Controls:');
  print('  LEFT/RIGHT or H/L = switch pages');
  print('  F = toggle FPS');
  print('  Q/ESC = quit');
  print('');
  print('${BoxChars.lightH * 40}');
  print('Starting in 1 second...');

  Future.delayed(Duration(seconds: 1), () {
    BigTextDemo().start();
  });
}
