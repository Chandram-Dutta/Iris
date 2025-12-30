import Iris

class SnakeGame: Game {
    let grid: Grid
    var snake: Snake
    var food: Food
    var score: Int = 0
    var highScore: Int = 0
    var isGameOver: Bool = false
    var foodEatenCount: Int = 0

    let screenWidth: Float = 800
    let screenHeight: Float = 600
    let gridCols = 30
    let gridRows = 22
    let uiHeight: Float = 80

    init() {
        let cellSize: Float = 25
        let gridWidth = Float(gridCols) * cellSize
        let gridHeight = Float(gridRows) * cellSize
        let offsetX = (screenWidth - gridWidth) / 2
        let offsetY = uiHeight + (screenHeight - uiHeight - gridHeight) / 2

        grid = Grid(
            cellSize: cellSize, rows: gridRows, cols: gridCols, offsetX: offsetX, offsetY: offsetY)
        snake = Snake(startX: gridCols / 2, startY: gridRows / 2)
        food = Food(gridX: 0, gridY: 0)
        spawnFood()
    }

    func spawnFood() {
        var validPosition = false
        var newX = 0
        var newY = 0

        while !validPosition {
            newX = Int.random(in: 0..<gridCols)
            newY = Int.random(in: 0..<gridRows)

            validPosition = true
            for segment in snake.segments {
                if segment.gridX == newX && segment.gridY == newY {
                    validPosition = false
                    break
                }
            }
        }

        // 10% chance for bonus food
        let foodType: FoodType = Int.random(in: 0..<10) == 0 ? .bonus : .normal
        food = Food(gridX: newX, gridY: newY, type: foodType)
    }

    func update(deltaTime: Double, debug: DebugInfo) {
        if isGameOver {
            if Input.shared.isKeyDown(.space) {
                resetGame()
            }
            return
        }

        // Handle input
        if Input.shared.isKeyDown(.up) || Input.shared.isKeyDown(.w) {
            snake.setDirection(.up)
        }
        if Input.shared.isKeyDown(.down) || Input.shared.isKeyDown(.s) {
            snake.setDirection(.down)
        }
        if Input.shared.isKeyDown(.left) || Input.shared.isKeyDown(.a) {
            snake.setDirection(.left)
        }
        if Input.shared.isKeyDown(.right) || Input.shared.isKeyDown(.d) {
            snake.setDirection(.right)
        }

        // Update snake
        snake.update(deltaTime: deltaTime)

        // Move snake if it's time
        if snake.shouldMove() {
            snake.move()

            // Check wall collision
            let head = snake.head
            if !grid.isInBounds(gridX: head.gridX, gridY: head.gridY) {
                gameOver()
                return
            }

            // Check self collision
            if snake.checkSelfCollision() {
                gameOver()
                return
            }

            // Check food collision
            if head.gridX == food.gridX && head.gridY == food.gridY {
                snake.grow()
                score += food.type.points
                foodEatenCount += 1

                // Speed up every 5 foods
                if foodEatenCount % 5 == 0 {
                    snake.moveInterval = max(0.05, snake.moveInterval * 0.9)
                }

                spawnFood()
            }
        }

        // Update food animation
        food.update(deltaTime: deltaTime)
    }

    func draw(_ g: Graphics, debug: DebugInfo) {
        // Background gradient
        drawBackground(g)

        // UI area
        drawUI(g)

        if isGameOver {
            drawGameOver(g)
        } else {
            // Draw grid
            grid.draw(g)

            // Draw food
            food.draw(g, grid: grid)

            // Draw snake
            snake.draw(g, grid: grid)
        }
    }

    func drawBackground(_ g: Graphics) {
        // Dark gradient background
        let bgColor1 = Color(r: 0.05, g: 0.08, b: 0.12)
        let bgColor2 = Color(r: 0.08, g: 0.12, b: 0.18)

        // Simple gradient effect with horizontal bands
        let bands = 20
        for i in 0..<bands {
            let ratio = Float(i) / Float(bands)
            let r = bgColor1.r + (bgColor2.r - bgColor1.r) * ratio
            let gb = bgColor1.g + (bgColor2.g - bgColor1.g) * ratio
            let b = bgColor1.b + (bgColor2.b - bgColor1.b) * ratio
            let color = Color(r: r, g: gb, b: b)

            let y = Float(i) * screenHeight / Float(bands)
            let height = screenHeight / Float(bands) + 1
            g.fillRect(x: 0, y: y, width: screenWidth, height: height, color: color)
        }
    }

    func drawUI(_ g: Graphics) {
        // UI background
        g.fillRect(
            x: 0, y: 0, width: screenWidth, height: uiHeight,
            color: Color(r: 0.1, g: 0.15, b: 0.2, a: 0.9))

        // Title
        g.drawText(
            "SNAKE", x: 30, y: 25, font: .system(size: 32), color: Color(r: 0.2, g: 1.0, b: 0.6))

        // Score
        g.drawText("Score: \(score)", x: 200, y: 30, font: .system(size: 24), color: .white)

        // High Score
        g.drawText(
            "High: \(highScore)", x: 400, y: 30, font: .system(size: 24),
            color: Color(r: 1.0, g: 0.84, b: 0.0))

        // Speed indicator
        let speed = Int((1.0 / snake.moveInterval) * 10)
        g.drawText(
            "Speed: \(speed)", x: 600, y: 30, font: .system(size: 24),
            color: Color(r: 0.5, g: 0.8, b: 1.0))
    }

    func drawGameOver(_ g: Graphics) {
        // Semi-transparent overlay
        g.fillRect(
            x: 0, y: 0, width: screenWidth, height: screenHeight,
            color: Color(r: 0, g: 0, b: 0, a: 0.7))

        // Game Over text
        g.drawText(
            "GAME OVER",
            x: screenWidth / 2 - 120,
            y: screenHeight / 2 - 60,
            font: .system(size: 48),
            color: Color(r: 1.0, g: 0.3, b: 0.3)
        )

        // Final score
        g.drawText(
            "Final Score: \(score)",
            x: screenWidth / 2 - 100,
            y: screenHeight / 2,
            font: .system(size: 28),
            color: .white
        )

        // High score
        if score == highScore && score > 0 {
            g.drawText(
                "NEW HIGH SCORE!",
                x: screenWidth / 2 - 110,
                y: screenHeight / 2 + 40,
                font: .system(size: 24),
                color: Color(r: 1.0, g: 0.84, b: 0.0)
            )
        }

        // Restart instruction
        g.drawText(
            "Press SPACE to restart",
            x: screenWidth / 2 - 120,
            y: screenHeight / 2 + 80,
            font: .system(size: 20),
            color: Color(r: 0.7, g: 0.7, b: 0.7)
        )
    }

    func gameOver() {
        isGameOver = true
        if score > highScore {
            highScore = score
        }
    }

    func resetGame() {
        snake = Snake(startX: gridCols / 2, startY: gridRows / 2)
        score = 0
        foodEatenCount = 0
        isGameOver = false
        spawnFood()
    }
}
