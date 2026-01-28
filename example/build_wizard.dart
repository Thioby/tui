import 'dart:async';
import 'package:tui/tui.dart';

/// Simple choice page
class ChoicePage extends Page {
  final String title;
  final List<String> options;
  int selected = 0;

  ChoicePage(this.title, this.options);

  @override
  void update() {
    text = [
      Text(title)..color = '33',
      Text('─' * 40)..position = Position(0, 1),
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

/// Left panel showing build status (content for Frame)
class BuildStatusContent extends View {
  String status = 'Waiting...';
  String statusColor = '90';
  late ProgressBar progressBar;

  BuildStatusContent() {
    progressBar = ProgressBar()
      ..color = '33'
      ..showPercent = true;
    children = [progressBar];
  }

  void setStatus(String newStatus, String color) {
    status = newStatus;
    statusColor = color;
  }

  void setProgress(double value) {
    progressBar.value = value;
  }

  @override
  void update() {
    text = [
      Text(status)..color = statusColor,
    ];

    if (progressBar.value >= 1.0) {
      text.add(Text('✓ Complete')
        ..color = '32'
        ..position = Position(0, 2));
    } else {
      text.add(Text('${(progressBar.value * 100).toInt()}%')
        ..color = '33'
        ..position = Position(0, 2));
    }
  }

  @override
  void resizeChildren() {
    progressBar.resize(Size(width, 1), Position(0, 1));
  }
}

/// Right panel showing build log (content for Frame)
class BuildLogContent extends View {
  List<String> logs = [];
  List<String> colors = [];

  void addLog(String message, {String color = '7'}) {
    logs.add(message);
    colors.add(color);
    if (logs.length > 50) {
      logs.removeAt(0);
      colors.removeAt(0);
    }
  }

  void clear() {
    logs.clear();
    colors.clear();
  }

  @override
  void update() {
    text = [];

    var visibleLines = height;
    var startIdx = logs.length > visibleLines ? logs.length - visibleLines : 0;

    for (var i = startIdx; i < logs.length; i++) {
      var line = logs[i];
      if (line.length > width) {
        line = line.substring(0, width);
      }
      text.add(Text(line)
        ..color = colors[i]
        ..position = Position(0, i - startIdx));
    }
  }
}

/// Build page with SplitView: status on left, log on right
class BuildPage extends Page {
  late BuildStatusContent statusContent;
  late BuildLogContent logContent;
  late Frame statusFrame;
  late Frame logFrame;
  late SplitView splitView;

  Timer? _timer;
  bool _complete = false;
  int _step = 0;

  final List<Map<String, dynamic>> _buildSteps = [
    {'msg': 'Initializing build environment...', 'duration': 800},
    {'msg': 'Checking dependencies...', 'duration': 600},
    {'msg': 'Resolving packages...', 'duration': 1200},
    {'msg': 'Compiling src/main.dart...', 'duration': 900},
    {'msg': 'Compiling src/utils.dart...', 'duration': 700},
    {'msg': 'Compiling src/models.dart...', 'duration': 800},
    {'msg': 'Compiling src/services.dart...', 'duration': 1100},
    {'msg': 'Linking objects...', 'duration': 600},
    {'msg': 'Optimizing binary...', 'duration': 1500},
    {'msg': 'Generating assets...', 'duration': 800},
    {'msg': 'Running post-build hooks...', 'duration': 500},
    {'msg': 'Finalizing build...', 'duration': 500},
  ];

  @override
  void onEnter() {
    statusContent = BuildStatusContent();
    logContent = BuildLogContent();

    statusFrame = Frame(title: 'Build Status', padding: 0);
    statusFrame.children = [statusContent];

    logFrame = Frame(title: 'Build Log', padding: 0);
    logFrame.children = [logContent];

    splitView = SplitView(horizontal: true, ratios: [1, 2]);
    splitView.children = [statusFrame, logFrame];
    children = [splitView];

    // Start build
    _startBuild();
  }

  void _startBuild() {
    _step = 0;
    _complete = false;
    logContent.clear();

    statusContent.setStatus('Building...', '33');
    logContent.addLog('=== Build started ===', color: '36');
    logContent.addLog('');

    _runNextStep();
  }

  void _runNextStep() {
    if (_step >= _buildSteps.length) {
      _finishBuild();
      return;
    }

    var step = _buildSteps[_step];
    var msg = step['msg'] as String;
    var duration = step['duration'] as int;

    logContent.addLog('  $msg', color: '7');
    statusContent.setProgress((_step + 0.5) / _buildSteps.length);

    _timer = Timer(Duration(milliseconds: duration), () {
      logContent.addLog('  ✓ Done', color: '32');
      _step++;
      statusContent.setProgress(_step / _buildSteps.length);
      _runNextStep();
    });
  }

  void _finishBuild() {
    logContent.addLog('');
    logContent.addLog('=== Build successful! ===', color: '32');
    logContent.addLog('');
    logContent.addLog('Press Enter to continue...', color: '36');

    statusContent.setStatus('Success!', '32');
    statusContent.setProgress(1.0);
    _complete = true;
  }

  @override
  void onLeave() {
    _timer?.cancel();
  }

  @override
  void update() {
    text = [
      Text('Building Project')
        ..color = '33'
        ..position = Position(0, 0),
    ];

    if (!_complete) {
      text.add(Text('Please wait...')
        ..color = '90'
        ..position = Position(0, height - 1));
    } else {
      text.add(Text('Press Enter to continue')
        ..color = '32'
        ..position = Position(0, height - 1));
    }
  }

  @override
  void resizeChildren() {
    splitView.resize(Size(width, height - 2), Position(0, 1));
  }

  @override
  bool canProceed() => _complete;

  @override
  bool onKey(String key) {
    if (key == KeyCode.ENTER && _complete) {
      pageView.goNext();
      return true;
    }
    return false;
  }

  @override
  dynamic getData() => {'buildTime': DateTime.now().toIso8601String()};
}

/// Summary page
class SummaryPage extends Page {
  @override
  void update() {
    var target = pageView.getData<String>(0) ?? '?';
    var buildData = pageView.getData<Map>(1) ?? {};

    text = [
      Text('═══════════════════════════════════')..color = '32',
      Text('       Build Complete!')
        ..color = '32'
        ..position = Position(0, 1),
      Text('═══════════════════════════════════')
        ..color = '32'
        ..position = Position(0, 2),
      Text('Target: $target')..position = Position(2, 4),
      Text('Built at: ${buildData['buildTime'] ?? 'N/A'}')
        ..color = '90'
        ..position = Position(2, 5),
      Text('Press q to exit')
        ..color = '90'
        ..position = Position(0, height - 1),
    ];
  }
}

/// Main build wizard
class BuildWizard extends Window {
  late PageView pager;
  late DotIndicator indicator;

  BuildWizard() {
    indicator = DotIndicator();

    pager = PageView(
      indicator: indicator,
      pages: [
        ChoicePage('Select Build Target', ['Debug', 'Release', 'Profile']),
        BuildPage(),
        SummaryPage(),
      ],
    );

    var layout = SplitView(horizontal: false, ratios: [1, 15]);
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
  BuildWizard().start();
}
