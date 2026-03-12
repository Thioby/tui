import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('AudioPlayer', () {
    late AudioPlayer player;

    setUp(() {
      player = AudioPlayer();
    });

    tearDown(() {
      player.stop();
    });

    test('isAvailable returns a bool', () {
      // Platform detection should not throw.
      final result = player.isAvailable;
      expect(result, isA<bool>());
    });

    test('playWav completes without error for a valid WAV', () async {
      if (!player.isAvailable) {
        markTestSkipped('No audio player available on this platform');
        return;
      }

      // Generate a very short tone (50ms) and encode to WAV.
      final samples = Synthesizer.tone(
        frequency: 440,
        duration: 0.05,
        volume: 0.0, // silent so tests don't make noise
      );
      final wavBytes = WavWriter.encode(samples);

      // Should complete without throwing.
      await player.playWav(wavBytes);
    });

    test('stop kills running playback', () async {
      if (!player.isAvailable) {
        markTestSkipped('No audio player available on this platform');
        return;
      }

      // Generate a longer tone so we have time to stop it.
      final samples = Synthesizer.tone(
        frequency: 440,
        duration: 5.0,
        volume: 0.0, // silent
      );
      final wavBytes = WavWriter.encode(samples);

      // Start playback but don't await — we want to stop it mid-play.
      final playFuture = player.playWav(wavBytes);

      // Give the process a moment to start.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Stop should kill the process.
      player.stop();

      // The future should complete (process was killed).
      await playFuture;
    });
  });
}
