part of tui;

/// Tracks frame timing and calculates FPS statistics.
class FpsMeter {
  final int _samples;
  final Queue<double> _times = Queue();
  DateTime _last = DateTime.now();

  double _curr = 0;
  double _avg = 0;
  double _min = 0;
  double _max = 0;
  double _ms = 0;

  FpsMeter({int sampleSize = 60}) : _samples = sampleSize;

  void tick() {
    final now = DateTime.now();
    final delta = now.difference(_last);
    _last = now;

    _ms = delta.inMicroseconds / 1000.0;
    if (_ms > 0) {
      _curr = 1000.0 / _ms;
    }

    _times.add(_ms);
    if (_times.length > _samples) {
      _times.removeFirst();
    }

    if (_times.isNotEmpty) {
      var sum = 0.0;
      var minTime = double.infinity;
      var maxTime = 0.0;
      for (final t in _times) {
        sum += t;
        if (t < minTime) minTime = t;
        if (t > maxTime) maxTime = t;
      }
      final avgTime = sum / _times.length;
      _avg = avgTime > 0 ? 1000.0 / avgTime : 0;
      _max = minTime > 0 ? 1000.0 / minTime : 0;
      _min = maxTime > 0 ? 1000.0 / maxTime : 0;
    }
  }

  double get currentFps => _curr;
  double get averageFps => _avg;
  double get minFps => _min;
  double get maxFps => _max;
  double get frameTimeMs => _ms;

  String get summary =>
    'FPS: ${_curr.toStringAsFixed(0)} (avg: ${_avg.toStringAsFixed(0)}, min: ${_min.toStringAsFixed(0)})';

  String get compact =>
    '${_avg.toStringAsFixed(0)} fps ${BoxChars.lightV} ${_ms.toStringAsFixed(1)}ms';

  List<String> get detailed => [
    'FPS: ${_curr.toStringAsFixed(1)}',
    'Avg: ${_avg.toStringAsFixed(1)}',
    'Min: ${_min.toStringAsFixed(1)}',
    'Max: ${_max.toStringAsFixed(1)}',
    'Frame: ${_ms.toStringAsFixed(2)}ms',
  ];

  void reset() {
    _times.clear();
    _curr = 0;
    _avg = 0;
    _min = 0;
    _max = 0;
    _ms = 0;
    _last = DateTime.now();
  }
}

class RenderLoop {
  late Duration _dur;
  bool _stopped = false;
  final FpsMeter fps = FpsMeter();

  int get targetFps => (1000 / _dur.inMilliseconds).round();

  RenderLoop({int milliseconds = 16}) {
    _dur = Duration(milliseconds: milliseconds);
  }

  RenderLoop.withFps(int fps) {
    _dur = Duration(milliseconds: (1000 / fps).round());
  }

  void start([Function? onUpdate]) {
    _loop(onUpdate);
  }

  void _loop([Function? onUpdate]) {
    Timer(_dur, () {
      if (_stopped) return;
      fps.tick();
      if (onUpdate != null) {
        onUpdate();
      } else {
        update();
      }
      _loop(onUpdate);
    });
  }

  void update() {
    throw UnimplementedError("Either pass an update function to start() or extend RenderLoop and implement update().");
  }

  void stop() {
    _stopped = true;
  }
}