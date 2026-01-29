import 'dart:io';
import 'package:tui/tui.dart';
import 'package:path/path.dart';

class FileNode extends TreeNode {
  FileNode(this.entity) {
    filename = basename(entity.path);
    if (entity is File) leaf = true;
  }

  late String filename;
  FileSystemEntity entity;

  bool _opened = false;
  @override
  bool get opened => _opened;
  @override
  set opened(bool value) {
    if (value && !leaf) {
      loadChildren();
      _opened = true;
    } else {
      _opened = false;
    }
  }

  void loadChildren() {
    try {
      (entity as Directory).listSync().forEach((e) => add(FileNode(e)));
    } catch (e) {
      // Permission denied or other errors - ignore
    }
  }
}

class FileTree extends TreeModel {
  FileTree() {
    var path = Platform.environment['HOME']!;
    var dir = Directory(path);
    try {
      dir.listSync().forEach((e) => root.add(FileNode(e)));
    } catch (e) {
      // Handle permission errors
    }
  }
}

class FileBrowserView extends TreeView {
  FileBrowserView(super.model);

  @override
  String renderNode(covariant FileNode node) {
    var prefix = node.leaf ? '  ' : (node.opened ? '▼ ' : '▶ ');
    return '  ' * node.depth + prefix + node.filename;
  }
}

class FileBrowserWindow extends Window {
  late FileBrowserView browser;

  FileBrowserWindow() {
    var tree = FileTree();
    browser = FileBrowserView(tree);
    children = [browser];
  }

  @override
  bool onKey(String key) {
    if (key == 'q') {
      stop();
      return true;
    }
    return false;
  }
}

void main() {
  print("File Browser");
  print(BoxChars.lightH * 37);
  print("↑/↓       = navigate");
  print("←         = collapse folder");
  print("→         = expand folder");
  print("q         = quit");
  print(BoxChars.lightH * 37);
  print("Starting in 2 seconds...");
  Future.delayed(Duration(seconds: 2), () {
    FileBrowserWindow().start();
  });
}
