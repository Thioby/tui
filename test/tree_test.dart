import 'package:test/test.dart';
import 'package:tui/tui.dart';

class TestNode extends TreeNode {
  String name;
  TestNode(this.name);
}

class TestTreeView extends TreeView {
  TestTreeView(super.model);

  @override
  String renderNode(TreeNode node) {
    return '  ' * node.depth + (node as TestNode).name;
  }
}

void main() {
  group('TreeNode', () {
    test('depth is 0 for root node', () {
      var node = TestNode('root');
      expect(node.depth, equals(0));
    });

    test('depth increases with nesting', () {
      var root = TestNode('root');
      var child = TestNode('child');
      var grandchild = TestNode('grandchild');

      root.add(child);
      child.add(grandchild);

      expect(root.depth, equals(0));
      expect(child.depth, equals(1));
      expect(grandchild.depth, equals(2));
    });

    test('add returns the added node', () {
      var parent = TestNode('parent');
      var child = TestNode('child');

      var result = parent.add(child);
      expect(result, same(child));
    });

    test('leaf defaults to false', () {
      var node = TestNode('test');
      expect(node.leaf, isFalse);
    });

    test('opened defaults to false', () {
      var node = TestNode('test');
      expect(node.opened, isFalse);
    });
  });

  group('TreeModel', () {
    late TreeModel model;

    setUp(() {
      model = TreeModel();
      var child1 = TestNode('child1');
      var child2 = TestNode('child2');
      var grandchild = TestNode('grandchild');

      model.root.add(child1);
      model.root.add(child2);
      child1.add(grandchild);
    });

    test('iterates only visible nodes (closed)', () {
      var names = model.map((n) => (n as TestNode).name).toList();
      expect(names, equals(['child1', 'child2']));
    });

    test('iterates including children when opened', () {
      var child1 = model.first as TestNode;
      child1.opened = true;

      var names = model.map((n) => (n as TestNode).name).toList();
      expect(names, equals(['child1', 'grandchild', 'child2']));
    });

    test('indexOf finds correct position', () {
      var nodes = model.toList();
      expect(model.indexOf(nodes[0]), equals(0));
      expect(model.indexOf(nodes[1]), equals(1));
    });

    test('indexOf returns null for non-existent node', () {
      var orphan = TestNode('orphan');
      expect(model.indexOf(orphan), isNull);
    });
  });

  group('TreeView', () {
    late TreeModel model;
    late TestTreeView treeView;

    setUp(() {
      model = TreeModel();
      for (var i = 0; i < 10; i++) {
        model.root.add(TestNode('item$i'));
      }
      treeView = TestTreeView(model);
      treeView.resize(Size(40, 5), Position(0, 0));
    });

    test('is focusable by default', () {
      expect(treeView.focusable, isTrue);
    });

    test('cursor starts at 0', () {
      expect(treeView.cursor, equals(0));
    });

    test('scrollOffset starts at 0', () {
      expect(treeView.scrollOffset, equals(0));
    });

    test('moveDown increments cursor', () {
      treeView.moveDown();
      expect(treeView.cursor, equals(1));
    });

    test('moveUp decrements cursor', () {
      treeView.cursor = 3;
      treeView.moveUp();
      expect(treeView.cursor, equals(2));
    });

    test('moveUp does not go below 0', () {
      treeView.cursor = 0;
      treeView.moveUp();
      expect(treeView.cursor, equals(0));
    });

    test('moveDown does not exceed model length', () {
      treeView.cursor = 9;
      treeView.moveDown();
      expect(treeView.cursor, equals(9));
    });

    test('scrollOffset adjusts when cursor goes below visible area', () {
      // Height is 5, so visible items are 0-4
      for (var i = 0; i < 6; i++) {
        treeView.moveDown();
      }
      expect(treeView.cursor, equals(6));
      expect(treeView.scrollOffset, equals(2)); // 6-5+1 = 2
    });

    test('scrollOffset adjusts when cursor goes above visible area', () {
      treeView.scrollOffset = 3;
      treeView.cursor = 3;
      treeView.moveUp();
      expect(treeView.cursor, equals(2));
      expect(treeView.scrollOffset, equals(2));
    });

    test('onKey handles arrow keys', () {
      expect(treeView.onKey(KeyCode.DOWN), isTrue);
      expect(treeView.cursor, equals(1));

      expect(treeView.onKey(KeyCode.UP), isTrue);
      expect(treeView.cursor, equals(0));
    });

    test('onKey returns false for unhandled keys', () {
      expect(treeView.onKey('x'), isFalse);
    });

    test('update generates text for visible rows', () {
      treeView.update();
      expect(treeView.text.length, equals(5)); // height is 5
    });

    test('expandNode opens non-leaf nodes', () {
      var child = TestNode('child');
      var grandchild = TestNode('grandchild');
      child.add(grandchild);

      model = TreeModel();
      model.root.add(child);
      treeView = TestTreeView(model);
      treeView.resize(Size(40, 10), Position(0, 0));

      expect(child.opened, isFalse);
      treeView.expandNode();
      expect(child.opened, isTrue);
    });
  });
}
