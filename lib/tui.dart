library tui;

import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:collection';

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

class Size {
  int width;
  int height;

  Size(this.width, this.height);
  Size.from(Size size)
      : width = size.width,
        height = size.height;
}

mixin Sizable {
  late Size size;
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
