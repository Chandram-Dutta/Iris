import Iris

class SpaceShooterGame: Game {
    let screenWidth: Float = 800
    let screenHeight: Float = 600

    var player: Player
    var bullets: [Bullet] = []
    var enemies: [Enemy] = []
    var explosions: [Explosion] = []
    var stars: [Star] = []

    var score: Int = 0
    var highScore: Int = 0
    var lives: Int = 3
    var isGameOver: Bool = false
    var isPaused: Bool = false

    // Enemy spawning
    var enemySpawnTimer: Double = 0
    var enemySpawnRate: Double = 1.5  // seconds between spawns
    var wave: Int = 1
    var enemiesKilledThisWave: Int = 0
    let enemiesPerWave: Int = 10

    // Visual feedback
    var screenShake: Float = 0
    var flashTimer: Double = 0

    init() {
        player = Player(screenWidth: screenWidth, screenHeight: screenHeight)

        // Create initial starfield
        for _ in 0..<100 {
            stars.append(Star(screenWidth: screenWidth, screenHeight: screenHeight))
        }
    }

    func update(deltaTime: Double, debug: DebugInfo) {
        // Handle game over state
        if isGameOver {
            if Input.shared.isKeyDown(.space) {
                resetGame()
            }
            return
        }

        // Pause toggle
        if Input.shared.isKeyDown(.escape) {
            isPaused.toggle()
        }

        if isPaused { return }

        // Update visual effects
        if screenShake > 0 {
            screenShake -= Float(deltaTime) * 20
        }
        if flashTimer > 0 {
            flashTimer -= deltaTime
        }

        // Update stars
        for i in 0..<stars.count {
            stars[i].update(
                deltaTime: deltaTime, screenWidth: screenWidth, screenHeight: screenHeight)
        }

        // Update player
        player.update(deltaTime: deltaTime)

        // Shooting
        if Input.shared.isKeyDown(.space) && player.canShoot() {
            let bullet = Bullet(x: player.centerX, y: player.centerY)
            bullets.append(bullet)
            player.shoot()
        }

        // Update bullets
        for i in 0..<bullets.count {
            bullets[i].update(deltaTime: deltaTime)
        }
        bullets.removeAll { !$0.isActive }

        // Spawn enemies
        enemySpawnTimer += deltaTime
        if enemySpawnTimer >= enemySpawnRate {
            spawnEnemy()
            enemySpawnTimer = 0
        }

        // Update enemies
        for i in 0..<enemies.count {
            enemies[i].update(
                deltaTime: deltaTime, screenWidth: screenWidth, screenHeight: screenHeight)

            // Check collision with player
            if enemies[i].isActive && checkCollision(rect1: enemies[i].rect, rect2: player.rect) {
                enemies[i].isActive = false
                explosions.append(
                    Explosion(
                        x: enemies[i].x + enemies[i].width / 2,
                        y: enemies[i].y + enemies[i].height / 2))
                loseLife()
            }
        }
        enemies.removeAll { !$0.isActive }

        // Check bullet-enemy collisions
        for bullet in bullets {
            guard bullet.isActive else { continue }

            for i in 0..<enemies.count {
                guard enemies[i].isActive else { continue }

                if checkCollision(rect1: bullet.rect, rect2: enemies[i].rect) {
                    bullet.isActive = false
                    enemies[i].isActive = false

                    // Create explosion
                    explosions.append(
                        Explosion(
                            x: enemies[i].x + enemies[i].width / 2,
                            y: enemies[i].y + enemies[i].height / 2))

                    // Score
                    score += 100 * wave
                    enemiesKilledThisWave += 1
                    screenShake = 5

                    // Check for wave completion
                    if enemiesKilledThisWave >= enemiesPerWave {
                        advanceWave()
                    }

                    break
                }
            }
        }

        // Update explosions
        for i in 0..<explosions.count {
            explosions[i].update(deltaTime: deltaTime)
        }
        explosions.removeAll { !$0.isActive }
    }

    func draw(_ g: Graphics, debug: DebugInfo) {
        // Note: screenShake is tracked but not rendered (would need engine transform support)

        // Draw background
        drawBackground(g)

        // Draw stars
        for star in stars {
            star.draw(g)
        }

        if isGameOver {
            drawGameOver(g)
        } else {
            // Draw explosions (behind everything else)
            for explosion in explosions {
                explosion.draw(g)
            }

            // Draw enemies
            for enemy in enemies {
                enemy.draw(g)
            }

            // Draw bullets
            for bullet in bullets {
                bullet.draw(g)
            }

            // Draw player
            player.draw(g)

            // Draw UI
            drawUI(g)

            // Draw pause overlay
            if isPaused {
                drawPauseOverlay(g)
            }

            // Draw damage flash
            if flashTimer > 0 {
                let alpha = Float(flashTimer / 0.2) * 0.3
                g.fillRect(
                    x: 0, y: 0, width: screenWidth, height: screenHeight,
                    color: Color(r: 1.0, g: 0, b: 0, a: alpha))
            }
        }
    }

    func drawBackground(_ g: Graphics) {
        // Deep space gradient
        let bands = 15
        for i in 0..<bands {
            let ratio = Float(i) / Float(bands)
            let r: Float = 0.02 + ratio * 0.03
            let gb: Float = 0.0 + ratio * 0.04
            let b: Float = 0.05 + ratio * 0.08

            let y = Float(i) * screenHeight / Float(bands)
            let height = screenHeight / Float(bands) + 1
            g.fillRect(
                x: 0, y: y, width: screenWidth, height: height, color: Color(r: r, g: gb, b: b))
        }
    }

    func drawUI(_ g: Graphics) {
        // Top bar background
        g.fillRect(
            x: 0, y: 0, width: screenWidth, height: 50, color: Color(r: 0, g: 0, b: 0, a: 0.7))

        // Score
        g.drawText("SCORE: \(score)", x: 20, y: 15, font: .system(size: 20), color: .white)

        // Wave
        g.drawText(
            "WAVE \(wave)", x: screenWidth / 2 - 40, y: 15, font: .system(size: 20),
            color: Color(r: 1.0, g: 0.84, b: 0.0))

        // Lives
        g.drawText(
            "LIVES: \(lives)", x: screenWidth - 120, y: 15, font: .system(size: 20),
            color: Color(r: 1.0, g: 0.3, b: 0.3))

        // High score
        g.drawText(
            "HIGH: \(highScore)", x: 200, y: 15, font: .system(size: 16),
            color: Color(r: 0.7, g: 0.7, b: 0.7))
    }

    func drawGameOver(_ g: Graphics) {
        // Overlay
        g.fillRect(
            x: 0, y: 0, width: screenWidth, height: screenHeight,
            color: Color(r: 0, g: 0, b: 0, a: 0.8))

        // Title
        g.drawText(
            "GAME OVER", x: screenWidth / 2 - 120, y: screenHeight / 2 - 80,
            font: .system(size: 48), color: Color(r: 1.0, g: 0.3, b: 0.3))

        // Final Score
        g.drawText(
            "Final Score: \(score)", x: screenWidth / 2 - 100, y: screenHeight / 2 - 10,
            font: .system(size: 28), color: .white)

        // Waves survived
        g.drawText(
            "Waves Survived: \(wave)", x: screenWidth / 2 - 90, y: screenHeight / 2 + 30,
            font: .system(size: 20), color: Color(r: 0.5, g: 0.8, b: 1.0))

        // New high score
        if score == highScore && score > 0 {
            g.drawText(
                "NEW HIGH SCORE!", x: screenWidth / 2 - 100, y: screenHeight / 2 + 70,
                font: .system(size: 24), color: Color(r: 1.0, g: 0.84, b: 0.0))
        }

        // Restart prompt
        g.drawText(
            "Press SPACE to restart", x: screenWidth / 2 - 110, y: screenHeight / 2 + 120,
            font: .system(size: 18), color: Color(r: 0.7, g: 0.7, b: 0.7))
    }

    func drawPauseOverlay(_ g: Graphics) {
        g.fillRect(
            x: 0, y: 0, width: screenWidth, height: screenHeight,
            color: Color(r: 0, g: 0, b: 0, a: 0.5))
        g.drawText(
            "PAUSED", x: screenWidth / 2 - 60, y: screenHeight / 2 - 20,
            font: .system(size: 40), color: .white)
        g.drawText(
            "Press ESC to resume", x: screenWidth / 2 - 90, y: screenHeight / 2 + 30,
            font: .system(size: 18), color: Color(r: 0.7, g: 0.7, b: 0.7))
    }

    func spawnEnemy() {
        let x = Float.random(in: 50...(screenWidth - 98))
        let baseSpeed: Float = 80 + Float(wave) * 15
        let speed = baseSpeed + Float.random(in: -20...20)

        let enemy = Enemy(x: x, y: -50, speedY: speed)
        enemies.append(enemy)
    }

    func advanceWave() {
        wave += 1
        enemiesKilledThisWave = 0
        enemySpawnRate = max(0.3, enemySpawnRate * 0.9)  // Faster spawns

        // Bonus life every 3 waves
        if wave % 3 == 0 {
            lives = min(5, lives + 1)
        }
    }

    func loseLife() {
        lives -= 1
        flashTimer = 0.2
        screenShake = 15

        if lives <= 0 {
            gameOver()
        }
    }

    func gameOver() {
        isGameOver = true
        if score > highScore {
            highScore = score
        }
    }

    func resetGame() {
        player = Player(screenWidth: screenWidth, screenHeight: screenHeight)
        bullets.removeAll()
        enemies.removeAll()
        explosions.removeAll()

        score = 0
        lives = 3
        wave = 1
        enemiesKilledThisWave = 0
        enemySpawnRate = 1.5
        enemySpawnTimer = 0
        isGameOver = false
        isPaused = false
    }

    func checkCollision(
        rect1: (x: Float, y: Float, w: Float, h: Float),
        rect2: (x: Float, y: Float, w: Float, h: Float)
    ) -> Bool {
        return rect1.x < rect2.x + rect2.w && rect1.x + rect1.w > rect2.x
            && rect1.y < rect2.y + rect2.h && rect1.y + rect1.h > rect2.y
    }
}
