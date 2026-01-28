part of tui;

class TreeNode {

  TreeNode? _parent;
  List<TreeNode> _children = [];

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
  TreeModel _model;
  final _queue = Queue<List>();

  TreeNodeIterator(this._model) {
    _queue.add([_model.root, 0]);
  }

  @override
  bool moveNext() {
    while (_queue.isNotEmpty) {
      var parent = _queue.last;
      if (parent[0]._children.length > parent[1]) {
        TreeNode node = parent[0]._children[parent[1]++];
        current = node;
        if (node.opened && node._children.isNotEmpty)
          _queue.add([node, 0]);
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
      if (node == target)
        return i;
      i++;
    }
    return null;
  }
}

/// A View that displays a tree structure with expandable nodes.
///
/// Example:
/// ```dart
/// class MyTreeView extends TreeView {
///   MyTreeView(super.model);
///
///   @override
///   String renderNode(TreeNode node) {
///     return '  ' * node.depth + node.toString();
///   }
/// }
/// ```
abstract class TreeView extends View {

  int scrollOffset = 0;
  int cursor = 0;

  TreeModel model;

  /// Color for the selected/cursor row
  String cursorColor = "2";

  /// Color for normal rows
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