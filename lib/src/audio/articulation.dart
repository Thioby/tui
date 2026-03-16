part of tui;

/// Named articulation presets that override the melody's default envelope.
///
/// Used in the DSL with `:` suffix: `C4.q:st` (staccato), `C4.q:pz` (pizz).
class Articulation {
  /// Envelope override for this articulation.
  final Envelope envelope;

  const Articulation(this.envelope);

  /// Staccato: short, detached, percussive.
  static const staccato = Articulation(
    Envelope(attack: 0.003, decay: 0.06, sustain: 0.0, release: 0.01),
  );

  /// Pizzicato: plucked string, snappy attack, fast decay.
  static const pizzicato = Articulation(
    Envelope(attack: 0.001, decay: 0.12, sustain: 0.0, release: 0.02),
  );

  /// Spiccato: bouncing bow, slightly longer than staccato.
  static const spiccato = Articulation(
    Envelope(attack: 0.005, decay: 0.08, sustain: 0.1, release: 0.03),
  );

  /// Tenuto: held full value, slight emphasis.
  static const tenuto = Articulation(
    Envelope(attack: 0.01, decay: 0.02, sustain: 0.85, release: 0.04),
  );

  /// DSL code mapping.
  static const Map<String, Articulation> codes = {
    'st': staccato,
    'pz': pizzicato,
    'sp': spiccato,
    'tn': tenuto,
  };
}
