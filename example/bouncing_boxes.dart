import "package:tui/tui.dart";


class BouncingBoxes extends Window {

  late Box box1, box2, box3;

  BouncingBoxes() {
    box1 = Box("1", "1")
            ..size = Size(18, 8)
            ..position = Position(0, 0);
    box2 = Box("2", "2")
            ..size = Size(18, 8)
            ..position = Position(8, 2);
    box3 = Box("3", "31")
            ..size = Size(18, 8)
            ..position = Position(4, 4);

    children.addAll([box1, box2, box3]);

    box1.children.add(CenteredText("box 1"));

  }

  @override
  void onKey(String key) {
    switch (key) {
      case KeyCode.UP:
        box1.position = Position(box1.x, box1.y - 1);
        break;
      case KeyCode.LEFT:
        box1.position = Position(box1.x - 1, box1.y);
        break;
      case KeyCode.DOWN:
        box1.position = Position(box1.x, box1.y + 1);
        break;
      case KeyCode.RIGHT:
        box1.position = Position(box1.x + 1, box1.y);
        break;
      case "q":
        stop();
    }
  }
}

void main() {
  BouncingBoxes().start();
}