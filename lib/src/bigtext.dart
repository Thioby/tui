part of tui;

/// Font style for BigText widget.
enum BigTextFont {
  /// Block letters using █ characters
  block,

  /// Slim letters using ╔═╗ box drawing
  slim,

  /// Chunky 3D-style letters
  chunky,
}

/// RGB color for gradients.
class RGB {
  final int r, g, b;
  const RGB(this.r, this.g, this.b);

  /// Interpolate between two colors.
  RGB lerp(RGB other, double t) {
    return RGB(
      (r + (other.r - r) * t).round(),
      (g + (other.g - g) * t).round(),
      (b + (other.b - b) * t).round(),
    );
  }

  /// Convert to ANSI true color escape sequence.
  String toAnsi() => '38;2;$r;$g;$b';
}

/// Predefined gradients.
class Gradients {
  static const rainbow = [
    RGB(255, 0, 0),    // Red
    RGB(255, 127, 0),  // Orange
    RGB(255, 255, 0),  // Yellow
    RGB(0, 255, 0),    // Green
    RGB(0, 0, 255),    // Blue
    RGB(139, 0, 255),  // Violet
  ];

  static const sunset = [
    RGB(255, 100, 100),
    RGB(255, 150, 50),
    RGB(255, 200, 100),
  ];

  static const ocean = [
    RGB(0, 100, 150),
    RGB(0, 150, 200),
    RGB(100, 200, 255),
  ];

  static const purple = [
    RGB(100, 100, 255),
    RGB(150, 100, 200),
    RGB(200, 100, 150),
  ];

  static const cyan = [
    RGB(0, 200, 200),
    RGB(0, 255, 255),
    RGB(100, 255, 255),
  ];

  static const fire = [
    RGB(255, 0, 0),
    RGB(255, 100, 0),
    RGB(255, 200, 0),
  ];

  static const forest = [
    RGB(0, 100, 0),
    RGB(0, 150, 50),
    RGB(50, 200, 100),
  ];

  static const gemini = [
    RGB(100, 130, 255),  // Blue
    RGB(150, 120, 200),  // Purple
    RGB(200, 150, 180),  // Pink
  ];
}

/// Displays text as large ASCII art letters.
///
/// Example:
/// ```dart
/// var banner = BigText('HELLO')
///   ..font = BigTextFont.block
///   ..color = '36';
///
/// // With gradient:
/// var gradientBanner = BigText('HELLO')
///   ..gradient = Gradients.rainbow;
/// ```
class BigText extends View {
  String _text;

  String get content => _text;
  set content(String value) {
    _text = value.toUpperCase();
    update();
  }

  /// Font style to use.
  BigTextFont font;

  /// Color for the text (ANSI code). Ignored if gradient is set.
  String color = '0';

  /// Gradient colors. If set, overrides color.
  List<RGB>? gradient;

  /// Horizontal spacing between letters.
  int letterSpacing = 1;

  BigText(this._text, {this.font = BigTextFont.block, this.gradient}) {
    _text = _text.toUpperCase();
  }

  @override
  void update() {
    text = [];
    if (width < 1 || height < 1) return;

    var fontData = _getFontData();
    var charHeight = fontData.height;
    var lines = List.generate(charHeight, (_) => StringBuffer());

    for (var i = 0; i < _text.length; i++) {
      var char = _text[i];
      var glyph = fontData.glyphs[char] ?? fontData.glyphs[' ']!;

      for (var row = 0; row < charHeight; row++) {
        if (row < glyph.length) {
          lines[row].write(glyph[row]);
        }
        if (i < _text.length - 1) {
          lines[row].write(' ' * letterSpacing);
        }
      }
    }

    for (var row = 0; row < charHeight && row < height; row++) {
      var line = lines[row].toString();
      if (line.length > width) {
        line = line.substring(0, width);
      }

      if (gradient != null && gradient!.isNotEmpty) {
        // Render with gradient - each character gets its own color
        _renderGradientLine(line, row);
      } else {
        text.add(Text(line)
          ..color = color
          ..position = Position(0, row));
      }
    }
  }

  void _renderGradientLine(String line, int row) {
    if (line.isEmpty) return;

    for (var x = 0; x < line.length; x++) {
      var char = line[x];
      if (char == ' ') continue; // Skip spaces for performance

      var gradientColor = _getGradientColor(x, line.length);
      text.add(Text(char)
        ..color = gradientColor.toAnsi()
        ..position = Position(x, row));
    }
  }

  RGB _getGradientColor(int position, int totalWidth) {
    if (gradient == null || gradient!.isEmpty) {
      return RGB(255, 255, 255);
    }
    if (gradient!.length == 1) {
      return gradient!.first;
    }

    var t = totalWidth > 1 ? position / (totalWidth - 1) : 0.0;
    var scaledT = t * (gradient!.length - 1);
    var index = scaledT.floor();
    var localT = scaledT - index;

    if (index >= gradient!.length - 1) {
      return gradient!.last;
    }

    return gradient![index].lerp(gradient![index + 1], localT);
  }

  _FontData _getFontData() {
    switch (font) {
      case BigTextFont.block:
        return _blockFont;
      case BigTextFont.slim:
        return _slimFont;
      case BigTextFont.chunky:
        return _chunkyFont;
    }
  }
}

class _FontData {
  final int height;
  final Map<String, List<String>> glyphs;

  _FontData(this.height, this.glyphs);
}

final _blockFont = _FontData(5, {
  'A': [
    '█████',
    '█   █',
    '█████',
    '█   █',
    '█   █',
  ],
  'B': [
    '████ ',
    '█   █',
    '████ ',
    '█   █',
    '████ ',
  ],
  'C': [
    '█████',
    '█    ',
    '█    ',
    '█    ',
    '█████',
  ],
  'D': [
    '████ ',
    '█   █',
    '█   █',
    '█   █',
    '████ ',
  ],
  'E': [
    '█████',
    '█    ',
    '████ ',
    '█    ',
    '█████',
  ],
  'F': [
    '█████',
    '█    ',
    '████ ',
    '█    ',
    '█    ',
  ],
  'G': [
    '█████',
    '█    ',
    '█  ██',
    '█   █',
    '█████',
  ],
  'H': [
    '█   █',
    '█   █',
    '█████',
    '█   █',
    '█   █',
  ],
  'I': [
    '█████',
    '  █  ',
    '  █  ',
    '  █  ',
    '█████',
  ],
  'J': [
    '█████',
    '    █',
    '    █',
    '█   █',
    '█████',
  ],
  'K': [
    '█   █',
    '█  █ ',
    '███  ',
    '█  █ ',
    '█   █',
  ],
  'L': [
    '█    ',
    '█    ',
    '█    ',
    '█    ',
    '█████',
  ],
  'M': [
    '█   █',
    '██ ██',
    '█ █ █',
    '█   █',
    '█   █',
  ],
  'N': [
    '█   █',
    '██  █',
    '█ █ █',
    '█  ██',
    '█   █',
  ],
  'O': [
    '█████',
    '█   █',
    '█   █',
    '█   █',
    '█████',
  ],
  'P': [
    '█████',
    '█   █',
    '█████',
    '█    ',
    '█    ',
  ],
  'Q': [
    '█████',
    '█   █',
    '█   █',
    '█  █ ',
    '███ █',
  ],
  'R': [
    '█████',
    '█   █',
    '█████',
    '█  █ ',
    '█   █',
  ],
  'S': [
    '█████',
    '█    ',
    '█████',
    '    █',
    '█████',
  ],
  'T': [
    '█████',
    '  █  ',
    '  █  ',
    '  █  ',
    '  █  ',
  ],
  'U': [
    '█   █',
    '█   █',
    '█   █',
    '█   █',
    '█████',
  ],
  'V': [
    '█   █',
    '█   █',
    '█   █',
    ' █ █ ',
    '  █  ',
  ],
  'W': [
    '█   █',
    '█   █',
    '█ █ █',
    '██ ██',
    '█   █',
  ],
  'X': [
    '█   █',
    ' █ █ ',
    '  █  ',
    ' █ █ ',
    '█   █',
  ],
  'Y': [
    '█   █',
    ' █ █ ',
    '  █  ',
    '  █  ',
    '  █  ',
  ],
  'Z': [
    '█████',
    '   █ ',
    '  █  ',
    ' █   ',
    '█████',
  ],
  '0': [
    '█████',
    '█   █',
    '█   █',
    '█   █',
    '█████',
  ],
  '1': [
    '  █  ',
    ' ██  ',
    '  █  ',
    '  █  ',
    '█████',
  ],
  '2': [
    '█████',
    '    █',
    '█████',
    '█    ',
    '█████',
  ],
  '3': [
    '█████',
    '    █',
    '█████',
    '    █',
    '█████',
  ],
  '4': [
    '█   █',
    '█   █',
    '█████',
    '    █',
    '    █',
  ],
  '5': [
    '█████',
    '█    ',
    '█████',
    '    █',
    '█████',
  ],
  '6': [
    '█████',
    '█    ',
    '█████',
    '█   █',
    '█████',
  ],
  '7': [
    '█████',
    '    █',
    '   █ ',
    '  █  ',
    '  █  ',
  ],
  '8': [
    '█████',
    '█   █',
    '█████',
    '█   █',
    '█████',
  ],
  '9': [
    '█████',
    '█   █',
    '█████',
    '    █',
    '█████',
  ],
  ' ': [
    '     ',
    '     ',
    '     ',
    '     ',
    '     ',
  ],
  '!': [
    '  █  ',
    '  █  ',
    '  █  ',
    '     ',
    '  █  ',
  ],
  '.': [
    '     ',
    '     ',
    '     ',
    '     ',
    '  █  ',
  ],
  '-': [
    '     ',
    '     ',
    '█████',
    '     ',
    '     ',
  ],
  '_': [
    '     ',
    '     ',
    '     ',
    '     ',
    '█████',
  ],
});

final _slimFont = _FontData(5, {
  'A': [
    '╔═╗',
    '╠═╣',
    '║ ║',
  ].followedBy(['║ ║', '╩ ╩']).toList(),
  'B': [
    '╔═╗',
    '╠═╣',
    '╠═╣',
    '║ ║',
    '╚═╝',
  ],
  'C': [
    '╔══',
    '║  ',
    '║  ',
    '║  ',
    '╚══',
  ],
  'D': [
    '╔═╗',
    '║ ║',
    '║ ║',
    '║ ║',
    '╚═╝',
  ],
  'E': [
    '╔══',
    '╠═ ',
    '║  ',
    '║  ',
    '╚══',
  ],
  'F': [
    '╔══',
    '╠═ ',
    '║  ',
    '║  ',
    '╩  ',
  ],
  'G': [
    '╔══',
    '║  ',
    '║ ╗',
    '║ ║',
    '╚═╝',
  ],
  'H': [
    '║ ║',
    '╠═╣',
    '║ ║',
    '║ ║',
    '╩ ╩',
  ],
  'I': [
    '═╦═',
    ' ║ ',
    ' ║ ',
    ' ║ ',
    '═╩═',
  ],
  'J': [
    '══╗',
    '  ║',
    '  ║',
    '╔═╣',
    '╚═╝',
  ],
  'K': [
    '║ ╱',
    '╠╣ ',
    '║ ╲',
    '║ ║',
    '╩ ╩',
  ],
  'L': [
    '║  ',
    '║  ',
    '║  ',
    '║  ',
    '╚══',
  ],
  'M': [
    '╔╗╔╗',
    '║╚╝║',
    '║  ║',
    '║  ║',
    '╩  ╩',
  ],
  'N': [
    '╔╗ ║',
    '║╚╗║',
    '║ ╚╣',
    '║  ║',
    '╩  ╩',
  ],
  'O': [
    '╔═╗',
    '║ ║',
    '║ ║',
    '║ ║',
    '╚═╝',
  ],
  'P': [
    '╔═╗',
    '╠═╝',
    '║  ',
    '║  ',
    '╩  ',
  ],
  'Q': [
    '╔═╗',
    '║ ║',
    '║ ║',
    '║╚╗',
    '╚═╩',
  ],
  'R': [
    '╔═╗',
    '╠═╣',
    '║╚╗',
    '║ ║',
    '╩ ╩',
  ],
  'S': [
    '╔══',
    '╚═╗',
    '  ║',
    '╔═╝',
    '╚══',
  ],
  'T': [
    '═╦═',
    ' ║ ',
    ' ║ ',
    ' ║ ',
    ' ╩ ',
  ],
  'U': [
    '║ ║',
    '║ ║',
    '║ ║',
    '║ ║',
    '╚═╝',
  ],
  'V': [
    '║ ║',
    '║ ║',
    '║ ║',
    '╚╦╝',
    ' ╩ ',
  ],
  'W': [
    '║  ║',
    '║  ║',
    '║╔╗║',
    '╠╝╚╣',
    '╩  ╩',
  ],
  'X': [
    '╲ ╱',
    ' ╳ ',
    '╱ ╲',
    '║ ║',
    '╩ ╩',
  ],
  'Y': [
    '╲ ╱',
    ' ║ ',
    ' ║ ',
    ' ║ ',
    ' ╩ ',
  ],
  'Z': [
    '══╗',
    ' ╔╝',
    '╔╝ ',
    '║  ',
    '╚══',
  ],
  ' ': [
    '   ',
    '   ',
    '   ',
    '   ',
    '   ',
  ],
});

final _chunkyFont = _FontData(4, {
  'A': [
    '▄▀▀▄',
    '█▄▄█',
    '█  █',
    '▀  ▀',
  ],
  'B': [
    '█▀▀▄',
    '█▄▄▀',
    '█  █',
    '▀▀▀ ',
  ],
  'C': [
    '▄▀▀▀',
    '█   ',
    '█   ',
    '▀▀▀▀',
  ],
  'D': [
    '█▀▀▄',
    '█  █',
    '█  █',
    '▀▀▀ ',
  ],
  'E': [
    '█▀▀▀',
    '█▄▄ ',
    '█   ',
    '▀▀▀▀',
  ],
  'F': [
    '█▀▀▀',
    '█▄▄ ',
    '█   ',
    '▀   ',
  ],
  'G': [
    '▄▀▀▀',
    '█ ▀█',
    '█  █',
    '▀▀▀▀',
  ],
  'H': [
    '█  █',
    '█▄▄█',
    '█  █',
    '▀  ▀',
  ],
  'I': [
    '▀█▀',
    ' █ ',
    ' █ ',
    '▀▀▀',
  ],
  'J': [
    '  ▀█',
    '   █',
    '█  █',
    '▀▀▀ ',
  ],
  'K': [
    '█ ▄▀',
    '██  ',
    '█ ▀▄',
    '▀  ▀',
  ],
  'L': [
    '█   ',
    '█   ',
    '█   ',
    '▀▀▀▀',
  ],
  'M': [
    '█▄▄█',
    '█▀▀█',
    '█  █',
    '▀  ▀',
  ],
  'N': [
    '█▄ █',
    '█ ▀█',
    '█  █',
    '▀  ▀',
  ],
  'O': [
    '▄▀▀▄',
    '█  █',
    '█  █',
    '▀▀▀▀',
  ],
  'P': [
    '█▀▀▄',
    '█▄▄▀',
    '█   ',
    '▀   ',
  ],
  'Q': [
    '▄▀▀▄',
    '█  █',
    '█ ▀█',
    '▀▀▀▀',
  ],
  'R': [
    '█▀▀▄',
    '█▄▄▀',
    '█ ▀▄',
    '▀  ▀',
  ],
  'S': [
    '▄▀▀▀',
    '▀▀▀▄',
    '▄  █',
    '▀▀▀ ',
  ],
  'T': [
    '▀█▀',
    ' █ ',
    ' █ ',
    ' ▀ ',
  ],
  'U': [
    '█  █',
    '█  █',
    '█  █',
    '▀▀▀▀',
  ],
  'V': [
    '█  █',
    '█  █',
    '▀▄▄▀',
    ' ▀▀ ',
  ],
  'W': [
    '█  █',
    '█  █',
    '█▄▄█',
    '▀▀▀▀',
  ],
  'X': [
    '▀▄▄▀',
    ' ▀▀ ',
    '▄▀▀▄',
    '▀  ▀',
  ],
  'Y': [
    '█  █',
    '▀▄▄▀',
    ' █▀ ',
    ' ▀  ',
  ],
  'Z': [
    '▀▀▀█',
    ' ▄▀ ',
    '▄▀  ',
    '▀▀▀▀',
  ],
  ' ': [
    '    ',
    '    ',
    '    ',
    '    ',
  ],
  '!': [
    ' █ ',
    ' █ ',
    '   ',
    ' ▀ ',
  ],
});
