import Foundation
import Iris

class Enemy {
    var x: Float
    var y: Float
    let width: Float = 48
    let height: Float = 48
    var speedY: Float
    var speedX: Float
    var isActive: Bool = true

    static nonisolated(unsafe) var image: Image?

    // Animation
    var wobbleTime: Double = 0
    let wobbleAmount: Float = 20

    init(x: Float, y: Float, speedY: Float = 100, speedX: Float = 0) {
        self.x = x
        self.y = y
        self.speedY = speedY
        self.speedX = speedX
        self.wobbleTime = Double.random(in: 0...3.14)

        if Enemy.image == nil {
            Enemy.image = Image.load(GameResources.imagePath("enemy.png"))
        }
    }

    func update(deltaTime: Double, screenWidth: Float, screenHeight: Float) {
        // Move downward
        y += speedY * Float(deltaTime)

        // Wobble side to side
        wobbleTime += deltaTime * 3
        let wobbleOffset = Float(sin(wobbleTime)) * wobbleAmount * Float(deltaTime)
        x += wobbleOffset

        // Keep in bounds horizontally
        x = max(0, min(screenWidth - width, x))

        // Deactivate if off screen
        if y > screenHeight + height {
            isActive = false
        }
    }

    func draw(_ g: Graphics) {
        if let img = Enemy.image {
            g.drawImage(img, x: x, y: y)
        } else {
            // Enhanced fallback with gradient and stroke
            let gradient = Gradient.linear(
                startX: x, startY: y,
                endX: x, endY: y + height,
                startColor: Color(r: 0.9, g: 0.3, b: 0.6),
                endColor: Color(r: 0.6, g: 0.1, b: 0.3)
            )
            g.fillRectGradient(
                x: x, y: y, width: width, height: height,
                gradient: gradient
            )

            // Add stroke outline for definition
            g.strokeRect(
                x: x, y: y, width: width, height: height,
                strokeWidth: 2.0,
                color: Color(r: 1.0, g: 0.5, b: 0.7, a: 0.8)
            )
        }
    }

    var rect: (x: Float, y: Float, w: Float, h: Float) {
        return (x, y, width, height)
    }
}
