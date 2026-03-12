import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('WavWriter', () {
    group('RIFF/WAVE header', () {
      test('starts with RIFF magic bytes', () {
        final wav = WavWriter.encode(Float64List(0));
        // "RIFF"
        expect(wav[0], equals(0x52)); // R
        expect(wav[1], equals(0x49)); // I
        expect(wav[2], equals(0x46)); // F
        expect(wav[3], equals(0x46)); // F
      });

      test('contains WAVE format identifier', () {
        final wav = WavWriter.encode(Float64List(0));
        // "WAVE" at offset 8
        expect(wav[8], equals(0x57)); // W
        expect(wav[9], equals(0x41)); // A
        expect(wav[10], equals(0x56)); // V
        expect(wav[11], equals(0x45)); // E
      });

      test('contains fmt sub-chunk', () {
        final wav = WavWriter.encode(Float64List(0));
        // "fmt " at offset 12
        expect(wav[12], equals(0x66)); // f
        expect(wav[13], equals(0x6D)); // m
        expect(wav[14], equals(0x74)); // t
        expect(wav[15], equals(0x20)); // (space)
      });

      test('contains data sub-chunk', () {
        final wav = WavWriter.encode(Float64List(0));
        // "data" at offset 36
        expect(wav[36], equals(0x64)); // d
        expect(wav[37], equals(0x61)); // a
        expect(wav[38], equals(0x74)); // t
        expect(wav[39], equals(0x61)); // a
      });

      test('audio format is PCM (1)', () {
        final wav = WavWriter.encode(Float64List(0));
        final byteData = ByteData.sublistView(wav);
        expect(byteData.getUint16(20, Endian.little), equals(1));
      });

      test('channel count is 1 (mono)', () {
        final wav = WavWriter.encode(Float64List(0));
        final byteData = ByteData.sublistView(wav);
        expect(byteData.getUint16(22, Endian.little), equals(1));
      });

      test('sample rate is written correctly', () {
        final wav = WavWriter.encode(Float64List(0), sampleRate: 22050);
        final byteData = ByteData.sublistView(wav);
        expect(byteData.getUint32(24, Endian.little), equals(22050));
      });

      test('bits per sample is 16', () {
        final wav = WavWriter.encode(Float64List(0));
        final byteData = ByteData.sublistView(wav);
        expect(byteData.getUint16(34, Endian.little), equals(16));
      });
    });

    group('output length', () {
      test('empty samples produces 44-byte header only', () {
        final wav = WavWriter.encode(Float64List(0));
        expect(wav.length, equals(44));
      });

      test('output length equals 44 + numSamples * 2', () {
        final samples = Float64List.fromList([0.0, 0.5, -0.5, 1.0, -1.0]);
        final wav = WavWriter.encode(samples);
        expect(wav.length, equals(44 + 5 * 2));
      });

      test('RIFF chunk size is fileSize - 8', () {
        final samples = Float64List.fromList([0.0, 0.5, -0.5]);
        final wav = WavWriter.encode(samples);
        final byteData = ByteData.sublistView(wav);
        expect(byteData.getUint32(4, Endian.little), equals(wav.length - 8));
      });

      test('data chunk size equals numSamples * 2', () {
        final samples = Float64List.fromList([0.0, 0.5, -0.5]);
        final wav = WavWriter.encode(samples);
        final byteData = ByteData.sublistView(wav);
        expect(byteData.getUint32(40, Endian.little), equals(3 * 2));
      });
    });

    group('sample clamping', () {
      test('values greater than 1.0 are clamped to 32767', () {
        final samples = Float64List.fromList([2.0, 1.5, 100.0]);
        final wav = WavWriter.encode(samples);
        final byteData = ByteData.sublistView(wav);
        expect(byteData.getInt16(44, Endian.little), equals(32767));
        expect(byteData.getInt16(46, Endian.little), equals(32767));
        expect(byteData.getInt16(48, Endian.little), equals(32767));
      });

      test('values less than -1.0 are clamped to -32767', () {
        final samples = Float64List.fromList([-2.0, -1.5, -100.0]);
        final wav = WavWriter.encode(samples);
        final byteData = ByteData.sublistView(wav);
        // -1.0 * 32767 = -32767
        expect(byteData.getInt16(44, Endian.little), equals(-32767));
        expect(byteData.getInt16(46, Endian.little), equals(-32767));
        expect(byteData.getInt16(48, Endian.little), equals(-32767));
      });

      test('exact 1.0 maps to 32767', () {
        final samples = Float64List.fromList([1.0]);
        final wav = WavWriter.encode(samples);
        final byteData = ByteData.sublistView(wav);
        expect(byteData.getInt16(44, Endian.little), equals(32767));
      });

      test('exact -1.0 maps to -32767', () {
        final samples = Float64List.fromList([-1.0]);
        final wav = WavWriter.encode(samples);
        final byteData = ByteData.sublistView(wav);
        expect(byteData.getInt16(44, Endian.little), equals(-32767));
      });

      test('0.0 maps to 0', () {
        final samples = Float64List.fromList([0.0]);
        final wav = WavWriter.encode(samples);
        final byteData = ByteData.sublistView(wav);
        expect(byteData.getInt16(44, Endian.little), equals(0));
      });

      test('0.5 maps to approximately 16384', () {
        final samples = Float64List.fromList([0.5]);
        final wav = WavWriter.encode(samples);
        final byteData = ByteData.sublistView(wav);
        expect(byteData.getInt16(44, Endian.little), equals(16384));
      });
    });
  });
}
