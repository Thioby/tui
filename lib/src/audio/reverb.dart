part of tui;

/// Schroeder reverb for hall/room simulation.
///
/// Uses 4 parallel comb filters + 2 serial allpass filters
/// to create a convincing reverb tail. Essential for Vivaldi
/// (performed in churches with significant reverberation).
class Reverb {
  /// Wet/dry mix: 0.0 = completely dry, 1.0 = completely wet.
  final double mix;

  /// Decay factor (0.0-1.0). Higher = longer reverb tail.
  final double decay;

  const Reverb({this.mix = 0.3, this.decay = 0.5});

  /// Church reverb: long tail, moderate mix (Vivaldi's sound).
  static const church = Reverb(mix: 0.35, decay: 0.7);

  /// Small room: short tail, subtle.
  static const room = Reverb(mix: 0.2, decay: 0.3);

  /// Large hall: very long tail.
  static const hall = Reverb(mix: 0.4, decay: 0.8);

  /// Apply reverb to mono samples.
  Float64List apply(Float64List input, {int sampleRate = 44100}) {
    if (mix <= 0 || input.isEmpty) return Float64List.fromList(input);

    final feedback = decay.clamp(0.0, 0.98);

    // Schroeder comb filter delays (ms) — tuned prime-ish spacing
    final combDelayMs = [29.7, 37.1, 41.1, 43.7];

    // Process 4 parallel comb filters
    final combSum = Float64List(input.length);
    for (final ms in combDelayMs) {
      final delaySamples = (ms / 1000.0 * sampleRate).round();
      _addCombFilter(input, combSum, delaySamples, feedback);
    }

    // Normalize comb sum
    for (var i = 0; i < combSum.length; i++) {
      combSum[i] /= combDelayMs.length;
    }

    // 2 serial allpass filters
    var wet = combSum;
    for (final ms in [5.0, 1.7]) {
      wet = _allpassFilter(
        wet,
        (ms / 1000.0 * sampleRate).round(),
        0.7,
      );
    }

    // Mix dry + wet
    final output = Float64List(input.length);
    final dryGain = 1.0 - mix;
    for (var i = 0; i < input.length; i++) {
      output[i] = (input[i] * dryGain + wet[i] * mix).clamp(-1.0, 1.0);
    }

    return output;
  }

  /// Apply reverb to stereo samples (each channel independently).
  StereoSamples applyStereo(
    StereoSamples input, {
    int sampleRate = 44100,
  }) {
    return StereoSamples(
      apply(input.left, sampleRate: sampleRate),
      apply(input.right, sampleRate: sampleRate),
    );
  }

  /// Comb filter: y[n] = x[n-d] + feedback * y[n-d], accumulated into out.
  static void _addCombFilter(
    Float64List input,
    Float64List out,
    int delay,
    double feedback,
  ) {
    final buf = Float64List(input.length);
    for (var i = 0; i < input.length; i++) {
      final d = i - delay;
      final x = d >= 0 ? input[d] : 0.0;
      final y = d >= 0 ? buf[d] : 0.0;
      buf[i] = x + feedback * y;
      out[i] += buf[i];
    }
  }

  /// Allpass filter: y[n] = -g*x[n] + x[n-d] + g*y[n-d]
  static Float64List _allpassFilter(
    Float64List input,
    int delay,
    double gain,
  ) {
    final output = Float64List(input.length);
    for (var i = 0; i < input.length; i++) {
      final d = i - delay;
      final xd = d >= 0 ? input[d] : 0.0;
      final yd = d >= 0 ? output[d] : 0.0;
      output[i] = -gain * input[i] + xd + gain * yd;
    }
    return output;
  }
}
