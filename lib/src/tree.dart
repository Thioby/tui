part of tui;

class TreeNode {
  TreeNode? _parent;
  final List<TreeNode> _children = [];

  int get depth => _parent != null ? _parent!.depth + 1 : 0;

  bool opened = false;
  bool leaf = false;

  TreeNode add(TreeNode node) {
    node._parent = this;
    _children.add(node);
    return node;
  }
}

class TreeNodeIterator implements Iterator<TreeNode> {
  late TreeNode current;
  final TreeModel _model;

  // Use a record or simple class for queue items: [node, nextChildIndex]
  final _queue = Queue<({TreeNode node, int index})>();

  TreeNodeIterator(this._model) {
    _queue.add((node: _model.root, index: 0));
  }

  @override
  bool moveNext() {
    while (_queue.isNotEmpty) {
      var parent = _queue.last;
      var node = parent.node;
      var index = parent.index;

      if (node._children.length > index) {
        // Increment index for next time we visit this parent
        _queue.removeLast();
        _queue.add((node: node, index: index + 1));

        var child = node._children[index];
        current = child;

        // If open and has children, add to queue to visit its children next
        if (child.opened && child._children.isNotEmpty) {
          _queue.add((node: child, index: 0));
        }
        return true;
      } else {
        _queue.removeLast();
      }
    }
    return false;
  }
}

class TreeModel extends IterableBase<TreeNode> {
  final _controller = StreamController<Map>.broadcast();
  Stream<Map> get changes => _controller.stream;

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
      if (node._parent?._parent != null) {
        node._parent!.opened = false;
        cursor = model.indexOf(node._parent!) ?? 0;
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

  /// Override to customize how each node is rendered as a string.
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
