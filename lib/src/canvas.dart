part of tui;

/// A Canvas provides constrained read/write access to the [Screen].
///
/// When a container view renders its children, it creates a new [Canvas]
/// offset/sized for that child.
class Canvas with Sizable, Positionable {
  final Screen _screen;

  Canvas(Size size, Position offset, this._screen) {
    this.size = size;
    this.position = offset;
  }

  /// Create a new canvas offset from this one.
  Canvas canvas(Size size, Position offset) {
    var combinedOffset = Position(offset.x + x, offset.y + y);
    return Canvas(size, combinedOffset, _screen);
  }

  /// Returns true if there is already something written at this point.
  bool occluded(int x, int y) => _screen.occluded(position.x + x, position.y + y);

  /// Writes to a point on the canvas.
  void write(int x, int y, String char) => _screen.write(position.x + x, position.y + y, char);

  /// Returns value at this point.
  String stringAt(int x, int y) => _screen.stringAt(position.x + x, position.y + y);
}
