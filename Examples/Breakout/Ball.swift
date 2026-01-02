import Iris

struct Ball {
    var x: Float
    var y: Float
    let radius: Float
    var dx: Float
    var dy: Float

    /// Circle hitbox for accurate ball collision
    var hitbox: Hitbox

    init(x: Float, y: Float, radius: Float) {
        self.x = x
        self.y = y
        self.radius = radius
        self.dx = 200.0
        self.dy = -200.0

        self.hitbox = Hitbox(x: x + radius, y: y + radius, shape: .circle(radius: radius))
    }

    mutating func update(deltaTime: Double, screenWidth: Float, screenHeight: Float) {
        x += dx * Float(deltaTime)
        y += dy * Float(deltaTime)

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

        hitbox.position = SIMD2<Float>(x + radius, y + radius)
    }

    func draw(_ g: Graphics) {
        let gradient = Gradient.radial(
            centerX: x + radius, centerY: y + radius, radius: radius,
            innerColor: Color(r: 1.0, g: 0.8, b: 0.8),
            outerColor: Color(r: 1.0, g: 0.2, b: 0.2)
        )
        g.fillRectGradient(x: x, y: y, width: radius * 2, height: radius * 2, gradient: gradient)

        g.strokeCircle(x: x + radius, y: y + radius, radius: radius, width: 2, color: .white)
    }

    var rect: (x: Float, y: Float, w: Float, h: Float) {
        return (x, y, radius * 2, radius * 2)
    }

    mutating func bounceY() {
        dy = -dy
    }

    mutating func bounceX() {
        dx = -dx
    }
}
