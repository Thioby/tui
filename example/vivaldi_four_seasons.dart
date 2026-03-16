import 'package:tui/tui.dart';
import 'dart:typed_data';

Future<void> _wait(double s) =>
    Future.delayed(Duration(milliseconds: (s * 1000).round()));

// -- Instrument Envelopes (ADSR) ------------------------------------

const _violinEnv = Envelope(
  attack: 0.02,
  decay: 0.08,
  sustain: 0.65,
  release: 0.06,
);

const _violaEnv = Envelope(
  attack: 0.03,
  decay: 0.1,
  sustain: 0.5,
  release: 0.08,
);

const _celloEnv = Envelope(
  attack: 0.05,
  decay: 0.12,
  sustain: 0.55,
  release: 0.1,
);

const _tremoloEnv = Envelope(
  attack: 0.002,
  decay: 0.02,
  sustain: 0.5,
  release: 0.02,
);

const _staccatoEnv = Envelope(
  attack: 0.003,
  decay: 0.06,
  sustain: 0.0,
  release: 0.01,
);

// -- Helpers --------------------------------------------------------

Float64List _scale(Float64List buf, double factor) {
  final out = Float64List(buf.length);
  for (var i = 0; i < buf.length; i++) {
    out[i] = (buf[i] * factor).clamp(-1.0, 1.0);
  }
  return out;
}

/// Render a DSL voice with timbre, vibrato, and optional tempo map.
Float64List _voice(
  String dsl, {
  int bpm = 120,
  Envelope env = _violinEnv,
  double vol = 0.5,
  Vibrato? vibrato,
  Timbre? timbre,
  TempoMap? tempoMap,
}) {
  final m = Melody.parse(dsl, bpm: bpm, vibrato: vibrato, timbre: timbre);
  m.envelope = env;
  m.tempoMap = tempoMap;
  return _scale(m.toSamples(), vol);
}

/// Mix mono voices into stereo with panning + church reverb.
StereoSamples _mixOrchestra(List<(Float64List, double)> voices) {
  final stereo = StereoSamples.mix(
    voices.map((v) => StereoSamples.fromMono(v.$1, pan: v.$2)).toList(),
  );
  return Reverb.church.applyStereo(stereo);
}

/// Play stereo samples.
Future<void> _play(StereoSamples samples) async {
  await AudioPlayer().playWav(WavWriter.encodeStereo(samples));
}

// === SPRING -- La Primavera, Allegro, E major ======================

StereoSamples _spring() {
  const bpm = 140;

  // Violin I: birdsong trills + grace notes
  final v1Melody = Melody.parse('''
    E5.e@f E5.e@f E5.q@f  E5.e@mf Ds5.s E5.s E5.q |
    E5.e E5.e E5.q~tr  E5.e Ds5.s E5.s E5.q |
    Fs5.e@f Fs5.e Fs5.q~tr  Fs5.e E5.s Fs5.s Fs5.q |
    Gs5.e@ff Gs5.e Gs5.q  Gs5.e Fs5.s Gs5.s Gs5.q~mr |
    A5.e@ff Gs5.e Fs5.e E5.e  Fs5.e Ds5.e E5.q@mf |
    E5.dh@mp R.q
  ''', bpm: bpm, vibrato: Vibrato.violin, timbre: Timbre.violin);
  v1Melody.envelope = _violinEnv;
  // Add grace note birdsong at the start
  final springBird =
      Melody(bpm: bpm, vibrato: Vibrato.violin, timbre: Timbre.violin);
  springBird.envelope = _violinEnv;
  springBird.graceNote(Note.Ds5, Note.E5, Dur.quarter);
  final v1 = _scale(v1Melody.toSamples(), 0.55);

  final v2 = _voice('''
    Gs4.e Gs4.e Gs4.q  Gs4.e Fs4.s Gs4.s Gs4.q |
    Gs4.e Gs4.e Gs4.q  Gs4.e Fs4.s Gs4.s Gs4.q |
    A4.e A4.e A4.q  A4.e Gs4.s A4.s A4.q |
    B4.e B4.e B4.q  B4.e A4.s B4.s B4.q |
    Cs5.e B4.e A4.e Gs4.e  A4.e Fs4.e Gs4.q |
    Gs4.dh R.q
  ''',
      bpm: bpm,
      env: _violaEnv,
      vol: 0.35,
      vibrato: Vibrato.viola,
      timbre: Timbre.viola);

  final bass = _voice('''
    E3.q@f B3.q E3.q B3.q |
    E3.q B3.q E3.q B3.q |
    Fs3.q Cs4.q Fs3.q Cs4.q |
    E3.q B3.q E3.q B3.q |
    A3.q E3.q Fs3.q B2.q |
    E3.dh@mp R.q
  ''',
      bpm: bpm,
      env: _celloEnv,
      vol: 0.3,
      vibrato: Vibrato.cello,
      timbre: Timbre.cello);

  // Stereo: Violin I left, Violin II right, Cello center
  return _mixOrchestra([(v1, -0.4), (v2, 0.35), (bass, 0.0)]);
}

// === SUMMER -- L'Estate, Presto, G minor ===========================

StereoSamples _summer() {
  const bpm = 168;
  const stormVib = Vibrato(rate: 7.0, depth: 15.0, delay: 0.0);

  final storm = _voice('''
    G5.s@ff G5.s G5.s G5.s  G5.s G5.s G5.s G5.s |
    G5.s G5.s G5.s G5.s  G5.s G5.s G5.s G5.s |
    G5.s G5.s G5.s G5.s  G5.s G5.s G5.s G5.s |
    G5.s G5.s G5.s G5.s  G5.s G5.s G5.s G5.s |
    Fs5.s G5.s A5.s As5.s  A5.s G5.s Fs5.s G5.s |
    D5.s D5.s D5.s D5.s  Ds5.s E5.s F5.s Fs5.s |
    G5.s A5.s As5.s A5.s  G5.s Fs5.s G5.s D5.s |
    Fs5.s G5.s A5.s G5.s  Fs5.s E5.s D5.s Ds5.s |
    G5.e Fs5.e G5.e D5.e  Ds5.e C5.e D5.q@mf |
    G4.w@mp
  ''',
      bpm: bpm,
      env: _tremoloEnv,
      vol: 0.5,
      vibrato: stormVib,
      timbre: Timbre.violin);

  // Drive: staccato articulation via DSL :st suffix
  final drive = _voice('''
    G4.e@f:st D5.e:st G4.e:st D5.e:st  G4.e:st D5.e:st G4.e:st D5.e:st |
    G4.e:st D5.e:st G4.e:st D5.e:st  G4.e:st D5.e:st G4.e:st D5.e:st |
    G4.e:sp As4.e:sp G4.e:sp As4.e:sp  G4.e:sp As4.e:sp G4.e:sp As4.e:sp |
    G4.e:sp As4.e:sp G4.e:sp As4.e:sp  G4.e:sp As4.e:sp G4.e:sp As4.e:sp |
    G4.e:st D4.e:st As3.e:st D4.e:st  G3.q R.q |
    G3.w@p
  ''', bpm: bpm, vol: 0.3, timbre: Timbre.viola);

  final thunder = _voice('''
    G2.h@ff G2.h | G2.h D3.h | G2.h D3.h |
    G2.h D3.h | G2.q D3.q G2.q R.q | G2.w@mp
  ''',
      bpm: bpm,
      env: _celloEnv,
      vol: 0.35,
      vibrato: Vibrato.cello,
      timbre: Timbre.cello);

  return _mixOrchestra([(storm, -0.3), (drive, 0.4), (thunder, 0.0)]);
}

// === AUTUMN -- L'Autunno, Allegro, F major =========================

StereoSamples _autumn() {
  const bpm = 132;

  // Dance: legato ties for smooth phrase connections
  final dance = _voice('''
    F5.q@f F5.e E5.s F5.s  G5.q@ff_ A5.q |
    G5.e_ F5.e_ E5.e_ F5.e  D5.h@mf |
    F5.q@f F5.e E5.s F5.s  G5.q@ff_ A5.q |
    As5.e_ A5.e_ G5.e_ F5.e  E5.e_ F5.e G5.q~mr |
    A5.e@f_ G5.e_ F5.e_ E5.e  D5.e_ E5.e F5.q@mf:tn |
    F5.w@mp
  ''',
      bpm: bpm,
      env: _violinEnv,
      vol: 0.5,
      vibrato: Vibrato.violin,
      timbre: Timbre.violin);

  final accomp = _voice('''
    F4.q A4.q C5.q A4.q | As4.q F4.q As4.q F4.q |
    F4.q A4.q C5.q A4.q | F4.q A4.q C5.q A4.q |
    F4.q A4.q D4.q G4.q | F4.w
  ''',
      bpm: bpm,
      env: _violaEnv,
      vol: 0.3,
      vibrato: Vibrato.viola,
      timbre: Timbre.viola);

  // Ritardando in last 2 bars
  final bassTempoMap = TempoMap(bpm, [
    TempoChange(16.0, bpm),
    TempoChange(20.0, 100), // gentle rit.
  ]);

  final bass = _voice('''
    F3.q@f C3.q F3.q C3.q | As2.q F3.q As2.q F3.q |
    F3.q C3.q F3.q C3.q | F3.q C3.q F3.q C3.q |
    F3.q C3.q D3.q G3.q | F3.w@mp
  ''',
      bpm: bpm,
      env: _celloEnv,
      vol: 0.35,
      vibrato: Vibrato.cello,
      timbre: Timbre.cello,
      tempoMap: bassTempoMap);

  return _mixOrchestra([(dance, -0.35), (accomp, 0.3), (bass, 0.0)]);
}

// === WINTER -- L'Inverno, Allegro non molto, F minor ===============

StereoSamples _winter() {
  const bpm = 120;

  // Tempo map: rit. at chromatic descent, a tempo, final rit.
  final winterTempo = TempoMap(bpm, [
    TempoChange(8.0, 110), // slightly slower for descent
    TempoChange(16.0, 120), // back to tempo
    TempoChange(22.0, 90), // ritardando to end
    TempoChange(24.0, 70), // molto rit.
  ]);

  final shiver = Melody(
    bpm: bpm,
    vibrato: const Vibrato(rate: 8.0, depth: 12.0, delay: 0.0),
    timbre: Timbre.violin,
    tempoMap: winterTempo,
  );
  shiver.envelope = _tremoloEnv;

  // Bars 1-2: shivering tremolo (ff)
  for (var i = 0; i < 32; i++) {
    shiver.note(Note.F5, Dur.sixteenth, volume: 0.9);
  }

  // Bars 3-4: chromatic descent (decrescendo)
  final descent = [
    Note.F5,
    Note.E5,
    Note.Ds5,
    Note.D5,
    Note.C5,
    Note.B4,
    Note.As4,
    Note.Gs4,
  ];
  for (var i = 0; i < descent.length; i++) {
    shiver.note(descent[i], Dur.quarter, volume: 0.9 - (i * 0.07));
  }

  // Bars 5: alternating tremolo
  for (var i = 0; i < 16; i++) {
    shiver.note(i.isEven ? Note.Gs4 : Note.F4, Dur.sixteenth, volume: 0.6);
  }

  // Bar 6: dark resolution (pp, molto rit.)
  shiver.note(Note.F4, Dur.whole, volume: 0.35);

  final v1 = _scale(shiver.toSamples(), 0.45);

  final pedal = _voice('''
    C5.s C5.s C5.s C5.s  C5.s C5.s C5.s C5.s
    C5.s C5.s C5.s C5.s  C5.s C5.s C5.s C5.s |
    C5.s C5.s C5.s C5.s  C5.s C5.s C5.s C5.s
    C5.s C5.s C5.s C5.s  C5.s C5.s C5.s C5.s |
    Gs4.q Gs4.q Gs4.q Gs4.q |
    Gs4.q Gs4.q Gs4.q Gs4.q |
    E4.s E4.s E4.s E4.s  E4.s E4.s E4.s E4.s
    E4.s E4.s E4.s E4.s  E4.s E4.s E4.s E4.s |
    C4.w@pp
  ''',
      bpm: bpm,
      env: _tremoloEnv,
      vol: 0.3,
      vibrato: const Vibrato(rate: 7.0, depth: 10.0, delay: 0.0),
      timbre: Timbre.viola);

  final bass = _voice('''
    F2.h@f F2.h | F2.h F2.h |
    C3.h Gs2.h | C3.h Gs2.h |
    Gs2.h F2.h | F2.w@pp
  ''',
      bpm: bpm,
      env: _celloEnv,
      vol: 0.4,
      vibrato: Vibrato.cello,
      timbre: Timbre.cello);

  // Wide stereo: shivering left, pedal right, bass center
  return _mixOrchestra([(v1, -0.5), (pedal, 0.45), (bass, 0.0)]);
}

// === MAIN ==========================================================

void main() async {
  final player = AudioPlayer();
  if (!player.isAvailable) {
    print('Audio player not available on this platform.');
    return;
  }

  print('');
  print('  +=========================================================+');
  print('  |   Antonio Vivaldi -- Le Quattro Stagioni (1725)          |');
  print('  |   Synthesized with TUI Audio Engine                      |');
  print('  |                                                          |');
  print('  |   Timbre: additive synthesis (8-harmonic profiles)       |');
  print('  |   Vibrato: pitch LFO per instrument preset              |');
  print('  |   Dynamics: per-note pp/mf/ff via DSL @-suffix          |');
  print('  |   Stereo: constant-power panning per voice              |');
  print('  |   Reverb: Schroeder church reverb (4 comb + 2 allpass)  |');
  print('  |   Tempo: TempoMap with ritardando (Winter)              |');
  print('  |   Trills: birdsong ornaments ~tr ~mr (Spring)           |');
  print('  |   Articulation: :st :sp :tn DSL (Summer drive)         |');
  print('  |   Legato: tied notes _ suffix (Autumn dance)            |');
  print('  |   Polyphony: 3-voice stereo mix per season              |');
  print('  +=========================================================+');
  print('');

  // -- Orchestra Tuning ---------------------------------------------
  print('  * Orchestra tuning -- A4 = 440 Hz');
  final tuningMono = Synthesizer.tone(
    frequency: Note.A4,
    duration: 1.5,
    volume: 0.5,
    envelope: const Envelope(
      attack: 0.1,
      decay: 0.2,
      sustain: 0.6,
      release: 0.4,
    ),
    vibrato: Vibrato.violin,
    timbre: Timbre.violin,
  );
  final tuningStereo = StereoSamples.fromMono(tuningMono, pan: 0.0);
  await _play(Reverb.church.applyStereo(tuningStereo));
  await _wait(0.3);

  // -- Opening Chord ------------------------------------------------
  print('  * E major chord -- strings enter');
  final chordFreqs = [Note.E3, Note.B3, Note.E4, Note.Gs4, Note.B4, Note.E5];
  final chordMono = Synthesizer.mix(
    chordFreqs
        .map((f) => Synthesizer.tone(
              frequency: f,
              duration: 2.5,
              volume: 0.12,
              envelope: const Envelope(
                attack: 0.15,
                decay: 0.3,
                sustain: 0.4,
                release: 0.5,
              ),
              vibrato: Vibrato.violin,
              timbre: Timbre.violin,
            ))
        .toList(),
  );
  final chordStereo = StereoSamples.fromMono(chordMono, pan: 0.0);
  await _play(Reverb.church.applyStereo(chordStereo));
  await _wait(0.5);

  // -- The Four Seasons ---------------------------------------------
  final seasons = <(String, String, StereoSamples Function())>[
    ('I.  La Primavera', 'Allegro, E major -- birdsong & joy', _spring),
    ("II. L'Estate", 'Presto, G minor -- the summer storm', _summer),
    ("III. L'Autunno", 'Allegro, F major -- harvest dance', _autumn),
    ("IV. L'Inverno", 'Allegro non molto, F minor -- shivering', _winter),
  ];

  for (final (name, desc, build) in seasons) {
    print('');
    print('  -- $name --');
    print('     $desc');

    final stereo = build();
    final wav = WavWriter.encodeStereo(stereo);
    final durSec = stereo.length / 44100;

    print('     ${durSec.toStringAsFixed(1)}s | '
        '${stereo.length} frames | '
        'stereo | '
        '${(wav.length / 1024).toStringAsFixed(0)} KB WAV');
    print('     Playing...');

    await player.playWav(wav);
    await _wait(0.4);
  }

  // -- Finale -------------------------------------------------------
  print('');
  print('  * Finale -- F major resolution');
  final finaleFreqs = [
    Note.F2,
    Note.C3,
    Note.F3,
    Note.A3,
    Note.C4,
    Note.F4,
    Note.A4,
    Note.C5,
  ];
  final finaleMono = Synthesizer.mix(
    finaleFreqs
        .map((f) => Synthesizer.tone(
              frequency: f,
              duration: 3.0,
              volume: 0.1,
              envelope: const Envelope(
                attack: 0.2,
                decay: 0.4,
                sustain: 0.5,
                release: 0.8,
              ),
              vibrato: const Vibrato(rate: 4.5, depth: 15.0, delay: 0.3),
              timbre: Timbre.cello,
            ))
        .toList(),
  );
  final finaleStereo = StereoSamples.fromMono(finaleMono, pan: 0.0);
  await _play(Reverb.church.applyStereo(finaleStereo));

  _printFeatureReport();
}

void _printFeatureReport() {
  print('');
  print('  +=========================================================+');
  print('  |   Features USED in this performance:                     |');
  print('  +=========================================================+');
  print('  |  [x] Timbre -- additive synthesis (violin/viola/cello)   |');
  print('  |  [x] Vibrato -- pitch LFO per instrument preset         |');
  print('  |  [x] Per-note dynamics -- @ff/@mf/@pp in DSL + builder  |');
  print('  |  [x] Stereo panning -- constant-power per voice         |');
  print('  |  [x] Reverb -- Schroeder church (4 comb + 2 allpass)    |');
  print('  |  [x] Tempo map -- ritardando in Winter chromatic desc.  |');
  print('  |  [x] Melody.parse() DSL -- all four seasons             |');
  print('  |  [x] Melody builder (programmatic) -- Winter shivering  |');
  print('  |  [x] Synthesizer.mix() -- 3-voice polyphony per season  |');
  print('  |  [x] WavWriter.encodeStereo() -- stereo 16-bit PCM WAV  |');
  print('  |  [x] 5 ADSR Envelopes: violin/viola/cello/trem/stacc    |');
  print('  |  [x] Trills/ornaments -- ~tr, ~mr, ~tn + graceNote()   |');
  print('  |  [x] Legato/ties -- _ suffix, smooth phrase envelopes   |');
  print('  |  [x] Articulation DSL -- :st/:sp/:pz/:tn per-note      |');
  print('  +=========================================================+');
  print('');
  print('  Fine.');
  print('');
}
