import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('Articulation presets', () {
    test('staccato has very short envelope', () {
      final env = Articulation.staccato.envelope;
      expect(env.attack, equals(0.003));
      expect(env.decay, equals(0.06));
      expect(env.sustain, equals(0.0));
      expect(env.release, equals(0.01));
    });

    test('pizzicato has snap attack and fast decay', () {
      final env = Articulation.pizzicato.envelope;
      expect(env.attack, equals(0.001));
      expect(env.decay, equals(0.12));
      expect(env.sustain, equals(0.0));
      expect(env.release, equals(0.02));
    });

    test('spiccato is between staccato and normal', () {
      final env = Articulation.spiccato.envelope;
      expect(env.attack, equals(0.005));
      expect(env.decay, equals(0.08));
      expect(env.sustain, equals(0.1));
      expect(env.release, equals(0.03));
    });

    test('tenuto holds full value', () {
      final env = Articulation.tenuto.envelope;
      expect(env.attack, equals(0.01));
      expect(env.sustain, equals(0.85));
      expect(env.release, equals(0.04));
    });
  });

  group('Articulation DSL codes', () {
    test('codes map contains all presets', () {
      expect(Articulation.codes, hasLength(4));
      expect(Articulation.codes['st'], equals(Articulation.staccato));
      expect(Articulation.codes['pz'], equals(Articulation.pizzicato));
      expect(Articulation.codes['sp'], equals(Articulation.spiccato));
      expect(Articulation.codes['tn'], equals(Articulation.tenuto));
    });
  });

  group('Articulation in NoteEvent', () {
    test('NoteEvent stores articulation', () {
      final event = NoteEvent(
        440.0,
        1.0,
        Waveform.sine,
        articulation: Articulation.staccato,
      );
      expect(event.articulation, equals(Articulation.staccato));
    });

    test('NoteEvent articulation defaults to null', () {
      final event = NoteEvent(440.0, 1.0, Waveform.sine);
      expect(event.articulation, isNull);
    });
  });

  group('Articulation in Melody', () {
    test('note() accepts articulation parameter', () {
      final melody = Melody();
      melody.note(440.0, 1.0, articulation: Articulation.pizzicato);
      final event = melody.events.first as NoteEvent;
      expect(event.articulation, equals(Articulation.pizzicato));
    });

    test('articulation overrides default envelope in synthesis', () {
      // Staccato note should be mostly silent at the end
      final staccatoMelody = Melody(bpm: 60);
      staccatoMelody.note(
        440.0,
        2.0,
        articulation: Articulation.staccato,
      );
      final samples = staccatoMelody.toSamples(sampleRate: 8000);

      // Last quarter of samples should be near-silent
      final lastQuarter = samples.length * 3 ~/ 4;
      var maxTail = 0.0;
      for (var i = lastQuarter; i < samples.length; i++) {
        if (samples[i].abs() > maxTail) maxTail = samples[i].abs();
      }
      expect(maxTail, lessThan(0.05));
    });
  });

  group('Articulation DSL parsing', () {
    test('C4.q:st parses staccato', () {
      final melody = Melody.parse('C4.q:st');
      expect(melody.events, hasLength(1));
      final event = melody.events.first as NoteEvent;
      expect(event.articulation, equals(Articulation.staccato));
      expect(event.beats, equals(Dur.quarter));
    });

    test('C4.e:pz parses pizzicato', () {
      final melody = Melody.parse('C4.e:pz');
      final event = melody.events.first as NoteEvent;
      expect(event.articulation, equals(Articulation.pizzicato));
    });

    test('C4.h:sp parses spiccato', () {
      final melody = Melody.parse('C4.h:sp');
      final event = melody.events.first as NoteEvent;
      expect(event.articulation, equals(Articulation.spiccato));
    });

    test('C4.q:tn parses tenuto', () {
      final melody = Melody.parse('C4.q:tn');
      final event = melody.events.first as NoteEvent;
      expect(event.articulation, equals(Articulation.tenuto));
    });

    test('dynamics + articulation: C4.q@ff:st', () {
      final melody = Melody.parse('C4.q@ff:st');
      final event = melody.events.first as NoteEvent;
      expect(event.volume, equals(1.0));
      expect(event.articulation, equals(Articulation.staccato));
    });

    test('throws on unknown articulation code', () {
      expect(
        () => Melody.parse('C4.q:xx'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
