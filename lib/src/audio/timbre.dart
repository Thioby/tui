part of tui;

/// A single harmonic partial in an instrument timbre.
class Harmonic {
  /// Harmonic number: 1 = fundamental, 2 = octave, 3 = fifth+octave, etc.
  final int number;

  /// Relative amplitude (0.0 - 1.0).
  final double amplitude;

  const Harmonic(this.number, this.amplitude);
}

/// Defines the harmonic content of an instrument via additive synthesis.
///
/// Real instruments produce a series of overtones above the fundamental
/// that give each instrument its unique character. A violin sounds
/// different from a flute at the same pitch because of different
/// harmonic profiles.
class Timbre {
  final List<Harmonic> harmonics;

  const Timbre(this.harmonics);

  /// Violin: bright, rich harmonics with strong even and odd partials.
  static const violin = Timbre([
    Harmonic(1, 1.0),
    Harmonic(2, 0.55),
    Harmonic(3, 0.42),
    Harmonic(4, 0.28),
    Harmonic(5, 0.18),
    Harmonic(6, 0.12),
    Harmonic(7, 0.07),
    Harmonic(8, 0.04),
  ]);

  /// Viola: warmer than violin, fewer high harmonics.
  static const viola = Timbre([
    Harmonic(1, 1.0),
    Harmonic(2, 0.48),
    Harmonic(3, 0.32),
    Harmonic(4, 0.18),
    Harmonic(5, 0.1),
    Harmonic(6, 0.05),
  ]);

  /// Cello: deep, rich, strong low harmonics.
  static const cello = Timbre([
    Harmonic(1, 1.0),
    Harmonic(2, 0.65),
    Harmonic(3, 0.48),
    Harmonic(4, 0.32),
    Harmonic(5, 0.22),
    Harmonic(6, 0.14),
    Harmonic(7, 0.08),
  ]);

  /// Pure tone: fundamental only (equivalent to sine waveform).
  static const pure = Timbre([Harmonic(1, 1.0)]);

  /// Generate samples using additive synthesis with phase accumulators.
  ///
  /// Uses per-sample phase accumulation (not `sin(2*pi*f*t)`) to prevent
  /// discontinuities when frequency changes (e.g. vibrato).
  Float64List generate(
    double frequency,
    double duration,
    int sampleRate, {
    Vibrato? vibrato,
  }) {
    final length = (duration * sampleRate).round();
    final samples = Float64List(length);

    // Normalization factor to keep output in [-1, 1]
    var totalAmp = 0.0;
    for (final h in harmonics) {
      totalAmp += h.amplitude;
    }
    final norm = totalAmp > 0 ? 1.0 / totalAmp : 1.0;

    // Phase accumulators per harmonic (prevents clicks on freq change)
    final phases = List<double>.filled(harmonics.length, 0.0);
    final nyquist = sampleRate / 2.0;

    for (var i = 0; i < length; i++) {
      final t = i / sampleRate;
      final freq = vibrato?.frequencyAt(t, frequency) ?? frequency;

      var sample = 0.0;
      for (var h = 0; h < harmonics.length; h++) {
        final harmonic = harmonics[h];
        final hFreq = freq * harmonic.number;
        if (hFreq >= nyquist) continue;

        sample += harmonic.amplitude * sin(2 * pi * phases[h]);
        phases[h] += hFreq / sampleRate;
        phases[h] %= 1.0;
      }

      samples[i] = sample * norm;
    }

    return samples;
  }
}
