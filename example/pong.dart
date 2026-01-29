import 'package:tui/tui.dart';
import 'dart:math';

class PongGame extends Window {
  // Game constants
  static const int paddleHeight = 5;
  static const int paddleMargin = 2;
  static const String paddleChar = BoxChars.fullBlock;
  static const String ballChar = '●';
  static const String centerLineChar = '┊';

  // Game state
  int paddle1Y = 0;
  int paddle2Y = 0;
  double ballX = 0;
  double ballY = 0;
  double ballDx = 1;
  double ballDy = 0.5;
  int score1 = 0;
  int score2 = 0;
  bool gameRunning = true;
  bool gameOver = false;

  // Frame counter for ball speed control
  int frameCount = 0;
  static const int ballUpdateInterval = 2; // Update ball every N frames

  PongGame() {
    showFps = true;
  }

  @override
  void start() {
    super.start();
  }

  void _resetGame() {
    score1 = 0;
    score2 = 0;
    gameOver = false;
    gameRunning = true;
    _resetPaddles();
    _resetBall();
  }

  void _resetBall() {
    ballX = width / 2;
    ballY = height / 2;

    // Random initial direction
    final random = Random();
    ballDx = random.nextBool() ? 1.0 : -1.0;
    ballDy = (random.nextDouble() - 0.5) * 1.5;
  }

  void _resetPaddles() {
    paddle1Y = (height - paddleHeight) ~/ 2;
    paddle2Y = (height - paddleHeight) ~/ 2;
  }

  bool _initialized = false;

  @override
  void resize(Size size, Position position) {
    super.resize(size, position);
    if (!_initialized) {
      _initialized = true;
      _resetPaddles();
      _resetBall();
    }
  }

  @override
  bool onKey(String key) {
    switch (key) {
      // Player 1 controls (W/S)
      case 'w':
      case 'W':
        if (paddle1Y > 1) paddle1Y--;
        return true;
      case 's':
      case 'S':
        if (paddle1Y < height - paddleHeight - 2) paddle1Y++;
        return true;

      // Player 2 controls (Arrow keys)
      case KeyCode.UP:
        if (paddle2Y > 1) paddle2Y--;
        return true;
      case KeyCode.DOWN:
        if (paddle2Y < height - paddleHeight - 2) paddle2Y++;
        return true;

      // Game controls
      case KeyCode.SPACE:
        if (gameOver) {
          _resetGame();
        } else {
          gameRunning = !gameRunning;
        }
        return true;
      case 'r':
      case 'R':
        _resetGame();
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

    // Bounce off top/bottom walls
    if (ballY <= 1) {
      ballY = 1;
      ballDy = -ballDy;
    }
    if (ballY >= height - 2) {
      ballY = height - 2.0;
      ballDy = -ballDy;
    }

    // Check paddle collisions
    final paddle1X = paddleMargin;
    final paddle2X = width - paddleMargin - 1;

    // Ball hits left paddle
    if (ballX <= paddle1X + 1 && ballX >= paddle1X) {
      if (ballY >= paddle1Y && ballY < paddle1Y + paddleHeight) {
        ballX = paddle1X + 1.0;
        ballDx = -ballDx;
        // Add spin based on where it hit the paddle
        final hitPos = (ballY - paddle1Y) / paddleHeight;
        ballDy = (hitPos - 0.5) * 2;
      }
    }

    // Ball hits right paddle
    if (ballX >= paddle2X - 1 && ballX <= paddle2X) {
      if (ballY >= paddle2Y && ballY < paddle2Y + paddleHeight) {
        ballX = paddle2X - 1.0;
        ballDx = -ballDx;
        // Add spin based on where it hit the paddle
        final hitPos = (ballY - paddle2Y) / paddleHeight;
        ballDy = (hitPos - 0.5) * 2;
      }
    }

    // Check for scoring
    if (ballX <= 0) {
      score2++;
      _checkWin();
      _resetBall();
    }
    if (ballX >= width - 1) {
      score1++;
      _checkWin();
      _resetBall();
    }
  }

  void _checkWin() {
    if (score1 >= 11 || score2 >= 11) {
      gameOver = true;
      gameRunning = false;
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw border
    _drawBorder(canvas);

    // Draw center line
    _drawCenterLine(canvas);

    // Draw score
    _drawScore(canvas);

    // Draw paddles
    _drawPaddle(canvas, paddleMargin, paddle1Y);
    _drawPaddle(canvas, width - paddleMargin - 1, paddle2Y);

    // Draw ball
    if (!gameOver) {
      canvas.write(ballX.round(), ballY.round(), ballChar);
    }

    // Draw status
    _drawStatus(canvas);

    // Draw game over message
    if (gameOver) {
      _drawGameOver(canvas);
    }
  }

  void _drawBorder(Canvas canvas) {
    // Top border
    canvas.write(0, 0, BoxChars.roundedTL);
    for (var x = 1; x < width - 1; x++) {
      canvas.write(x, 0, BoxChars.lightH);
    }
    canvas.write(width - 1, 0, BoxChars.roundedTR);

    // Bottom border
    canvas.write(0, height - 1, BoxChars.roundedBL);
    for (var x = 1; x < width - 1; x++) {
      canvas.write(x, height - 1, BoxChars.lightH);
    }
    canvas.write(width - 1, height - 1, BoxChars.roundedBR);

    // Side borders
    for (var y = 1; y < height - 1; y++) {
      canvas.write(0, y, BoxChars.lightV);
      canvas.write(width - 1, y, BoxChars.lightV);
    }
  }

  void _drawCenterLine(Canvas canvas) {
    final centerX = width ~/ 2;
    for (var y = 1; y < height - 1; y++) {
      if (y % 2 == 0) {
        canvas.write(centerX, y, centerLineChar);
      }
    }
  }

  void _drawScore(Canvas canvas) {
    final scoreText = '  $score1  ${BoxChars.lightV}  $score2  ';
    final scoreX = (width - scoreText.length) ~/ 2;
    for (var i = 0; i < scoreText.length; i++) {
      canvas.write(scoreX + i, 0, scoreText[i]);
    }
  }

  void _drawPaddle(Canvas canvas, int x, int y) {
    for (var i = 0; i < paddleHeight; i++) {
      canvas.write(x, y + i, paddleChar);
    }
  }

  void _drawStatus(Canvas canvas) {
    String status;
    if (gameOver) {
      status = ' GAME OVER - SPACE to restart ';
    } else if (!gameRunning) {
      status = ' PAUSED - SPACE to resume ';
    } else {
      status = ' W/S: P1 ${BoxChars.lightV} ↑/↓: P2 ${BoxChars.lightV} SPACE: pause ${BoxChars.lightV} R: restart ${BoxChars.lightV} Q: quit ';
    }
    final statusX = (width - status.length) ~/ 2;
    for (var i = 0; i < status.length; i++) {
      canvas.write(statusX + i, height - 1, status[i]);
    }
  }

  void _drawGameOver(Canvas canvas) {
    final winner = score1 >= 11 ? 'Player 1' : 'Player 2';
    final message = ' $winner wins! ';
    final messageX = (width - message.length) ~/ 2;
    final messageY = height ~/ 2;

    // Draw message box
    final boxWidth = message.length + 4;
    final boxX = messageX - 2;

    canvas.write(boxX, messageY - 1, BoxChars.doubleTL);
    for (var i = 1; i < boxWidth - 1; i++) {
      canvas.write(boxX + i, messageY - 1, BoxChars.doubleH);
    }
    canvas.write(boxX + boxWidth - 1, messageY - 1, BoxChars.doubleTR);

    canvas.write(boxX, messageY, BoxChars.doubleV);
    for (var i = 0; i < message.length; i++) {
      canvas.write(messageX + i, messageY, message[i]);
    }
    canvas.write(boxX + boxWidth - 1, messageY, BoxChars.doubleV);

    canvas.write(boxX, messageY + 1, BoxChars.doubleBL);
    for (var i = 1; i < boxWidth - 1; i++) {
      canvas.write(boxX + i, messageY + 1, BoxChars.doubleH);
    }
    canvas.write(boxX + boxWidth - 1, messageY + 1, BoxChars.doubleBR);
  }
}

void main() {
  print('PONG');
  print(BoxChars.lightH * 40);
  print('');
  print('Controls:');
  print('  Player 1: W (up) / S (down)');
  print('  Player 2: ↑ (up) / ↓ (down)');
  print('');
  print('  SPACE: Pause/Resume');
  print('  R: Restart');
  print('  Q/ESC: Quit');
  print('');
  print('First to 11 points wins!');
  print(BoxChars.lightH * 40);
  print('Starting in 2 seconds...');

  Future.delayed(Duration(seconds: 2), () {
    PongGame().start();
  });
}
