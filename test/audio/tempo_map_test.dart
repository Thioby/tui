import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('TempoChange', () {
    test('stores beat and bpm', () {
      const tc = TempoChange(8.0, 80);
      expect(tc.beat, equals(8.0));
      expect(tc.bpm, equals(80));
    });
  });

  group('TempoMap.bpmAt', () {
    test('returns baseBpm when no changes', () {
      final map = TempoMap(120, []);
      expect(map.bpmAt(0.0), equals(120.0));
      expect(map.bpmAt(100.0), equals(120.0));
    });

    test('returns baseBpm before first change', () {
      final map = TempoMap(120, [TempoChange(8.0, 80)]);
      expect(map.bpmAt(0.0), closeTo(120.0, 0.1));
    });

    test('interpolates to first change', () {
      final map = TempoMap(120, [TempoChange(4.0, 80)]);
      // At beat 2, should be halfway between 120 and 80 = 100
      expect(map.bpmAt(2.0), closeTo(100.0, 0.5));
    });

    test('returns last bpm after last change', () {
      final map = TempoMap(120, [TempoChange(4.0, 80)]);
      expect(map.bpmAt(10.0), equals(80.0));
    });

    test('interpolates between two changes (ritardando)', () {
      final map = TempoMap(120, [
        TempoChange(4.0, 120),
        TempoChange(8.0, 60),
      ]);
      // Midpoint between beat 4 and 8 = beat 6
      expect(map.bpmAt(6.0), closeTo(90.0, 0.5));
    });

    test('handles multiple change points', () {
      final map = TempoMap(120, [
        TempoChange(4.0, 100),
        TempoChange(8.0, 60),
        TempoChange(12.0, 120),
      ]);
      expect(map.bpmAt(6.0), closeTo(80.0, 0.5));
      expect(map.bpmAt(10.0), closeTo(90.0, 0.5));
      expect(map.bpmAt(20.0), equals(120.0));
    });

    test('sorts changes by beat position', () {
      // Changes provided out of order
      final map = TempoMap(120, [
        TempoChange(8.0, 60),
        TempoChange(4.0, 100),
      ]);
      expect(map.bpmAt(6.0), closeTo(80.0, 0.5));
    });
  });

  group('TempoMap.beatsToSeconds', () {
    test('constant tempo matches simple calculation', () {
      final map = TempoMap(120, []);
      // At 120 BPM: 1 beat = 0.5s, 4 beats = 2.0s
      expect(map.beatsToSeconds(0, 4.0), closeTo(2.0, 0.05));
    });

    test('zero beats returns zero', () {
      final map = TempoMap(120, []);
      expect(map.beatsToSeconds(0, 0), equals(0.0));
    });

    test('ritardando makes phrase longer', () {
      final constant = TempoMap(120, []);
      final rit = TempoMap(120, [
        TempoChange(0.0, 120),
        TempoChange(4.0, 60), // slow to half speed
      ]);
      final normalDuration = constant.beatsToSeconds(0, 4.0);
      final ritDuration = rit.beatsToSeconds(0, 4.0);
      expect(ritDuration, greaterThan(normalDuration));
    });

    test('accelerando makes phrase shorter', () {
      final constant = TempoMap(60, []);
      final accel = TempoMap(60, [
        TempoChange(0.0, 60),
        TempoChange(4.0, 120),
      ]);
      final normalDuration = constant.beatsToSeconds(0, 4.0);
      final accelDuration = accel.beatsToSeconds(0, 4.0);
      expect(accelDuration, lessThan(normalDuration));
    });
  });

  group('Melody with TempoMap', () {
    test('totalSeconds accounts for tempo map', () {
      final melody = Melody(
        bpm: 120,
        tempoMap: TempoMap(120, []),
      );
      melody.note(440.0, 4.0); // 4 beats at 120 BPM = 2s
      expect(melody.totalSeconds, closeTo(2.0, 0.05));
    });

    test('tempo map produces valid samples', () {
      final melody = Melody(
        bpm: 120,
        tempoMap: TempoMap(120, [
          TempoChange(0.0, 120),
          TempoChange(2.0, 80),
        ]),
      );
      melody.note(440.0, 2.0);
      melody.note(330.0, 2.0);
      final samples = melody.toSamples();
      expect(samples.length, greaterThan(0));
      expect(samples.any((s) => s != 0.0), isTrue);
    });

    test('ritardando produces longer output than fixed tempo', () {
      final fixed = Melody(bpm: 120);
      fixed.note(440.0, 4.0);

      final rit = Melody(
        bpm: 120,
        tempoMap: TempoMap(120, [
          TempoChange(0.0, 120),
          TempoChange(4.0, 60),
        ]),
      );
      rit.note(440.0, 4.0);

      expect(rit.toSamples().length, greaterThan(fixed.toSamples().length));
    });
  });
}
