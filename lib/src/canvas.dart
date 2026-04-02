part of tui;

/// A Canvas provides constrained read/write access to the [Screen].
///
/// All writes are clipped to the canvas bounds AND the inherited
/// clip region from the parent canvas.
class Canvas with Sizable, Positionable {
  final Screen _scr;
  final int _clipRight;
  final int _clipBottom;

  Canvas(Size size, Position offset, this._scr, [int? clipRight, int? clipBottom])
      : _clipRight = clipRight ?? (offset.x + size.width),
        _clipBottom = clipBottom ?? (offset.y + size.height) {
    this.size = size;
    this.position = offset;
  }

  Canvas canvas(Size size, Position offset) {
    var combinedOffset = Position(offset.x + x, offset.y + y);
    return Canvas(
      size,
      combinedOffset,
      _scr,
      min(combinedOffset.x + size.width, _clipRight),
      min(combinedOffset.y + size.height, _clipBottom),
    );
  }

  /// Returns absolute screen coordinates, or null if clipped.
  (int, int)? _abs(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return null;
    var absX = position.x + x;
    var absY = position.y + y;
    if (absX >= _clipRight || absY >= _clipBottom) return null;
    return (absX, absY);
  }

  bool occluded(int x, int y) {
    var pt = _abs(x, y);
    return pt == null || _scr.occluded(pt.$1, pt.$2);
  }

  void write(int x, int y, String char) {
    var pt = _abs(x, y);
    if (pt != null) _scr.write(pt.$1, pt.$2, char);
  }

  String stringAt(int x, int y) {
    var pt = _abs(x, y);
    return pt != null ? _scr.stringAt(pt.$1, pt.$2) : '';
  }
}
