import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('Reverb', () {
    test('default parameters are reasonable', () {
      const r = Reverb();
      expect(r.mix, equals(0.3));
      expect(r.decay, equals(0.5));
    });

    test('presets have expected characteristics', () {
      expect(Reverb.church.decay, greaterThan(Reverb.room.decay));
      expect(Reverb.hall.decay, greaterThan(Reverb.church.decay));
      expect(Reverb.room.mix, lessThan(Reverb.hall.mix));
    });
  });

  group('Reverb.apply', () {
    test('zero mix returns copy of input', () {
      final input = Float64List.fromList([0.5, -0.3, 0.8, -0.1]);
      final output = const Reverb(mix: 0.0).apply(input);
      for (var i = 0; i < input.length; i++) {
        expect(output[i], equals(input[i]));
      }
    });

    test('output has same length as input', () {
      final input = Synthesizer.tone(frequency: 440, duration: 0.2);
      final output = Reverb.church.apply(input);
      expect(output.length, equals(input.length));
    });

    test('output is within [-1, 1]', () {
      final input = Synthesizer.tone(frequency: 440, duration: 0.3);
      final output = Reverb.hall.apply(input);
      for (final s in output) {
        expect(s, greaterThanOrEqualTo(-1.0));
        expect(s, lessThanOrEqualTo(1.0));
      }
    });

    test('reverb modifies the signal (not identical to input)', () {
      final input = Synthesizer.tone(frequency: 440, duration: 0.3);
      final output = Reverb.church.apply(input);
      var diffCount = 0;
      for (var i = 0; i < input.length; i++) {
        if ((input[i] - output[i]).abs() > 0.001) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('empty input returns empty output', () {
      final output = Reverb.church.apply(Float64List(0));
      expect(output.length, equals(0));
    });

    test('reverb adds energy after signal ends', () {
      // Create a short tone followed by silence
      final tone = Synthesizer.tone(frequency: 440, duration: 0.05);
      final input = Float64List(tone.length + 44100); // +1s silence
      for (var i = 0; i < tone.length; i++) {
        input[i] = tone[i];
      }

      final output = Reverb.church.apply(input);

      // Check that samples after the tone are non-zero (reverb tail)
      var hasReverbTail = false;
      for (var i = tone.length + 1000; i < output.length; i++) {
        if (output[i].abs() > 0.001) {
          hasReverbTail = true;
          break;
        }
      }
      expect(hasReverbTail, isTrue);
    });
  });

  group('Reverb.applyStereo', () {
    test('processes both channels', () {
      final mono = Synthesizer.tone(frequency: 440, duration: 0.2);
      final stereo = StereoSamples.fromMono(mono, pan: -0.3);
      final result = Reverb.room.applyStereo(stereo);
      expect(result.length, equals(stereo.length));
      expect(result.left.any((s) => s != 0.0), isTrue);
      expect(result.right.any((s) => s != 0.0), isTrue);
    });
  });
}
