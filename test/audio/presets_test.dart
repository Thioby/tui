import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tui/tui.dart';

void main() {
  group('SFX presets', () {
    for (final preset in SFX.values) {
      test('${preset.name} produces non-empty, non-silent samples', () {
        final samples = preset.toSamples();
        expect(samples, isA<Float64List>());
        expect(samples.length, greaterThan(0), reason: '${preset.name} should produce non-empty samples');
        expect(samples.any((s) => s != 0.0), isTrue, reason: '${preset.name} should not be completely silent');
      });
    }

    test('beep is short (< 0.5s at 44100 Hz)', () {
      final samples = SFX.beep.toSamples(sampleRate: 44100);
      expect(samples.length, lessThan(22050), reason: 'beep should be shorter than 0.5 seconds');
    });

    test('error has descending frequencies', () {
      final melody = SFX.error.melody;
      final notes = melody.events.whereType<NoteEvent>().toList();
      expect(notes.length, greaterThanOrEqualTo(2));
      expect(notes.first.frequency, greaterThan(notes.last.frequency),
          reason: 'error preset should have descending frequencies');
    });

    test('success has ascending frequencies', () {
      final melody = SFX.success.melody;
      final notes = melody.events.whereType<NoteEvent>().toList();
      expect(notes.length, greaterThanOrEqualTo(2));
      expect(notes.first.frequency, lessThan(notes.last.frequency),
          reason: 'success preset should have ascending frequencies');
    });
  });
}
