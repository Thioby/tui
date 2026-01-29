import 'package:tui/tui.dart';
import 'dart:math';

class FallingWord {
  String word;
  int x;
  double y;
  double speed;
  bool completed = false;

  FallingWord(this.word, this.x, this.y, this.speed);
}

class TypingRace extends Window {
  static const List<String> wordList = [
    'dart', 'flutter', 'code', 'type', 'fast', 'game', 'word', 'race',
    'speed', 'quick', 'jump', 'run', 'play', 'win', 'score', 'level',
    'terminal', 'console', 'keyboard', 'screen', 'pixel', 'render',
    'loop', 'frame', 'input', 'output', 'string', 'list', 'map', 'set',
    'class', 'function', 'method', 'widget', 'canvas', 'draw', 'write',
    'async', 'await', 'stream', 'future', 'null', 'void', 'bool', 'int',
  ];

  List<FallingWord> words = [];
  String currentInput = '';
  int score = 0;
  int lives = 5;
  int level = 1;
  bool gameRunning = false;
  bool gameOver = false;

  int frameCount = 0;
  int spawnInterval = 60;
  int wordsFallen = 0;

  final Random random = Random();
  bool _initialized = false;

  TypingRace() {
    showFps = true;
  }

  @override
  void resize(Size size, Position position) {
    super.resize(size, position);
    if (!_initialized) {
      _initialized = true;
      _initGame();
    }
  }

  void _initGame() {
    words.clear();
    currentInput = '';
    score = 0;
    lives = 5;
    level = 1;
    wordsFallen = 0;
    spawnInterval = 60;
    gameOver = false;
    gameRunning = false;
  }

  void _spawnWord() {
    final word = wordList[random.nextInt(wordList.length)];
    final x = 2 + random.nextInt(width - word.length - 4);
    final speed = 0.1 + level * 0.03 + random.nextDouble() * 0.05;
    words.add(FallingWord(word, x, 2, speed));
  }

  @override
  bool onKey(String key) {
    if (gameOver) {
      if (key == KeyCode.SPACE || key == 'r' || key == 'R') {
        _initGame();
        return true;
      }
    }

    switch (key) {
      case KeyCode.SPACE:
        if (!gameRunning) {
          gameRunning = true;
        }
        return true;
      case KeyCode.ESCAPE:
        if (gameRunning) {
          gameRunning = false; // pause
        } else {
          stop();
        }
        return true;
      case KeyCode.BACKSPACE:
        if (currentInput.isNotEmpty) {
          currentInput = currentInput.substring(0, currentInput.length - 1);
        }
        return true;
      case KeyCode.ENTER:
        _checkWord();
        return true;
      default:
        // Add typed character
        if (key.length == 1 && gameRunning) {
          final code = key.codeUnitAt(0);
          if (code >= 32 && code < 127) {
            currentInput += key.toLowerCase();
            _checkPartialMatch();
          }
        }
        return true;
    }
  }

  void _checkPartialMatch() {
    // Auto-complete if exact match
    for (var word in words) {
      if (!word.completed && word.word == currentInput) {
        word.completed = true;
        score += word.word.length * 10 * level;
        currentInput = '';
        wordsFallen++;
        _checkLevelUp();
        return;
      }
    }
  }

  void _checkWord() {
    for (var word in words) {
      if (!word.completed && word.word == currentInput) {
        word.completed = true;
        score += word.word.length * 10 * level;
        wordsFallen++;
        _checkLevelUp();
        break;
      }
    }
    currentInput = '';
  }

  void _checkLevelUp() {
    if (wordsFallen >= level * 10) {
      level++;
      spawnInterval = (60 / (1 + level * 0.2)).round().clamp(20, 60);
    }
  }

  @override
  void update() {
    if (!gameRunning || gameOver) return;

    frameCount++;

    // Spawn new words
    if (frameCount >= spawnInterval) {
      frameCount = 0;
      if (words.where((w) => !w.completed).length < 5 + level) {
        _spawnWord();
      }
    }

    // Update word positions
    for (var word in words) {
      if (!word.completed) {
        word.y += word.speed;

        // Word reached bottom
        if (word.y >= height - 4) {
          word.completed = true;
          lives--;
          if (lives <= 0) {
            gameOver = true;
            gameRunning = false;
          }
        }
      }
    }

    // Remove old completed words
    words.removeWhere((w) => w.completed && w.y >= height - 4);
  }

  @override
  void render(Canvas canvas) {
    _drawBorder(canvas);
    _drawWords(canvas);
    _drawInput(canvas);
    _drawHUD(canvas);

    if (!gameRunning && !gameOver) {
      _drawMessage(canvas, 'SPACE to start typing!');
    }
    if (gameOver) {
      _drawMessage(canvas, 'GAME OVER! Score: $score - SPACE to restart');
    }
  }

  void _drawBorder(Canvas canvas) {
    for (var x = 0; x < width; x++) {
      canvas.write(x, 0, BoxChars.lightH);
      canvas.write(x, height - 1, BoxChars.lightH);
      canvas.write(x, height - 3, BoxChars.lightH);
    }
    for (var y = 0; y < height; y++) {
      canvas.write(0, y, BoxChars.lightV);
      canvas.write(width - 1, y, BoxChars.lightV);
    }
    canvas.write(0, 0, BoxChars.roundedTL);
    canvas.write(width - 1, 0, BoxChars.roundedTR);
    canvas.write(0, height - 1, BoxChars.roundedBL);
    canvas.write(width - 1, height - 1, BoxChars.roundedBR);
    canvas.write(0, height - 3, BoxChars.lightTeeR);
    canvas.write(width - 1, height - 3, BoxChars.lightTeeL);
  }

  void _drawWords(Canvas canvas) {
    for (var word in words) {
      if (word.completed) continue;

      final y = word.y.round();
      if (y < 1 || y >= height - 3) continue;

      // Highlight matching prefix
      for (var i = 0; i < word.word.length; i++) {
        final char = word.word[i];
        final isMatched = i < currentInput.length &&
            currentInput[i] == char;

        if (isMatched) {
          // Draw matched chars brighter
          canvas.write(word.x + i, y, char.toUpperCase());
        } else {
          canvas.write(word.x + i, y, char);
        }
      }
    }
  }

  void _drawInput(Canvas canvas) {
    final prompt = '> ';
    final inputY = height - 2;

    canvas.write(2, inputY, prompt);
    for (var i = 0; i < currentInput.length && i < width - 6; i++) {
      canvas.write(4 + i, inputY, currentInput[i]);
    }

    // Cursor
    final cursorX = 4 + currentInput.length;
    if (cursorX < width - 2 && gameRunning) {
      canvas.write(cursorX, inputY, '_');
    }
  }

  void _drawHUD(Canvas canvas) {
    final hud = ' Score: $score ${BoxChars.lightV} Lives: ${'♥' * lives} ${BoxChars.lightV} Level: $level ';
    final hudX = (width - hud.length) ~/ 2;
    for (var i = 0; i < hud.length; i++) {
      canvas.write(hudX + i, 0, hud[i]);
    }
  }

  void _drawMessage(Canvas canvas, String message) {
    final msgX = (width - message.length) ~/ 2;
    final msgY = height ~/ 2;

    final boxWidth = message.length + 4;
    final boxX = msgX - 2;

    canvas.write(boxX, msgY - 1, BoxChars.roundedTL);
    for (var i = 1; i < boxWidth - 1; i++) {
      canvas.write(boxX + i, msgY - 1, BoxChars.lightH);
    }
    canvas.write(boxX + boxWidth - 1, msgY - 1, BoxChars.roundedTR);

    canvas.write(boxX, msgY, BoxChars.lightV);
    canvas.write(boxX + 1, msgY, ' ');
    for (var i = 0; i < message.length; i++) {
      canvas.write(msgX + i, msgY, message[i]);
    }
    canvas.write(boxX + boxWidth - 2, msgY, ' ');
    canvas.write(boxX + boxWidth - 1, msgY, BoxChars.lightV);

    canvas.write(boxX, msgY + 1, BoxChars.roundedBL);
    for (var i = 1; i < boxWidth - 1; i++) {
      canvas.write(boxX + i, msgY + 1, BoxChars.lightH);
    }
    canvas.write(boxX + boxWidth - 1, msgY + 1, BoxChars.roundedBR);
  }
}

void main() {
  print('TYPING RACE');
  print(BoxChars.lightH * 40);
  print('');
  print('Type the falling words before they');
  print('reach the bottom!');
  print('');
  print('Controls:');
  print('  Type words as they fall');
  print('  SPACE : Start / Restart');
  print('  ESC : Pause / Quit');
  print('');
  print(BoxChars.lightH * 40);
  print('Starting in 2 seconds...');

  Future.delayed(Duration(seconds: 2), () {
    TypingRace().start();
  });
}
