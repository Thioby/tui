# tui

A Dart library for building terminal user interfaces.

## What's in here

- **Widgets**: Input, TextArea, Select, Confirm, Table, Spinner, ProgressBar
- **Layout**: SplitView, Frame, Box
- **BigText**: ASCII art banners with gradient support
- **Animations**: Typewriter, glitch, matrix rain, shimmer, and more
- **Audio**: Programmatic synthesis, melody DSL, SFX presets — no sound files needed
- **Focus management**: Tab between focusable widgets
- **60 FPS render loop** with optional FPS meter

## Quick start

```dart
import 'package:tui/tui.dart';

class MyApp extends Window {
  MyApp() {
    var input = Input(placeholder: 'Your name')
      ..onSubmit = (name) {
        print('Hello, $name!');
        stop();
      };

    children = [
      Frame(title: 'Welcome')..children = [input]
    ];
  }
}

void main() => MyApp().start();
```

## Widgets

### Input

```dart
var input = Input(placeholder: 'Type here...')
  ..prompt = '> '
  ..onSubmit = (value) => print(value);
```

### Select

```dart
var select = Select<String>(
  options: ['Apple', 'Banana', 'Cherry'],
  header: 'Pick a fruit:',
  onSelect: (fruit) => print(fruit),
);

// Multi-select
var multi = Select<String>(
  options: ['Red', 'Green', 'Blue'],
  multiSelect: true,
  onSelectMultiple: (colors) => print(colors),
);
```

### Table

```dart
var table = Table<List<String>>(
  columns: [
    TableColumn('Name', width: 15),
    TableColumn('Status', width: 10),
  ],
  rows: [
    ['Alice', 'Online'],
    ['Bob', 'Away'],
  ],
  rowBuilder: (row) => row,
  onSelect: (row) => print(row),
);
```

### Spinner

```dart
var spinner = Spinner(
  label: 'Loading...',
  style: SpinnerStyle.dots,  // dots, circle, line, arrow, bounce, moon, etc.
)..start();

// Later:
spinner.stop();
```

### ProgressBar

```dart
var bar = ProgressBar()
  ..label = 'Download'
  ..value = 0.75;  // 0.0 to 1.0
```

## Layout

### SplitView

```dart
// Horizontal split (side by side)
SplitView(horizontal: true)
  ..children = [leftPanel, rightPanel];

// With custom ratios
SplitView(horizontal: true, ratios: [2, 1])
  ..children = [mainPanel, sidebar];

// Vertical split
SplitView(horizontal: false)
  ..children = [topPanel, bottomPanel];
```

### Frame

```dart
Frame(title: 'My Panel', color: '36', focusColor: '33')
  ..children = [someWidget];
```

The frame uses light borders normally, double borders when focused.

## BigText

ASCII art text with optional gradients.

```dart
var banner = BigText('HELLO', font: BigTextFont.shadow)
  ..gradient = Gradients.rainbow;

children = [banner];
```

Fonts: `block`, `slim`, `chunky`, `shadow`

Gradients: `rainbow`, `sunset`, `ocean`, `fire`, `forest`, `purple`, `cyan`, `gemini`, `matrix`

## Animations

```dart
var controller = AnimationController()..fps = 60;

// Typewriter
controller.add(TypewriterAnimation(
  text: 'Hello world',
  duration: Duration(seconds: 2),
  onUpdate: (visible) => currentText = visible,
));

// Glitch
controller.add(GlitchAnimation(
  text: 'ERROR',
  duration: Duration(milliseconds: 1500),
  intensity: 0.5,
  onUpdate: (glitched) => currentText = glitched,
));

// Looping pulse
controller.add(ValueAnimation(
  from: 0,
  to: 1,
  duration: Duration(milliseconds: 500),
  repeatMode: RepeatMode.pingPong,
  onUpdate: (value) => opacity = value,
));
```

Repeat modes: `once`, `reverse`, `loop`, `pingPong`

## FPS meter

```dart
class MyApp extends Window {
  MyApp() {
    showFps = true;  // Shows FPS in top-right corner
  }
}
```

## Audio

Programmatic audio synthesis — generate sounds from code, no files needed.

```dart
final audio = Audio();

// Quick beep
audio.beep();

// SFX presets
SFX.success.playOn(audio.channel('sfx'));
SFX.coin.playOn(audio.channel('sfx'));
```

### Melody builder

```dart
final melody = Melody(bpm: 120, waveform: Waveform.square)
  ..note(Note.C4, Dur.quarter)
  ..note(Note.E4, Dur.quarter)
  ..note(Note.G4, Dur.half)
  ..rest(Dur.quarter)
  ..note(Note.C5, Dur.whole);

audio.channel('music').playMelody(melody);
```

### Melody DSL

Compact string notation for quick melodies:

```dart
audio.channel('music').play(
  'E4.q E4.q F4.q G4.q | G4.q F4.q E4.q D4.q | C4.q C4.q D4.q E4.q | E4.dq D4.e D4.h',
  bpm: 120,
);
```

Note format: `{Name}{Octave}.{Duration}` — e.g. `C4.q`, `Fs5.e`, `R.h` (rest)

Durations: `w` whole, `h` half, `q` quarter, `e` eighth, `s` sixteenth, `t` triplet, `d` prefix for dotted (`dh`, `dq`, `de`)

### Waveforms and envelopes

```dart
// 5 waveform types
audio.channel('sfx').tone(
  frequency: Note.A4,
  waveform: Waveform.sawtooth,  // sine, square, triangle, sawtooth, noise
  duration: 0.5,
);

// Custom ADSR envelope
final staccato = Envelope(attack: 0.005, decay: 0.1, sustain: 0.0, release: 0.01);
audio.channel('sfx').tone(frequency: Note.C5, envelope: staccato);
```

### Channels

Named channels — each plays one sound at a time (new replaces old):

```dart
audio.channel('sfx');    // sound effects
audio.channel('music');  // background melody
audio.channel('ui');     // UI feedback
audio.muted = true;      // mute everything
```

### SFX presets

`beep`, `click`, `success`, `error`, `powerUp`, `explosion`, `coin`, `jump`

### Low-level synthesis

```dart
// Generate raw samples
final samples = Synthesizer.tone(frequency: 440.0, duration: 0.5, waveform: Waveform.sine);

// Mix multiple buffers into a chord
final chord = Synthesizer.mix([
  Synthesizer.tone(frequency: Note.C4, duration: 1.0, volume: 0.5),
  Synthesizer.tone(frequency: Note.E4, duration: 1.0, volume: 0.5),
  Synthesizer.tone(frequency: Note.G4, duration: 1.0, volume: 0.5),
]);

// Encode to WAV
final wav = WavWriter.encode(chord);
```

## Running the demos

```bash
dart run example/widgets_demo.dart
dart run example/animation_demo.dart
dart run example/split_view.dart
dart run example/bigtext_demo.dart
dart run example/audio_demo.dart
```

## License

Apache 2.0
