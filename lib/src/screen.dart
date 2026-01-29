part of tui;

/// Screen is the main buffer shared by all Canvas write operations.
///
/// Once all [View.render] methods have been called, the Screen writes
/// its buffer to stdout, optimizing by only writing changed lines.
class Screen with Sizable {
  List<List<String?>> _buf = [];

  Screen(Size size) {
    this.size = size;
    clear();
  }

  void resize(Size size) {
    this.size = size;
    clear();
  }

  void clear() {
    _buf = List.generate(height, (_) => List.filled(width, null));
  }

  Canvas canvas([Size? size, Position? offset]) {
    return Canvas(
      size ?? Size.from(this.size),
      offset ?? Position(0, 0),
      this,
    );
  }

  @override
  String toString() {
    return _buf.map((line) => line.map((char) => char ?? " ").join()).join('\n');
  }

  bool occluded(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return true;
    return _buf[y][x] != null;
  }

  void write(int x, int y, String char) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    _buf[y][x] = char;
  }

  String stringAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return '';
    return _buf[y][x] ?? '';
  }
}