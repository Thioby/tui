import 'dart:math';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('StereoSamples', () {
    test('constructor asserts equal channel lengths', () {
      final left = Float64List(100);
      final right = Float64List(100);
      final stereo = StereoSamples(left, right);
      expect(stereo.length, equals(100));
    });

    test('length returns channel length', () {
      final s = StereoSamples(Float64List(50), Float64List(50));
      expect(s.length, equals(50));
    });
  });

  group('StereoSamples.fromMono', () {
    test('center pan gives equal L and R', () {
      final mono = Float64List.fromList([1.0, -1.0, 0.5]);
      final stereo = StereoSamples.fromMono(mono, pan: 0.0);
      for (var i = 0; i < mono.length; i++) {
        expect(stereo.left[i], closeTo(stereo.right[i], 0.001));
      }
    });

    test('full left pan gives signal in left only', () {
      final mono = Float64List.fromList([1.0, 0.5]);
      final stereo = StereoSamples.fromMono(mono, pan: -1.0);
      expect(stereo.left[0], closeTo(1.0, 0.001));
      expect(stereo.right[0], closeTo(0.0, 0.001));
    });

    test('full right pan gives signal in right only', () {
      final mono = Float64List.fromList([1.0, 0.5]);
      final stereo = StereoSamples.fromMono(mono, pan: 1.0);
      expect(stereo.left[0], closeTo(0.0, 0.001));
      expect(stereo.right[0], closeTo(1.0, 0.001));
    });

    test('constant power: center is not -6dB', () {
      final mono = Float64List.fromList([1.0]);
      final stereo = StereoSamples.fromMono(mono, pan: 0.0);
      // With constant-power panning, center = cos(pi/4) = ~0.707
      final gain = stereo.left[0];
      expect(gain, closeTo(cos(pi / 4), 0.001));
    });

    test('pan clamps to [-1, 1]', () {
      final mono = Float64List.fromList([1.0]);
      final stereo = StereoSamples.fromMono(mono, pan: 5.0);
      // Should behave like pan: 1.0
      expect(stereo.left[0], closeTo(0.0, 0.001));
      expect(stereo.right[0], closeTo(1.0, 0.001));
    });
  });

  group('StereoSamples.mix', () {
    test('mix empty list returns empty stereo', () {
      final result = StereoSamples.mix([]);
      expect(result.length, equals(0));
    });

    test('mix single buffer returns same values', () {
      final buf = StereoSamples(
        Float64List.fromList([0.5, -0.3]),
        Float64List.fromList([0.2, 0.7]),
      );
      final result = StereoSamples.mix([buf]);
      expect(result.left[0], closeTo(0.5, 0.001));
      expect(result.right[1], closeTo(0.7, 0.001));
    });

    test('mix adds signals and clamps', () {
      final a = StereoSamples(
        Float64List.fromList([0.8]),
        Float64List.fromList([0.5]),
      );
      final b = StereoSamples(
        Float64List.fromList([0.8]),
        Float64List.fromList([0.3]),
      );
      final result = StereoSamples.mix([a, b]);
      expect(result.left[0], closeTo(1.0, 0.001)); // clamped
      expect(result.right[0], closeTo(0.8, 0.001));
    });

    test('mix handles different length buffers', () {
      final short = StereoSamples(
        Float64List.fromList([0.5]),
        Float64List.fromList([0.5]),
      );
      final long = StereoSamples(
        Float64List.fromList([0.3, 0.7]),
        Float64List.fromList([0.3, 0.7]),
      );
      final result = StereoSamples.mix([short, long]);
      expect(result.length, equals(2));
    });
  });

  group('StereoSamples.toMono', () {
    test('downmix averages L and R', () {
      final stereo = StereoSamples(
        Float64List.fromList([1.0, 0.0]),
        Float64List.fromList([0.0, 1.0]),
      );
      final mono = stereo.toMono();
      expect(mono[0], closeTo(0.5, 0.001));
      expect(mono[1], closeTo(0.5, 0.001));
    });
  });

  group('WavWriter.encodeStereo', () {
    test('produces valid WAV header for stereo', () {
      final stereo = StereoSamples(
        Float64List.fromList([0.5, -0.5]),
        Float64List.fromList([0.3, -0.3]),
      );
      final wav = WavWriter.encodeStereo(stereo);

      // Check RIFF header
      expect(wav[0], equals(0x52)); // R
      expect(wav[1], equals(0x49)); // I
      expect(wav[2], equals(0x46)); // F
      expect(wav[3], equals(0x46)); // F

      // Check channels = 2 (offset 22, little-endian)
      expect(wav[22], equals(2));
      expect(wav[23], equals(0));
    });

    test('stereo file is larger than mono for same frame count', () {
      final mono = Float64List.fromList([0.5, -0.5, 0.3]);
      final stereo = StereoSamples(
        Float64List.fromList([0.5, -0.5, 0.3]),
        Float64List.fromList([0.5, -0.5, 0.3]),
      );
      final monoWav = WavWriter.encode(mono);
      final stereoWav = WavWriter.encodeStereo(stereo);
      // Stereo has 2x the samples (interleaved)
      expect(stereoWav.length, greaterThan(monoWav.length));
    });
  });
}
