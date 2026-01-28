import 'package:test/test.dart';
import 'package:tui/tui.dart';

/// Test page that tracks lifecycle calls
class TestPage extends Page {
  bool enterCalled = false;
  bool leaveCalled = false;
  bool _canProceed = true;
  dynamic _data;

  TestPage({bool canProceed = true, dynamic data}) {
    _canProceed = canProceed;
    _data = data;
  }

  @override
  void onEnter() {
    enterCalled = true;
  }

  @override
  void onLeave() {
    leaveCalled = true;
  }

  @override
  bool canProceed() => _canProceed;

  void setCanProceed(bool value) => _canProceed = value;

  @override
  dynamic getData() => _data;
}

void main() {
  group('PageView construction', () {
    test('requires at least one page', () {
      expect(() => PageView(pages: []), throwsArgumentError);
    });

    test('attaches pages to PageView', () {
      var page = TestPage();
      PageView(pages: [page]);
      expect(page.pageView, isNotNull);
    });

    test('starts at first page', () {
      var pages = [TestPage(), TestPage(), TestPage()];
      var pv = PageView(pages: pages);
      expect(pv.currentIndex, equals(0));
      expect(pv.currentPage, same(pages[0]));
    });

    test('reports correct page count', () {
      var pv = PageView(pages: [TestPage(), TestPage()]);
      expect(pv.pageCount, equals(2));
    });
  });

  group('PageView navigation', () {
    test('goNext moves to next page', () {
      var pages = [TestPage(), TestPage(), TestPage()];
      var pv = PageView(pages: pages);
      pv.start();

      expect(pv.goNext(), isTrue);
      expect(pv.currentIndex, equals(1));
    });

    test('goNext returns false at last page', () {
      var pv = PageView(pages: [TestPage(), TestPage()]);
      pv.start();

      pv.goNext();
      expect(pv.goNext(), isFalse);
      expect(pv.currentIndex, equals(1));
    });

    test('goPrev moves to previous page', () {
      var pages = [TestPage(), TestPage(), TestPage()];
      var pv = PageView(pages: pages);
      pv.start();
      pv.goNext();
      pv.goNext();

      expect(pv.goPrev(), isTrue);
      expect(pv.currentIndex, equals(1));
    });

    test('goPrev returns false at first page', () {
      var pv = PageView(pages: [TestPage(), TestPage()]);
      pv.start();

      expect(pv.goPrev(), isFalse);
      expect(pv.currentIndex, equals(0));
    });

    test('goTo navigates to unlocked page', () {
      var pv = PageView(pages: [TestPage(), TestPage(), TestPage()]);
      pv.start();
      pv.unlock(2);

      expect(pv.goTo(2), isTrue);
      expect(pv.currentIndex, equals(2));
    });

    test('goTo fails for locked future page', () {
      var pv = PageView(pages: [TestPage(), TestPage(), TestPage()]);
      pv.start();

      expect(pv.goTo(2), isFalse);
      expect(pv.currentIndex, equals(0));
    });

    test('goTo allows navigation to previous pages', () {
      var pv = PageView(pages: [TestPage(), TestPage(), TestPage()]);
      pv.start();
      pv.goNext();
      pv.goNext();

      expect(pv.goTo(0), isTrue);
      expect(pv.currentIndex, equals(0));
    });

    test('goTo returns false for same page', () {
      var pv = PageView(pages: [TestPage(), TestPage()]);
      pv.start();

      expect(pv.goTo(0), isFalse);
    });

    test('goTo returns false for invalid index', () {
      var pv = PageView(pages: [TestPage(), TestPage()]);
      pv.start();

      expect(pv.goTo(-1), isFalse);
      expect(pv.goTo(5), isFalse);
    });
  });

  group('PageView validation', () {
    test('goNext blocked when canProceed returns false', () {
      var page = TestPage(canProceed: false);
      var pv = PageView(pages: [page, TestPage()]);
      pv.start();

      expect(pv.goNext(), isFalse);
      expect(pv.currentIndex, equals(0));
    });

    test('goNext succeeds when canProceed returns true', () {
      var page = TestPage(canProceed: true);
      var pv = PageView(pages: [page, TestPage()]);
      pv.start();

      expect(pv.goNext(), isTrue);
      expect(pv.currentIndex, equals(1));
    });

    test('canProceed checked dynamically', () {
      var page = TestPage(canProceed: false);
      var pv = PageView(pages: [page, TestPage()]);
      pv.start();

      expect(pv.goNext(), isFalse);

      page.setCanProceed(true);
      expect(pv.goNext(), isTrue);
    });
  });

  group('PageView lifecycle', () {
    test('start calls onEnter on first page', () {
      var page = TestPage();
      var pv = PageView(pages: [page, TestPage()]);

      expect(page.enterCalled, isFalse);
      pv.start();
      expect(page.enterCalled, isTrue);
    });

    test('goNext calls onLeave then onEnter', () {
      var page1 = TestPage();
      var page2 = TestPage();
      var pv = PageView(pages: [page1, page2]);
      pv.start();

      pv.goNext();

      expect(page1.leaveCalled, isTrue);
      expect(page2.enterCalled, isTrue);
    });

    test('goPrev calls onLeave then onEnter', () {
      var page1 = TestPage();
      var page2 = TestPage();
      var pv = PageView(pages: [page1, page2]);
      pv.start();
      pv.goNext();

      // Reset tracking
      page1.enterCalled = false;
      page2.leaveCalled = false;

      pv.goPrev();

      expect(page2.leaveCalled, isTrue);
      expect(page1.enterCalled, isTrue);
    });

    test('failed goNext does not call lifecycle methods', () {
      var page1 = TestPage(canProceed: false);
      var page2 = TestPage();
      var pv = PageView(pages: [page1, page2]);
      pv.start();

      pv.goNext();

      expect(page1.leaveCalled, isFalse);
      expect(page2.enterCalled, isFalse);
    });
  });

  group('PageView data collection', () {
    test('getData returns page data after navigation', () {
      var page = TestPage(data: 'test-value');
      var pv = PageView(pages: [page, TestPage()]);
      pv.start();

      pv.goNext();

      expect(pv.getData<String>(0), equals('test-value'));
    });

    test('getData returns null for page not yet left', () {
      var page = TestPage(data: 'test-value');
      var pv = PageView(pages: [page, TestPage()]);
      pv.start();

      expect(pv.getData<String>(0), isNull);
    });

    test('getAllData returns all collected data', () {
      var page1 = TestPage(data: 'value1');
      var page2 = TestPage(data: {'key': 'value2'});
      var page3 = TestPage();
      var pv = PageView(pages: [page1, page2, page3]);
      pv.start();

      pv.goNext();
      pv.goNext();

      var allData = pv.getAllData();
      expect(allData[0], equals('value1'));
      expect(allData[1], equals({'key': 'value2'}));
      expect(allData.containsKey(2), isFalse);
    });

    test('getAllData returns unmodifiable map', () {
      var pv = PageView(pages: [TestPage(data: 'x'), TestPage()]);
      pv.start();
      pv.goNext();

      var allData = pv.getAllData();
      expect(() => allData[0] = 'modified', throwsUnsupportedError);
    });
  });

  group('PageView unlocking', () {
    test('unlock adds page to unlockedPages', () {
      var pv = PageView(pages: [TestPage(), TestPage(), TestPage()]);

      pv.unlock(2);

      expect(pv.unlockedPages.contains(2), isTrue);
    });

    test('unlock ignores invalid indices', () {
      var pv = PageView(pages: [TestPage(), TestPage()]);

      pv.unlock(-1);
      pv.unlock(10);

      expect(pv.unlockedPages, isEmpty);
    });

    test('unlockedPages returns unmodifiable set', () {
      var pv = PageView(pages: [TestPage(), TestPage()]);
      pv.unlock(1);

      expect(() => pv.unlockedPages.add(0), throwsUnsupportedError);
    });
  });

  group('Page access to PageView', () {
    test('page can access pageView after attachment', () {
      var page = TestPage();
      PageView(pages: [page]);

      expect(() => page.pageView, returnsNormally);
    });

    test('page throws when accessing pageView before attachment', () {
      var page = TestPage();

      expect(() => page.pageView, throwsStateError);
    });

    test('page can call goNext on pageView', () {
      var page1 = TestPage();
      var page2 = TestPage();
      var pv = PageView(pages: [page1, page2]);
      pv.start();

      page1.pageView.goNext();

      expect(pv.currentIndex, equals(1));
    });
  });

  group('PageIndicator', () {
    test('StepIndicator creates step display', () {
      var indicator = StepIndicator();
      indicator.updateState(1, 3, {});

      expect(indicator.current, equals(1));
      expect(indicator.total, equals(3));
      expect(indicator.text.isNotEmpty, isTrue);
    });

    test('DotIndicator creates dot display', () {
      var indicator = DotIndicator();
      indicator.updateState(0, 4, {});

      expect(indicator.text.isNotEmpty, isTrue);
    });

    test('TextIndicator uses default formatter', () {
      var indicator = TextIndicator();
      indicator.updateState(1, 3, {});

      expect(indicator.text.first.text, equals("Krok 2 z 3"));
    });

    test('TextIndicator uses custom formatter', () {
      var indicator = TextIndicator(
        formatter: (c, t) => "Step ${c + 1} of $t",
      );
      indicator.updateState(0, 5, {});

      expect(indicator.text.first.text, equals("Step 1 of 5"));
    });

    test('PageView updates indicator on navigation', () {
      var indicator = StepIndicator();
      var pv = PageView(
        pages: [TestPage(), TestPage(), TestPage()],
        indicator: indicator,
      );
      pv.start();

      expect(indicator.current, equals(0));

      pv.goNext();
      expect(indicator.current, equals(1));

      pv.goNext();
      expect(indicator.current, equals(2));
    });
  });

  group('Button widget', () {
    test('button is focusable', () {
      var button = Button('Test');
      expect(button.focusable, isTrue);
    });

    test('button calls onPressed on Enter', () {
      var pressed = false;
      var button = Button('Test', onPressed: () => pressed = true);

      button.onKey(KeyCode.ENTER);

      expect(pressed, isTrue);
    });

    test('button calls onPressed on Space', () {
      var pressed = false;
      var button = Button('Test', onPressed: () => pressed = true);

      button.onKey(' ');

      expect(pressed, isTrue);
    });

    test('button ignores other keys', () {
      var pressed = false;
      var button = Button('Test', onPressed: () => pressed = true);

      var handled = button.onKey('x');

      expect(pressed, isFalse);
      expect(handled, isFalse);
    });

    test('displayWidth includes brackets and spaces', () {
      var button = Button('OK');
      expect(button.displayWidth, equals(6)); // "[ OK ]"
    });
  });

  group('NavigationBar widget', () {
    test('creates next button', () {
      var page = TestPage();
      PageView(pages: [page, TestPage()]);

      var nav = NavigationBar(page, prevLabel: null);

      expect(nav.children.length, equals(1));
    });

    test('creates prev and next buttons', () {
      var page = TestPage();
      PageView(pages: [page, TestPage()]);

      var nav = NavigationBar(page);

      expect(nav.children.length, equals(2));
    });

    test('next button triggers goNext', () {
      var page1 = TestPage();
      var page2 = TestPage();
      var pv = PageView(pages: [page1, page2]);
      pv.start();

      var nav = NavigationBar(page1);
      var nextButton = nav.children.last as Button;

      nextButton.onPressed?.call();

      expect(pv.currentIndex, equals(1));
    });

    test('prev button triggers goPrev', () {
      var page1 = TestPage();
      var page2 = TestPage();
      var pv = PageView(pages: [page1, page2]);
      pv.start();
      pv.goNext();

      var nav = NavigationBar(page2);
      var prevButton = nav.children.first as Button;

      prevButton.onPressed?.call();

      expect(pv.currentIndex, equals(0));
    });
  });
}
