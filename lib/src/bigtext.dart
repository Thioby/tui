part of tui;

/// Font style for BigText widget.
enum BigTextFont {
  /// Block letters using █ characters (5 lines high)
  block,

  /// Slim letters using ╔═╗ box drawing (5 lines high)
  slim,

  /// Chunky half-block style ▄▀ (4 lines high)
  chunky,

  /// FIGlet-style 3D shadow font ███╗ (6 lines high)
  shadow,
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
    RGB(255, 0, 0),
    RGB(255, 127, 0),
    RGB(255, 255, 0),
    RGB(0, 255, 0),
    RGB(0, 0, 255),
    RGB(139, 0, 255),
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
    RGB(100, 130, 255),
    RGB(150, 120, 200),
    RGB(200, 150, 180),
  ];

  static const matrix = [
    RGB(0, 80, 0),
    RGB(0, 180, 0),
    RGB(100, 255, 100),
  ];
}

/// Displays text as large ASCII art letters with optional subtitle and border.
///
/// Example:
/// ```dart
/// var banner = BigText('HELLO', font: BigTextFont.shadow)
///   ..subtitle = 'Welcome to the app'
///   ..gradient = Gradients.gemini
///   ..showBorder = true;
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

  /// Optional subtitle displayed below the main text.
  String? subtitle;

  /// Color for subtitle (ANSI code).
  String subtitleColor = '8';

  /// Whether to show a border around the banner.
  bool showBorder = false;

  /// Border color (ANSI code).
  String borderColor = '36';

  /// Whether to center the text horizontally.
  bool centered = true;

  BigText(this._text, {
    this.font = BigTextFont.block,
    this.gradient,
    this.subtitle,
    this.showBorder = false,
    this.centered = true,
  }) {
    _text = _text.toUpperCase();
  }

  /// Generate raw ASCII art lines for given text and font.
  /// Useful for animations that need the raw line data.
  static List<String> generateLines(String text, {BigTextFont font = BigTextFont.shadow, int letterSpacing = 1}) {
    text = text.toUpperCase();
    var fontData = _getFontDataFor(font);
    var charHeight = fontData.height;
    var lines = List.generate(charHeight, (_) => StringBuffer());

    for (var i = 0; i < text.length; i++) {
      var char = text[i];
      var glyph = fontData.glyphs[char] ?? fontData.glyphs[' ']!;

      for (var row = 0; row < charHeight; row++) {
        if (row < glyph.length) {
          lines[row].write(glyph[row]);
        }
        if (i < text.length - 1) {
          lines[row].write(' ' * letterSpacing);
        }
      }
    }

    return lines.map((sb) => sb.toString()).toList();
  }

  static _FontData _getFontDataFor(BigTextFont font) {
    switch (font) {
      case BigTextFont.block:
        return _blockFont;
      case BigTextFont.slim:
        return _slimFont;
      case BigTextFont.chunky:
        return _chunkyFont;
      case BigTextFont.shadow:
        return _shadowFont;
    }
  }

  @override
  void update() {
    text = [];
    if (width < 1 || height < 1) return;

    var fontData = _getFontData();
    var charHeight = fontData.height;
    var lines = List.generate(charHeight, (_) => StringBuffer());

    // Build the text lines
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

    var textWidth = lines.isNotEmpty ? lines[0].length : 0;
    var totalHeight = charHeight;
    if (subtitle != null) totalHeight += 2; // spacing + subtitle
    if (showBorder) totalHeight += 2; // top + bottom border

    var y = 0;
    var contentWidth = showBorder ? width - 2 : width;
    var xOffset = showBorder ? 1 : 0;

    // Top border
    if (showBorder) {
      var borderWidth = max(textWidth + 4, (subtitle?.length ?? 0) + 6);
      if (borderWidth > width) borderWidth = width;
      var borderLine = '${BoxChars.doubleTL}${BoxChars.doubleH * (borderWidth - 2)}${BoxChars.doubleTR}';
      var bx = centered ? (width - borderWidth) ~/ 2 : 0;
      text.add(Text(borderLine)
        ..color = borderColor
        ..position = Position(bx, y++));
    }

    // Main text lines
    for (var row = 0; row < charHeight && y < height - (showBorder ? 1 : 0); row++) {
      var line = lines[row].toString();
      if (line.length > contentWidth) {
        line = line.substring(0, contentWidth);
      }

      var x = xOffset;
      if (centered) {
        x = (width - line.length) ~/ 2;
        if (x < xOffset) x = xOffset;
      }

      if (showBorder) {
        // Add side borders
        var borderWidth = max(textWidth + 4, (subtitle?.length ?? 0) + 6);
        if (borderWidth > width) borderWidth = width;
        var bx = centered ? (width - borderWidth) ~/ 2 : 0;
        text.add(Text(BoxChars.doubleV)
          ..color = borderColor
          ..position = Position(bx, y));
        text.add(Text(BoxChars.doubleV)
          ..color = borderColor
          ..position = Position(bx + borderWidth - 1, y));
      }

      if (gradient != null && gradient!.isNotEmpty) {
        _renderGradientLine(line, x, y);
      } else {
        text.add(Text(line)
          ..color = color
          ..position = Position(x, y));
      }
      y++;
    }

    // Subtitle
    if (subtitle != null && y < height - (showBorder ? 1 : 0)) {
      y++; // spacing

      if (showBorder) {
        var borderWidth = max(textWidth + 4, subtitle!.length + 6);
        if (borderWidth > width) borderWidth = width;
        var bx = centered ? (width - borderWidth) ~/ 2 : 0;

        // Subtitle box inside main border
        var subBoxWidth = subtitle!.length + 4;
        var subX = centered ? (width - subBoxWidth) ~/ 2 : bx + 2;

        text.add(Text(BoxChars.doubleV)
          ..color = borderColor
          ..position = Position(bx, y));
        text.add(Text('${BoxChars.lightTL}${BoxChars.lightH * (subBoxWidth - 2)}${BoxChars.lightTR}')
          ..color = subtitleColor
          ..position = Position(subX, y));
        text.add(Text(BoxChars.doubleV)
          ..color = borderColor
          ..position = Position(bx + borderWidth - 1, y));
        y++;

        text.add(Text(BoxChars.doubleV)
          ..color = borderColor
          ..position = Position(bx, y));
        text.add(Text(BoxChars.lightV)
          ..color = subtitleColor
          ..position = Position(subX, y));
        text.add(Text(' ${subtitle!} ')
          ..color = subtitleColor
          ..position = Position(subX + 1, y));
        text.add(Text(BoxChars.lightV)
          ..color = subtitleColor
          ..position = Position(subX + subBoxWidth - 1, y));
        text.add(Text(BoxChars.doubleV)
          ..color = borderColor
          ..position = Position(bx + borderWidth - 1, y));
        y++;

        text.add(Text(BoxChars.doubleV)
          ..color = borderColor
          ..position = Position(bx, y));
        text.add(Text('${BoxChars.lightBL}${BoxChars.lightH * (subBoxWidth - 2)}${BoxChars.lightBR}')
          ..color = subtitleColor
          ..position = Position(subX, y));
        text.add(Text(BoxChars.doubleV)
          ..color = borderColor
          ..position = Position(bx + borderWidth - 1, y));
        y++;
      } else {
        // Simple subtitle without border
        var subX = centered ? (width - subtitle!.length) ~/ 2 : 0;
        text.add(Text(subtitle!)
          ..color = subtitleColor
          ..position = Position(subX, y));
        y++;
      }
    }

    // Bottom border
    if (showBorder && y < height) {
      var borderWidth = max(textWidth + 4, (subtitle?.length ?? 0) + 6);
      if (borderWidth > width) borderWidth = width;
      var borderLine = '${BoxChars.doubleBL}${BoxChars.doubleH * (borderWidth - 2)}${BoxChars.doubleBR}';
      var bx = centered ? (width - borderWidth) ~/ 2 : 0;
      text.add(Text(borderLine)
        ..color = borderColor
        ..position = Position(bx, y));
    }
  }

  void _renderGradientLine(String line, int startX, int row) {
    if (line.isEmpty) return;

    for (var i = 0; i < line.length; i++) {
      var char = line[i];
      if (char == ' ') continue;

      var gradientColor = _getGradientColor(i, line.length);
      text.add(Text(char)
        ..color = gradientColor.toAnsi()
        ..position = Position(startX + i, row));
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
      case BigTextFont.shadow:
        return _shadowFont;
    }
  }
}

class _FontData {
  final int height;
  final Map<String, List<String>> glyphs;

  _FontData(this.height, this.glyphs);
}

// ═══════════════════════════════════════════════════════════════════════════
// SHADOW FONT - FIGlet-style 3D (6 lines high)
// ═══════════════════════════════════════════════════════════════════════════

final _shadowFont = _FontData(6, {
  'A': [
    ' █████╗ ',
    '██╔══██╗',
    '███████║',
    '██╔══██║',
    '██║  ██║',
    '╚═╝  ╚═╝',
  ],
  'B': [
    '██████╗ ',
    '██╔══██╗',
    '██████╔╝',
    '██╔══██╗',
    '██████╔╝',
    '╚═════╝ ',
  ],
  'C': [
    ' ██████╗',
    '██╔════╝',
    '██║     ',
    '██║     ',
    '╚██████╗',
    ' ╚═════╝',
  ],
  'D': [
    '██████╗ ',
    '██╔══██╗',
    '██║  ██║',
    '██║  ██║',
    '██████╔╝',
    '╚═════╝ ',
  ],
  'E': [
    '███████╗',
    '██╔════╝',
    '█████╗  ',
    '██╔══╝  ',
    '███████╗',
    '╚══════╝',
  ],
  'F': [
    '███████╗',
    '██╔════╝',
    '█████╗  ',
    '██╔══╝  ',
    '██║     ',
    '╚═╝     ',
  ],
  'G': [
    ' ██████╗ ',
    '██╔════╝ ',
    '██║  ███╗',
    '██║   ██║',
    '╚██████╔╝',
    ' ╚═════╝ ',
  ],
  'H': [
    '██╗  ██╗',
    '██║  ██║',
    '███████║',
    '██╔══██║',
    '██║  ██║',
    '╚═╝  ╚═╝',
  ],
  'I': [
    '██╗',
    '██║',
    '██║',
    '██║',
    '██║',
    '╚═╝',
  ],
  'J': [
    '     ██╗',
    '     ██║',
    '     ██║',
    '██   ██║',
    '╚█████╔╝',
    ' ╚════╝ ',
  ],
  'K': [
    '██╗  ██╗',
    '██║ ██╔╝',
    '█████╔╝ ',
    '██╔═██╗ ',
    '██║  ██╗',
    '╚═╝  ╚═╝',
  ],
  'L': [
    '██╗     ',
    '██║     ',
    '██║     ',
    '██║     ',
    '███████╗',
    '╚══════╝',
  ],
  'M': [
    '███╗   ███╗',
    '████╗ ████║',
    '██╔████╔██║',
    '██║╚██╔╝██║',
    '██║ ╚═╝ ██║',
    '╚═╝     ╚═╝',
  ],
  'N': [
    '███╗   ██╗',
    '████╗  ██║',
    '██╔██╗ ██║',
    '██║╚██╗██║',
    '██║ ╚████║',
    '╚═╝  ╚═══╝',
  ],
  'O': [
    ' ██████╗ ',
    '██╔═══██╗',
    '██║   ██║',
    '██║   ██║',
    '╚██████╔╝',
    ' ╚═════╝ ',
  ],
  'P': [
    '██████╗ ',
    '██╔══██╗',
    '██████╔╝',
    '██╔═══╝ ',
    '██║     ',
    '╚═╝     ',
  ],
  'Q': [
    ' ██████╗ ',
    '██╔═══██╗',
    '██║   ██║',
    '██║▄▄ ██║',
    '╚██████╔╝',
    ' ╚══▀▀═╝ ',
  ],
  'R': [
    '██████╗ ',
    '██╔══██╗',
    '██████╔╝',
    '██╔══██╗',
    '██║  ██║',
    '╚═╝  ╚═╝',
  ],
  'S': [
    '███████╗',
    '██╔════╝',
    '███████╗',
    '╚════██║',
    '███████║',
    '╚══════╝',
  ],
  'T': [
    '████████╗',
    '╚══██╔══╝',
    '   ██║   ',
    '   ██║   ',
    '   ██║   ',
    '   ╚═╝   ',
  ],
  'U': [
    '██╗   ██╗',
    '██║   ██║',
    '██║   ██║',
    '██║   ██║',
    '╚██████╔╝',
    ' ╚═════╝ ',
  ],
  'V': [
    '██╗   ██╗',
    '██║   ██║',
    '██║   ██║',
    '╚██╗ ██╔╝',
    ' ╚████╔╝ ',
    '  ╚═══╝  ',
  ],
  'W': [
    '██╗    ██╗',
    '██║    ██║',
    '██║ █╗ ██║',
    '██║███╗██║',
    '╚███╔███╔╝',
    ' ╚══╝╚══╝ ',
  ],
  'X': [
    '██╗  ██╗',
    '╚██╗██╔╝',
    ' ╚███╔╝ ',
    ' ██╔██╗ ',
    '██╔╝ ██╗',
    '╚═╝  ╚═╝',
  ],
  'Y': [
    '██╗   ██╗',
    '╚██╗ ██╔╝',
    ' ╚████╔╝ ',
    '  ╚██╔╝  ',
    '   ██║   ',
    '   ╚═╝   ',
  ],
  'Z': [
    '███████╗',
    '╚══███╔╝',
    '  ███╔╝ ',
    ' ███╔╝  ',
    '███████╗',
    '╚══════╝',
  ],
  '0': [
    ' ██████╗ ',
    '██╔═████╗',
    '██║██╔██║',
    '████╔╝██║',
    '╚██████╔╝',
    ' ╚═════╝ ',
  ],
  '1': [
    ' ██╗',
    '███║',
    '╚██║',
    ' ██║',
    ' ██║',
    ' ╚═╝',
  ],
  '2': [
    '██████╗ ',
    '╚════██╗',
    ' █████╔╝',
    '██╔═══╝ ',
    '███████╗',
    '╚══════╝',
  ],
  '3': [
    '██████╗ ',
    '╚════██╗',
    ' █████╔╝',
    ' ╚═══██╗',
    '██████╔╝',
    '╚═════╝ ',
  ],
  '4': [
    '██╗  ██╗',
    '██║  ██║',
    '███████║',
    '╚════██║',
    '     ██║',
    '     ╚═╝',
  ],
  '5': [
    '███████╗',
    '██╔════╝',
    '███████╗',
    '╚════██║',
    '███████║',
    '╚══════╝',
  ],
  '6': [
    ' ██████╗',
    '██╔════╝',
    '███████╗',
    '██╔══██║',
    '╚█████╔╝',
    ' ╚════╝ ',
  ],
  '7': [
    '███████╗',
    '╚════██║',
    '    ██╔╝',
    '   ██╔╝ ',
    '   ██║  ',
    '   ╚═╝  ',
  ],
  '8': [
    ' █████╗ ',
    '██╔══██╗',
    '╚█████╔╝',
    '██╔══██╗',
    '╚█████╔╝',
    ' ╚════╝ ',
  ],
  '9': [
    ' █████╗ ',
    '██╔══██╗',
    '╚██████║',
    ' ╚═══██║',
    ' █████╔╝',
    ' ╚════╝ ',
  ],
  ' ': [
    '   ',
    '   ',
    '   ',
    '   ',
    '   ',
    '   ',
  ],
  '!': [
    '██╗',
    '██║',
    '██║',
    '╚═╝',
    '██╗',
    '╚═╝',
  ],
  '.': [
    '   ',
    '   ',
    '   ',
    '   ',
    '██╗',
    '╚═╝',
  ],
  '-': [
    '      ',
    '      ',
    '█████╗',
    '╚════╝',
    '      ',
    '      ',
  ],
  ':': [
    '   ',
    '██╗',
    '╚═╝',
    '██╗',
    '╚═╝',
    '   ',
  ],
});

// ═══════════════════════════════════════════════════════════════════════════
// BLOCK FONT (5 lines high)
// ═══════════════════════════════════════════════════════════════════════════

final _blockFont = _FontData(5, {
  'A': ['█████', '█   █', '█████', '█   █', '█   █'],
  'B': ['████ ', '█   █', '████ ', '█   █', '████ '],
  'C': ['█████', '█    ', '█    ', '█    ', '█████'],
  'D': ['████ ', '█   █', '█   █', '█   █', '████ '],
  'E': ['█████', '█    ', '████ ', '█    ', '█████'],
  'F': ['█████', '█    ', '████ ', '█    ', '█    '],
  'G': ['█████', '█    ', '█  ██', '█   █', '█████'],
  'H': ['█   █', '█   █', '█████', '█   █', '█   █'],
  'I': ['█████', '  █  ', '  █  ', '  █  ', '█████'],
  'J': ['█████', '    █', '    █', '█   █', '█████'],
  'K': ['█   █', '█  █ ', '███  ', '█  █ ', '█   █'],
  'L': ['█    ', '█    ', '█    ', '█    ', '█████'],
  'M': ['█   █', '██ ██', '█ █ █', '█   █', '█   █'],
  'N': ['█   █', '██  █', '█ █ █', '█  ██', '█   █'],
  'O': ['█████', '█   █', '█   █', '█   █', '█████'],
  'P': ['█████', '█   █', '█████', '█    ', '█    '],
  'Q': ['█████', '█   █', '█   █', '█  █ ', '███ █'],
  'R': ['█████', '█   █', '█████', '█  █ ', '█   █'],
  'S': ['█████', '█    ', '█████', '    █', '█████'],
  'T': ['█████', '  █  ', '  █  ', '  █  ', '  █  '],
  'U': ['█   █', '█   █', '█   █', '█   █', '█████'],
  'V': ['█   █', '█   █', '█   █', ' █ █ ', '  █  '],
  'W': ['█   █', '█   █', '█ █ █', '██ ██', '█   █'],
  'X': ['█   █', ' █ █ ', '  █  ', ' █ █ ', '█   █'],
  'Y': ['█   █', ' █ █ ', '  █  ', '  █  ', '  █  '],
  'Z': ['█████', '   █ ', '  █  ', ' █   ', '█████'],
  '0': ['█████', '█   █', '█   █', '█   █', '█████'],
  '1': ['  █  ', ' ██  ', '  █  ', '  █  ', '█████'],
  '2': ['█████', '    █', '█████', '█    ', '█████'],
  '3': ['█████', '    █', '█████', '    █', '█████'],
  '4': ['█   █', '█   █', '█████', '    █', '    █'],
  '5': ['█████', '█    ', '█████', '    █', '█████'],
  '6': ['█████', '█    ', '█████', '█   █', '█████'],
  '7': ['█████', '    █', '   █ ', '  █  ', '  █  '],
  '8': ['█████', '█   █', '█████', '█   █', '█████'],
  '9': ['█████', '█   █', '█████', '    █', '█████'],
  ' ': ['     ', '     ', '     ', '     ', '     '],
  '!': ['  █  ', '  █  ', '  █  ', '     ', '  █  '],
  '.': ['     ', '     ', '     ', '     ', '  █  '],
  '-': ['     ', '     ', '█████', '     ', '     '],
});

// ═══════════════════════════════════════════════════════════════════════════
// SLIM FONT (5 lines high)
// ═══════════════════════════════════════════════════════════════════════════

final _slimFont = _FontData(5, {
  'A': ['╔═╗', '╠═╣', '║ ║', '║ ║', '╩ ╩'],
  'B': ['╔═╗', '╠═╣', '╠═╣', '║ ║', '╚═╝'],
  'C': ['╔══', '║  ', '║  ', '║  ', '╚══'],
  'D': ['╔═╗', '║ ║', '║ ║', '║ ║', '╚═╝'],
  'E': ['╔══', '╠═ ', '║  ', '║  ', '╚══'],
  'F': ['╔══', '╠═ ', '║  ', '║  ', '╩  '],
  'G': ['╔══', '║  ', '║ ╗', '║ ║', '╚═╝'],
  'H': ['║ ║', '╠═╣', '║ ║', '║ ║', '╩ ╩'],
  'I': ['═╦═', ' ║ ', ' ║ ', ' ║ ', '═╩═'],
  'J': ['══╗', '  ║', '  ║', '╔═╣', '╚═╝'],
  'K': ['║ ╱', '╠╣ ', '║ ╲', '║ ║', '╩ ╩'],
  'L': ['║  ', '║  ', '║  ', '║  ', '╚══'],
  'M': ['╔╗╔╗', '║╚╝║', '║  ║', '║  ║', '╩  ╩'],
  'N': ['╔╗ ║', '║╚╗║', '║ ╚╣', '║  ║', '╩  ╩'],
  'O': ['╔═╗', '║ ║', '║ ║', '║ ║', '╚═╝'],
  'P': ['╔═╗', '╠═╝', '║  ', '║  ', '╩  '],
  'Q': ['╔═╗', '║ ║', '║ ║', '║╚╗', '╚═╩'],
  'R': ['╔═╗', '╠═╣', '║╚╗', '║ ║', '╩ ╩'],
  'S': ['╔══', '╚═╗', '  ║', '╔═╝', '╚══'],
  'T': ['═╦═', ' ║ ', ' ║ ', ' ║ ', ' ╩ '],
  'U': ['║ ║', '║ ║', '║ ║', '║ ║', '╚═╝'],
  'V': ['║ ║', '║ ║', '║ ║', '╚╦╝', ' ╩ '],
  'W': ['║  ║', '║  ║', '║╔╗║', '╠╝╚╣', '╩  ╩'],
  'X': ['╲ ╱', ' ╳ ', '╱ ╲', '║ ║', '╩ ╩'],
  'Y': ['╲ ╱', ' ║ ', ' ║ ', ' ║ ', ' ╩ '],
  'Z': ['══╗', ' ╔╝', '╔╝ ', '║  ', '╚══'],
  ' ': ['   ', '   ', '   ', '   ', '   '],
});

// ═══════════════════════════════════════════════════════════════════════════
// CHUNKY FONT (4 lines high)
// ═══════════════════════════════════════════════════════════════════════════

final _chunkyFont = _FontData(4, {
  'A': ['▄▀▀▄', '█▄▄█', '█  █', '▀  ▀'],
  'B': ['█▀▀▄', '█▄▄▀', '█  █', '▀▀▀ '],
  'C': ['▄▀▀▀', '█   ', '█   ', '▀▀▀▀'],
  'D': ['█▀▀▄', '█  █', '█  █', '▀▀▀ '],
  'E': ['█▀▀▀', '█▄▄ ', '█   ', '▀▀▀▀'],
  'F': ['█▀▀▀', '█▄▄ ', '█   ', '▀   '],
  'G': ['▄▀▀▀', '█ ▀█', '█  █', '▀▀▀▀'],
  'H': ['█  █', '█▄▄█', '█  █', '▀  ▀'],
  'I': ['▀█▀', ' █ ', ' █ ', '▀▀▀'],
  'J': ['  ▀█', '   █', '█  █', '▀▀▀ '],
  'K': ['█ ▄▀', '██  ', '█ ▀▄', '▀  ▀'],
  'L': ['█   ', '█   ', '█   ', '▀▀▀▀'],
  'M': ['█▄▄█', '█▀▀█', '█  █', '▀  ▀'],
  'N': ['█▄ █', '█ ▀█', '█  █', '▀  ▀'],
  'O': ['▄▀▀▄', '█  █', '█  █', '▀▀▀▀'],
  'P': ['█▀▀▄', '█▄▄▀', '█   ', '▀   '],
  'Q': ['▄▀▀▄', '█  █', '█ ▀█', '▀▀▀▀'],
  'R': ['█▀▀▄', '█▄▄▀', '█ ▀▄', '▀  ▀'],
  'S': ['▄▀▀▀', '▀▀▀▄', '▄  █', '▀▀▀ '],
  'T': ['▀█▀', ' █ ', ' █ ', ' ▀ '],
  'U': ['█  █', '█  █', '█  █', '▀▀▀▀'],
  'V': ['█  █', '█  █', '▀▄▄▀', ' ▀▀ '],
  'W': ['█  █', '█  █', '█▄▄█', '▀▀▀▀'],
  'X': ['▀▄▄▀', ' ▀▀ ', '▄▀▀▄', '▀  ▀'],
  'Y': ['█  █', '▀▄▄▀', ' █▀ ', ' ▀  '],
  'Z': ['▀▀▀█', ' ▄▀ ', '▄▀  ', '▀▀▀▀'],
  ' ': ['    ', '    ', '    ', '    '],
  '!': [' █ ', ' █ ', '   ', ' ▀ '],
});
