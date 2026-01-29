part of tui;

/// Abstract base for page progress indicators.
abstract class PageIndicator extends View {
  int _curr = 0;
  int _total = 0;
  Set<int> _open = {};

  int get current => _curr;
  int get total => _total;
  Set<int> get unlocked => _open;

  void updateState(int current, int total, Set<int> unlocked) {
    _curr = current;
    _total = total;
    _open = unlocked;
    update();
  }
}

/// Step indicator with lines: [1]───[2]───[3]
class StepIndicator extends PageIndicator {
  final String? activeColor;
  final String? inactiveColor;

  StepIndicator({this.activeColor = "32", this.inactiveColor = "90"});

  @override
  void update() {
    if (total == 0) return;

    var b = StringBuffer();

    for (var i = 0; i < total; i++) {
      var label = "[${i + 1}]";

      if (i == current) {
        if (activeColor != null) {
          b.write("\x1B[${activeColor}m$label\x1B[0m");
        } else {
          b.write(label);
        }
      } else if (i < current || unlocked.contains(i)) {
        b.write(label);
      } else {
        if (inactiveColor != null) {
          b.write("\x1B[${inactiveColor}m$label\x1B[0m");
        } else {
          b.write(label);
        }
      }

      if (i < total - 1) {
        b.write("───");
      }
    }

    text = [Text(b.toString())];
  }
}

/// Dot indicator: ○ ● ○ ○
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

    var b = StringBuffer();

    for (var i = 0; i < total; i++) {
      if (i > 0) b.write(" ");

      if (i == current) {
        if (activeColor != null) {
          b.write("\x1B[${activeColor}m$filledDot\x1B[0m");
        } else {
          b.write(filledDot);
        }
      } else {
        b.write(emptyDot);
      }
    }

    text = [Text(b.toString())];
  }
}

/// Text indicator: "Krok 2 z 4"
class TextIndicator extends PageIndicator {
  final String Function(int current, int total)? formatter;

  TextIndicator({this.formatter});

  String _fmt(int current, int total) {
    return "Krok ${current + 1} z $total";
  }

  @override
  void update() {
    if (total == 0) return;

    var format = formatter ?? _fmt;
    text = [Text(format(current, total))];
  }
}