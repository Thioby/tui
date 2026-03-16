import 'dart:math';

import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('MelodyOrnaments.trill', () {
    test('expands into alternating notes', () {
      final melody = Melody(bpm: 120);
      melody.trill(Note.C4, Dur.quarter);
      expect(melody.events.length, greaterThanOrEqualTo(4));
      // Even-indexed notes should be C4, odd should be D4
      for (var i = 0; i < melody.events.length; i++) {
        final event = melody.events[i] as NoteEvent;
        if (i.isEven) {
          expect(event.frequency, closeTo(Note.C4, 0.01));
        } else {
          // Default 2 semitones up = D4
          final expected = Note.C4 * pow(2.0, 2 / 12.0);
          expect(event.frequency, closeTo(expected, 0.01));
        }
      }
    });

    test('total beats equal original duration', () {
      final melody = Melody(bpm: 120);
      melody.trill(Note.A4, Dur.half);
      expect(melody.totalBeats, closeTo(Dur.half, 0.001));
    });

    test('custom semitones interval', () {
      final melody = Melody(bpm: 120);
      melody.trill(Note.C4, Dur.quarter, semitones: 1);
      // Upper note should be 1 semitone up = Cs4
      final upper = melody.events[1] as NoteEvent;
      final expected = Note.C4 * pow(2.0, 1 / 12.0);
      expect(upper.frequency, closeTo(expected, 0.01));
    });

    test('volume is passed to individual notes', () {
      final melody = Melody(bpm: 120);
      melody.trill(Note.C4, Dur.quarter, volume: 0.5);
      for (final event in melody.events) {
        expect((event as NoteEvent).volume, equals(0.5));
      }
    });

    test('trill produces valid audio', () {
      final melody = Melody(bpm: 120);
      melody.trill(Note.E5, Dur.half);
      final samples = melody.toSamples(sampleRate: 8000);
      expect(samples.length, greaterThan(0));
      expect(samples.any((s) => s != 0.0), isTrue);
    });
  });

  group('MelodyOrnaments.mordent', () {
    test('expands into 4 notes (3 ornament + main)', () {
      final melody = Melody(bpm: 120);
      melody.mordent(Note.E4, Dur.quarter);
      expect(melody.events, hasLength(4));
    });

    test('pattern is principal-lower-principal-principal', () {
      final melody = Melody(bpm: 120);
      melody.mordent(Note.E4, Dur.quarter);
      final notes = melody.events.cast<NoteEvent>();
      final lower = Note.E4 / pow(2.0, 2 / 12.0);
      expect(notes[0].frequency, closeTo(Note.E4, 0.01));
      expect(notes[1].frequency, closeTo(lower, 0.5));
      expect(notes[2].frequency, closeTo(Note.E4, 0.01));
      expect(notes[3].frequency, closeTo(Note.E4, 0.01));
    });

    test('total beats equal original duration', () {
      final melody = Melody(bpm: 120);
      melody.mordent(Note.A4, Dur.half);
      expect(melody.totalBeats, closeTo(Dur.half, 0.001));
    });

    test('ornament takes first 25% of duration', () {
      final melody = Melody(bpm: 120);
      melody.mordent(Note.C4, Dur.quarter);
      final notes = melody.events.cast<NoteEvent>();
      final ornDur = notes[0].beats + notes[1].beats + notes[2].beats;
      final mainDur = notes[3].beats;
      expect(ornDur, closeTo(Dur.quarter * 0.25, 0.001));
      expect(mainDur, closeTo(Dur.quarter * 0.75, 0.001));
    });
  });

  group('MelodyOrnaments.turn', () {
    test('expands into 5 notes (4 ornament + main)', () {
      final melody = Melody(bpm: 120);
      melody.turn(Note.G4, Dur.quarter);
      expect(melody.events, hasLength(5));
    });

    test('pattern is upper-principal-lower-principal-principal', () {
      final melody = Melody(bpm: 120);
      melody.turn(Note.G4, Dur.quarter);
      final notes = melody.events.cast<NoteEvent>();
      final upper = Note.G4 * pow(2.0, 2 / 12.0);
      final lower = Note.G4 / pow(2.0, 2 / 12.0);
      expect(notes[0].frequency, closeTo(upper, 0.5));
      expect(notes[1].frequency, closeTo(Note.G4, 0.01));
      expect(notes[2].frequency, closeTo(lower, 0.5));
      expect(notes[3].frequency, closeTo(Note.G4, 0.01));
      expect(notes[4].frequency, closeTo(Note.G4, 0.01));
    });

    test('total beats equal original duration', () {
      final melody = Melody(bpm: 120);
      melody.turn(Note.G4, Dur.half);
      expect(melody.totalBeats, closeTo(Dur.half, 0.001));
    });
  });

  group('MelodyOrnaments.graceNote', () {
    test('expands into 2 notes (grace + main)', () {
      final melody = Melody(bpm: 120);
      melody.graceNote(Note.D4, Note.E4, Dur.quarter);
      expect(melody.events, hasLength(2));
    });

    test('first note is grace frequency, second is main', () {
      final melody = Melody(bpm: 120);
      melody.graceNote(Note.D4, Note.E4, Dur.quarter);
      final notes = melody.events.cast<NoteEvent>();
      expect(notes[0].frequency, closeTo(Note.D4, 0.01));
      expect(notes[1].frequency, closeTo(Note.E4, 0.01));
    });

    test('grace note is very short', () {
      final melody = Melody(bpm: 120);
      melody.graceNote(Note.D4, Note.E4, Dur.quarter);
      final grace = melody.events[0] as NoteEvent;
      // Grace note max 12% of total or 1/32nd
      expect(grace.beats, lessThanOrEqualTo(Dur.thirtySecond));
    });

    test('total beats equal original duration', () {
      final melody = Melody(bpm: 120);
      melody.graceNote(Note.D4, Note.E4, Dur.half);
      expect(melody.totalBeats, closeTo(Dur.half, 0.001));
    });

    test('grace note produces valid audio', () {
      final melody = Melody(bpm: 120);
      melody.graceNote(Note.B3, Note.C4, Dur.quarter);
      final samples = melody.toSamples(sampleRate: 8000);
      expect(samples.length, greaterThan(0));
      expect(samples.any((s) => s != 0.0), isTrue);
    });
  });

  group('Ornament DSL parsing', () {
    test('C4.q~tr parses as trill', () {
      final melody = Melody.parse('C4.q~tr');
      // Trill expands to multiple notes
      expect(melody.events.length, greaterThanOrEqualTo(4));
      expect(melody.totalBeats, closeTo(Dur.quarter, 0.001));
    });

    test('E4.h~mr parses as mordent', () {
      final melody = Melody.parse('E4.h~mr');
      expect(melody.events, hasLength(4));
      expect(melody.totalBeats, closeTo(Dur.half, 0.001));
    });

    test('G4.q~tn parses as turn', () {
      final melody = Melody.parse('G4.q~tn');
      expect(melody.events, hasLength(5));
      expect(melody.totalBeats, closeTo(Dur.quarter, 0.001));
    });

    test('ornament with dynamics: C4.q@ff~tr', () {
      final melody = Melody.parse('C4.q@ff~tr');
      expect(melody.events.length, greaterThanOrEqualTo(4));
      // All trill notes should have ff volume
      for (final event in melody.events) {
        expect((event as NoteEvent).volume, equals(1.0));
      }
    });

    test('throws on unknown ornament code', () {
      expect(
        () => Melody.parse('C4.q~xx'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
