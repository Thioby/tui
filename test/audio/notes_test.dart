import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('Note frequencies', () {
    test('A4 = 440 Hz', () {
      expect(Note.A4, equals(440.0));
    });

    test('A5 = 880 Hz', () {
      expect(Note.A5, equals(880.0));
    });

    test('C4 ≈ 261.63 Hz', () {
      expect(Note.C4, closeTo(261.63, 0.01));
    });

    test('A0 = 27.5 Hz', () {
      expect(Note.A0, equals(27.5));
    });

    test('C8 ≈ 4186.01 Hz', () {
      expect(Note.C8, closeTo(4186.01, 0.01));
    });

    test('octave doubling: A3 = 220, A4 = 440, A5 = 880', () {
      expect(Note.A3, equals(220.0));
      expect(Note.A4, equals(440.0));
      expect(Note.A5, equals(880.0));
      expect(Note.A5, equals(Note.A4 * 2));
      expect(Note.A4, equals(Note.A3 * 2));
    });
  });

  group('noteFrequency()', () {
    test('matches static constant for A4', () {
      expect(noteFrequency('A', 4), closeTo(Note.A4, 0.01));
    });

    test('matches static constant for C4', () {
      expect(noteFrequency('C', 4), closeTo(Note.C4, 0.01));
    });

    test('matches static constant for Cs4 (C#4)', () {
      expect(noteFrequency('Cs', 4), closeTo(Note.Cs4, 0.01));
    });

    test('matches static constant for A5', () {
      expect(noteFrequency('A', 5), closeTo(Note.A5, 0.01));
    });

    test('matches static constant for G3', () {
      expect(noteFrequency('G', 3), closeTo(Note.G3, 0.01));
    });

    test('matches static constant for C0', () {
      expect(noteFrequency('C', 0), closeTo(Note.C0, 0.01));
    });

    test('matches static constant for C8', () {
      expect(noteFrequency('C', 8), closeTo(Note.C8, 0.01));
    });

    test('Note.frequency delegates to noteFrequency', () {
      expect(Note.frequency('A', 4), closeTo(noteFrequency('A', 4), 0.001));
    });

    test('throws on unknown note name', () {
      expect(() => noteFrequency('X', 4), throwsArgumentError);
    });

    test('throws on octave out of range', () {
      expect(() => noteFrequency('A', -1), throwsArgumentError);
      expect(() => noteFrequency('A', 9), throwsArgumentError);
    });

    test('throws for notes above C8', () {
      expect(() => noteFrequency('D', 8), throwsArgumentError);
    });
  });

  group('Dur constants', () {
    test('whole = 4x quarter', () {
      expect(Dur.whole, equals(4.0 * Dur.quarter));
    });

    test('half = 2x quarter', () {
      expect(Dur.half, equals(2.0 * Dur.quarter));
    });

    test('eighth = 0.5x quarter', () {
      expect(Dur.eighth, equals(0.5 * Dur.quarter));
    });

    test('sixteenth = 0.25x quarter', () {
      expect(Dur.sixteenth, equals(0.25 * Dur.quarter));
    });

    test('thirtySecond = 0.125', () {
      expect(Dur.thirtySecond, equals(0.125));
    });

    test('dotted values are 1.5x their base', () {
      expect(Dur.dottedHalf, equals(Dur.half * 1.5));
      expect(Dur.dottedQuarter, equals(Dur.quarter * 1.5));
      expect(Dur.dottedEighth, equals(Dur.eighth * 1.5));
      expect(Dur.dottedSixteenth, equals(Dur.sixteenth * 1.5));
    });
  });

  group('Dur helpers', () {
    test('quarterAt(120) = 0.5 seconds', () {
      expect(Dur.quarterAt(120), equals(0.5));
    });

    test('quarterAt(60) = 1.0 seconds', () {
      expect(Dur.quarterAt(60), equals(1.0));
    });

    test('toSeconds converts beats to seconds', () {
      // At 120 BPM, quarter = 0.5s, so whole (4 beats) = 2.0s
      expect(Dur.toSeconds(Dur.whole, 120), equals(2.0));
      expect(Dur.toSeconds(Dur.half, 120), equals(1.0));
      expect(Dur.toSeconds(Dur.quarter, 120), equals(0.5));
      expect(Dur.toSeconds(Dur.eighth, 120), equals(0.25));
    });

    test('toSeconds at 60 BPM: 1 beat = 1 second', () {
      expect(Dur.toSeconds(1.0, 60), equals(1.0));
      expect(Dur.toSeconds(4.0, 60), equals(4.0));
    });
  });
}
