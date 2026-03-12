part of tui;

/// Preset sound effects for games and UI.
enum SFX {
  beep,
  click,
  success,
  error,
  powerUp,
  explosion,
  coin,
  jump;

  Melody get melody {
    final m = Melody(bpm: 240, waveform: Waveform.sine);
    switch (this) {
      case SFX.beep:
        m.note(Note.A4, Dur.quarter);
      case SFX.click:
        m.note(Note.C6, Dur.sixteenth);
      case SFX.success:
        m.note(Note.C5, Dur.eighth);
        m.note(Note.E5, Dur.eighth);
        m.note(Note.G5, Dur.eighth);
        m.note(Note.C6, Dur.quarter);
      case SFX.error:
        m.note(Note.E4, Dur.eighth);
        m.note(Note.C4, Dur.eighth);
        m.note(Note.A3, Dur.quarter);
      case SFX.powerUp:
        m.note(Note.C4, Dur.sixteenth);
        m.note(Note.D4, Dur.sixteenth);
        m.note(Note.E4, Dur.sixteenth);
        m.note(Note.F4, Dur.sixteenth);
        m.note(Note.G4, Dur.sixteenth);
        m.note(Note.A4, Dur.sixteenth);
        m.note(Note.B4, Dur.sixteenth);
        m.note(Note.C5, Dur.sixteenth);
      case SFX.explosion:
        m.waveform = Waveform.noise;
        m.note(Note.C2, Dur.half);
      case SFX.coin:
        m.note(Note.B5, Dur.eighth);
        m.note(Note.E6, Dur.quarter);
      case SFX.jump:
        m.note(Note.C4, Dur.sixteenth);
        m.note(Note.E4, Dur.sixteenth);
        m.note(Note.G4, Dur.eighth);
    }
    return m;
  }

  Float64List toSamples({int sampleRate = 44100}) => melody.toSamples(sampleRate: sampleRate);

  void playOn(AudioChannel channel) => channel.playMelody(melody);
}
