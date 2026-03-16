part of tui;

/// Encodes audio samples into PCM WAV files.
abstract class WavWriter {
  /// Encodes mono float64 samples into a 16-bit mono PCM WAV file.
  static Uint8List encode(Float64List samples, {int sampleRate = 44100}) {
    return _encodeWav(samples: samples, channels: 1, sampleRate: sampleRate);
  }

  /// Encodes stereo samples into a 16-bit stereo PCM WAV file.
  static Uint8List encodeStereo(
    StereoSamples stereo, {
    int sampleRate = 44100,
  }) {
    // Interleave L/R channels: [L0, R0, L1, R1, ...]
    final interleaved = Float64List(stereo.length * 2);
    for (var i = 0; i < stereo.length; i++) {
      interleaved[i * 2] = stereo.left[i];
      interleaved[i * 2 + 1] = stereo.right[i];
    }
    return _encodeWav(
      samples: interleaved,
      channels: 2,
      sampleRate: sampleRate,
    );
  }

  static Uint8List _encodeWav({
    required Float64List samples,
    required int channels,
    required int sampleRate,
  }) {
    final numSamples = samples.length;
    final dataSize = numSamples * 2;
    final fileSize = 44 + dataSize;
    final byteRate = sampleRate * channels * 2;
    final blockAlign = channels * 2;

    final buf = ByteData(fileSize);
    var o = 0;

    // RIFF header
    buf.setUint8(o++, 0x52); // R
    buf.setUint8(o++, 0x49); // I
    buf.setUint8(o++, 0x46); // F
    buf.setUint8(o++, 0x46); // F
    buf.setUint32(o, fileSize - 8, Endian.little);
    o += 4;
    buf.setUint8(o++, 0x57); // W
    buf.setUint8(o++, 0x41); // A
    buf.setUint8(o++, 0x56); // V
    buf.setUint8(o++, 0x45); // E

    // fmt sub-chunk
    buf.setUint8(o++, 0x66); // f
    buf.setUint8(o++, 0x6D); // m
    buf.setUint8(o++, 0x74); // t
    buf.setUint8(o++, 0x20); // (space)
    buf.setUint32(o, 16, Endian.little);
    o += 4; // sub-chunk size
    buf.setUint16(o, 1, Endian.little);
    o += 2; // PCM format
    buf.setUint16(o, channels, Endian.little);
    o += 2; // channels
    buf.setUint32(o, sampleRate, Endian.little);
    o += 4;
    buf.setUint32(o, byteRate, Endian.little);
    o += 4; // byte rate
    buf.setUint16(o, blockAlign, Endian.little);
    o += 2; // block align
    buf.setUint16(o, 16, Endian.little);
    o += 2; // bits per sample

    // data sub-chunk
    buf.setUint8(o++, 0x64); // d
    buf.setUint8(o++, 0x61); // a
    buf.setUint8(o++, 0x74); // t
    buf.setUint8(o++, 0x61); // a
    buf.setUint32(o, dataSize, Endian.little);
    o += 4;

    // PCM samples
    for (var i = 0; i < numSamples; i++) {
      final int16 = (samples[i].clamp(-1.0, 1.0) * 32767).round();
      buf.setInt16(o, int16, Endian.little);
      o += 2;
    }

    return buf.buffer.asUint8List();
  }
}
