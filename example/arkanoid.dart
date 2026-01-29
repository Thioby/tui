import 'package:tui/tui.dart';
import 'dart:math';

class Brick {
  int x, y, width;
  int hits; // how many hits to destroy
  bool destroyed = false;

  Brick(this.x, this.y, this.width, this.hits);
}

class ArkanoidGame extends Window {
  // Game constants
  static const int paddleWidth = 12;
  static const int paddleY = 3; // from bottom
  static const String paddleChar = BoxChars.fullBlock;
  static const String ballChar = '●';
  static const int brickHeight = 1;
  static const int brickRows = 5;
  static const int brickCols = 10;

  // Game state
  int paddleX = 0;
  double ballX = 0;
  double ballY = 0;
  double ballDx = 1;
  double ballDy = -1;
  int score = 0;
  int lives = 3;
  bool gameRunning = false;
  bool gameOver = false;
  int level = 1;

  List<Brick> bricks = [];

  // Frame counter for ball speed control
  int frameCount = 0;
  int ballUpdateInterval = 2;

  bool _initialized = false;

  ArkanoidGame() {
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
    score = 0;
    lives = 3;
    level = 1;
    gameOver = false;
    _initLevel();
  }

  void _initLevel() {
    _initBricks();
    _resetBall();
    _resetPaddle();
    gameRunning = false;
  }

  void _initBricks() {
    bricks.clear();
    final brickWidth = (width - 4) ~/ brickCols;
    final startX = (width - brickWidth * brickCols) ~/ 2;
    final startY = 4;

    for (var row = 0; row < brickRows; row++) {
      final hits = (brickRows - row) <= 2 ? 1 : (row < 2 ? 2 : 1);
      for (var col = 0; col < brickCols; col++) {
        bricks.add(Brick(
          startX + col * brickWidth,
          startY + row * (brickHeight + 1),
          brickWidth - 1,
          hits,
        ));
      }
    }
  }

  void _resetBall() {
    ballX = width / 2;
    ballY = height - paddleY - 2.0;
    final random = Random();
    ballDx = (random.nextDouble() - 0.5) * 2;
    ballDy = -1;
  }

  void _resetPaddle() {
    paddleX = (width - paddleWidth) ~/ 2;
  }

  @override
  bool onKey(String key) {
    switch (key) {
      case KeyCode.LEFT:
      case 'a':
      case 'A':
        if (paddleX > 1) paddleX -= 2;
        return true;
      case KeyCode.RIGHT:
      case 'd':
      case 'D':
        if (paddleX < width - paddleWidth - 2) paddleX += 2;
        return true;
      case KeyCode.SPACE:
        if (gameOver) {
          _initGame();
        } else {
          gameRunning = !gameRunning;
        }
        return true;
      case 'r':
      case 'R':
        _initGame();
        return true;
      case 'q':
      case KeyCode.ESCAPE:
        stop();
        return true;
    }
    return false;
  }

  @override
  void update() {
    if (!gameRunning || gameOver) return;

    frameCount++;
    if (frameCount < ballUpdateInterval) return;
    frameCount = 0;

    // Update ball position
    ballX += ballDx;
    ballY += ballDy;

    // Bounce off walls
    if (ballX <= 1) {
      ballX = 1;
      ballDx = ballDx.abs();
    }
    if (ballX >= width - 2) {
      ballX = width - 2.0;
      ballDx = -ballDx.abs();
    }
    if (ballY <= 1) {
      ballY = 1;
      ballDy = ballDy.abs();
    }

    // Ball falls below paddle
    if (ballY >= height - 1) {
      lives--;
      if (lives <= 0) {
        gameOver = true;
        gameRunning = false;
      } else {
        _resetBall();
        gameRunning = false;
      }
      return;
    }

    // Paddle collision
    final paddleTop = height - paddleY - 1;
    if (ballY >= paddleTop - 1 && ballY <= paddleTop) {
      if (ballX >= paddleX && ballX <= paddleX + paddleWidth) {
        ballY = paddleTop - 1.0;
        ballDy = -ballDy.abs();
        // Add spin based on hit position
        final hitPos = (ballX - paddleX) / paddleWidth;
        ballDx = (hitPos - 0.5) * 3;
      }
    }

    // Brick collisions
    _checkBrickCollisions();

    // Check level complete
    if (bricks.every((b) => b.destroyed)) {
      level++;
      ballUpdateInterval = max(1, ballUpdateInterval - 1);
      _initLevel();
    }
  }

  void _checkBrickCollisions() {
    final bx = ballX.round();
    final by = ballY.round();

    for (var brick in bricks) {
      if (brick.destroyed) continue;

      if (bx >= brick.x && bx <= brick.x + brick.width &&
          by >= brick.y && by <= brick.y + brickHeight) {
        brick.hits--;
        if (brick.hits <= 0) {
          brick.destroyed = true;
          score += 10 * level;
        }

        // Determine bounce direction
        final brickCenterX = brick.x + brick.width / 2;
        final brickCenterY = brick.y + brickHeight / 2;

        if ((ballX - brickCenterX).abs() > (ballY - brickCenterY).abs() * 2) {
          ballDx = -ballDx;
        } else {
          ballDy = -ballDy;
        }
        return;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    _drawBorder(canvas);
    _drawBricks(canvas);
    _drawPaddle(canvas);
    _drawBall(canvas);
    _drawHUD(canvas);

    if (!gameRunning && !gameOver) {
      _drawMessage(canvas, 'SPACE to launch');
    }
    if (gameOver) {
      _drawMessage(canvas, 'GAME OVER - SPACE to restart');
    }
  }

  void _drawBorder(Canvas canvas) {
    for (var x = 0; x < width; x++) {
      canvas.write(x, 0, BoxChars.lightH);
      canvas.write(x, height - 1, BoxChars.lightH);
    }
    for (var y = 0; y < height; y++) {
      canvas.write(0, y, BoxChars.lightV);
      canvas.write(width - 1, y, BoxChars.lightV);
    }
    canvas.write(0, 0, BoxChars.roundedTL);
    canvas.write(width - 1, 0, BoxChars.roundedTR);
    canvas.write(0, height - 1, BoxChars.roundedBL);
    canvas.write(width - 1, height - 1, BoxChars.roundedBR);
  }

  void _drawBricks(Canvas canvas) {
    for (var brick in bricks) {
      if (brick.destroyed) continue;

      final char = brick.hits > 1 ? BoxChars.fullBlock : BoxChars.mediumShade;
      for (var x = 0; x < brick.width; x++) {
        canvas.write(brick.x + x, brick.y, char);
      }
    }
  }

  void _drawPaddle(Canvas canvas) {
    final y = height - paddleY - 1;
    for (var x = 0; x < paddleWidth; x++) {
      canvas.write(paddleX + x, y, paddleChar);
    }
  }

  void _drawBall(Canvas canvas) {
    if (!gameOver) {
      canvas.write(ballX.round(), ballY.round(), ballChar);
    }
  }

  void _drawHUD(Canvas canvas) {
    final hud = ' Score: $score ${BoxChars.lightV} Lives: ${'♥' * lives} ${BoxChars.lightV} Level: $level ';
    final hudX = (width - hud.length) ~/ 2;
    for (var i = 0; i < hud.length; i++) {
      canvas.write(hudX + i, 0, hud[i]);
    }

    final controls = ' ←/→ or A/D: move ${BoxChars.lightV} SPACE: launch/pause ${BoxChars.lightV} R: restart ${BoxChars.lightV} Q: quit ';
    final ctrlX = (width - controls.length) ~/ 2;
    if (controls.length < width - 2) {
      for (var i = 0; i < controls.length; i++) {
        canvas.write(ctrlX + i, height - 1, controls[i]);
      }
    }
  }

  void _drawMessage(Canvas canvas, String message) {
    final msgX = (width - message.length) ~/ 2;
    final msgY = height ~/ 2 + 4;

    // Draw box around message
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
  print('ARKANOID');
  print(BoxChars.lightH * 40);
  print('');
  print('Controls:');
  print('  ← / → or A / D : Move paddle');
  print('  SPACE : Launch ball / Pause');
  print('  R : Restart game');
  print('  Q / ESC : Quit');
  print('');
  print('Destroy all bricks to advance!');
  print(BoxChars.lightH * 40);
  print('Starting in 2 seconds...');

  Future.delayed(Duration(seconds: 2), () {
    ArkanoidGame().start();
  });
}
