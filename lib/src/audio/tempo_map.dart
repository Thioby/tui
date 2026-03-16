part of tui;

/// A tempo change point in the music.
class TempoChange {
  /// Beat position where this tempo takes effect.
  final double beat;

  /// Target BPM at this point.
  final int bpm;

  const TempoChange(this.beat, this.bpm);
}

/// Maps tempo changes across a piece. Between change points,
/// BPM interpolates linearly (enabling ritardando/accelerando).
///
/// ```dart
/// final map = TempoMap(120, [
///   TempoChange(16.0, 100), // start slowing at beat 16
///   TempoChange(20.0, 60),  // reach 60 BPM by beat 20
///   TempoChange(21.0, 120), // snap back to tempo
/// ]);
/// ```
class TempoMap {
  final int baseBpm;
  final List<TempoChange> _changes;

  TempoMap(this.baseBpm, List<TempoChange> changes)
      : _changes = List.of(changes)..sort((a, b) => a.beat.compareTo(b.beat));

  /// BPM at a given beat position. Interpolates linearly between changes.
  double bpmAt(double beat) {
    if (_changes.isEmpty) return baseBpm.toDouble();

    // Before first change: use baseBpm
    if (beat <= _changes.first.beat) {
      // Interpolate from baseBpm to first change
      if (_changes.first.beat > 0) {
        final t = beat / _changes.first.beat;
        return baseBpm + t * (_changes.first.bpm - baseBpm);
      }
      return _changes.first.bpm.toDouble();
    }

    // After last change
    if (beat >= _changes.last.beat) return _changes.last.bpm.toDouble();

    // Between two change points
    for (var i = 0; i < _changes.length - 1; i++) {
      if (beat >= _changes[i].beat && beat < _changes[i + 1].beat) {
        final range = _changes[i + 1].beat - _changes[i].beat;
        final t = (beat - _changes[i].beat) / range;
        final bpmDelta = _changes[i + 1].bpm - _changes[i].bpm;
        return _changes[i].bpm + t * bpmDelta;
      }
    }

    return _changes.last.bpm.toDouble();
  }

  /// Convert a beat range to seconds, integrating over tempo changes.
  ///
  /// Uses trapezoid rule for numerical integration — accurate for
  /// the linear interpolation used in [bpmAt].
  double beatsToSeconds(double startBeat, double numBeats) {
    if (numBeats <= 0) return 0.0;

    const steps = 64;
    final stepSize = numBeats / steps;
    var seconds = 0.0;

    for (var i = 0; i < steps; i++) {
      final b1 = startBeat + i * stepSize;
      final b2 = startBeat + (i + 1) * stepSize;
      // Trapezoid rule: average of seconds-per-beat at both endpoints
      seconds += stepSize * 0.5 * (60.0 / bpmAt(b1) + 60.0 / bpmAt(b2));
    }

    return seconds;
  }
}
