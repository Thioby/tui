part of tui;

/// A Canvas provides constrained read/write access to the [Screen].
class Canvas with Sizable, Positionable {
  final Screen _scr;

  Canvas(Size size, Position offset, this._scr) {
    this.size = size;
    this.position = offset;
  }

  Canvas canvas(Size size, Position offset) {
    var combinedOffset = Position(offset.x + x, offset.y + y);
    return Canvas(size, combinedOffset, _scr);
  }

  bool occluded(int x, int y) => _scr.occluded(position.x + x, position.y + y);

  void write(int x, int y, String char) => _scr.write(position.x + x, position.y + y, char);

  String stringAt(int x, int y) => _scr.stringAt(position.x + x, position.y + y);
}