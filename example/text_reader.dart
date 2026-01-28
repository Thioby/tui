import "package:tui/tui.dart";
import "dart:io";

class Scrollable extends View {

  Scrollable(List<String> text) {
    this.text = text.map((l) => Text(l)).toList();
  }

}

class FileReader extends Window {

  late Scrollable scrollable;

  FileReader() {
    scrollable = Scrollable(["No file loaded."]);
    children = [scrollable];
    File('file_browser.dart').readAsLines().then((text) {
      int i = 1;
      scrollable.text = text.map((l) => Text(l)..position = Position(0, i++)).toList().sublist(0, 12);
    });
  }

  @override
  void onKey(String key) {
    switch (key) {
      case KeyCode.UP:
        break;
      case KeyCode.LEFT:
        break;
      case KeyCode.DOWN:
        break;
      case KeyCode.RIGHT:
        break;
      case "q":
        stop();
    }
  }
}

void main() {
  FileReader().start();
}