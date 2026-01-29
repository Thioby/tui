part of tui;

class _NodePtr {
  Text node;
  int idx;
  _NodePtr(this.node, this.idx);
}

class TextNodeIterator implements Iterator<String> {
  String current = '';
  List<Text> lastStack = [];
  Iterator<String>? _strIter;
  final _stack = Queue<_NodePtr>();

  Queue<_NodePtr> get stack => _stack;

  TextNodeIterator(Text first) {
    _stack.add(_NodePtr(first, 0));
  }

  @override
  bool moveNext() {
    if (_strIter != null) {
      if (_strIter!.moveNext()) {
        current = _strIter!.current;
        return true;
      } else {
        _strIter = null;
        _stack.removeLast();
      }
    }

    while (_stack.isNotEmpty) {
      var last = _stack.last;
      Text node = last.node;
      if (node.isLeaf) {
        lastStack = _stack.map((p) => p.node).toList();
        _strIter = node.text!.split('').iterator;
        return moveNext();
      } else if (node._nodes.length > last.idx) {
        Text childNode = node._nodes[last.idx++];
        _stack.add(_NodePtr(childNode, 0));
      } else {
        node = _stack.removeLast().node;
      }
    }
    return false;
  }
}

/// A text element that supports styling and hierarchy.
class Text extends IterableBase<String> with Positionable {
  bool get isLeaf => _txt != null;
  bool get hasChildren => _nodes.isNotEmpty;

  String? _txt;
  String? get text => _txt;
  set text(String? text) {
    if (hasChildren) throw StateError("Cannot set text on container type.");
    _txt = text;
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

  Text([this._txt]);

  void apply(Text text) {
    bold = text.bold;
    italics = text.italics;
    color = text.color;
  }

  String open() {
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