import Iris

class BreakoutGame: Game {
    var paddle: Paddle
    var ball: Ball
    var bricks: [Brick] = []

    let screenWidth: Float = 800
    let screenHeight: Float = 600

    var score: Int = 0
    var isGameOver: Bool = false

    init() {
        paddle = Paddle(
            x: screenWidth / 2 - 50, y: screenHeight - 40, width: 100, height: 20,
            screenWidth: screenWidth)
        ball = Ball(x: screenWidth / 2, y: screenHeight / 2, radius: 8)
        resetLevel()
    }

    func resetLevel() {
        bricks.removeAll()
        let rows = 5
        let cols = 8
        let brickW: Float = (screenWidth - 100) / Float(cols)
        let brickH: Float = 30

        for r in 0..<rows {
            for c in 0..<cols {
                let color = Color(
                    r: Float(r) / Float(rows), g: 0.5, b: 1.0 - Float(r) / Float(rows))
                let brick = Brick(
                    x: 50 + Float(c) * brickW,
                    y: 50 + Float(r) * brickH,
                    width: brickW - 5,
                    height: brickH - 5,
                    color: color
                )
                bricks.append(brick)
            }
        }
    }

    func update(deltaTime: Double, debug: DebugInfo) {
        if isGameOver {
            if Input.shared.isKeyDown(.space) {
                isGameOver = false
                score = 0
                resetLevel()
                ball = Ball(x: screenWidth / 2, y: screenHeight / 2, radius: 8)
            }
            return
        }

        paddle.update(deltaTime: deltaTime)
        ball.update(deltaTime: deltaTime, screenWidth: screenWidth, screenHeight: screenHeight)

        // Death check
        if ball.y > screenHeight {
            isGameOver = true
        }

        // Paddle collision
        if checkCollision(rect1: ball.rect, rect2: paddle.rect) {
            ball.dy = -abs(ball.dy)  // Always bounce up
            // Simple speed increase
            ball.dx *= 1.05
            ball.dy *= 1.05
        }

        // Brick collision
        for i in 0..<bricks.count {
            if bricks[i].isActive {
                if checkCollision(rect1: ball.rect, rect2: bricks[i].rect) {
                    bricks[i].isActive = false
                    ball.bounceY()  // Simple bounce
                    score += 10
                    break  // Only one brick per frame to prevent weirdness
                }
            }
        }
    }

    func draw(_ g: Graphics, debug: DebugInfo) {
        g.clear(.black)

        if isGameOver {
            g.drawText(
                "GAME OVER", x: screenWidth / 2 - 50, y: screenHeight / 2, font: .system(size: 32),
                color: .white)
            g.drawText(
                "Press Space to Restart", x: screenWidth / 2 - 80, y: screenHeight / 2 + 30,
                font: .system(size: 16), color: .white)
        } else {
            paddle.draw(g)
            ball.draw(g)

            for brick in bricks {
                if brick.isActive {
                    g.fillRect(
                        x: brick.x, y: brick.y, width: brick.width, height: brick.height,
                        color: brick.color)
                }
            }

            g.drawText("Score: \(score)", x: 20, y: 30, font: .system(size: 24), color: .white)
        }
    }

    func checkCollision(
        rect1: (x: Float, y: Float, w: Float, h: Float),
        rect2: (x: Float, y: Float, w: Float, h: Float)
    ) -> Bool {
        return rect1.x < rect2.x + rect2.w && rect1.x + rect1.w > rect2.x
            && rect1.y < rect2.y + rect2.h && rect1.y + rect1.h > rect2.y
    }
}
