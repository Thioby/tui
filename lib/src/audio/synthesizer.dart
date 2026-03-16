part of tui;

enum Waveform {
  sine,
  square,
  triangle,
  sawtooth,
  noise;

  Float64List generate(double frequency, double duration, int sampleRate) {
    final length = (duration * sampleRate).round();
    final samples = Float64List(length);
    final rng = Random();

    for (var i = 0; i < length; i++) {
      final t = i / sampleRate;
      switch (this) {
        case Waveform.sine:
          samples[i] = sin(2 * pi * frequency * t);
        case Waveform.square:
          final phase = (frequency * t) % 1.0;
          samples[i] = phase < 0.5 ? 1.0 : -1.0;
        case Waveform.triangle:
          final phase = (frequency * t) % 1.0;
          samples[i] = phase < 0.5 ? -1.0 + 4.0 * phase : 3.0 - 4.0 * phase;
        case Waveform.sawtooth:
          final phase = (frequency * t) % 1.0;
          samples[i] = 2.0 * phase - 1.0;
        case Waveform.noise:
          samples[i] = rng.nextDouble() * 2.0 - 1.0;
      }
    }
    return samples;
  }
}

/// ADSR envelope for shaping amplitude over time.
class Envelope {
  final double attack;
  final double decay;
  final double sustain;
  final double release;

  const Envelope({
    required this.attack,
    required this.decay,
    required this.sustain,
    required this.release,
  });

  /// Short default envelope that prevents clicks.
  const Envelope.preset()
      : attack = 0.01,
        decay = 0.05,
        sustain = 0.7,
        release = 0.05;

  double amplitudeAt(double t, double duration) {
    if (t < 0) return 0.0;

    final releaseStart = duration - release;

    // Attack: ramp 0 -> 1
    if (t < attack) return attack == 0 ? 1.0 : t / attack;

    // Decay: ramp 1 -> sustain
    if (t < attack + decay) {
      final p = (t - attack) / (decay == 0 ? 1.0 : decay);
      return 1.0 - (1.0 - sustain) * p;
    }

    // Release: ramp sustain -> 0
    if (t >= releaseStart && releaseStart >= attack + decay) {
      final p = release == 0 ? 1.0 : (t - releaseStart) / release;
      return sustain * (1.0 - p.clamp(0.0, 1.0));
    }

    // Sustain
    return sustain;
  }
}

abstract class Synthesizer {
  /// Generate a single tone with optional [vibrato] and [timbre].
  ///
  /// When [timbre] is provided, uses additive synthesis (harmonic series)
  /// instead of the raw [waveform]. When [vibrato] is provided, modulates
  /// pitch with a low-frequency oscillator.
  static Float64List tone({
    required double frequency,
    required double duration,
    Waveform waveform = Waveform.sine,
    Envelope? envelope,
    double volume = 1.0,
    int sampleRate = 44100,
    Vibrato? vibrato,
    Timbre? timbre,
  }) {
    envelope ??= const Envelope.preset();

    // Timbre (additive synthesis) takes priority over basic waveform
    final raw = timbre != null
        ? timbre.generate(frequency, duration, sampleRate, vibrato: vibrato)
        : _generateWithVibrato(
            waveform, frequency, duration, sampleRate, vibrato);

    final length = raw.length;
    final output = Float64List(length);

    for (var i = 0; i < length; i++) {
      final t = i / sampleRate;
      final amp = envelope.amplitudeAt(t, duration);
      output[i] = (raw[i] * amp * volume).clamp(-1.0, 1.0);
    }
    return output;
  }

  /// Generate waveform samples with optional vibrato modulation.
  ///
  /// When vibrato is null or noise waveform, falls back to plain generation.
  /// Otherwise uses phase accumulation for smooth frequency modulation.
  static Float64List _generateWithVibrato(
    Waveform waveform,
    double frequency,
    double duration,
    int sampleRate,
    Vibrato? vibrato,
  ) {
    if (vibrato == null || vibrato.depth == 0 || waveform == Waveform.noise) {
      return waveform.generate(frequency, duration, sampleRate);
    }

    final length = (duration * sampleRate).round();
    final samples = Float64List(length);
    var phase = 0.0;

    for (var i = 0; i < length; i++) {
      final t = i / sampleRate;
      final freq = vibrato.frequencyAt(t, frequency);

      switch (waveform) {
        case Waveform.sine:
          samples[i] = sin(2 * pi * phase);
        case Waveform.square:
          samples[i] = (phase % 1.0) < 0.5 ? 1.0 : -1.0;
        case Waveform.triangle:
          final p = phase % 1.0;
          samples[i] = p < 0.5 ? -1.0 + 4.0 * p : 3.0 - 4.0 * p;
        case Waveform.sawtooth:
          samples[i] = 2.0 * (phase % 1.0) - 1.0;
        case Waveform.noise:
          break; // unreachable — handled above
      }

      phase += freq / sampleRate;
      phase %= 1.0;
    }

    return samples;
  }

  /// Additively mix multiple buffers, clamped to [-1, 1].
  static Float64List mix(List<Float64List> buffers) {
    if (buffers.isEmpty) return Float64List(0);

    var maxLen = 0;
    for (final buf in buffers) {
      if (buf.length > maxLen) maxLen = buf.length;
    }

    final output = Float64List(maxLen);
    for (final buf in buffers) {
      for (var i = 0; i < buf.length; i++) {
        output[i] += buf[i];
      }
    }
    for (var i = 0; i < maxLen; i++) {
      output[i] = output[i].clamp(-1.0, 1.0);
    }
    return output;
  }
}
