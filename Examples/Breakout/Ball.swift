import Iris

struct Ball {
    var x: Float
    var y: Float
    let radius: Float
    var dx: Float
    var dy: Float

    init(x: Float, y: Float, radius: Float) {
        self.x = x
        self.y = y
        self.radius = radius
        self.dx = 200.0
        self.dy = -200.0
    }

    mutating func update(deltaTime: Double, screenWidth: Float, screenHeight: Float) {
        x += dx * Float(deltaTime)
        y += dy * Float(deltaTime)

        // Wall collisions
        if x <= 0 {
            x = 0
            dx = -dx
        }
        if x + radius * 2 >= screenWidth {
            x = screenWidth - radius * 2
            dx = -dx
        }
        if y <= 0 {
            y = 0
            dy = -dy
        }
        // Bottom wall is game over, handled by game loop usually, but for now let's just bounce or let it pass
        // The Game class will check for game over condition
    }

    func draw(_ g: Graphics) {
        // Draw ball with radial gradient for depth
        let gradient = Gradient.radial(
            centerX: x + radius, centerY: y + radius, radius: radius,
            innerColor: Color(r: 1.0, g: 0.8, b: 0.8),
            outerColor: Color(r: 1.0, g: 0.2, b: 0.2)
        )
        g.fillRectGradient(x: x, y: y, width: radius * 2, height: radius * 2, gradient: gradient)

        // Add stroke outline for better visibility
        g.strokeCircle(x: x + radius, y: y + radius, radius: radius, width: 2, color: .white)
    }

    var rect: (x: Float, y: Float, w: Float, h: Float) {
        // Simple AABB for the ball
        return (x, y, radius * 2, radius * 2)
    }

    mutating func bounceY() {
        dy = -dy
    }

    mutating func bounceX() {
        dx = -dx
    }
}
