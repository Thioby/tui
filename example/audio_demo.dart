import 'package:tui/tui.dart';

Future<void> _wait(double seconds) => Future.delayed(Duration(milliseconds: (seconds * 1000).round()));

// Für Elise — opening motif, Section A
const _furEliseA = '''
  E5.e Ds5.e E5.e Ds5.e E5.e B4.e D5.e C5.e |
  A4.q R.e C4.e E4.e A4.e |
  B4.q R.e E4.e Gs4.e B4.e |
  C5.q R.e E4.e E5.e Ds5.e |
  E5.e Ds5.e E5.e B4.e D5.e C5.e |
  A4.q R.e C4.e E4.e A4.e |
  B4.q R.e E4.e C5.e B4.e |
  A4.h
''';

// Section B — contrasting theme
const _furEliseB = '''
  B4.e C5.e D5.e E5.e |
  F5.q R.e D5.e F5.e E5.e |
  E5.q R.e C5.e E5.e D5.e |
  D5.q R.e B4.e D5.e C5.e
''';

void main() async {
  final audio = Audio();
  if (!audio.isAvailable) {
    print('No audio player found.');
    return;
  }

  final sfx = audio.channel('sfx');
  final music = audio.channel('music');

  print('');
  print('  ╔══════════════════════════════════════════════════════╗');
  print('  ║        TUI Audio Engine — Feature Showcase          ║');
  print('  ╚══════════════════════════════════════════════════════╝');
  print('');

  // ── 1. SFX Presets ──────────────────────────────────────────
  print('  ▸ SFX Presets');
  for (final preset in SFX.values) {
    print('    ${preset.name}');
    preset.playOn(sfx);
    await _wait(0.6);
  }
  print('');

  // ── 2. Waveform Gallery ─────────────────────────────────────
  print('  ▸ Waveform Gallery (A4 = 440 Hz)');
  for (final wf in Waveform.values.where((w) => w != Waveform.noise)) {
    print('    ${wf.name}');
    sfx.tone(frequency: Note.A4, duration: 0.4, waveform: wf);
    await _wait(0.6);
  }
  print('');

  // ── 3. ADSR Envelope Comparison ─────────────────────────────
  print('  ▸ Envelope Comparison (same note, different ADSR)');

  print('    staccato (short attack, no sustain)');
  sfx.tone(
    frequency: Note.C5,
    duration: 0.3,
    waveform: Waveform.square,
    envelope: Envelope(attack: 0.005, decay: 0.1, sustain: 0.0, release: 0.01),
  );
  await _wait(0.5);

  print('    legato (slow attack, full sustain)');
  sfx.tone(
    frequency: Note.C5,
    duration: 0.6,
    waveform: Waveform.sine,
    envelope: Envelope(attack: 0.15, decay: 0.05, sustain: 0.8, release: 0.2),
  );
  await _wait(0.9);

  print('    pluck (fast attack, quick decay)');
  sfx.tone(
    frequency: Note.C5,
    duration: 0.4,
    waveform: Waveform.triangle,
    envelope: Envelope(attack: 0.001, decay: 0.2, sustain: 0.1, release: 0.15),
  );
  await _wait(0.6);

  print('    pad (very slow everything)');
  sfx.tone(
    frequency: Note.C5,
    duration: 1.0,
    waveform: Waveform.sawtooth,
    envelope: Envelope(attack: 0.3, decay: 0.2, sustain: 0.5, release: 0.3),
  );
  await _wait(1.3);
  print('');

  // ── 4. Synthesizer.mix — Layered chord ──────────────────────
  print('  ▸ Synthesizer.mix — C major chord (3 tones layered)');
  final env = Envelope(attack: 0.02, decay: 0.1, sustain: 0.4, release: 0.2);
  final c = Synthesizer.tone(frequency: Note.C4, duration: 1.0, waveform: Waveform.sine, envelope: env, volume: 0.5);
  final e = Synthesizer.tone(frequency: Note.E4, duration: 1.0, waveform: Waveform.sine, envelope: env, volume: 0.5);
  final g = Synthesizer.tone(frequency: Note.G4, duration: 1.0, waveform: Waveform.sine, envelope: env, volume: 0.5);
  final chord = Synthesizer.mix([c, e, g]);
  sfx.playMelody(Melody(bpm: 60)..note(Note.C4, Dur.whole)); // dummy, we play raw below
  sfx.stop();
  // play the raw mixed chord directly
  final player = AudioPlayer();
  await player.playWav(WavWriter.encode(chord));
  print('');

  // ── 5. Melody Builder — Für Elise theme ─────────────────────
  print('  ▸ Melody Builder — Für Elise, Section A (square wave, chiptune)');
  final eliseBuilder = Melody(bpm: 180, waveform: Waveform.square, volume: 0.6);
  // The famous motif
  void motif(Melody m) {
    m.note(Note.E5, Dur.eighth);
    m.note(Note.Ds5, Dur.eighth);
    m.note(Note.E5, Dur.eighth);
    m.note(Note.Ds5, Dur.eighth);
    m.note(Note.E5, Dur.eighth);
    m.note(Note.B4, Dur.eighth);
    m.note(Note.D5, Dur.eighth);
    m.note(Note.C5, Dur.eighth);
  }

  motif(eliseBuilder);
  eliseBuilder.note(Note.A4, Dur.quarter);
  eliseBuilder.rest(Dur.eighth);
  eliseBuilder.note(Note.C4, Dur.eighth);
  eliseBuilder.note(Note.E4, Dur.eighth);
  eliseBuilder.note(Note.A4, Dur.eighth);
  eliseBuilder.note(Note.B4, Dur.quarter);
  eliseBuilder.rest(Dur.eighth);
  eliseBuilder.note(Note.E4, Dur.eighth);
  eliseBuilder.note(Note.Gs4, Dur.eighth);
  eliseBuilder.note(Note.B4, Dur.eighth);
  eliseBuilder.note(Note.C5, Dur.quarter);
  eliseBuilder.rest(Dur.eighth);
  eliseBuilder.note(Note.E4, Dur.eighth);
  eliseBuilder.note(Note.E5, Dur.eighth);
  eliseBuilder.note(Note.Ds5, Dur.eighth);
  motif(eliseBuilder);
  eliseBuilder.note(Note.A4, Dur.quarter);
  eliseBuilder.rest(Dur.eighth);
  eliseBuilder.note(Note.C4, Dur.eighth);
  eliseBuilder.note(Note.E4, Dur.eighth);
  eliseBuilder.note(Note.A4, Dur.eighth);
  eliseBuilder.note(Note.B4, Dur.quarter);
  eliseBuilder.rest(Dur.eighth);
  eliseBuilder.note(Note.E4, Dur.eighth);
  eliseBuilder.note(Note.C5, Dur.eighth);
  eliseBuilder.note(Note.B4, Dur.eighth);
  eliseBuilder.note(Note.A4, Dur.half);

  print('    ${eliseBuilder.totalBeats} beats, ${eliseBuilder.totalSeconds.toStringAsFixed(1)}s');
  music.playMelody(eliseBuilder);
  await _wait(eliseBuilder.totalSeconds + 0.3);
  print('');

  // ── 6. DSL String — Für Elise again, sine wave ─────────────
  print('  ▸ DSL String — Für Elise, Section A (sine wave, softer)');
  final eliseDsl = Melody.parse(_furEliseA, bpm: 180, waveform: Waveform.sine);
  print('    ${eliseDsl.totalBeats} beats, ${eliseDsl.totalSeconds.toStringAsFixed(1)}s');
  music.playMelody(eliseDsl);
  await _wait(eliseDsl.totalSeconds + 0.3);
  print('');

  // ── 7. DSL — Section B, triangle wave ──────────────────────
  print('  ▸ DSL String — Für Elise, Section B (triangle wave)');
  final eliseB = Melody.parse(_furEliseB, bpm: 180, waveform: Waveform.triangle);
  print('    ${eliseB.totalBeats} beats, ${eliseB.totalSeconds.toStringAsFixed(1)}s');
  music.playMelody(eliseB);
  await _wait(eliseB.totalSeconds + 0.3);
  print('');

  // ── 8. Full Für Elise A+B, sawtooth ────────────────────────
  print('  ▸ Full Für Elise A+B (sawtooth, custom envelope)');
  final full = Melody.parse(
    '$_furEliseA $_furEliseB',
    bpm: 160,
    waveform: Waveform.sawtooth,
  );
  full.envelope = Envelope(attack: 0.01, decay: 0.08, sustain: 0.3, release: 0.08);
  print('    ${full.totalBeats} beats, ${full.totalSeconds.toStringAsFixed(1)}s');
  music.playMelody(full);
  await _wait(full.totalSeconds + 0.3);
  print('');

  // ── Finale ──────────────────────────────────────────────────
  print('  ▸ Finale');
  SFX.success.playOn(sfx);
  await _wait(1.0);

  audio.dispose();
  print('');
  print('  Done!');
  print('');
}
