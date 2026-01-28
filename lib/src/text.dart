part of tui;

class _TextNodeIteratorPointer {
  Text node;
  int index;
  _TextNodeIteratorPointer(this.node, this.index);
}

class TextNodeIterator implements Iterator<String> {
  // represents single character
  String current = '';

  // all of the parent nodes of the last String returned
  List<Text> lastStack = [];

  // current text node
  Iterator<String>? string;

  // all of the parent text nodes, this is used to
  // apply all of the previous styles up to this point
  final stack = Queue<_TextNodeIteratorPointer>();

  TextNodeIterator(Text first) {
    stack.add(_TextNodeIteratorPointer(first, 0));
  }

  @override
  bool moveNext() {
    if (string != null) {
      if (string!.moveNext()) {
        current = string!.current;
        return true;
      } else {
        string = null;
        stack.removeLast();
      }
    }

    while (stack.isNotEmpty) {
      var last = stack.last;
      Text node = last.node;
      if (node.isLeaf) {
        lastStack = stack.map((p) => p.node).toList();
        string = node.text!.split('').iterator;
        return moveNext();
      } else if (node._nodes.length > last.index) {
        Text childNode = node._nodes[last.index++];
        stack.add(_TextNodeIteratorPointer(childNode, 0));
      } else {
        node = stack.removeLast().node;
      }
    }
    return false;
  }
}

/// A text element that supports styling and hierarchy.
class Text extends IterableBase<String> with Positionable {
  bool get isLeaf => _text != null;
  bool get hasChildren => _nodes.isNotEmpty;

  String? _text;
  String? get text => _text;
  set text(String? text) {
    if (hasChildren) throw StateError("Cannot set text on container type.");
    _text = text;
  }

  final List<Text> _nodes = [];
  List<Text> get nodes {
    if (isLeaf) throw StateError("Cannot access nodes on leaf type.");
    return _nodes;
  }

  bool bold = false;
  bool italics = false;
  String? color;

  @override
  TextNodeIterator get iterator => TextNodeIterator(this);

  Text([this._text]);

  void apply(Text text) {
    bold = text.bold;
    italics = text.italics;
    color = text.color;
  }

  String open() {
    // Default to red if no color set? Preserving original logic.
    if (color != null) {
      return "\x1b[${color}m";
    } else {
      return "\x1b[31m";
    }
  }

  String close() {
    return "\x1b[0m";
  }

  Text add([String text = ""]) {
    var node = Text(text);
    nodes.add(node);
    return node;
  }
}
