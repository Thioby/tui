part of tui;

class InputParser {
  final void Function(String key) onKey;
  final void Function(String text) onPaste;

  String _buf = '';
  Timer? _escTimer;
  bool _inPaste = false;
  final StringBuffer _pasteBuf = StringBuffer();

  static final _csiPattern = RegExp(r'\x1b\[[0-9;]*[A-Za-z~]');
  static const _escTimeout = Duration(milliseconds: 50);
  static const _pasteStart = '\x1b[200~';
  static const _pasteEnd = '\x1b[201~';

  InputParser({required this.onKey, required this.onPaste});

  void feed(String data) {
    _escTimer?.cancel();
    _buf += data;
    _parse();
  }

  void _parse() {
    while (_buf.isNotEmpty) {
      if (_inPaste) {
        _parsePaste();
        return;
      }

      if (_buf[0] == '\x1b') {
        if (!_parseEscape()) {
          _escTimer = Timer(_escTimeout, _flushBuf);
          return;
        }
        continue;
      }

      var char = String.fromCharCode(_buf.runes.first);
      onKey(char);
      _buf = _buf.substring(char.length);
    }
  }

  bool _parseEscape() {
    if (_buf.length < 2) return false;

    if (_buf[1] == '[') {
      return _parseCsi();
    }

    onKey('\x1b');
    _buf = _buf.substring(1);
    return true;
  }

  bool _parseCsi() {
    var match = _csiPattern.matchAsPrefix(_buf);
    if (match == null) {
      if (_buf.length > 20) {
        onKey('\x1b');
        _buf = _buf.substring(1);
        return true;
      }
      return false;
    }

    var seq = match.group(0)!;
    _buf = _buf.substring(seq.length);

    if (seq == _pasteStart) {
      _inPaste = true;
      _parsePaste();
      return true;
    }

    onKey(seq);
    return true;
  }

  void _parsePaste() {
    while (_buf.isNotEmpty) {
      var escIdx = _buf.indexOf('\x1b');

      if (escIdx == -1) {
        _pasteBuf.write(_buf);
        _buf = '';
        return;
      }

      if (escIdx > 0) {
        _pasteBuf.write(_buf.substring(0, escIdx));
        _buf = _buf.substring(escIdx);
      }

      if (_buf.length < _pasteEnd.length) {
        // Might be partial end marker — wait for more data
        return;
      }

      if (_buf.startsWith(_pasteEnd)) {
        _buf = _buf.substring(_pasteEnd.length);
        _inPaste = false;
        onPaste(_pasteBuf.toString());
        _pasteBuf.clear();
        return;
      }

      // Not the end marker — add ESC to paste content and continue
      _pasteBuf.write(_buf[0]);
      _buf = _buf.substring(1);
    }
  }

  void _flushBuf() {
    if (_buf.isEmpty) return;
    onKey(_buf[0]);
    _buf = _buf.substring(1);
    _parse();
  }

  void dispose() {
    _escTimer?.cancel();
  }
}
