library tui;

import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'dart:typed_data';

part 'src/screen.dart';
part 'src/canvas.dart';

part 'src/text.dart';
part 'src/view.dart';
part 'src/widgets.dart';

part 'src/escape.dart';
part 'src/focus.dart';
part 'src/window.dart';
part 'src/render_loop.dart';

part 'src/tree.dart';
part 'src/page_view.dart';
part 'src/page_indicator.dart';
part 'src/navigation_bar.dart';
part 'src/input.dart';
part 'src/select.dart';
part 'src/textarea.dart';
part 'src/spinner.dart';
part 'src/table.dart';
part 'src/bigtext.dart';
part 'src/animation.dart';
part 'src/audio/notes.dart';
part 'src/audio/wav_writer.dart';
part 'src/audio/synthesizer.dart';
part 'src/audio/player.dart';
part 'src/audio/melody.dart';
part 'src/audio/channel.dart';
part 'src/audio/presets.dart';

class Size {
  int width;
  int height;

  Size(this.width, this.height);
  Size.from(Size size)
      : width = size.width,
        height = size.height;
}

mixin Sizable {
  Size size = Size(0, 0);
  int get width => size.width;
  int get height => size.height;
}

class Position {
  int x;
  int y;

  Position(this.x, this.y);
  Position.from(Position position)
      : x = position.x,
        y = position.y;
}

mixin Positionable {
  Position position = Position(0, 0);
  int get x => position.x;
  int get y => position.y;
}
