part of tui;

/// Plays WAV audio via platform commands (afplay / aplay / PowerShell).
class AudioPlayer {
  Process? _process;
  String? _tempPath;

  static List<String>? get _command {
    if (Platform.isMacOS) return ['afplay'];
    if (Platform.isLinux) return ['aplay', '-q'];
    if (Platform.isWindows) return ['powershell', '-c', '(New-Object Media.SoundPlayer "{path}").PlaySync()'];
    return null;
  }

  bool get isAvailable => _command != null;

  Future<void> playWav(Uint8List wavBytes) async {
    final cmd = _command;
    if (cmd == null) throw StateError('No audio player available on this platform');

    final tempDir = await Directory.systemTemp.createTemp('tui_audio_');
    final tempFile = File('${tempDir.path}/playback.wav');
    _tempPath = tempFile.path;
    await tempFile.writeAsBytes(wavBytes);

    try {
      final List<String> args;
      if (Platform.isWindows) {
        args = cmd.map((s) => s.replaceAll('{path}', tempFile.path)).toList();
      } else {
        args = [...cmd, tempFile.path];
      }

      _process = await Process.start(args.first, args.skip(1).toList());
      await _process!.exitCode;
    } finally {
      _process = null;
      await _cleanup();
    }
  }

  void stop() {
    final proc = _process;
    if (proc != null) {
      proc.kill();
      _process = null;
    }
    _cleanupSync();
  }

  Future<void> _cleanup() async {
    final path = _tempPath;
    if (path != null) {
      _tempPath = null;
      try {
        final file = File(path);
        if (await file.exists()) await file.parent.delete(recursive: true);
      } catch (_) {}
    }
  }

  void _cleanupSync() {
    final path = _tempPath;
    if (path != null) {
      _tempPath = null;
      try {
        final file = File(path);
        if (file.existsSync()) file.parent.deleteSync(recursive: true);
      } catch (_) {}
    }
  }
}
