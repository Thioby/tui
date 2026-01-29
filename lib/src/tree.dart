part of tui;

class TreeNode {
  TreeNode? _p;
  final List<TreeNode> _kids = [];

  int get depth => _p != null ? _p!.depth + 1 : 0;

  bool opened = false;
  bool leaf = false;

  TreeNode add(TreeNode node) {
    node._p = this;
    _kids.add(node);
    return node;
  }
}

class TreeNodeIterator implements Iterator<TreeNode> {
  late TreeNode current;
  final TreeModel _mdl;

  final _q = Queue<({TreeNode node, int index})>();

  TreeNodeIterator(this._mdl) {
    _q.add((node: _mdl.root, index: 0));
  }

  @override
  bool moveNext() {
    while (_q.isNotEmpty) {
      var parent = _q.last;
      var node = parent.node;
      var index = parent.index;

      if (node._kids.length > index) {
        _q.removeLast();
        _q.add((node: node, index: index + 1));

        var child = node._kids[index];
        current = child;

        if (child.opened && child._kids.isNotEmpty) {
          _q.add((node: child, index: 0));
        }
        return true;
      } else {
        _q.removeLast();
      }
    }
    return false;
  }
}

class TreeModel extends IterableBase<TreeNode> {
  final _ctrl = StreamController<Map>.broadcast();
  Stream<Map> get changes => _ctrl.stream;

  final root = TreeNode();

  @override
  Iterator<TreeNode> get iterator => TreeNodeIterator(this);

  int? indexOf(TreeNode target) {
    int i = 0;
    for (var node in this) {
      if (node == target) return i;
      i++;
    }
    return null;
  }
}

/// A View that displays a tree structure with expandable nodes.
abstract class TreeView extends View {
  int scrollOffset = 0;
  int cursor = 0;

  TreeModel model;

  String cursorColor = "2";
  String normalColor = "7";

  TreeView(this.model) {
    focusable = true;
  }

  @override
  bool onKey(String key) {
    switch (key) {
      case KeyCode.UP:
        moveUp();
        return true;
      case KeyCode.DOWN:
        moveDown();
        return true;
      case KeyCode.LEFT:
        collapseNode();
        return true;
      case KeyCode.RIGHT:
        expandNode();
        return true;
    }
    return false;
  }

  void moveUp() {
    if (cursor > 0) {
      cursor--;
      if (cursor < scrollOffset) {
        scrollOffset--;
      }
    }
  }

  void moveDown() {
    var len = model.length - 1;
    if (len > cursor) {
      cursor++;
      if (cursor >= (scrollOffset + height)) {
        scrollOffset++;
      }
    }
  }

  void collapseNode() {
    var nodes = model.toList();
    if (cursor < nodes.length) {
      var node = nodes[cursor];
      if (node._p?._p != null) {
        node._p!.opened = false;
        cursor = model.indexOf(node._p!) ?? 0;
        scrollOffset = min(cursor, scrollOffset);
      }
    }
  }

  void expandNode() {
    var nodes = model.toList();
    if (cursor < nodes.length) {
      var node = nodes[cursor];
      if (!node.leaf) {
        node.opened = true;
        moveDown();
      }
    }
  }

  String renderNode(TreeNode node);

  @override
  void update() {
    text = [];
    var nodes = model.skip(scrollOffset).take(height).toList();

    for (var i = 0; i < height; i++) {
      if (i < nodes.length) {
        var node = nodes[i];
        var line = renderNode(node);
        if (line.length > width) {
          line = line.substring(0, width);
        }

        var isSelected = (i + scrollOffset) == cursor;
        var t = Text(line.padRight(width))
          ..position = Position(0, i)
          ..color = isSelected ? cursorColor : normalColor;
        text.add(t);
      }
    }
  }
}