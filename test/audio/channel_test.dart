import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('Audio', () {
    late Audio audio;

    setUp(() {
      audio = Audio();
    });

    tearDown(() {
      audio.dispose();
    });

    test('provides named channels', () {
      final sfx = audio.channel('sfx');
      final music = audio.channel('music');
      expect(sfx, isA<AudioChannel>());
      expect(music, isA<AudioChannel>());
      expect(sfx, isNot(same(music)));
    });

    test('same name returns same channel instance', () {
      final first = audio.channel('sfx');
      final second = audio.channel('sfx');
      expect(first, same(second));
    });

    test('muted flag defaults to false', () {
      expect(audio.muted, isFalse);
    });

    test('muted flag can be toggled', () {
      audio.muted = true;
      expect(audio.muted, isTrue);
      audio.muted = false;
      expect(audio.muted, isFalse);
    });

    test('isAvailable returns a bool', () {
      expect(audio.isAvailable, isA<bool>());
    });

    test('dispose stops all channels and clears them', () {
      // Create some channels.
      audio.channel('sfx');
      audio.channel('music');
      audio.channel('ui');

      // dispose should not throw.
      audio.dispose();

      // After dispose, requesting a channel creates a fresh one.
      final fresh = audio.channel('sfx');
      expect(fresh, isA<AudioChannel>());
    });

    test('stopAll does not throw on empty channels', () {
      expect(() => audio.stopAll(), returnsNormally);
    });

    test('beep does not throw', () {
      // With muted on so we don't actually play audio.
      audio.muted = true;
      expect(
        () => audio.beep(frequency: 880.0, duration: 0.1),
        returnsNormally,
      );
    });
  });

  group('AudioChannel', () {
    late Audio audio;

    setUp(() {
      audio = Audio();
    });

    tearDown(() {
      audio.dispose();
    });

    test('tone() does not throw', () {
      // Mute so we don't produce actual audio during tests.
      audio.muted = true;
      final ch = audio.channel('test');
      expect(
        () => ch.tone(frequency: 440.0, duration: 0.1),
        returnsNormally,
      );
    });

    test('tone() with all parameters does not throw', () {
      audio.muted = true;
      final ch = audio.channel('test');
      expect(
        () => ch.tone(
          frequency: 880.0,
          duration: 0.2,
          waveform: Waveform.square,
          envelope: const Envelope.preset(),
          volume: 0.5,
        ),
        returnsNormally,
      );
    });

    test('playMelody() accepts Melody object', () {
      audio.muted = true;
      final ch = audio.channel('test');
      final melody = Melody(bpm: 120);
      melody.note(Note.C4, Dur.quarter);
      melody.note(Note.E4, Dur.quarter);
      melody.note(Note.G4, Dur.half);

      expect(() => ch.playMelody(melody), returnsNormally);
    });

    test('stop() cancels playback without error', () {
      audio.muted = true;
      final ch = audio.channel('test');
      ch.tone(frequency: 440.0);
      expect(() => ch.stop(), returnsNormally);
    });

    test('stop() on a fresh channel does not throw', () {
      final ch = audio.channel('test');
      expect(() => ch.stop(), returnsNormally);
    });

    test('play() accepts DSL string', () {
      audio.muted = true;
      final ch = audio.channel('test');
      expect(
        () => ch.play('C4.q D4.q E4.h', bpm: 120),
        returnsNormally,
      );
    });

    test('play() with default bpm does not throw', () {
      audio.muted = true;
      final ch = audio.channel('test');
      expect(
        () => ch.play('C4.q R.e G4.q'),
        returnsNormally,
      );
    });
  });
}
