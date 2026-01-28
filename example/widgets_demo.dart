import "package:tui/tui.dart";
import "dart:async";

class WidgetsDemo extends Window {
  late Select<String> demoSelect;
  late Frame mainFrame;
  View? currentDemo;

  final demos = [
    'Input - single line text',
    'TextArea - multi-line text',
    'Select - list selection',
    'Confirm - yes/no dialog',
    'Spinner - loading indicator',
    'Table - tabular data',
  ];

  WidgetsDemo() {
    demoSelect = Select<String>(
      options: demos,
      header: 'Choose a demo:',
      onSelect: _showDemo,
    );

    mainFrame = Frame(title: 'TUI Widgets Demo', color: '36')
      ..children = [demoSelect];

    children = [mainFrame];
  }

  void _showDemo(String demo) {
    switch (demo) {
      case 'Input - single line text':
        _showInputDemo();
      case 'TextArea - multi-line text':
        _showTextAreaDemo();
      case 'Select - list selection':
        _showSelectDemo();
      case 'Confirm - yes/no dialog':
        _showConfirmDemo();
      case 'Spinner - loading indicator':
        _showSpinnerDemo();
      case 'Table - tabular data':
        _showTableDemo();
    }
  }

  void _showInputDemo() {
    var input = Input(placeholder: 'Type something...')
      ..prompt = 'Input: '
      ..onSubmit = (value) {
        _backToMenu('You entered: $value');
      };

    var frame = Frame(title: 'Input Demo (ENTER to submit, ESC to back)', color: '33')
      ..children = [input];

    mainFrame.children = [frame];
    focusFirst();
  }

  void _showTextAreaDemo() {
    var textarea = TextArea(placeholder: 'Type multiple lines...')
      ..showLineNumbers = true
      ..onSubmit = (value) {
        _backToMenu('Lines: ${value.split('\n').length}');
      };

    var frame = Frame(title: 'TextArea Demo (Ctrl+D to submit, ESC to back)', color: '33')
      ..children = [textarea];

    mainFrame.children = [frame];
    focusFirst();
  }

  void _showSelectDemo() {
    var select = Select<String>(
      options: ['Apple', 'Banana', 'Cherry', 'Date', 'Elderberry', 'Fig', 'Grape'],
      header: 'Pick a fruit:',
      multiSelect: true,
      onSelectMultiple: (values) {
        _backToMenu('Selected: ${values.join(', ')}');
      },
    );

    var frame = Frame(title: 'Select Demo (SPACE to toggle, ENTER to confirm)', color: '33')
      ..children = [select];

    mainFrame.children = [frame];
    focusFirst();
  }

  void _showConfirmDemo() {
    var confirm = Confirm(
      message: 'Do you like this demo?',
      onConfirm: (result) {
        _backToMenu(result ? 'Thanks!' : 'Sorry to hear that!');
      },
    );

    var frame = Frame(title: 'Confirm Demo (LEFT/RIGHT to choose, ENTER to confirm)', color: '33')
      ..children = [confirm];

    mainFrame.children = [frame];
    focusFirst();
  }

  void _showSpinnerDemo() {
    var spinner = Spinner(label: 'Processing...', style: SpinnerStyle.dots)
      ..start();

    var spinnerFrame = Frame(title: 'Spinner Demo (wait 3 seconds or ESC to back)', color: '33')
      ..children = [
        SplitView(horizontal: false, ratios: [1, 2])
          ..children = [
            spinner,
            _SpinnerShowcase(),
          ],
      ];

    mainFrame.children = [spinnerFrame];

    // Auto return after 3 seconds
    Timer(Duration(seconds: 3), () {
      spinner.stop();
      _backToMenu('Spinner completed!');
    });
  }

  void _showTableDemo() {
    var table = Table<List<String>>(
      columns: [
        TableColumn('Name', width: 15),
        TableColumn('Role', width: 12),
        TableColumn('Status', width: 10),
      ],
      rows: [
        ['Alice', 'Developer', 'Active'],
        ['Bob', 'Designer', 'Active'],
        ['Charlie', 'Manager', 'Away'],
        ['Diana', 'Tester', 'Active'],
        ['Eve', 'DevOps', 'Busy'],
      ],
      rowBuilder: (row) => row,
      border: TableBorder.rounded,
      onSelect: (row) {
        _backToMenu('Selected: ${row[0]}');
      },
    );

    var frame = Frame(title: 'Table Demo (UP/DOWN to navigate, ENTER to select)', color: '33')
      ..children = [table];

    mainFrame.children = [frame];
    focusFirst();
  }

  void _backToMenu(String message) {
    mainFrame.children = [
      SplitView(horizontal: false, ratios: [1, 5])
        ..children = [
          CenteredText(message),
          demoSelect,
        ],
    ];
    demoSelect.selectedIndex = 0;
    focusFirst();
  }

  @override
  bool onKey(String key) {
    if (key == KeyCode.ESCAPE) {
      if (mainFrame.children.first != demoSelect) {
        mainFrame.children = [demoSelect];
        focusFirst();
        return true;
      } else {
        stop();
        return true;
      }
    }
    if (key == 'q') {
      stop();
      return true;
    }
    return super.onKey(key);
  }
}

class _SpinnerShowcase extends View {
  final spinners = <Spinner>[];

  _SpinnerShowcase() {
    var styles = [
      (SpinnerStyle.dots, 'dots'),
      (SpinnerStyle.circle, 'circle'),
      (SpinnerStyle.line, 'line'),
      (SpinnerStyle.arrow, 'arrow'),
      (SpinnerStyle.bounce, 'bounce'),
      (SpinnerStyle.moon, 'moon'),
    ];

    for (var (style, name) in styles) {
      var s = Spinner(label: name, style: style)..start();
      spinners.add(s);
    }
  }

  @override
  void update() {
    text = [];
    var y = 0;
    for (var spinner in spinners) {
      spinner.update();
      for (var t in spinner.text) {
        text.add(Text(t.text ?? '')
          ..color = t.color
          ..position = Position(t.x, y + t.y));
      }
      y++;
    }
  }
}

void main() {
  print("TUI Widgets Demo");
  print("─────────────────────────────────────");
  print("UP/DOWN     = navigate");
  print("ENTER       = select");
  print("ESC         = back / quit");
  print("q           = quit");
  print("─────────────────────────────────────");
  print("Starting in 1 second...");
  Future.delayed(Duration(seconds: 1), () {
    WidgetsDemo().start();
  });
}
