part of tui;

/// Ornament extensions for [Melody]: trill, mordent, turn, grace note.
///
/// Each ornament expands into multiple short [NoteEvent]s so the
/// existing synthesis pipeline handles them without modification.
extension MelodyOrnaments on Melody {
  /// Trill: rapid alternation between [frequency] and the note above.
  ///
  /// [semitones] controls interval (default 2 = whole step).
  void trill(
    double frequency,
    double beats, {
    int semitones = 2,
    Waveform? waveform,
    double? volume,
  }) {
    final upper = frequency * pow(2.0, semitones / 12.0);
    final noteCount = max(4, (beats / Dur.thirtySecond).round());
    final noteDur = beats / noteCount;
    for (var i = 0; i < noteCount; i++) {
      note(i.isEven ? frequency : upper, noteDur,
          waveform: waveform, volume: volume);
    }
  }

  /// Mordent: quick alternation down-up-principal.
  ///
  /// First 1/4 of duration is the ornament, rest is the main note.
  void mordent(
    double frequency,
    double beats, {
    int semitones = 2,
    Waveform? waveform,
    double? volume,
  }) {
    final lower = frequency / pow(2.0, semitones / 12.0);
    final ornDur = beats * 0.25;
    final mainDur = beats - ornDur;
    final triplet = ornDur / 3.0;

    note(frequency, triplet, waveform: waveform, volume: volume);
    note(lower, triplet, waveform: waveform, volume: volume);
    note(frequency, triplet, waveform: waveform, volume: volume);
    note(frequency, mainDur, waveform: waveform, volume: volume);
  }

  /// Turn: 4-note ornament — upper, principal, lower, principal.
  ///
  /// First 1/3 of duration is the ornament, rest is the main note.
  void turn(
    double frequency,
    double beats, {
    int semitones = 2,
    Waveform? waveform,
    double? volume,
  }) {
    final upper = frequency * pow(2.0, semitones / 12.0);
    final lower = frequency / pow(2.0, semitones / 12.0);
    final ornDur = beats * 0.333;
    final mainDur = beats - ornDur;
    final quarter = ornDur / 4.0;

    note(upper, quarter, waveform: waveform, volume: volume);
    note(frequency, quarter, waveform: waveform, volume: volume);
    note(lower, quarter, waveform: waveform, volume: volume);
    note(frequency, quarter, waveform: waveform, volume: volume);
    note(frequency, mainDur, waveform: waveform, volume: volume);
  }

  /// Grace note: very short note leading into the principal note.
  void graceNote(
    double graceFrequency,
    double mainFrequency,
    double beats, {
    Waveform? waveform,
    double? volume,
  }) {
    final graceDur = min(beats * 0.12, Dur.thirtySecond);
    note(graceFrequency, graceDur, waveform: waveform, volume: volume);
    note(mainFrequency, beats - graceDur, waveform: waveform, volume: volume);
  }
}
