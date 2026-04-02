import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('InputParser', () {
    late List<String> keys;
    late List<String> pastes;
    late InputParser parser;

    setUp(() {
      keys = [];
      pastes = [];
      parser = InputParser(
        onKey: (k) => keys.add(k),
        onPaste: (t) => pastes.add(t),
      );
    });

    group('single characters', () {
      test('emits printable ASCII one at a time', () {
        parser.feed('abc');
        expect(keys, equals(['a', 'b', 'c']));
      });

      test('emits space', () {
        parser.feed(' ');
        expect(keys, equals([' ']));
      });

      test('emits control characters that are not ESC', () {
        parser.feed('\n');
        expect(keys, equals(['\n']));
      });

      test('emits tab', () {
        parser.feed('\t');
        expect(keys, equals(['\t']));
      });

      test('emits backspace (0x7f)', () {
        parser.feed('\x7f');
        expect(keys, equals(['\x7f']));
      });
    });

    group('CSI escape sequences', () {
      test('parses arrow keys', () {
        parser.feed('\x1b[A');
        expect(keys, equals(['\x1b[A']));
      });

      test('parses multiple escape sequences in one chunk', () {
        parser.feed('\x1b[A\x1b[B');
        expect(keys, equals(['\x1b[A', '\x1b[B']));
      });

      test('parses delete key (CSI with tilde)', () {
        parser.feed('\x1b[3~');
        expect(keys, equals(['\x1b[3~']));
      });

      test('parses page down (CSI 6~)', () {
        parser.feed('\x1b[6~');
        expect(keys, equals(['\x1b[6~']));
      });

      test('parses shift-tab (CSI Z)', () {
        parser.feed('\x1b[Z');
        expect(keys, equals(['\x1b[Z']));
      });

      test('parses sequence followed by regular chars', () {
        parser.feed('\x1b[Aabc');
        expect(keys, equals(['\x1b[A', 'a', 'b', 'c']));
      });

      test('parses regular chars followed by sequence', () {
        parser.feed('xy\x1b[B');
        expect(keys, equals(['x', 'y', '\x1b[B']));
      });

      test('parses CSI with semicolon parameters', () {
        parser.feed('\x1b[1;5C'); // Ctrl+Right in many terminals
        expect(keys, equals(['\x1b[1;5C']));
      });
    });

    group('bracketed paste', () {
      test('detects paste and emits via onPaste', () {
        parser.feed('\x1b[200~hello world\x1b[201~');
        expect(keys, isEmpty);
        expect(pastes, equals(['hello world']));
      });

      test('paste with newlines', () {
        parser.feed('\x1b[200~line1\nline2\nline3\x1b[201~');
        expect(pastes, equals(['line1\nline2\nline3']));
      });

      test('paste followed by regular key', () {
        parser.feed('\x1b[200~pasted\x1b[201~a');
        expect(pastes, equals(['pasted']));
        expect(keys, equals(['a']));
      });

      test('regular key followed by paste', () {
        parser.feed('x\x1b[200~pasted\x1b[201~');
        expect(keys, equals(['x']));
        expect(pastes, equals(['pasted']));
      });

      test('paste split across chunks', () {
        parser.feed('\x1b[200~hel');
        expect(pastes, isEmpty);

        parser.feed('lo\x1b[201~');
        expect(pastes, equals(['hello']));
      });

      test('paste end marker split across chunks', () {
        parser.feed('\x1b[200~text\x1b');
        expect(pastes, isEmpty);

        parser.feed('[201~');
        expect(pastes, equals(['text']));
      });

      test('empty paste', () {
        parser.feed('\x1b[200~\x1b[201~');
        expect(pastes, equals(['']));
      });

      test('paste with escape chars that are not end marker', () {
        parser.feed('\x1b[200~has \x1b in it\x1b[201~');
        expect(pastes, equals(['has \x1b in it']));
      });
    });

    group('incomplete sequences and timeout', () {
      test('buffers lone ESC until more data arrives', () {
        parser.feed('\x1b');
        expect(keys, isEmpty, reason: 'ESC should be buffered');

        parser.feed('[A');
        expect(keys, equals(['\x1b[A']));
      });

      test('buffers incomplete CSI until completed', () {
        parser.feed('\x1b[');
        expect(keys, isEmpty);

        parser.feed('3~');
        expect(keys, equals(['\x1b[3~']));
      });

      test('lone ESC emits after timeout', () async {
        parser.feed('\x1b');
        expect(keys, isEmpty);

        // Wait for timeout to fire
        await Future.delayed(Duration(milliseconds: 80));
        expect(keys, equals(['\x1b']));
      });

      test('incomplete CSI flushes after timeout', () async {
        parser.feed('\x1b[');
        expect(keys, isEmpty);

        await Future.delayed(Duration(milliseconds: 80));
        expect(keys, equals(['\x1b', '[']));
      });

      test('timeout is cancelled when more data arrives', () async {
        parser.feed('\x1b');
        expect(keys, isEmpty);

        // Data arrives before timeout
        await Future.delayed(Duration(milliseconds: 10));
        parser.feed('[B');
        expect(keys, equals(['\x1b[B']));

        // Wait past timeout — no extra ESC should appear
        await Future.delayed(Duration(milliseconds: 80));
        expect(keys, equals(['\x1b[B']));
      });

      test('arrow key split across two chunks', () {
        parser.feed('\x1b');
        parser.feed('[A');
        expect(keys, equals(['\x1b[A']));
      });

      test('delete key split across three chunks', () {
        parser.feed('\x1b');
        parser.feed('[3');
        parser.feed('~');
        expect(keys, equals(['\x1b[3~']));
      });
    });
  });
}
