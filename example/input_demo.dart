import "package:tui/tui.dart";
import "dart:async";

class InputDemo extends Window {
  late Input nameInput;
  late Input emailInput;
  late Input passwordInput;
  String? submittedName;
  String? submittedEmail;

  InputDemo() {
    nameInput = Input(placeholder: 'Enter your name...')
      ..prompt = 'Name: '
      ..promptColor = '36'
      ..onSubmit = (value) => submittedName = value;

    emailInput = Input(placeholder: 'user@example.com')
      ..prompt = 'Email: '
      ..promptColor = '33'
      ..onSubmit = (value) => submittedEmail = value;

    passwordInput = Input(placeholder: 'Enter password...', password: true)
      ..prompt = 'Password: '
      ..promptColor = '35'
      ..maxLength = 20;

    var frame = Frame(title: 'Input Demo', color: '36')
      ..children = [
        SplitView(horizontal: false, ratios: [1, 1, 1, 2])
          ..children = [
            nameInput,
            emailInput,
            passwordInput,
            ResultPanel(this),
          ],
      ];

    children = [frame];
  }

  @override
  bool onKey(String key) {
    if (key == 'q' || key == KeyCode.ESCAPE) {
      stop();
      return true;
    }
    return super.onKey(key);
  }
}

class ResultPanel extends View {
  final InputDemo demo;

  ResultPanel(this.demo);

  @override
  void update() {
    text = [];
    if (width < 2 || height < 1) return;

    var y = 0;
    text.add(Text(BoxChars.lightH * width)
      ..color = '8'
      ..position = Position(0, y++));

    text.add(Text('Results:')
      ..color = '1'
      ..position = Position(0, y++));

    if (demo.submittedName != null) {
      text.add(Text('  Name: ${demo.submittedName}')
        ..color = '2'
        ..position = Position(0, y++));
    }

    if (demo.submittedEmail != null) {
      text.add(Text('  Email: ${demo.submittedEmail}')
        ..color = '2'
        ..position = Position(0, y++));
    }

    y = height - 1;
    text.add(Text('TAB=next field, ENTER=submit, q=quit')
      ..color = '8'
      ..position = Position(0, y));
  }
}

void main() {
  print("Input Widget Demo");
  print(BoxChars.lightH * 37);
  print("TAB         = next field");
  print("SHIFT+TAB   = previous field");
  print("ENTER       = submit current field");
  print("q/ESC       = quit");
  print(BoxChars.lightH * 37);
  print("Starting in 1 second...");
  Future.delayed(Duration(seconds: 1), () {
    InputDemo().start();
  });
}
