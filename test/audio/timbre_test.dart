import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('Harmonic', () {
    test('stores number and amplitude', () {
      const h = Harmonic(3, 0.42);
      expect(h.number, equals(3));
      expect(h.amplitude, equals(0.42));
    });
  });

  group('Timbre presets', () {
    test('violin has 8 harmonics starting with fundamental', () {
      expect(Timbre.violin.harmonics.length, equals(8));
      expect(Timbre.violin.harmonics.first.number, equals(1));
      expect(Timbre.violin.harmonics.first.amplitude, equals(1.0));
    });

    test('cello has strong low harmonics', () {
      final cello = Timbre.cello;
      // 2nd harmonic should be stronger than violin's
      final cello2nd = cello.harmonics[1].amplitude;
      final violin2nd = Timbre.violin.harmonics[1].amplitude;
      expect(cello2nd, greaterThan(violin2nd));
    });

    test('pure timbre has only fundamental', () {
      expect(Timbre.pure.harmonics.length, equals(1));
      expect(Timbre.pure.harmonics.first.number, equals(1));
    });

    test('all presets have decreasing amplitude', () {
      for (final timbre in [Timbre.violin, Timbre.viola, Timbre.cello]) {
        for (var i = 1; i < timbre.harmonics.length; i++) {
          expect(
            timbre.harmonics[i].amplitude,
            lessThanOrEqualTo(timbre.harmonics[i - 1].amplitude),
            reason: 'Harmonic ${timbre.harmonics[i].number} '
                'should be <= harmonic ${timbre.harmonics[i - 1].number}',
          );
        }
      }
    });
  });

  group('Timbre.generate', () {
    const sampleRate = 44100;
    const frequency = 440.0;
    const duration = 0.1;

    test('produces correct length', () {
      final samples = Timbre.violin.generate(frequency, duration, sampleRate);
      final expected = (duration * sampleRate).round();
      expect(samples.length, equals(expected));
    });

    test('output is within [-1, 1]', () {
      final samples = Timbre.violin.generate(frequency, duration, sampleRate);
      for (final s in samples) {
        expect(s, greaterThanOrEqualTo(-1.0));
        expect(s, lessThanOrEqualTo(1.0));
      }
    });

    test('pure timbre matches sine wave shape', () {
      final pure = Timbre.pure.generate(frequency, duration, sampleRate);
      final sine = Waveform.sine.generate(frequency, duration, sampleRate);
      // Pure timbre with 1 harmonic should be very close to sine
      for (var i = 0; i < pure.length; i++) {
        expect(pure[i], closeTo(sine[i], 0.02));
      }
    });

    test('violin timbre differs from pure sine', () {
      final violin = Timbre.violin.generate(frequency, duration, sampleRate);
      final pure = Timbre.pure.generate(frequency, duration, sampleRate);
      // Should have differences due to overtones
      var diffSum = 0.0;
      for (var i = 0; i < violin.length; i++) {
        diffSum += (violin[i] - pure[i]).abs();
      }
      expect(diffSum / violin.length, greaterThan(0.01));
    });

    test('respects Nyquist — skips harmonics above half sample rate', () {
      // Very high base frequency — most harmonics should be above Nyquist
      final samples = Timbre.violin.generate(10000.0, 0.01, sampleRate);
      expect(samples.length, greaterThan(0));
      // Should still produce valid output
      for (final s in samples) {
        expect(s, greaterThanOrEqualTo(-1.0));
        expect(s, lessThanOrEqualTo(1.0));
      }
    });

    test('generates non-silent output', () {
      final samples = Timbre.cello.generate(220.0, 0.2, sampleRate);
      expect(samples.any((s) => s != 0.0), isTrue);
    });

    test('works with vibrato parameter', () {
      final withVib = Timbre.violin.generate(
        frequency,
        0.5,
        sampleRate,
        vibrato: Vibrato.violin,
      );
      final without = Timbre.violin.generate(frequency, 0.5, sampleRate);
      // Should produce different samples due to pitch modulation
      var diffCount = 0;
      for (var i = 0; i < withVib.length; i++) {
        if ((withVib[i] - without[i]).abs() > 0.001) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });
  });
}
