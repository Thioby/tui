import "package:tui/tui.dart";
import "dart:async";
import "dart:math";

class CounterPanel extends Frame {
  int counter = 0;

  CounterPanel(String label)
      : super(title: label, color: '8', focusColor: '36') {
    focusable = true;
  }

  @override
  bool onKey(String key) {
    switch (key) {
      case KeyCode.UP:
        counter++;
        return true;
      case KeyCode.DOWN:
        counter--;
        return true;
    }
    return false;
  }

  @override
  void update() {
    super.update();

    var displayText = '$counter';
    var cx = (width - displayText.length) ~/ 2;
    var cy = height ~/ 2;

    var numColor = focused ? '96' : '36';
    text.add(Text(displayText)
      ..color = numColor
      ..position = Position(cx, cy));

    if (focused) {
      var hint = '↑/↓ to change';
      var hx = (width - hint.length) ~/ 2;
      text.add(Text(hint)
        ..color = '8'
        ..position = Position(hx, cy + 1));
    }
  }
}

class ProgressPanel extends Frame {
  List<ProgressBar> bars = [];
  List<double> speeds = [];
  Random random = Random();
  Timer? timer;
  bool paused = false;

  ProgressPanel() : super(title: 'PROGRESS', color: '8', focusColor: '33') {
    focusable = true;

    var configs = [
      ('CPU', '31'),
      ('Memory', '32'),
      ('Disk', '33'),
      ('Network', '34'),
    ];

    for (var (label, color) in configs) {
      var bar = ProgressBar()
        ..label = label.padRight(8)
        ..color = color
        ..value = random.nextDouble();
      bars.add(bar);
      speeds.add((random.nextDouble() - 0.5) * 0.05);
    }
  }

  void startAnimation() {
    timer = Timer.periodic(Duration(milliseconds: 100), (_) {
      if (paused) return;
      for (int i = 0; i < bars.length; i++) {
        bars[i].value += speeds[i];
        if (bars[i].value >= 1.0 || bars[i].value <= 0.0) {
          speeds[i] = -speeds[i];
        }
      }
    });
  }

  void stopAnimation() {
    timer?.cancel();
  }

  @override
  bool onKey(String key) {
    if (key == KeyCode.SPACE || key == KeyCode.ENTER) {
      paused = !paused;
      title = paused ? 'PAUSED' : 'PROGRESS';
      return true;
    }
    return false;
  }

  @override
  void update() {
    super.update();

    children = [];
    int barY = 2;
    for (var bar in bars) {
      if (barY < height - 2) {
        bar.resize(Size(width - 4, 1), Position(2, barY));
        children.add(bar);
        barY += 2;
      }
    }

    if (focused) {
      var hint = 'SPACE = pause';
      text.add(Text(hint)
        ..color = '8'
        ..position = Position(2, height - 2));
    }
  }
}

class LogPanel extends Frame {
  List<String> logs = [];
  int scrollOffset = 0;
  Random random = Random();
  Timer? logTimer;
  bool autoScroll = true;

  final List<String> logMessages = [
    'INFO  Connected to server',
    'DEBUG Processing request #',
    'WARN  High memory usage detected',
    'INFO  User logged in',
    'DEBUG Cache hit ratio: ',
    'ERROR Connection timeout',
    'INFO  Task completed',
    'DEBUG Garbage collection ran',
    'WARN  Slow query detected',
    'INFO  File saved',
    'DEBUG Heartbeat received',
    'ERROR Disk space low',
  ];

  LogPanel() : super(title: 'LOG', color: '8', focusColor: '32') {
    focusable = true;
  }

  void startLogging() {
    logTimer = Timer.periodic(Duration(milliseconds: 400), (_) {
      addLog();
    });
  }

  void stopLogging() {
    logTimer?.cancel();
  }

  void addLog() {
    var msg = logMessages[random.nextInt(logMessages.length)];
    var timestamp = DateTime.now().toString().substring(11, 19);
    if (msg.contains('#')) {
      msg = msg.replaceFirst('#', '${random.nextInt(9999)}');
    } else if (msg.contains(': ')) {
      msg = '$msg${random.nextInt(100)}%';
    }
    logs.add('[$timestamp] $msg');
    if (autoScroll && logs.length > height - 2) {
      scrollOffset = logs.length - (height - 2);
    }
  }

  @override
  bool onKey(String key) {
    int visibleLines = height - 2;
    int maxScroll = max(0, logs.length - visibleLines);

    switch (key) {
      case KeyCode.UP:
        if (scrollOffset > 0) {
          scrollOffset--;
          autoScroll = false;
        }
        return true;
      case KeyCode.DOWN:
        if (scrollOffset < maxScroll) {
          scrollOffset++;
        }
        if (scrollOffset >= maxScroll) {
          autoScroll = true;
        }
        return true;
      case KeyCode.HOME:
        scrollOffset = 0;
        autoScroll = false;
        return true;
      case KeyCode.END:
        scrollOffset = maxScroll;
        autoScroll = true;
        return true;
    }
    return false;
  }

  @override
  void update() {
    title = autoScroll ? 'LOG' : 'LOG (scroll)';
    super.update();

    int visibleLines = height - 2;
    int start = scrollOffset;
    int end = min(logs.length, scrollOffset + visibleLines);

    for (int i = start; i < end; i++) {
      var line = logs[i];
      if (line.length > width - 2) {
        line = line.substring(0, width - 2);
      }
      var t = Text(line)..position = Position(1, 1 + (i - start));
      if (line.contains('ERROR')) {
        t.color = '91';
      } else if (line.contains('WARN')) {
        t.color = '93';
      } else if (line.contains('DEBUG')) {
        t.color = '90';
      } else {
        t.color = '92';
      }
      text.add(t);
    }

    if (focused) {
      var hint = '↑/↓ scroll';
      text.add(Text(hint)
        ..color = '8'
        ..position = Position(width - hint.length - 2, height - 2));
    }
  }
}

class SplitDemo extends Window {
  late SplitView mainSplit;
  late SplitView leftSplit;
  late LogPanel logPanel;
  late ProgressPanel progressPanel;
  bool horizontalMain = true;

  SplitDemo() {
    showFps = true;

    logPanel = LogPanel();
    progressPanel = ProgressPanel();

    leftSplit = SplitView(horizontal: false)
      ..children = [
        progressPanel,
        CounterPanel('COUNTER'),
      ];

    mainSplit = SplitView(horizontal: true, ratios: [2, 1])
      ..children = [
        leftSplit,
        logPanel,
      ];

    children = [mainSplit];
  }

  @override
  void start() {
    super.start();
    logPanel.startLogging();
    progressPanel.startAnimation();
  }

  @override
  void stop() {
    logPanel.stopLogging();
    progressPanel.stopAnimation();
    super.stop();
  }

  @override
  bool onKey(String key) {
    switch (key) {
      case ' ':
        horizontalMain = !horizontalMain;
        mainSplit.horizontal = horizontalMain;
        return true;
      case 'f':
      case 'F':
        showFps = !showFps;
        return true;
      case 'q':
        stop();
        return true;
    }
    return false;
  }
}

void main() {
  print('SplitView Demo');
  print(BoxChars.lightH * 37);
  print('TAB   = cycle focus between panels');
  print('SPACE = toggle layout / pause progress');
  print('F     = toggle FPS');
  print('q     = quit');
  print(BoxChars.lightH * 37);
  print('Starting in 2 seconds...');
  Future.delayed(Duration(seconds: 2), () {
    SplitDemo().start();
  });
}
