import 'package:tui/tui.dart';

class BigTextDemo extends Window {
  BigTextDemo() {
    // Simple solid color text
    var title = BigText('DART TUI', font: BigTextFont.block)
      ..color = '36';

    // With rainbow gradient
    var rainbow = BigText('RAINBOW', font: BigTextFont.block)
      ..gradient = Gradients.rainbow;

    // Gemini-style gradient
    var gemini = BigText('GEMINI', font: BigTextFont.block)
      ..gradient = Gradients.gemini;

    // Fire gradient with chunky font
    var fire = BigText('FIRE', font: BigTextFont.chunky)
      ..gradient = Gradients.fire;

    // Ocean gradient with slim font
    var ocean = BigText('OCEAN', font: BigTextFont.slim)
      ..gradient = Gradients.ocean;

    children = [
      SplitView(horizontal: false, ratios: [1, 1, 1, 1, 1])
        ..children = [title, rainbow, gemini, fire, ocean],
    ];
  }

  @override
  bool onKey(String key) {
    if (key == 'q' || key == KeyCode.ESCAPE) {
      stop();
      return true;
    }
    return super.onKey(key);
  }
}

void main() {
  print("BigText Demo - ASCII Art Banners with Gradients");
  print("────────────────────────────────────────────────");
  print("Fonts: block, slim, chunky");
  print("Gradients: rainbow, gemini, sunset, ocean, fire, forest, purple, cyan");
  print("");
  print("Press q or ESC to quit");
  print("Starting in 1 second...");
  Future.delayed(Duration(seconds: 1), () {
    BigTextDemo().start();
  });
}
