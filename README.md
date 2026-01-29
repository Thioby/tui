# tui

A Dart library for building terminal user interfaces.

## What's in here

- **Widgets**: Input, TextArea, Select, Confirm, Table, Spinner, ProgressBar
- **Layout**: SplitView, Frame, Box
- **BigText**: ASCII art banners with gradient support
- **Animations**: Typewriter, glitch, matrix rain, shimmer, and more
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

## Running the demos

```bash
dart run example/widgets_demo.dart
dart run example/animation_demo.dart
dart run example/split_view.dart
dart run example/bigtext_demo.dart
```

## License

Apache 2.0
