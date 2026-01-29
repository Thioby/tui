part of tui;

abstract class ANSI {
  static const String ESC = "\x1b[";

  static const String CURSOR_HOME = "${ESC}H";
  static const String CURSOR_HOME_COL = "\r";

  static const String HIDE_CURSOR = "${ESC}?25l";
  static const String SHOW_CURSOR = "${ESC}?25h";

  static const String MOUSE_TRACKING_ON = "${ESC}?1000h${ESC}?1002h";
  static const String MOUSE_TRACKING_OFF = "${ESC}?1002l${ESC}?1000l";

  static const String ERASE_SCREEN = "${ESC}2J";
  static const String ERASE_TO_END_OF_LINE = "${ESC}K";

  static String setCursorPosition(int x, int y) {
    return ESC + "${y + 1};${x + 1}H";
  }

  static String moveCursorUp(int x) {
    if (x < 1) return "";
    return ESC + "${x}A";
  }

  static String moveCursorDown(int x) {
    if (x < 1) return "";
    return ESC + "${x}B";
  }

  static String moveCursorRight(int x) {
    if (x < 1) return "";
    return ESC + "${x}C";
  }

  static String moveCursorLeft(int x) {
    if (x < 1) return "";
    return ESC + "${x}D";
  }
}

abstract class KeyCode {
  static const String UP = "${ANSI.ESC}A";
  static const String DOWN = "${ANSI.ESC}B";
  static const String RIGHT = "${ANSI.ESC}C";
  static const String LEFT = "${ANSI.ESC}D";

  static const String HOME = "${ANSI.ESC}H";
  static const String END = "${ANSI.ESC}F";

  static const String TAB = "\t";
  static const String SHIFT_TAB = "${ANSI.ESC}Z";
  static const String ENTER = "\n";
  static const String ESCAPE = "\x1b";
  static const String BACKSPACE = "\x7f";

  static const String F1 = "${ANSI.ESC}M";
  static const String F2 = "${ANSI.ESC}N";
  static const String F3 = "${ANSI.ESC}O";
  static const String F4 = "${ANSI.ESC}P";
  static const String F5 = "${ANSI.ESC}Q";
  static const String F6 = "${ANSI.ESC}R";
  static const String F7 = "${ANSI.ESC}S";
  static const String F8 = "${ANSI.ESC}T";
  static const String F9 = "${ANSI.ESC}U";
  static const String F10 = "${ANSI.ESC}V";
  static const String F11 = "${ANSI.ESC}W";
  static const String F12 = "${ANSI.ESC}X";

  static const String INS = "${ANSI.ESC}2~";
  static const String DEL = "${ANSI.ESC}3~";
  static const String PAGE_UP = "${ANSI.ESC}5~";
  static const String PAGE_DOWN = "${ANSI.ESC}6~";

  static const String SPACE = " ";
}

/// ANSI color codes for terminal output.
abstract class Colors {
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  static const String italic = '\x1B[3m';
  static const String underline = '\x1B[4m';
  static const String blink = '\x1B[5m';
  static const String inverse = '\x1B[7m';

  // Foreground colors
  static const String black = '\x1B[30m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';

  // Bright foreground colors
  static const String brightBlack = '\x1B[90m';
  static const String brightRed = '\x1B[91m';
  static const String brightGreen = '\x1B[92m';
  static const String brightYellow = '\x1B[93m';
  static const String brightBlue = '\x1B[94m';
  static const String brightMagenta = '\x1B[95m';
  static const String brightCyan = '\x1B[96m';
  static const String brightWhite = '\x1B[97m';

  // Background colors
  static const String bgBlack = '\x1B[40m';
  static const String bgRed = '\x1B[41m';
  static const String bgGreen = '\x1B[42m';
  static const String bgYellow = '\x1B[43m';
  static const String bgBlue = '\x1B[44m';
  static const String bgMagenta = '\x1B[45m';
  static const String bgCyan = '\x1B[46m';
  static const String bgWhite = '\x1B[47m';

  /// Create 256-color foreground: `\x1B[38;5;{n}m`
  static String fg256(int n) => '\x1B[38;5;${n}m';

  /// Create 256-color background: `\x1B[48;5;{n}m`
  static String bg256(int n) => '\x1B[48;5;${n}m';

  /// Create true color (24-bit) foreground: `\x1B[38;2;r;g;b m`
  static String fgRgb(int r, int g, int b) => '\x1B[38;2;$r;$g;${b}m';

  /// Create true color (24-bit) background: `\x1B[48;2;r;g;b m`
  static String bgRgb(int r, int g, int b) => '\x1B[48;2;$r;$g;${b}m';
}

/// Box drawing characters for borders and frames.
abstract class BoxChars {
  // Light box (─│┌┐└┘├┤┬┴┼)
  static const String lightH = '─';
  static const String lightV = '│';
  static const String lightTL = '┌';
  static const String lightTR = '┐';
  static const String lightBL = '└';
  static const String lightBR = '┘';
  static const String lightTeeR = '├';
  static const String lightTeeL = '┤';
  static const String lightTeeD = '┬';
  static const String lightTeeU = '┴';
  static const String lightCross = '┼';

  // Heavy box (━┃┏┓┗┛┣┫┳┻╋)
  static const String heavyH = '━';
  static const String heavyV = '┃';
  static const String heavyTL = '┏';
  static const String heavyTR = '┓';
  static const String heavyBL = '┗';
  static const String heavyBR = '┛';
  static const String heavyTeeR = '┣';
  static const String heavyTeeL = '┫';
  static const String heavyTeeD = '┳';
  static const String heavyTeeU = '┻';
  static const String heavyCross = '╋';

  // Double box (═║╔╗╚╝╠╣╦╩╬)
  static const String doubleH = '═';
  static const String doubleV = '║';
  static const String doubleTL = '╔';
  static const String doubleTR = '╗';
  static const String doubleBL = '╚';
  static const String doubleBR = '╝';
  static const String doubleTeeR = '╠';
  static const String doubleTeeL = '╣';
  static const String doubleTeeD = '╦';
  static const String doubleTeeU = '╩';
  static const String doubleCross = '╬';

  // Rounded corners (╭╮╰╯) - uses light lines
  static const String roundedTL = '╭';
  static const String roundedTR = '╮';
  static const String roundedBL = '╰';
  static const String roundedBR = '╯';

  // ASCII fallback
  static const String asciiH = '-';
  static const String asciiV = '|';
  static const String asciiCorner = '+';

  // Block elements
  static const String fullBlock = '█';
  static const String lightShade = '░';
  static const String mediumShade = '▒';
  static const String darkShade = '▓';
  static const String upperHalf = '▀';
  static const String lowerHalf = '▄';
  static const String leftHalf = '▌';
  static const String rightHalf = '▐';

  // Progress bar characters
  static const String progressFull = '█';
  static const String progressEmpty = '░';
  static const String progressHalf = '▌';
}
