part of tui;

enum BigTextFont {
  block,
  slim,
  chunky,
  shadow,
}

class RGB {
  final int r, g, b;
  const RGB(this.r, this.g, this.b);

  RGB lerp(RGB other, double t) {
    return RGB(
      (r + (other.r - r) * t).round(),
      (g + (other.g - g) * t).round(),
      (b + (other.b - b) * t).round(),
    );
  }

  String toAnsi() => '38;2;$r;$g;$b';
}

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
class BigText extends View {
  String _txt;

  String get content => _txt;
  set content(String value) {
    _txt = value.toUpperCase();
    update();
  }

  BigTextFont font;

  String color = '0';

  List<RGB>? gradient;

  int letterSpacing = 1;

  String? subtitle;

  String subtitleColor = '8';

  bool showBorder = false;

  String borderColor = '36';

  bool centered = true;

  BigText(
    this._txt, {
    this.font = BigTextFont.block,
    this.gradient,
    this.subtitle,
    this.showBorder = false,
    this.centered = true,
  }) {
    _txt = _txt.toUpperCase();
  }

  static List<String> generateLines(String text,
      {BigTextFont font = BigTextFont.shadow, int letterSpacing = 1}) {
    text = text.toUpperCase();
    var fontData = _fontData(font);
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

  static _FontData _fontData(BigTextFont font) {
    switch (font) {
      case BigTextFont.block:
        return _fontBlock;
      case BigTextFont.slim:
        return _fontSlim;
      case BigTextFont.chunky:
        return _fontChunky;
      case BigTextFont.shadow:
        return _fontShadow;
    }
  }

  @override
  void update() {
    text = [];
    if (width < 1 || height < 1) return;

    var fontData = _fontData(font);
    var charHeight = fontData.height;
    var lines = List.generate(charHeight, (_) => StringBuffer());

    for (var i = 0; i < _txt.length; i++) {
      var char = _txt[i];
      var glyph = fontData.glyphs[char] ?? fontData.glyphs[' ']!;

      for (var row = 0; row < charHeight; row++) {
        if (row < glyph.length) {
          lines[row].write(glyph[row]);
        }
        if (i < _txt.length - 1) {
          lines[row].write(' ' * letterSpacing);
        }
      }
    }

    var textWidth = lines.isNotEmpty ? lines[0].length : 0;
    var totalHeight = charHeight;
    if (subtitle != null) totalHeight += 2;
    if (showBorder) totalHeight += 2;

    var y = 0;
    var contentWidth = showBorder ? width - 2 : width;
    var xOffset = showBorder ? 1 : 0;

    if (showBorder) {
      var borderWidth = max(textWidth + 4, (subtitle?.length ?? 0) + 6);
      if (borderWidth > width) borderWidth = width;
      var borderLine =
          '${BoxChars.doubleTL}${BoxChars.doubleH * (borderWidth - 2)}${BoxChars.doubleTR}';
      var bx = centered ? (width - borderWidth) ~/ 2 : 0;
      text.add(Text(borderLine)
        ..color = borderColor
        ..position = Position(bx, y++));
    }

    for (var row = 0;
        row < charHeight && y < height - (showBorder ? 1 : 0);
        row++) {
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

    if (subtitle != null && y < height - (showBorder ? 1 : 0)) {
      y++;

      if (showBorder) {
        var borderWidth = max(textWidth + 4, subtitle!.length + 6);
        if (borderWidth > width) borderWidth = width;
        var bx = centered ? (width - borderWidth) ~/ 2 : 0;

        var subBoxWidth = subtitle!.length + 4;
        var subX = centered ? (width - subBoxWidth) ~/ 2 : bx + 2;

        text.add(Text(BoxChars.doubleV)
          ..color = borderColor
          ..position = Position(bx, y));
        text.add(Text(
            '${BoxChars.lightTL}${BoxChars.lightH * (subBoxWidth - 2)}${BoxChars.lightTR}')
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
        text.add(Text(
            '${BoxChars.lightBL}${BoxChars.lightH * (subBoxWidth - 2)}${BoxChars.lightBR}')
          ..color = subtitleColor
          ..position = Position(subX, y));
        text.add(Text(BoxChars.doubleV)
          ..color = borderColor
          ..position = Position(bx + borderWidth - 1, y));
        y++;
      } else {
        var subX = centered ? (width - subtitle!.length) ~/ 2 : 0;
        text.add(Text(subtitle!)
          ..color = subtitleColor
          ..position = Position(subX, y));
        y++;
      }
    }

    if (showBorder && y < height) {
      var borderWidth = max(textWidth + 4, (subtitle?.length ?? 0) + 6);
      if (borderWidth > width) borderWidth = width;
      var borderLine =
          '${BoxChars.doubleBL}${BoxChars.doubleH * (borderWidth - 2)}${BoxChars.doubleBR}';
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
    return interpolateGradient(gradient!, position, totalWidth);
  }

  /// Interpolate a color from [colors] at [position] of [totalWidth].
  static RGB interpolateGradient(
    List<RGB> colors,
    int position,
    int totalWidth,
  ) {
    if (colors.isEmpty) return RGB(255, 255, 255);
    if (colors.length == 1) return colors.first;

    var t = totalWidth > 1 ? position / (totalWidth - 1) : 0.0;
    var scaledT = t * (colors.length - 1);
    var index = scaledT.floor();
    var localT = scaledT - index;

    if (index >= colors.length - 1) return colors.last;
    return colors[index].lerp(colors[index + 1], localT);
  }
}

class _FontData {
  final int height;
  final Map<String, List<String>> glyphs;

  _FontData(this.height, this.glyphs);
}

final _fontShadow = _FontData(6, {
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

final _fontBlock = _FontData(5, {
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

final _fontSlim = _FontData(5, {
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

final _fontChunky = _FontData(4, {
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
