part of tui;

/// Abstract base class for pages in a PageView.
abstract class Page extends View {
  PageView? _pv;

  PageView get pageView {
    if (_pv == null) {
      throw StateError('Page not attached to PageView');
    }
    return _pv!;
  }

  void onEnter() {}

  void onLeave() {}

  bool canProceed() => true;

  dynamic getData() => null;
}

/// Multi-step container for sequential page navigation.
class PageView extends View {
  final List<Page> pages;
  final PageIndicator? indicator;

  int _idx = 0;
  final Map<int, dynamic> _data = {};
  final Set<int> _unlocked = {};

  int get currentIndex => _idx;
  int get pageCount => pages.length;
  Page get currentPage => pages[_idx];
  Set<int> get unlockedPages => Set.unmodifiable(_unlocked);

  PageView({required this.pages, this.indicator}) {
    if (pages.isEmpty) {
      throw ArgumentError('PageView requires at least one page');
    }

    focusable = true;

    for (var page in pages) {
      page._pv = this;
    }

    children = [_PageCont(this)];
  }

  @override
  bool onKey(String key) {
    return currentPage.onKey(key);
  }

  @override
  List<View> get focusableViews {
    var result = <View>[];
    if (focusable) result.add(this);
    result.addAll(currentPage.focusableViews);
    return result;
  }

  bool goNext() {
    if (_idx >= pages.length - 1) return false;

    var page = currentPage;
    if (!page.canProceed()) return false;

    _data[_idx] = page.getData();
    page.onLeave();

    _idx++;
    _updInd();
    currentPage.onEnter();

    return true;
  }

  bool goPrev() {
    if (_idx <= 0) return false;

    currentPage.onLeave();
    _idx--;
    _updInd();
    currentPage.onEnter();

    return true;
  }

  bool goTo(int index) {
    if (index < 0 || index >= pages.length) return false;
    if (index == _idx) return false;
    if (!_unlocked.contains(index) && index > _idx) return false;

    currentPage.onLeave();
    _idx = index;
    _updInd();
    currentPage.onEnter();

    return true;
  }

  void unlock(int index) {
    if (index >= 0 && index < pages.length) {
      _unlocked.add(index);
    }
  }

  T? getData<T>(int pageIndex) {
    return _data[pageIndex] as T?;
  }

  Map<int, dynamic> getAllData() => Map.unmodifiable(_data);

  void _updInd() {
    indicator?.updateState(_idx, pages.length, _unlocked);
  }

  @override
  void resize(Size size, Position position) {
    super.resize(size, position);
    _updInd();
  }

  void start() {
    currentPage.onEnter();
    _updInd();
  }
}

class _PageCont extends View {
  final PageView _pv;

  _PageCont(this._pv);

  @override
  void render(Canvas canvas) {
    var page = _pv.currentPage;
    page.resize(size, Position(0, 0));
    page.render(canvas);
  }
}