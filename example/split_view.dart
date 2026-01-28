import "package:tui/tui.dart";
import "dart:async";
import "dart:math";

class Panel extends View {
  String label;
  String color;
  String focusColor;
  int counter = 0;

  Panel(this.label, this.color, {this.focusColor = "7"}) {
    focusable = true;  // Enable focus
  }

  @override
  void onFocus() {
    // Could trigger visual update here
  }

  @override
  void onBlur() {
    // Could trigger visual update here
  }

  @override
  bool onKey(String key) {
    // Handle arrow keys when focused
    switch (key) {
      case KeyCode.UP:
        counter++;
        return true;
      case KeyCode.DOWN:
        counter--;
        return true;
    }
    return false; // Key not handled
  }

  @override
  void update() {
    text = [];
    if (width < 2 || height < 2) return;

    // Use focus color when focused
    var borderColor = focused ? focusColor : color;

    // Top border: ┌───┐ or ╔═══╗ when focused
    var hChar = focused ? "═" : "─";
    var tlChar = focused ? "╔" : "┌";
    var trChar = focused ? "╗" : "┐";
    var blChar = focused ? "╚" : "└";
    var brChar = focused ? "╝" : "┘";
    var vChar = focused ? "║" : "│";

    var topLine = "$tlChar${hChar * (width - 2)}$trChar";
    text.add(Text(topLine)..color = borderColor);

    // Side borders
    for (int i = 1; i < height - 1; i++) {
      text.add(Text(vChar)..color = borderColor..position = Position(0, i));
      text.add(Text(vChar)..color = borderColor..position = Position(width - 1, i));
    }

    // Bottom border
    var bottomLine = "$blChar${hChar * (width - 2)}$brChar";
    text.add(Text(bottomLine)..color = borderColor..position = Position(0, height - 1));

    // Centered label with counter
    var displayLabel = "$label: $counter";
    var x = ((width - displayLabel.length) / 2).toInt();
    var y = (height / 2).toInt();
    text.add(Text(displayLabel)..position = Position(x, y));

    // Focus hint
    if (focused) {
      var hint = "↑/↓ to change";
      var hx = ((width - hint.length) / 2).toInt();
      text.add(Text(hint)..color = "8"..position = Position(hx, y + 1));
    }
  }
}

class ProgressPanel extends View {
  List<ProgressBar> bars = [];
  List<double> speeds = [];
  Random random = Random();
  Timer? timer;
  bool paused = false;

  ProgressPanel() {
    focusable = true;  // Enable focus

    // Create progress bars with different colors and speeds
    var configs = [
      ("CPU", "1"),      // red
      ("Memory", "2"),   // green
      ("Disk", "3"),     // yellow
      ("Network", "4"),  // blue
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
        // Bounce at edges
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
      return true;
    }
    return false;
  }

  @override
  void update() {
    text = [];
    if (width < 2 || height < 2) return;

    var borderColor = focused ? "7" : "5";

    // Border - double line when focused
    var hChar = focused ? "═" : "─";
    var vChar = focused ? "║" : "│";
    var tl = focused ? "╔" : "┌";
    var tr = focused ? "╗" : "┐";
    var bl = focused ? "╚" : "└";
    var br = focused ? "╝" : "┘";

    var title = paused ? " PAUSED " : " PROGRESS ";
    var titleX = ((width - 2 - title.length) / 2).toInt();
    var topLine = "$tl${hChar * titleX}$title${hChar * (width - 2 - titleX - title.length)}$tr";
    text.add(Text(topLine)..color = borderColor);

    for (int i = 1; i < height - 1; i++) {
      text.add(Text(vChar)..color = borderColor..position = Position(0, i));
      text.add(Text(vChar)..color = borderColor..position = Position(width - 1, i));
    }

    var bottomLine = "$bl${hChar * (width - 2)}$br";
    text.add(Text(bottomLine)..color = borderColor..position = Position(0, height - 1));

    // Position progress bars inside the panel
    children = [];
    int barY = 2;
    for (var bar in bars) {
      if (barY < height - 2) {
        bar.resize(Size(width - 4, 1), Position(2, barY));
        children.add(bar);
        barY += 2;
      }
    }
  }
}

class LogPanel extends View {
  List<String> logs = [];
  int scrollOffset = 0;
  Random random = Random();
  Timer? logTimer;
  bool autoScroll = true;

  LogPanel() {
    focusable = true;  // Enable focus
  }

  final List<String> logMessages = [
    "INFO  Connected to server",
    "DEBUG Processing request #",
    "WARN  High memory usage detected",
    "INFO  User logged in",
    "DEBUG Cache hit ratio: ",
    "ERROR Connection timeout",
    "INFO  Task completed",
    "DEBUG Garbage collection ran",
    "WARN  Slow query detected",
    "INFO  File saved",
    "DEBUG Heartbeat received",
    "ERROR Disk space low",
  ];

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
    if (msg.contains("#")) {
      msg = msg.replaceFirst("#", "${random.nextInt(9999)}");
    } else if (msg.contains(": ")) {
      msg = "$msg${random.nextInt(100)}%";
    }
    logs.add("[$timestamp] $msg");
    // Auto-scroll to bottom if enabled
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
    text = [];
    if (width < 2 || height < 2) return;

    var borderColor = focused ? "7" : "6";

    // Border - double line when focused
    var hChar = focused ? "═" : "─";
    var vChar = focused ? "║" : "│";
    var tl = focused ? "╔" : "┌";
    var tr = focused ? "╗" : "┐";
    var bl = focused ? "╚" : "└";
    var br = focused ? "╝" : "┘";

    var title = autoScroll ? " LOG " : " LOG (scroll) ";
    var titleX = ((width - 2 - title.length) / 2).toInt();
    var topLine = "$tl${hChar * titleX}$title${hChar * (width - 2 - titleX - title.length)}$tr";
    text.add(Text(topLine)..color = borderColor);

    // Side borders
    for (int i = 1; i < height - 1; i++) {
      text.add(Text(vChar)..color = borderColor..position = Position(0, i));
      text.add(Text(vChar)..color = borderColor..position = Position(width - 1, i));
    }

    // Bottom border
    var bottomLine = "$bl${hChar * (width - 2)}$br";
    text.add(Text(bottomLine)..color = borderColor..position = Position(0, height - 1));

    // Log lines
    int visibleLines = height - 2;
    int start = scrollOffset;
    int end = min(logs.length, scrollOffset + visibleLines);

    for (int i = start; i < end; i++) {
      var line = logs[i];
      if (line.length > width - 2) {
        line = line.substring(0, width - 2);
      }
      var t = Text(line)..position = Position(1, 1 + (i - start));
      // Color based on log level
      if (line.contains("ERROR")) {
        t.color = "1";
      } else if (line.contains("WARN")) {
        t.color = "3";
      } else if (line.contains("DEBUG")) {
        t.color = "4";
      } else {
        t.color = "2";
      }
      text.add(t);
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
    logPanel = LogPanel();
    progressPanel = ProgressPanel();

    // Left side: vertical split - progress bars on top, panel on bottom
    leftSplit = SplitView(horizontal: false)
      ..children = [
        progressPanel,
        Panel("BOTTOM", "4"),
      ];

    // Main: horizontal split - left has nested split, right is log panel
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
      case " ":
        // Toggle main split direction
        horizontalMain = !horizontalMain;
        mainSplit.horizontal = horizontalMain;
        return true;
      case "q":
        stop();
        return true;
    }
    return false;
  }
}

void main() {
  print("SplitView Demo");
  print("─────────────────────────────────────");
  print("TAB         = cycle focus between panels");
  print("SPACE       = toggle layout / pause progress");
  print("q           = quit");
  print("");
  print("In PROGRESS panel: SPACE/ENTER = pause");
  print("In LOG panel:      ↑/↓ = scroll, HOME/END");
  print("In BOTTOM panel:   ↑/↓ = change counter");
  print("─────────────────────────────────────");
  print("Starting in 2 seconds...");
  Future.delayed(Duration(seconds: 2), () {
    SplitDemo().start();
  });
}
