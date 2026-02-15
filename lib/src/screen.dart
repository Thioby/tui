part of tui;

/// Screen is the main buffer shared by all Canvas write operations.
///
/// Uses double-buffering with line-level diffing: only lines that
/// actually changed between frames are written to the output.
class Screen with Sizable {
  /// Current frame buffer (front).
  List<List<String?>> _buf = [];

  /// Previous frame buffer (back) — used for diffing.
  List<List<String?>> _prev = [];

  /// Tracks which lines were written to this frame.
  List<bool> _dirtyLines = [];

  /// Whether any cell was written since last [swapBuffers].
  bool _hasWrites = false;

  Screen(Size size) {
    this.size = size;
    _allocate();
  }

  void resize(Size size) {
    this.size = size;
    _allocate();
  }

  /// Allocates fresh front and back buffers.
  void _allocate() {
    _buf = List.generate(height, (_) => List.filled(width, null));
    _prev = List.generate(height, (_) => List.filled(width, null));
    _dirtyLines = List.filled(height, false);
    _hasWrites = false;
  }

  /// Clears the front buffer for a new frame. O(height), not O(w*h).
  void clear() {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        _buf[y][x] = null;
      }
      _dirtyLines[y] = false;
    }
    _hasWrites = false;
  }

  /// True if any cell was written since last [clear].
  bool get hasWrites => _hasWrites;

  Canvas canvas([Size? size, Position? offset]) {
    return Canvas(
      size ?? Size.from(this.size),
      offset ?? Position(0, 0),
      this,
    );
  }

  // ── Rendering helpers ──────────────────────────────────────────

  /// Builds a single line string from the buffer row.
  String _renderLine(int y) {
    final row = _buf[y];
    final sb = StringBuffer();
    for (var x = 0; x < width; x++) {
      sb.write(row[x] ?? ' ');
    }
    return sb.toString();
  }

  /// Full frame as a single string (fallback, used on first frame).
  @override
  String toString() {
    final sb = StringBuffer();
    for (var y = 0; y < height; y++) {
      if (y > 0) sb.write('\n');
      sb.write(_renderLine(y));
    }
    return sb.toString();
  }

  /// Returns ANSI escape sequences to update only changed lines.
  ///
  /// Compares [_buf] against [_prev] row by row. Unchanged rows are
  /// skipped entirely. Returns empty string when nothing changed.
  String diff() {
    final sb = StringBuffer();
    for (var y = 0; y < height; y++) {
      if (!_lineChanged(y)) continue;
      // ANSI: move cursor to row y+1, column 1
      sb.write('\x1B[${y + 1};1H');
      sb.write(_renderLine(y));
    }
    return sb.toString();
  }

  /// Checks whether line [y] differs between front and back buffers.
  bool _lineChanged(int y) {
    final front = _buf[y];
    final back = _prev[y];
    for (var x = 0; x < width; x++) {
      if (front[x] != back[x]) return true;
    }
    return false;
  }

  /// Copies front buffer into back buffer. Call after writing to stdout.
  void swapBuffers() {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        _prev[y][x] = _buf[y][x];
      }
    }
  }

  // ── Cell access (unchanged API) ────────────────────────────────

  bool occluded(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return true;
    return _buf[y][x] != null;
  }

  void write(int x, int y, String char) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    _buf[y][x] = char;
    _dirtyLines[y] = true;
    _hasWrites = true;
  }

  String stringAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return '';
    return _buf[y][x] ?? '';
  }
}
