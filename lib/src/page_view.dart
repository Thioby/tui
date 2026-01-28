part of tui;

/// Abstract base class for pages in a PageView.
///
/// Override [canProceed] to control navigation, [getData] to return
/// data for collection, and [onEnter]/[onLeave] for lifecycle hooks.
abstract class Page extends View {
  PageView? _pageView;

  /// Reference to parent PageView for navigation
  PageView get pageView {
    if (_pageView == null) {
      throw StateError('Page not attached to PageView');
    }
    return _pageView!;
  }

  /// Called when this page becomes active
  void onEnter() {}

  /// Called when leaving this page
  void onLeave() {}

  /// Return true if user can proceed to next page
  bool canProceed() => true;

  /// Return data to be collected by PageView
  dynamic getData() => null;
}

/// Multi-step container for sequential page navigation.
///
/// Example:
/// ```dart
/// PageView(
///   indicator: StepIndicator(),
///   pages: [WelcomePage(), FormPage(), SummaryPage()],
/// )
/// ```
class PageView extends View {
  final List<Page> pages;
  final PageIndicator? indicator;

  int _currentIndex = 0;
  final Map<int, dynamic> _collectedData = {};
  final Set<int> _unlockedPages = {};

  int get currentIndex => _currentIndex;
  int get pageCount => pages.length;
  Page get currentPage => pages[_currentIndex];
  Set<int> get unlockedPages => Set.unmodifiable(_unlockedPages);

  PageView({required this.pages, this.indicator}) {
    if (pages.isEmpty) {
      throw ArgumentError('PageView requires at least one page');
    }

    // Make PageView focusable to receive keys
    focusable = true;

    // Attach pages to this PageView
    for (var page in pages) {
      page._pageView = this;
    }

    // Pages rendered via _PageContainer (indicator placed separately by user)
    children = [_PageContainer(this)];
  }

  @override
  bool onKey(String key) {
    // Forward keys to current page
    return currentPage.onKey(key);
  }

  /// Include current page's focusable views for Tab navigation
  @override
  List<View> get focusableViews {
    var result = <View>[];
    // Add self if focusable (for key forwarding)
    if (focusable) result.add(this);
    // Add current page's focusable children (e.g. NavigationBar buttons)
    result.addAll(currentPage.focusableViews);
    return result;
  }

  /// Navigate to next page if current page allows
  bool goNext() {
    if (_currentIndex >= pages.length - 1) return false;

    var page = currentPage;
    if (!page.canProceed()) return false;

    _collectedData[_currentIndex] = page.getData();
    page.onLeave();

    _currentIndex++;
    _updateIndicator();
    currentPage.onEnter();

    return true;
  }

  /// Navigate to previous page
  bool goPrev() {
    if (_currentIndex <= 0) return false;

    currentPage.onLeave();
    _currentIndex--;
    _updateIndicator();
    currentPage.onEnter();

    return true;
  }

  /// Navigate to specific page (must be unlocked)
  bool goTo(int index) {
    if (index < 0 || index >= pages.length) return false;
    if (index == _currentIndex) return false;
    if (!_unlockedPages.contains(index) && index > _currentIndex) return false;

    currentPage.onLeave();
    _currentIndex = index;
    _updateIndicator();
    currentPage.onEnter();

    return true;
  }

  /// Unlock a page for direct navigation
  void unlock(int index) {
    if (index >= 0 && index < pages.length) {
      _unlockedPages.add(index);
    }
  }

  /// Get collected data from a specific page
  T? getData<T>(int pageIndex) {
    return _collectedData[pageIndex] as T?;
  }

  /// Get all collected data
  Map<int, dynamic> getAllData() => Map.unmodifiable(_collectedData);

  void _updateIndicator() {
    indicator?.updateState(_currentIndex, pages.length, _unlockedPages);
  }

  @override
  void resize(Size size, Position position) {
    super.resize(size, position);
    _updateIndicator();
  }

  /// Called when PageView is first displayed
  void start() {
    currentPage.onEnter();
    _updateIndicator();
  }
}

/// Internal container that displays current page
class _PageContainer extends View {
  final PageView _pageView;

  _PageContainer(this._pageView);

  @override
  void render(Canvas canvas) {
    var page = _pageView.currentPage;
    page.resize(size, Position(0, 0));
    page.render(canvas);
  }
}
