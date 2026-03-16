part of tui;

/// Pitch modulation via low-frequency oscillator (LFO).
///
/// Vibrato adds warmth and life to sustained notes — critical for
/// realistic string sounds. [rate] controls oscillation speed,
/// [depth] controls pitch deviation, [delay] lets the note start straight.
class Vibrato {
  /// LFO frequency in Hz. Strings typically use 5-7 Hz.
  final double rate;

  /// Pitch deviation in cents (100 cents = 1 semitone).
  /// Typical string vibrato is ±15-30 cents.
  final double depth;

  /// Delay in seconds before vibrato begins.
  /// Strings often start a note straight, then add vibrato.
  final double delay;

  const Vibrato({
    this.rate = 5.5,
    this.depth = 20.0,
    this.delay = 0.1,
  });

  /// Subtle, fast vibrato for violin.
  static const violin = Vibrato(rate: 5.5, depth: 22.0, delay: 0.08);

  /// Wider, slower vibrato for viola.
  static const viola = Vibrato(rate: 5.0, depth: 20.0, delay: 0.1);

  /// Deep, slow vibrato for cello.
  static const cello = Vibrato(rate: 4.8, depth: 18.0, delay: 0.12);

  /// Compute instantaneous frequency at time [t] given base [frequency].
  ///
  /// Returns unmodulated frequency before [delay] or when [depth] is zero.
  double frequencyAt(double t, double frequency) {
    if (depth == 0 || rate == 0 || t < delay) return frequency;
    final vibratoT = t - delay;
    final cents = depth * sin(2 * pi * rate * vibratoT);
    return frequency * pow(2.0, cents / 1200.0);
  }
}
