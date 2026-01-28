part of tui;

/// Abstract base for page progress indicators.
///
/// Implement [updateState] to refresh the visual state and
/// override [update] to generate the display.
abstract class PageIndicator extends View {
  int _current = 0;
  int _total = 0;
  Set<int> _unlocked = {};

  int get current => _current;
  int get total => _total;
  Set<int> get unlocked => _unlocked;

  /// Called by PageView when navigation state changes
  void updateState(int current, int total, Set<int> unlocked) {
    _current = current;
    _total = total;
    _unlocked = unlocked;
    update();
  }
}

/// Step indicator with lines: [1]───[2]───[3]
///
/// Current step is highlighted, unlocked steps shown normally,
/// locked future steps shown dimmed.
class StepIndicator extends PageIndicator {
  final String? activeColor;
  final String? inactiveColor;

  StepIndicator({this.activeColor = "32", this.inactiveColor = "90"});

  @override
  void update() {
    if (total == 0) return;

    var buf = StringBuffer();

    for (var i = 0; i < total; i++) {
      var label = "[${i + 1}]";

      if (i == current) {
        // Current - highlighted
        if (activeColor != null) {
          buf.write("\x1B[${activeColor}m$label\x1B[0m");
        } else {
          buf.write(label);
        }
      } else if (i < current || unlocked.contains(i)) {
        // Visited or unlocked - normal
        buf.write(label);
      } else {
        // Future locked - dimmed
        if (inactiveColor != null) {
          buf.write("\x1B[${inactiveColor}m$label\x1B[0m");
        } else {
          buf.write(label);
        }
      }

      // Add connector line (except after last)
      if (i < total - 1) {
        buf.write("───");
      }
    }

    text = [Text(buf.toString())];
  }
}

/// Dot indicator: ○ ● ○ ○
///
/// Filled dot for current page, empty dots for others.
class DotIndicator extends PageIndicator {
  final String filledDot;
  final String emptyDot;
  final String? activeColor;

  DotIndicator({
    this.filledDot = "●",
    this.emptyDot = "○",
    this.activeColor = "32",
  });

  @override
  void update() {
    if (total == 0) return;

    var buf = StringBuffer();

    for (var i = 0; i < total; i++) {
      if (i > 0) buf.write(" ");

      if (i == current) {
        if (activeColor != null) {
          buf.write("\x1B[${activeColor}m$filledDot\x1B[0m");
        } else {
          buf.write(filledDot);
        }
      } else {
        buf.write(emptyDot);
      }
    }

    text = [Text(buf.toString())];
  }
}

/// Text indicator: "Krok 2 z 4" or "Step 2 of 4"
class TextIndicator extends PageIndicator {
  final String Function(int current, int total)? formatter;

  TextIndicator({this.formatter});

  String _defaultFormat(int current, int total) {
    return "Krok ${current + 1} z $total";
  }

  @override
  void update() {
    if (total == 0) return;

    var format = formatter ?? _defaultFormat;
    text = [Text(format(current, total))];
  }
}
