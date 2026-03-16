part of tui;

/// Stereo audio buffer with separate left and right channels.
class StereoSamples {
  final Float64List left;
  final Float64List right;

  StereoSamples(this.left, this.right) : assert(left.length == right.length);

  int get length => left.length;

  /// Create stereo from a mono signal with constant-power panning.
  ///
  /// [pan]: -1.0 = full left, 0.0 = center, +1.0 = full right.
  factory StereoSamples.fromMono(Float64List mono, {double pan = 0.0}) {
    final p = pan.clamp(-1.0, 1.0);
    // Constant-power panning law: equal loudness at center
    final angle = (p + 1.0) / 2.0 * pi / 2.0;
    final leftGain = cos(angle);
    final rightGain = sin(angle);

    final left = Float64List(mono.length);
    final right = Float64List(mono.length);

    for (var i = 0; i < mono.length; i++) {
      left[i] = mono[i] * leftGain;
      right[i] = mono[i] * rightGain;
    }

    return StereoSamples(left, right);
  }

  /// Additively mix multiple stereo buffers, clamped to [-1, 1].
  static StereoSamples mix(List<StereoSamples> buffers) {
    if (buffers.isEmpty) {
      return StereoSamples(Float64List(0), Float64List(0));
    }

    var maxLen = 0;
    for (final buf in buffers) {
      if (buf.length > maxLen) maxLen = buf.length;
    }

    final left = Float64List(maxLen);
    final right = Float64List(maxLen);

    for (final buf in buffers) {
      for (var i = 0; i < buf.length; i++) {
        left[i] += buf.left[i];
        right[i] += buf.right[i];
      }
    }

    for (var i = 0; i < maxLen; i++) {
      left[i] = left[i].clamp(-1.0, 1.0);
      right[i] = right[i].clamp(-1.0, 1.0);
    }

    return StereoSamples(left, right);
  }

  /// Downmix stereo to mono (average of L+R).
  Float64List toMono() {
    final mono = Float64List(length);
    for (var i = 0; i < length; i++) {
      mono[i] = ((left[i] + right[i]) * 0.5).clamp(-1.0, 1.0);
    }
    return mono;
  }
}
