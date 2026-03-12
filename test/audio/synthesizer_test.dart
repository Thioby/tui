import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('Waveform', () {
    const frequency = 440.0;
    const duration = 0.1;
    const sampleRate = 44100;
    final expectedLength = (duration * sampleRate).round();

    test('sine produces correct range and length', () {
      final samples = Waveform.sine.generate(frequency, duration, sampleRate);
      expect(samples.length, expectedLength);
      for (final s in samples) {
        expect(s, greaterThanOrEqualTo(-1.0));
        expect(s, lessThanOrEqualTo(1.0));
      }
    });

    test('square produces correct range and length', () {
      final samples = Waveform.square.generate(frequency, duration, sampleRate);
      expect(samples.length, expectedLength);
      for (final s in samples) {
        expect(s, greaterThanOrEqualTo(-1.0));
        expect(s, lessThanOrEqualTo(1.0));
      }
    });

    test('square wave values are exactly +1 or -1', () {
      final samples = Waveform.square.generate(frequency, duration, sampleRate);
      for (final s in samples) {
        expect(s == 1.0 || s == -1.0, isTrue, reason: 'Square wave sample should be +1 or -1, got $s');
      }
    });

    test('triangle produces correct range and length', () {
      final samples = Waveform.triangle.generate(frequency, duration, sampleRate);
      expect(samples.length, expectedLength);
      for (final s in samples) {
        expect(s, greaterThanOrEqualTo(-1.0));
        expect(s, lessThanOrEqualTo(1.0));
      }
    });

    test('triangle is symmetric', () {
      // Generate exactly one period so symmetry is clean.
      final onePeriodDuration = 1.0 / frequency;
      final samples = Waveform.triangle.generate(frequency, onePeriodDuration, sampleRate);
      final n = samples.length;
      final half = n ~/ 2;
      // First half ramps up, second half ramps down — mirror symmetry.
      for (var i = 1; i < half; i++) {
        final mirrorIndex = n - i;
        if (mirrorIndex < n) {
          expect(samples[i], closeTo(samples[mirrorIndex], 0.05), reason: 'Triangle should be symmetric at index $i');
        }
      }
    });

    test('sawtooth produces correct range and length', () {
      final samples = Waveform.sawtooth.generate(frequency, duration, sampleRate);
      expect(samples.length, expectedLength);
      for (final s in samples) {
        expect(s, greaterThanOrEqualTo(-1.0));
        expect(s, lessThanOrEqualTo(1.0));
      }
    });

    test('sawtooth ramps correctly within a period', () {
      // Generate one period.
      final onePeriodDuration = 1.0 / frequency;
      final samples = Waveform.sawtooth.generate(frequency, onePeriodDuration, sampleRate);
      // Samples should generally increase across the period.
      // Check that the first sample is near -1 and the last is near +1.
      expect(samples.first, closeTo(-1.0, 0.05));
      expect(samples.last, closeTo(1.0, 0.05));
    });

    test('noise produces correct range and length', () {
      final samples = Waveform.noise.generate(frequency, duration, sampleRate);
      expect(samples.length, expectedLength);
      for (final s in samples) {
        expect(s, greaterThanOrEqualTo(-1.0));
        expect(s, lessThanOrEqualTo(1.0));
      }
    });

    test('noise is random within range', () {
      final samples = Waveform.noise.generate(frequency, 0.5, sampleRate);
      // Check there is variance — not all the same value.
      final unique = samples.toSet();
      expect(unique.length, greaterThan(1), reason: 'Noise should produce varied values');
      // Check spread: should have positive and negative values.
      expect(samples.any((s) => s > 0), isTrue);
      expect(samples.any((s) => s < 0), isTrue);
    });
  });

  group('Envelope', () {
    test('ADSR shapes amplitude correctly', () {
      final env = Envelope(
        attack: 0.1,
        decay: 0.1,
        sustain: 0.5,
        release: 0.1,
      );
      const duration = 0.5;

      // During attack: amplitude rises.
      expect(env.amplitudeAt(0.0, duration), closeTo(0.0, 0.01));
      expect(env.amplitudeAt(0.05, duration), closeTo(0.5, 0.01));
      expect(env.amplitudeAt(0.1, duration), closeTo(1.0, 0.01));

      // During decay: amplitude falls from 1 to sustain.
      expect(env.amplitudeAt(0.15, duration), closeTo(0.75, 0.01));
      expect(env.amplitudeAt(0.2, duration), closeTo(0.5, 0.01));

      // During sustain: amplitude stays at sustain level.
      expect(env.amplitudeAt(0.3, duration), closeTo(0.5, 0.01));

      // During release: amplitude falls to 0.
      expect(env.amplitudeAt(0.4, duration), closeTo(0.5, 0.01));
      expect(env.amplitudeAt(0.45, duration), closeTo(0.25, 0.01));
      expect(env.amplitudeAt(0.5, duration), closeTo(0.0, 0.01));
    });

    test('preset starts near 0 during attack', () {
      final env = Envelope.preset();
      // At the very start, amplitude should be near 0.
      expect(env.amplitudeAt(0.0, 0.5), closeTo(0.0, 0.01));
      // A tiny bit into attack, still low.
      expect(env.amplitudeAt(0.001, 0.5), lessThan(0.2));
    });
  });

  group('Synthesizer', () {
    test('tone produces non-silent output', () {
      final samples = Synthesizer.tone(
        frequency: 440,
        duration: 0.1,
      );
      expect(samples.length, greaterThan(0));
      // At least some samples should be non-zero.
      expect(samples.any((s) => s != 0.0), isTrue);
    });

    test('tone applies envelope (first and last samples near 0)', () {
      final samples = Synthesizer.tone(
        frequency: 440,
        duration: 0.2,
        envelope: Envelope(
          attack: 0.05,
          decay: 0.02,
          sustain: 0.8,
          release: 0.05,
        ),
      );
      // First sample should be near zero (start of attack).
      expect(samples.first.abs(), lessThan(0.01));
      // Last sample should be near zero (end of release).
      expect(samples.last.abs(), lessThan(0.01));
    });

    test('mix combines buffers additively and clamps', () {
      final a = Float64List.fromList([0.5, -0.5, 0.8]);
      final b = Float64List.fromList([0.5, -0.5, 0.8]);
      final result = Synthesizer.mix([a, b]);
      expect(result.length, 3);
      expect(result[0], closeTo(1.0, 0.001));
      expect(result[1], closeTo(-1.0, 0.001));
      // 0.8 + 0.8 = 1.6, clamped to 1.0.
      expect(result[2], closeTo(1.0, 0.001));
    });

    test('mix handles different length buffers', () {
      final a = Float64List.fromList([0.5, 0.3]);
      final b = Float64List.fromList([0.5, 0.3, 0.7, 0.9]);
      final result = Synthesizer.mix([a, b]);
      expect(result.length, 4);
      expect(result[0], closeTo(1.0, 0.001));
      expect(result[2], closeTo(0.7, 0.001));
    });

    test('mix of empty list returns empty buffer', () {
      final result = Synthesizer.mix([]);
      expect(result.length, 0);
    });
  });
}
