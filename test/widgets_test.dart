import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('Input', () {
    late Input input;

    setUp(() {
      input = Input(placeholder: 'Enter text...');
      input.size = Size(40, 1);
    });

    test('starts empty with cursor at 0', () {
      expect(input.value, isEmpty);
      expect(input.cursorPosition, equals(0));
    });

    test('is focusable by default', () {
      expect(input.focusable, isTrue);
    });

    test('handles character input', () {
      input.onKey('h');
      input.onKey('i');
      expect(input.value, equals('hi'));
      expect(input.cursorPosition, equals(2));
    });

    test('handles backspace', () {
      input.value = 'hello';
      input.cursorPosition = 5;
      input.onKey(KeyCode.BACKSPACE);
      expect(input.value, equals('hell'));
      expect(input.cursorPosition, equals(4));
    });

    test('handles delete', () {
      input.value = 'hello';
      input.cursorPosition = 0;
      input.onKey(KeyCode.DEL);
      expect(input.value, equals('ello'));
      expect(input.cursorPosition, equals(0));
    });

    test('handles left arrow', () {
      input.value = 'hello';
      input.cursorPosition = 3;
      input.onKey(KeyCode.LEFT);
      expect(input.cursorPosition, equals(2));
    });

    test('handles right arrow', () {
      input.value = 'hello';
      input.cursorPosition = 2;
      input.onKey(KeyCode.RIGHT);
      expect(input.cursorPosition, equals(3));
    });

    test('handles home key', () {
      input.value = 'hello';
      input.cursorPosition = 3;
      input.onKey(KeyCode.HOME);
      expect(input.cursorPosition, equals(0));
    });

    test('handles end key', () {
      input.value = 'hello';
      input.cursorPosition = 0;
      input.onKey(KeyCode.END);
      expect(input.cursorPosition, equals(5));
    });

    test('respects maxLength', () {
      input.maxLength = 5;
      input.value = '';
      for (var c in 'hello world'.split('')) {
        input.onKey(c);
      }
      expect(input.value, equals('hello'));
    });

    test('calls onSubmit on enter', () {
      String? submitted;
      input.onSubmit = (v) => submitted = v;
      input.value = 'test';
      input.onKey(KeyCode.ENTER);
      expect(submitted, equals('test'));
    });

    test('calls onChange on input', () {
      String? changed;
      input.onChange = (v) => changed = v;
      input.onKey('a');
      expect(changed, equals('a'));
    });
  });

  group('Select', () {
    late Select<String> select;

    setUp(() {
      select = Select(
        options: ['Apple', 'Banana', 'Cherry'],
      );
      select.size = Size(30, 10);
    });

    test('starts with first item selected', () {
      expect(select.selectedIndex, equals(0));
    });

    test('is focusable by default', () {
      expect(select.focusable, isTrue);
    });

    test('moves down with down arrow', () {
      select.onKey(KeyCode.DOWN);
      expect(select.selectedIndex, equals(1));
    });

    test('moves up with up arrow', () {
      select.selectedIndex = 2;
      select.onKey(KeyCode.UP);
      expect(select.selectedIndex, equals(1));
    });

    test('does not go below 0', () {
      select.selectedIndex = 0;
      select.onKey(KeyCode.UP);
      expect(select.selectedIndex, equals(0));
    });

    test('does not exceed last index', () {
      select.selectedIndex = 2;
      select.onKey(KeyCode.DOWN);
      expect(select.selectedIndex, equals(2));
    });

    test('home goes to first', () {
      select.selectedIndex = 2;
      select.onKey(KeyCode.HOME);
      expect(select.selectedIndex, equals(0));
    });

    test('end goes to last', () {
      select.selectedIndex = 0;
      select.onKey(KeyCode.END);
      expect(select.selectedIndex, equals(2));
    });

    test('calls onSelect on enter', () {
      String? selected;
      select.onSelect = (v) => selected = v;
      select.selectedIndex = 1;
      select.onKey(KeyCode.ENTER);
      expect(selected, equals('Banana'));
    });

    test('multiSelect toggles with space', () {
      select.multiSelect = true;
      select.onKey(KeyCode.SPACE);
      expect(select.selectedIndices.contains(0), isTrue);

      select.onKey(KeyCode.SPACE);
      expect(select.selectedIndices.contains(0), isFalse);
    });

    test('multiSelect respects limit', () {
      select.multiSelect = true;
      select.limit = 2;

      select.onKey(KeyCode.SPACE); // Select 0
      select.onKey(KeyCode.DOWN);
      select.onKey(KeyCode.SPACE); // Select 1
      select.onKey(KeyCode.DOWN);
      select.onKey(KeyCode.SPACE); // Try select 2 (should fail)

      expect(select.selectedIndices.length, equals(2));
      expect(select.selectedIndices.contains(2), isFalse);
    });
  });

  group('Confirm', () {
    late Confirm confirm;

    setUp(() {
      confirm = Confirm(message: 'Are you sure?');
      confirm.size = Size(40, 2);
    });

    test('starts with Yes selected', () {
      expect(confirm.selected, isTrue);
    });

    test('is focusable by default', () {
      expect(confirm.focusable, isTrue);
    });

    test('left arrow selects Yes', () {
      confirm.selected = false;
      confirm.onKey(KeyCode.LEFT);
      expect(confirm.selected, isTrue);
    });

    test('right arrow selects No', () {
      confirm.selected = true;
      confirm.onKey(KeyCode.RIGHT);
      expect(confirm.selected, isFalse);
    });

    test('y selects Yes', () {
      confirm.selected = false;
      confirm.onKey('y');
      expect(confirm.selected, isTrue);
    });

    test('n selects No', () {
      confirm.selected = true;
      confirm.onKey('n');
      expect(confirm.selected, isFalse);
    });

    test('tab toggles selection', () {
      confirm.selected = true;
      confirm.onKey(KeyCode.TAB);
      expect(confirm.selected, isFalse);
      confirm.onKey(KeyCode.TAB);
      expect(confirm.selected, isTrue);
    });

    test('calls onConfirm with result on enter', () {
      bool? result;
      confirm.onConfirm = (r) => result = r;
      confirm.selected = false;
      confirm.onKey(KeyCode.ENTER);
      expect(result, isFalse);
    });
  });

  group('TextArea', () {
    late TextArea textarea;

    setUp(() {
      textarea = TextArea();
      textarea.size = Size(40, 10);
    });

    test('starts with empty line', () {
      expect(textarea.value, isEmpty);
      expect(textarea.cursorX, equals(0));
      expect(textarea.cursorY, equals(0));
    });

    test('is focusable by default', () {
      expect(textarea.focusable, isTrue);
    });

    test('handles character input', () {
      textarea.onKey('h');
      textarea.onKey('i');
      expect(textarea.value, equals('hi'));
    });

    test('handles enter to create new line', () {
      textarea.value = 'hello';
      textarea.cursorX = 5;
      textarea.onKey(KeyCode.ENTER);
      expect(textarea.value, equals('hello\n'));
      expect(textarea.cursorY, equals(1));
      expect(textarea.cursorX, equals(0));
    });

    test('handles enter in middle of line', () {
      textarea.value = 'hello world';
      textarea.cursorX = 5;
      textarea.cursorY = 0;
      textarea.onKey(KeyCode.ENTER);
      expect(textarea.value, equals('hello\n world'));
    });

    test('handles up/down navigation', () {
      textarea.value = 'line1\nline2\nline3';
      textarea.cursorY = 1;
      textarea.cursorX = 2;

      textarea.onKey(KeyCode.UP);
      expect(textarea.cursorY, equals(0));

      textarea.onKey(KeyCode.DOWN);
      expect(textarea.cursorY, equals(1));
    });

    test('handles backspace at line start (merge lines)', () {
      textarea.value = 'hello\nworld';
      textarea.cursorY = 1;
      textarea.cursorX = 0;
      textarea.onKey(KeyCode.BACKSPACE);
      expect(textarea.value, equals('helloworld'));
      expect(textarea.cursorY, equals(0));
      expect(textarea.cursorX, equals(5));
    });

    test('respects maxLines', () {
      textarea.maxLines = 2;
      textarea.value = 'line1';
      textarea.cursorX = 5;
      textarea.onKey(KeyCode.ENTER);
      textarea.onKey(KeyCode.ENTER); // Should not add third line
      expect(textarea.value.split('\n').length, equals(2));
    });
  });

  group('Spinner', () {
    late Spinner spinner;

    setUp(() {
      spinner = Spinner(label: 'Loading...');
      spinner.size = Size(20, 1);
    });

    test('starts stopped', () {
      expect(spinner.running, isFalse);
    });

    test('start sets running to true', () {
      spinner.start();
      expect(spinner.running, isTrue);
      spinner.stop();
    });

    test('stop sets running to false', () {
      spinner.start();
      spinner.stop();
      expect(spinner.running, isFalse);
    });

    test('has multiple styles available', () {
      expect(SpinnerStyle.values.length, greaterThan(5));
    });
  });

  group('Table', () {
    late Table<List<String>> table;

    setUp(() {
      table = Table(
        columns: [
          TableColumn('Name', width: 10),
          TableColumn('Age', width: 5),
        ],
        rows: [
          ['Alice', '30'],
          ['Bob', '25'],
          ['Charlie', '35'],
        ],
        rowBuilder: (row) => row,
      );
      table.size = Size(30, 10);
    });

    test('starts with first row selected', () {
      expect(table.selectedRow, equals(0));
    });

    test('is focusable when selectable', () {
      expect(table.focusable, isTrue);
    });

    test('is not focusable when created with selectable=false', () {
      var nonSelectableTable = Table(
        columns: [TableColumn('Name', width: 10)],
        rows: [['Alice']],
        rowBuilder: (row) => row,
        selectable: false,
      );
      expect(nonSelectableTable.focusable, isFalse);
    });

    test('moves down with down arrow', () {
      table.onKey(KeyCode.DOWN);
      expect(table.selectedRow, equals(1));
    });

    test('moves up with up arrow', () {
      table.selectedRow = 2;
      table.onKey(KeyCode.UP);
      expect(table.selectedRow, equals(1));
    });

    test('home goes to first row', () {
      table.selectedRow = 2;
      table.onKey(KeyCode.HOME);
      expect(table.selectedRow, equals(0));
    });

    test('end goes to last row', () {
      table.selectedRow = 0;
      table.onKey(KeyCode.END);
      expect(table.selectedRow, equals(2));
    });

    test('calls onSelect on enter', () {
      List<String>? selected;
      table.onSelect = (row) => selected = row;
      table.selectedRow = 1;
      table.onKey(KeyCode.ENTER);
      expect(selected, equals(['Bob', '25']));
    });

    test('has multiple border styles', () {
      expect(TableBorder.values.length, greaterThan(3));
    });
  });
}
