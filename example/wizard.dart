import 'package:tui/tui.dart';

/// Simple choice page - select with arrows, Enter to continue
class ChoicePage extends Page {
  final String title;
  final List<String> options;
  int selected = 0;

  ChoicePage(this.title, this.options);

  @override
  void update() {
    text = [
      Text(title)..color = '33',
      Text(BoxChars.lightH * 40)..position = Position(0, 1),
    ];

    for (var i = 0; i < options.length; i++) {
      var prefix = selected == i ? '► ' : '  ';
      var color = selected == i ? '32' : '7';
      text.add(Text('$prefix${options[i]}')
        ..color = color
        ..position = Position(2, 3 + i));
    }

    text.add(Text('↑↓ select, Enter continue')
      ..color = '90'
      ..position = Position(0, height - 1));
  }

  @override
  bool onKey(String key) {
    switch (key) {
      case KeyCode.UP:
        selected = (selected - 1 + options.length) % options.length;
        return true;
      case KeyCode.DOWN:
        selected = (selected + 1) % options.length;
        return true;
      case KeyCode.ENTER:
        pageView.goNext();
        return true;
    }
    return false;
  }

  @override
  dynamic getData() => options[selected];
}

/// Config page with checkboxes and NavigationBar
class ConfigPage extends Page {
  final List<String> options = ['Enable logging', 'Enable cache', 'Enable debug'];
  final List<bool> values = [true, false, false];
  int selected = 0;
  NavigationBar? nav;

  @override
  void onEnter() {
    nav = NavigationBar(this);
    children = [nav!];
  }

  @override
  void update() {
    text = [
      Text('Configuration')..color = '33',
      Text(BoxChars.lightH * 40)..position = Position(0, 1),
    ];

    for (var i = 0; i < options.length; i++) {
      var check = values[i] ? '[✓]' : '[ ]';
      var prefix = selected == i ? '► ' : '  ';
      var color = selected == i ? '32' : '7';
      text.add(Text('$prefix$check ${options[i]}')
        ..color = color
        ..position = Position(2, 3 + i));
    }

    text.add(Text('↑↓ select, Space toggle, Tab for buttons')
      ..color = '90'
      ..position = Position(0, height - 2));
  }

  @override
  void resizeChildren() {
    nav?.resize(Size(width, 1), Position(0, height - 1));
  }

  @override
  bool onKey(String key) {
    switch (key) {
      case KeyCode.UP:
        selected = (selected - 1 + options.length) % options.length;
        return true;
      case KeyCode.DOWN:
        selected = (selected + 1) % options.length;
        return true;
      case ' ':
        values[selected] = !values[selected];
        return true;
    }
    return false;
  }

  @override
  dynamic getData() => {
    'logging': values[0],
    'cache': values[1],
    'debug': values[2],
  };
}

/// Summary page - shows collected data
class SummaryPage extends Page {
  @override
  void update() {
    var env = pageView.getData<String>(0) ?? '?';
    var config = pageView.getData<Map>(1) ?? {};
    var theme = pageView.getData<String>(2) ?? '?';

    text = [
      Text('Summary')..color = '32',
      Text(BoxChars.doubleH * 40)..position = Position(0, 1),
      Text('Environment: $env')..position = Position(2, 3),
      Text('Logging: ${config['logging'] ?? false}')..position = Position(2, 4),
      Text('Cache: ${config['cache'] ?? false}')..position = Position(2, 5),
      Text('Debug: ${config['debug'] ?? false}')..position = Position(2, 6),
      Text('Theme: $theme')..position = Position(2, 7),
      Text('Press q to exit')
        ..color = '90'
        ..position = Position(0, height - 1),
    ];
  }
}

/// Main wizard
class SimpleWizard extends Window {
  late PageView pager;
  late StepIndicator indicator;

  SimpleWizard() {
    indicator = StepIndicator();

    pager = PageView(
      indicator: indicator,
      pages: [
        ChoicePage('Select Environment', ['Development', 'Staging', 'Production']),
        ConfigPage(),  // Page with NavigationBar - use Tab to focus buttons
        ChoicePage('Select Theme', ['Dark', 'Light', 'System']),
        SummaryPage(),
      ],
    );

    // Layout: indicator at top, pager below
    var layout = SplitView(horizontal: false, ratios: [1, 10]);
    layout.children = [indicator, pager];
    children = [layout];
  }

  @override
  void start() {
    super.start();
    pager.start();
  }

  @override
  bool onKey(String key) {
    if (key == 'q') {
      stop();
      return true;
    }
    return false;
  }
}

void main() {
  SimpleWizard().start();
}
