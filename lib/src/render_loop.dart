part of tui;

class RenderLoop {
  late Duration _interval;
  bool _stop = false;

  RenderLoop({int milliseconds = 50}) {
    _interval = Duration(milliseconds: milliseconds);
  }

  void start([Function? onUpdate]) {
    Timer(_interval, () {
      if (_stop) return;
      if (onUpdate != null) {
        onUpdate();
      } else {
        update();
      }
      Timer(_interval, () => start(onUpdate));
    });
  }

  void update() {
    throw UnimplementedError("Either pass an update function to start() or extend RenderLoop and implement update().");
  }

  void stop() {
    _stop = true;
  }
}
