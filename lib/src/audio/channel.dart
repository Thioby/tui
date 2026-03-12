part of tui;

/// Organizes audio playback into named channels.
///
/// Each channel plays one sound at a time — new playback replaces the old.
class Audio {
  final Map<String, AudioChannel> _channels = {};
  final AudioPlayer _player = AudioPlayer();
  bool muted = false;

  bool get isAvailable => _player.isAvailable;

  AudioChannel channel(String name) {
    return _channels.putIfAbsent(name, () => AudioChannel._(this));
  }

  void beep({double frequency = 440.0, double duration = 0.15, Waveform waveform = Waveform.sine}) {
    channel('sfx').tone(frequency: frequency, duration: duration, waveform: waveform);
  }

  void stopAll() {
    for (final ch in _channels.values) {
      ch.stop();
    }
  }

  void dispose() {
    stopAll();
    _channels.clear();
  }
}

/// A named audio channel — plays one sound at a time.
class AudioChannel {
  final Audio _audio;
  AudioPlayer? _currentPlayer;

  AudioChannel._(this._audio);

  void tone({
    required double frequency,
    double duration = 0.3,
    Waveform waveform = Waveform.sine,
    Envelope? envelope,
    double volume = 1.0,
  }) {
    _play(Synthesizer.tone(
        frequency: frequency, duration: duration, waveform: waveform, envelope: envelope, volume: volume));
  }

  void playMelody(Melody melody) => _play(melody.toSamples());

  void play(String dsl, {int bpm = 120}) => playMelody(Melody.parse(dsl, bpm: bpm));

  void stop() {
    _currentPlayer?.stop();
    _currentPlayer = null;
  }

  void _play(Float64List samples) {
    if (_audio.muted || !_audio.isAvailable) return;
    stop();

    final player = AudioPlayer();
    _currentPlayer = player;

    player.playWav(WavWriter.encode(samples)).whenComplete(() {
      if (_currentPlayer == player) _currentPlayer = null;
    });
  }
}
