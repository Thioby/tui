import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('MelodyEvent', () {
    test('NoteEvent stores frequency and duration', () {
      final event = NoteEvent(440.0, 1.0, Waveform.sine);
      expect(event.frequency, equals(440.0));
      expect(event.beats, equals(1.0));
      expect(event.waveform, equals(Waveform.sine));
    });

    test('RestEvent stores duration', () {
      final event = RestEvent(2.0);
      expect(event.beats, equals(2.0));
    });
  });

  group('Melody builder', () {
    test('note adds NoteEvent', () {
      final melody = Melody();
      melody.note(440.0, 1.0);
      expect(melody.events, hasLength(1));
      expect(melody.events.first, isA<NoteEvent>());
      final event = melody.events.first as NoteEvent;
      expect(event.frequency, equals(440.0));
      expect(event.beats, equals(1.0));
      expect(event.waveform, equals(Waveform.square)); // melody default
    });

    test('note with custom waveform overrides default', () {
      final melody = Melody();
      melody.note(440.0, 1.0, waveform: Waveform.sine);
      final event = melody.events.first as NoteEvent;
      expect(event.waveform, equals(Waveform.sine));
    });

    test('rest adds RestEvent', () {
      final melody = Melody();
      melody.rest(0.5);
      expect(melody.events, hasLength(1));
      expect(melody.events.first, isA<RestEvent>());
      expect(melody.events.first.beats, equals(0.5));
    });

    test('totalBeats sums all events', () {
      final melody = Melody();
      melody.note(440.0, 1.0); // quarter
      melody.rest(0.5); // eighth
      melody.note(523.0, 2.0); // half
      expect(melody.totalBeats, equals(3.5));
    });

    test('totalSeconds computes correctly', () {
      final melody = Melody(bpm: 120);
      melody.note(440.0, 4.0); // whole note = 4 beats
      // At 120 BPM, 4 beats = 2.0 seconds
      expect(melody.totalSeconds, equals(2.0));
    });

    test('default constructor values', () {
      final melody = Melody();
      expect(melody.bpm, equals(120));
      expect(melody.waveform, equals(Waveform.square));
      expect(melody.volume, equals(0.7));
      expect(melody.events, isEmpty);
    });

    test('waveform is mutable', () {
      final melody = Melody();
      expect(melody.waveform, equals(Waveform.square));
      melody.waveform = Waveform.sine;
      expect(melody.waveform, equals(Waveform.sine));
    });
  });

  group('Melody.toSamples', () {
    test('produces audio data', () {
      final melody = Melody(bpm: 120);
      melody.note(440.0, 1.0); // quarter note at 120 BPM = 0.5s
      final samples = melody.toSamples(sampleRate: 44100);
      expect(samples, isA<Float64List>());
      expect(samples.length, greaterThan(0));
      // Should have non-zero samples (not silence).
      expect(samples.any((s) => s != 0.0), isTrue);
    });

    test('rest produces silence', () {
      final melody = Melody(bpm: 120);
      melody.rest(1.0); // quarter rest
      final samples = melody.toSamples(sampleRate: 44100);
      expect(samples.length, greaterThan(0));
      // All samples should be zero (silence).
      for (final s in samples) {
        expect(s, equals(0.0));
      }
    });

    test('sample count matches expected duration', () {
      final melody = Melody(bpm: 120);
      melody.note(440.0, 2.0); // half note = 1.0s at 120 BPM
      const sampleRate = 44100;
      final samples = melody.toSamples(sampleRate: sampleRate);
      // 1.0 seconds * 44100 = 44100 samples
      expect(samples.length, equals(44100));
    });
  });

  group('Melody.parse', () {
    test('parses note with octave and duration', () {
      final melody = Melody.parse('C4.q');
      expect(melody.events, hasLength(1));
      final event = melody.events.first as NoteEvent;
      expect(event.frequency, closeTo(Note.C4, 0.01));
      expect(event.beats, equals(Dur.quarter));
    });

    test('parses multiple notes', () {
      final melody = Melody.parse('C4.q D4.q E4.h');
      expect(melody.events, hasLength(3));
      final first = melody.events[0] as NoteEvent;
      final second = melody.events[1] as NoteEvent;
      final third = melody.events[2] as NoteEvent;
      expect(first.frequency, closeTo(Note.C4, 0.01));
      expect(first.beats, equals(Dur.quarter));
      expect(second.frequency, closeTo(Note.D4, 0.01));
      expect(second.beats, equals(Dur.quarter));
      expect(third.frequency, closeTo(Note.E4, 0.01));
      expect(third.beats, equals(Dur.half));
    });

    test('parses rests', () {
      final melody = Melody.parse('R.q R.h');
      expect(melody.events, hasLength(2));
      expect(melody.events[0], isA<RestEvent>());
      expect(melody.events[0].beats, equals(Dur.quarter));
      expect(melody.events[1], isA<RestEvent>());
      expect(melody.events[1].beats, equals(Dur.half));
    });

    test('parses sharps (Cs, Fs, etc.)', () {
      final melody = Melody.parse('Cs4.e Fs5.q');
      expect(melody.events, hasLength(2));
      final cs = melody.events[0] as NoteEvent;
      final fs = melody.events[1] as NoteEvent;
      expect(cs.frequency, closeTo(Note.Cs4, 0.01));
      expect(cs.beats, equals(Dur.eighth));
      expect(fs.frequency, closeTo(Note.Fs5, 0.01));
      expect(fs.beats, equals(Dur.quarter));
    });

    test('ignores bar separators |', () {
      final melody = Melody.parse('C4.q D4.q | E4.q F4.q');
      expect(melody.events, hasLength(4));
      expect(melody.events[0], isA<NoteEvent>());
      expect(melody.events[1], isA<NoteEvent>());
      expect(melody.events[2], isA<NoteEvent>());
      expect(melody.events[3], isA<NoteEvent>());
    });

    test('parses all duration codes', () {
      final melody = Melody.parse(
        'C4.w C4.h C4.dh C4.q C4.dq C4.e C4.de C4.s C4.t',
      );
      expect(melody.events, hasLength(9));
      expect(melody.events[0].beats, equals(Dur.whole));
      expect(melody.events[1].beats, equals(Dur.half));
      expect(melody.events[2].beats, equals(Dur.dottedHalf));
      expect(melody.events[3].beats, equals(Dur.quarter));
      expect(melody.events[4].beats, equals(Dur.dottedQuarter));
      expect(melody.events[5].beats, equals(Dur.eighth));
      expect(melody.events[6].beats, equals(Dur.dottedEighth));
      expect(melody.events[7].beats, equals(Dur.sixteenth));
      expect(melody.events[8].beats, closeTo(1.0 / 3.0, 0.001));
    });

    test('respects bpm and waveform parameters', () {
      final melody = Melody.parse(
        'C4.q',
        bpm: 60,
        waveform: Waveform.sine,
      );
      expect(melody.bpm, equals(60));
      expect(melody.waveform, equals(Waveform.sine));
    });

    test('throws FormatException on invalid token', () {
      expect(
        () => Melody.parse('X4.q'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException on missing dot', () {
      expect(
        () => Melody.parse('C4q'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException on unknown duration code', () {
      expect(
        () => Melody.parse('C4.z'),
        throwsA(isA<FormatException>()),
      );
    });

    test('parses dynamics suffix @ff', () {
      final melody = Melody.parse('C4.q@ff D4.q@pp');
      expect(melody.events, hasLength(2));
      final c = melody.events[0] as NoteEvent;
      final d = melody.events[1] as NoteEvent;
      expect(c.volume, equals(1.0));
      expect(d.volume, equals(0.3));
    });

    test('parses all dynamic levels', () {
      final melody = Melody.parse(
        'C4.q@ppp C4.q@pp C4.q@p C4.q@mp C4.q@mf C4.q@f C4.q@ff',
      );
      final volumes =
          melody.events.cast<NoteEvent>().map((e) => e.volume).toList();
      expect(volumes, equals([0.15, 0.3, 0.45, 0.6, 0.75, 0.88, 1.0]));
    });

    test('notes without dynamics have null volume', () {
      final melody = Melody.parse('C4.q D4.q@mf E4.q');
      final c = melody.events[0] as NoteEvent;
      final d = melody.events[1] as NoteEvent;
      final e = melody.events[2] as NoteEvent;
      expect(c.volume, isNull);
      expect(d.volume, equals(0.75));
      expect(e.volume, isNull);
    });

    test('throws FormatException on unknown dynamics', () {
      expect(
        () => Melody.parse('C4.q@xyz'),
        throwsA(isA<FormatException>()),
      );
    });

    test('dynamics work with rests (rest ignores @)', () {
      // Rests don't have dynamics — only notes do
      final melody = Melody.parse('C4.q@ff R.q C4.q@pp');
      expect(melody.events, hasLength(3));
      expect(melody.events[1], isA<RestEvent>());
    });

    test('parse passes vibrato and timbre to melody', () {
      final melody = Melody.parse(
        'C4.q',
        vibrato: Vibrato.violin,
        timbre: Timbre.violin,
      );
      expect(melody.vibrato, equals(Vibrato.violin));
      expect(melody.timbre, equals(Timbre.violin));
    });
  });

  group('Melody per-note dynamics', () {
    test('note with explicit volume stores it', () {
      final melody = Melody();
      melody.note(440.0, 1.0, volume: 0.5);
      final event = melody.events.first as NoteEvent;
      expect(event.volume, equals(0.5));
    });

    test('note without volume has null volume', () {
      final melody = Melody();
      melody.note(440.0, 1.0);
      final event = melody.events.first as NoteEvent;
      expect(event.volume, isNull);
    });

    test('per-note volume affects sample amplitude', () {
      final loud = Melody(bpm: 120, volume: 1.0);
      loud.note(440.0, 1.0, volume: 1.0);
      final loudSamples = loud.toSamples();

      final quiet = Melody(bpm: 120, volume: 1.0);
      quiet.note(440.0, 1.0, volume: 0.3);
      final quietSamples = quiet.toSamples();

      // Peak of quiet should be less than peak of loud
      var loudPeak = 0.0;
      var quietPeak = 0.0;
      for (final s in loudSamples) {
        if (s.abs() > loudPeak) loudPeak = s.abs();
      }
      for (final s in quietSamples) {
        if (s.abs() > quietPeak) quietPeak = s.abs();
      }
      expect(quietPeak, lessThan(loudPeak));
    });
  });

  group('Melody legato ties', () {
    test('NoteEvent stores tied flag', () {
      final event = NoteEvent(440.0, 1.0, Waveform.sine, tied: true);
      expect(event.tied, isTrue);
    });

    test('NoteEvent tied defaults to false', () {
      final event = NoteEvent(440.0, 1.0, Waveform.sine);
      expect(event.tied, isFalse);
    });

    test('note() accepts tied parameter', () {
      final melody = Melody();
      melody.note(440.0, 1.0, tied: true);
      final event = melody.events.first as NoteEvent;
      expect(event.tied, isTrue);
    });

    test('tied notes produce continuous audio', () {
      // Two tied notes should blend smoothly
      final tied = Melody(bpm: 120);
      tied.note(440.0, 1.0, tied: true);
      tied.note(440.0, 1.0);
      final samples = tied.toSamples(sampleRate: 8000);
      expect(samples.length, greaterThan(0));
      expect(samples.any((s) => s != 0.0), isTrue);
    });

    test('DSL C4.q_ parses tie', () {
      final melody = Melody.parse('C4.q_ C4.q');
      expect(melody.events, hasLength(2));
      final first = melody.events[0] as NoteEvent;
      final second = melody.events[1] as NoteEvent;
      expect(first.tied, isTrue);
      expect(second.tied, isFalse);
    });

    test('DSL multiple ties: C4.q_ C4.q_ C4.q', () {
      final melody = Melody.parse('C4.q_ C4.q_ C4.q');
      expect(melody.events, hasLength(3));
      expect((melody.events[0] as NoteEvent).tied, isTrue);
      expect((melody.events[1] as NoteEvent).tied, isTrue);
      expect((melody.events[2] as NoteEvent).tied, isFalse);
    });

    test('DSL tie with dynamics: C4.q@mf_', () {
      final melody = Melody.parse('C4.q@mf_ C4.q');
      final first = melody.events[0] as NoteEvent;
      expect(first.tied, isTrue);
      expect(first.volume, equals(0.75));
    });

    test('DSL tie with articulation: C4.q:tn_', () {
      final melody = Melody.parse('C4.q:tn_ C4.q');
      final first = melody.events[0] as NoteEvent;
      expect(first.tied, isTrue);
      expect(first.articulation, equals(Articulation.tenuto));
    });
  });

  group('Melody DSL combined suffixes', () {
    test('dynamics + articulation + tie: C4.q@ff:st_', () {
      final melody = Melody.parse('C4.q@ff:st_ C4.q');
      final event = melody.events[0] as NoteEvent;
      expect(event.volume, equals(1.0));
      expect(event.articulation, equals(Articulation.staccato));
      expect(event.tied, isTrue);
    });

    test('mixed notes preserve correct parsing', () {
      final melody = Melody.parse('C4.q@ff E4.e:pz G4.h_ G4.h');
      expect(melody.events, hasLength(4));
      final c = melody.events[0] as NoteEvent;
      final e = melody.events[1] as NoteEvent;
      final g1 = melody.events[2] as NoteEvent;
      final g2 = melody.events[3] as NoteEvent;
      expect(c.volume, equals(1.0));
      expect(c.articulation, isNull);
      expect(c.tied, isFalse);
      expect(e.articulation, equals(Articulation.pizzicato));
      expect(g1.tied, isTrue);
      expect(g2.tied, isFalse);
    });
  });

  group('Melody with vibrato/timbre', () {
    test('toSamples with vibrato produces valid output', () {
      final melody = Melody(bpm: 120, vibrato: Vibrato.violin);
      melody.note(440.0, 2.0);
      final samples = melody.toSamples();
      expect(samples.length, greaterThan(0));
      expect(samples.any((s) => s != 0.0), isTrue);
    });

    test('toSamples with timbre produces valid output', () {
      final melody = Melody(bpm: 120, timbre: Timbre.cello);
      melody.note(220.0, 2.0);
      final samples = melody.toSamples();
      expect(samples.length, greaterThan(0));
      expect(samples.any((s) => s != 0.0), isTrue);
    });
  });
}
