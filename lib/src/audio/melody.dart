part of tui;

sealed class MelodyEvent {
  final double beats;
  const MelodyEvent(this.beats);
}

class NoteEvent extends MelodyEvent {
  final double frequency;
  final Waveform waveform;

  /// Per-note volume (0.0-1.0). When null, inherits from [Melody.volume].
  final double? volume;

  /// When true, this note connects to the next without re-attacking.
  final bool tied;

  /// Articulation override (staccato, pizzicato, etc.).
  final Articulation? articulation;

  const NoteEvent(
    this.frequency,
    double beats,
    this.waveform, {
    this.volume,
    this.tied = false,
    this.articulation,
  }) : super(beats);
}

class RestEvent extends MelodyEvent {
  const RestEvent(double beats) : super(beats);
}

/// A sequence of notes and rests that can be synthesized to audio.
class Melody {
  final int bpm;
  Waveform waveform;
  Envelope envelope;
  final double volume;

  /// Vibrato applied to all notes in this melody.
  Vibrato? vibrato;

  /// Harmonic timbre for additive synthesis (overrides [waveform]).
  Timbre? timbre;

  /// Tempo map for ritardando, accelerando, and fermata.
  TempoMap? tempoMap;

  final List<MelodyEvent> events = [];

  Melody({
    this.bpm = 120,
    this.waveform = Waveform.square,
    Envelope? envelope,
    this.volume = 0.7,
    this.vibrato,
    this.timbre,
    this.tempoMap,
  }) : envelope = envelope ?? const Envelope.preset();

  /// Add a note with optional per-note overrides.
  void note(
    double frequency,
    double beats, {
    Waveform? waveform,
    double? volume,
    bool tied = false,
    Articulation? articulation,
  }) {
    events.add(NoteEvent(
      frequency,
      beats,
      waveform ?? this.waveform,
      volume: volume,
      tied: tied,
      articulation: articulation,
    ));
  }

  void rest(double beats) {
    events.add(RestEvent(beats));
  }

  double get totalBeats {
    var sum = 0.0;
    for (final event in events) {
      sum += event.beats;
    }
    return sum;
  }

  double get totalSeconds {
    if (tempoMap != null) return tempoMap!.beatsToSeconds(0, totalBeats);
    return Dur.toSeconds(totalBeats, bpm);
  }

  Float64List toSamples({int sampleRate = 44100}) {
    final totalSamples = (totalSeconds * sampleRate).round();
    final output = Float64List(totalSamples);
    var offset = 0;
    var currentBeat = 0.0;

    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      final duration = tempoMap != null
          ? tempoMap!.beatsToSeconds(currentBeat, event.beats)
          : Dur.toSeconds(event.beats, bpm);
      final length = (duration * sampleRate).round();

      if (event is NoteEvent) {
        final env = _envelopeForNote(event, i);
        final samples = Synthesizer.tone(
          frequency: event.frequency,
          duration: duration,
          waveform: event.waveform,
          envelope: env,
          volume: event.volume ?? volume,
          sampleRate: sampleRate,
          vibrato: vibrato,
          timbre: timbre,
        );
        for (var j = 0; j < samples.length && offset + j < totalSamples; j++) {
          output[offset + j] = samples[j];
        }
      }
      currentBeat += event.beats;
      offset += length;
    }

    return output;
  }

  /// Compute effective envelope for a note, handling ties and articulations.
  Envelope _envelopeForNote(NoteEvent event, int index) {
    // Articulation overrides everything
    if (event.articulation != null) return event.articulation!.envelope;

    final prevIsTied = index > 0 &&
        events[index - 1] is NoteEvent &&
        (events[index - 1] as NoteEvent).tied;
    final nextIsTied = event.tied &&
        index + 1 < events.length &&
        events[index + 1] is NoteEvent;

    if (prevIsTied && nextIsTied) {
      // Middle of legato phrase: no attack, no release
      return Envelope(
        attack: 0.002,
        decay: 0,
        sustain: envelope.sustain,
        release: 0.002,
      );
    } else if (prevIsTied) {
      // End of legato phrase: no attack, normal release
      return Envelope(
        attack: 0.002,
        decay: 0,
        sustain: envelope.sustain,
        release: envelope.release,
      );
    } else if (nextIsTied) {
      // Start of legato phrase: normal attack, no release
      return Envelope(
        attack: envelope.attack,
        decay: envelope.decay,
        sustain: envelope.sustain,
        release: 0.002,
      );
    }

    return envelope;
  }

  static const Map<String, double> _durationCodes = {
    'w': Dur.whole,
    'h': Dur.half,
    'dh': Dur.dottedHalf,
    'q': Dur.quarter,
    'dq': Dur.dottedQuarter,
    'e': Dur.eighth,
    'de': Dur.dottedEighth,
    's': Dur.sixteenth,
    't': 1.0 / 3.0,
  };

  static const Map<String, double> _dynamicLevels = {
    'ppp': 0.15,
    'pp': 0.3,
    'p': 0.45,
    'mp': 0.6,
    'mf': 0.75,
    'f': 0.88,
    'ff': 1.0,
  };

  /// Ornament codes for DSL: `C4.q~tr` (trill), `C4.q~mr` (mordent).
  static const _ornamentCodes = {'tr', 'mr', 'tn'};

  /// Parse a melody from DSL string.
  ///
  /// Format: `"C4.q D4.q E4.h R.q Cs4.e"`
  /// - Note: `{Name}{Octave}.{Duration}` — e.g. `C4.q`, `Fs5.e`
  /// - Rest: `R.{Duration}`
  /// - Bar separator: `|` (ignored)
  /// - Durations: w h dh q dq e de s t
  /// - Dynamics: `@` + level — e.g. `C4.q@ff` (ppp pp p mp mf f ff)
  /// - Articulation: `:` + code — e.g. `C4.q:st` (st pz sp tn)
  /// - Tie: `_` suffix — e.g. `C4.q_` (legato to next note)
  /// - Ornament: `~` + code — e.g. `C4.q~tr` (tr mr tn)
  static Melody parse(
    String dsl, {
    int bpm = 120,
    Waveform waveform = Waveform.square,
    Vibrato? vibrato,
    Timbre? timbre,
  }) {
    final melody = Melody(
      bpm: bpm,
      waveform: waveform,
      vibrato: vibrato,
      timbre: timbre,
    );
    final tokens = dsl.trim().split(RegExp(r'\s+'));

    for (final token in tokens) {
      if (token == '|' || token.isEmpty) continue;
      _parseToken(melody, token);
    }

    return melody;
  }

  static void _parseToken(Melody melody, String token) {
    final dotIndex = token.indexOf('.');
    if (dotIndex == -1) {
      throw FormatException('Invalid token (missing dot): "$token"');
    }

    final left = token.substring(0, dotIndex);
    var right = token.substring(dotIndex + 1);

    // Parse suffixes from right side: duration[@dyn][:art][_][~orn]
    double? noteVolume;
    Articulation? articulation;
    var tied = false;
    String? ornament;

    // Ornament: ~tr, ~mr, ~tn (must be last)
    final tildeIdx = right.indexOf('~');
    if (tildeIdx != -1) {
      ornament = right.substring(tildeIdx + 1);
      right = right.substring(0, tildeIdx);
      if (!_ornamentCodes.contains(ornament)) {
        throw FormatException('Unknown ornament "$ornament" in "$token"');
      }
    }

    // Tie: trailing _
    if (right.endsWith('_')) {
      tied = true;
      right = right.substring(0, right.length - 1);
    }

    // Articulation: :st, :pz, :sp, :tn
    final colonIdx = right.indexOf(':');
    if (colonIdx != -1) {
      final artCode = right.substring(colonIdx + 1);
      right = right.substring(0, colonIdx);
      articulation = Articulation.codes[artCode];
      if (articulation == null) {
        throw FormatException('Unknown articulation "$artCode" in "$token"');
      }
    }

    // Dynamics: @ff, @pp, etc.
    final atIdx = right.indexOf('@');
    if (atIdx != -1) {
      final dynCode = right.substring(atIdx + 1);
      right = right.substring(0, atIdx);
      noteVolume = _dynamicLevels[dynCode];
      if (noteVolume == null) {
        throw FormatException('Unknown dynamics "$dynCode" in "$token"');
      }
    }

    final beats = _durationCodes[right];
    if (beats == null) {
      throw FormatException('Unknown duration code "$right" in "$token"');
    }

    if (left == 'R') {
      melody.rest(beats);
      return;
    }

    final noteMatch = RegExp(r'^([A-G]s?)(\d)$').firstMatch(left);
    if (noteMatch == null) {
      throw FormatException('Invalid note "$left" in "$token"');
    }
    final freq = noteFrequency(
      noteMatch.group(1)!,
      int.parse(noteMatch.group(2)!),
    );

    // Ornaments expand into multiple notes
    if (ornament != null) {
      _addOrnament(melody, ornament, freq, beats, noteVolume);
    } else {
      melody.note(
        freq,
        beats,
        volume: noteVolume,
        tied: tied,
        articulation: articulation,
      );
    }
  }

  static void _addOrnament(
    Melody melody,
    String code,
    double freq,
    double beats,
    double? volume,
  ) {
    switch (code) {
      case 'tr':
        melody.trill(freq, beats, volume: volume);
      case 'mr':
        melody.mordent(freq, beats, volume: volume);
      case 'tn':
        melody.turn(freq, beats, volume: volume);
    }
  }
}
