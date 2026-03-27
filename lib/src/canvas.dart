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

  bool occluded(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return true;
    var absX = position.x + x;
    var absY = position.y + y;
    if (absX >= _clipRight || absY >= _clipBottom) return true;
    return _scr.occluded(absX, absY);
  }

  void write(int x, int y, String char) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    var absX = position.x + x;
    var absY = position.y + y;
    if (absX >= _clipRight || absY >= _clipBottom) return;
    _scr.write(absX, absY, char);
  }

  String stringAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return '';
    var absX = position.x + x;
    var absY = position.y + y;
    if (absX >= _clipRight || absY >= _clipBottom) return '';
    return _scr.stringAt(absX, absY);
  }
}
