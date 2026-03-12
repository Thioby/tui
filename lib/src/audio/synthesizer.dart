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

    // Attack: ramp 0 → 1
    if (t < attack) return attack == 0 ? 1.0 : t / attack;

    // Decay: ramp 1 → sustain
    if (t < attack + decay) {
      final p = (t - attack) / (decay == 0 ? 1.0 : decay);
      return 1.0 - (1.0 - sustain) * p;
    }

    // Release: ramp sustain → 0
    if (t >= releaseStart && releaseStart >= attack + decay) {
      final p = release == 0 ? 1.0 : (t - releaseStart) / release;
      return sustain * (1.0 - p.clamp(0.0, 1.0));
    }

    // Sustain
    return sustain;
  }
}

abstract class Synthesizer {
  static Float64List tone({
    required double frequency,
    required double duration,
    Waveform waveform = Waveform.sine,
    Envelope? envelope,
    double volume = 1.0,
    int sampleRate = 44100,
  }) {
    envelope ??= const Envelope.preset();
    final raw = waveform.generate(frequency, duration, sampleRate);
    final length = raw.length;
    final output = Float64List(length);

    for (var i = 0; i < length; i++) {
      final t = i / sampleRate;
      final amp = envelope.amplitudeAt(t, duration);
      output[i] = (raw[i] * amp * volume).clamp(-1.0, 1.0);
    }
    return output;
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
