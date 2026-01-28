part of tui;

class RenderLoop {
  late Duration _interval;
  bool _stop = false;

  RenderLoop({int milliseconds = 50}) {
    _interval = Duration(milliseconds: milliseconds);
  }

  void start([Function? update_callback]) {
    Timer(_interval, () {
      if (_stop) return;
      if (update_callback != null) {
        update_callback();
      } else {
        update();
      }
      Timer(_interval, () => start(update_callback));
    });
  }

  void update() {
    throw "Either pass an update function to start() or extend the RenderLoop and implement update() method.";
  }

  void stop() {
    _stop = true;
  }

}
