part of tui;

sealed class MelodyEvent {
  final double beats;
  const MelodyEvent(this.beats);
}

class NoteEvent extends MelodyEvent {
  final double frequency;
  final Waveform waveform;
  const NoteEvent(this.frequency, double beats, this.waveform) : super(beats);
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
  final List<MelodyEvent> events = [];

  Melody({
    this.bpm = 120,
    this.waveform = Waveform.square,
    Envelope? envelope,
    this.volume = 0.7,
  }) : envelope = envelope ?? const Envelope.preset();

  void note(double frequency, double beats, {Waveform? waveform}) {
    events.add(NoteEvent(frequency, beats, waveform ?? this.waveform));
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

  double get totalSeconds => Dur.toSeconds(totalBeats, bpm);

  Float64List toSamples({int sampleRate = 44100}) {
    final totalSamples = (totalSeconds * sampleRate).round();
    final output = Float64List(totalSamples);
    var offset = 0;

    for (final event in events) {
      final duration = Dur.toSeconds(event.beats, bpm);
      final length = (duration * sampleRate).round();

      if (event is NoteEvent) {
        final samples = Synthesizer.tone(
          frequency: event.frequency,
          duration: duration,
          waveform: event.waveform,
          envelope: envelope,
          volume: volume,
          sampleRate: sampleRate,
        );
        for (var i = 0; i < samples.length && offset + i < totalSamples; i++) {
          output[offset + i] = samples[i];
        }
      }
      offset += length;
    }

    return output;
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

  /// Parse a melody from DSL string.
  ///
  /// Format: `"C4.q D4.q E4.h R.q Cs4.e"`
  /// - Note: `{Name}{Octave}.{Duration}` — e.g. `C4.q`, `Fs5.e`
  /// - Rest: `R.{Duration}`
  /// - Bar separator: `|` (ignored)
  /// - Durations: w h dh q dq e de s t
  static Melody parse(String dsl, {int bpm = 120, Waveform waveform = Waveform.square}) {
    final melody = Melody(bpm: bpm, waveform: waveform);
    final tokens = dsl.trim().split(RegExp(r'\s+'));

    for (final token in tokens) {
      if (token == '|' || token.isEmpty) continue;

      final dotIndex = token.indexOf('.');
      if (dotIndex == -1) {
        throw FormatException('Invalid token (missing dot): "$token"');
      }

      final left = token.substring(0, dotIndex);
      final right = token.substring(dotIndex + 1);

      final beats = _durationCodes[right];
      if (beats == null) {
        throw FormatException('Unknown duration code "$right" in "$token"');
      }

      if (left == 'R') {
        melody.rest(beats);
      } else {
        final noteMatch = RegExp(r'^([A-G]s?)(\d)$').firstMatch(left);
        if (noteMatch == null) {
          throw FormatException('Invalid note "$left" in "$token"');
        }
        melody.note(noteFrequency(noteMatch.group(1)!, int.parse(noteMatch.group(2)!)), beats);
      }
    }

    return melody;
  }
}
