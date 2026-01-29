part of tui;

/// Tracks frame timing and calculates FPS statistics.
class FpsMeter {
  final int _sampleSize;
  final List<double> _frameTimes = [];
  DateTime _lastFrame = DateTime.now();

  double _currentFps = 0;
  double _averageFps = 0;
  double _minFps = double.infinity;
  double _maxFps = 0;
  double _frameTimeMs = 0;

  FpsMeter({int sampleSize = 60}) : _sampleSize = sampleSize;

  /// Call at the start of each frame to record timing.
  void tick() {
    final now = DateTime.now();
    final delta = now.difference(_lastFrame);
    _lastFrame = now;

    _frameTimeMs = delta.inMicroseconds / 1000.0;
    if (_frameTimeMs > 0) {
      _currentFps = 1000.0 / _frameTimeMs;
    }

    _frameTimes.add(_frameTimeMs);
    if (_frameTimes.length > _sampleSize) {
      _frameTimes.removeAt(0);
    }

    if (_frameTimes.isNotEmpty) {
      final avgTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
      _averageFps = avgTime > 0 ? 1000.0 / avgTime : 0;

      final minTime = _frameTimes.reduce((a, b) => a < b ? a : b);
      final maxTime = _frameTimes.reduce((a, b) => a > b ? a : b);
      _maxFps = minTime > 0 ? 1000.0 / minTime : 0;
      _minFps = maxTime > 0 ? 1000.0 / maxTime : 0;
    }
  }

  /// Current instantaneous FPS.
  double get currentFps => _currentFps;

  /// Average FPS over sample window.
  double get averageFps => _averageFps;

  /// Minimum FPS in sample window.
  double get minFps => _minFps;

  /// Maximum FPS in sample window.
  double get maxFps => _maxFps;

  /// Last frame time in milliseconds.
  double get frameTimeMs => _frameTimeMs;

  /// Formatted string for display: "FPS: 60 (avg: 58, min: 45)"
  String get summary =>
    'FPS: ${_currentFps.toStringAsFixed(0)} (avg: ${_averageFps.toStringAsFixed(0)}, min: ${_minFps.toStringAsFixed(0)})';

  /// Compact display: "60 fps | 16.7ms"
  String get compact =>
    '${_averageFps.toStringAsFixed(0)} fps ${BoxChars.lightV} ${_frameTimeMs.toStringAsFixed(1)}ms';

  /// Detailed multi-line display.
  List<String> get detailed => [
    'FPS: ${_currentFps.toStringAsFixed(1)}',
    'Avg: ${_averageFps.toStringAsFixed(1)}',
    'Min: ${_minFps.toStringAsFixed(1)}',
    'Max: ${_maxFps.toStringAsFixed(1)}',
    'Frame: ${_frameTimeMs.toStringAsFixed(2)}ms',
  ];

  void reset() {
    _frameTimes.clear();
    _currentFps = 0;
    _averageFps = 0;
    _minFps = double.infinity;
    _maxFps = 0;
    _frameTimeMs = 0;
    _lastFrame = DateTime.now();
  }
}

class RenderLoop {
  late Duration _interval;
  bool _stop = false;
  final FpsMeter fps = FpsMeter();

  /// Target FPS for the render loop.
  int get targetFps => (1000 / _interval.inMilliseconds).round();

  RenderLoop({int milliseconds = 16}) {  // Default ~60 FPS
    _interval = Duration(milliseconds: milliseconds);
  }

  /// Create render loop with target FPS.
  RenderLoop.withFps(int fps) {
    _interval = Duration(milliseconds: (1000 / fps).round());
  }

  void start([Function? onUpdate]) {
    _scheduleFrame(onUpdate);
  }

  void _scheduleFrame([Function? onUpdate]) {
    Timer(_interval, () {
      if (_stop) return;
      fps.tick();
      if (onUpdate != null) {
        onUpdate();
      } else {
        update();
      }
      _scheduleFrame(onUpdate);
    });
  }

  void update() {
    throw UnimplementedError("Either pass an update function to start() or extend RenderLoop and implement update().");
  }

  void stop() {
    _stop = true;
  }
}
