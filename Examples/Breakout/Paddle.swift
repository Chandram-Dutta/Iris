import Iris

struct Paddle {
    var x: Float
    var y: Float
    let width: Float
    let height: Float
    let speed: Float = 400.0
    let screenWidth: Float

    init(x: Float, y: Float, width: Float, height: Float, screenWidth: Float) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.screenWidth = screenWidth
    }

    mutating func update(deltaTime: Double) {
        if Input.shared.isKeyDown(.left) || Input.shared.isKeyDown(.a) {
            x -= speed * Float(deltaTime)
        }
        if Input.shared.isKeyDown(.right) || Input.shared.isKeyDown(.d) {
            x += speed * Float(deltaTime)
        }

        // Clamp to screen
        if x < 0 { x = 0 }
        if x + width > screenWidth { x = screenWidth - width }
    }

    func draw(_ g: Graphics) {
        // Draw paddle with vertical gradient for 3D depth effect
        let gradient = Gradient.linear(
            startX: x, startY: y,
            endX: x, endY: y + height,
            startColor: Color(r: 0.9, g: 0.9, b: 0.9),
            endColor: Color(r: 0.5, g: 0.5, b: 0.5)
        )
        g.fillRectGradient(x: x, y: y, width: width, height: height, gradient: gradient)

        // Add stroke outline for definition
        g.strokeRect(x: x, y: y, width: width, height: height, strokeWidth: 2, color: .white)
    }

    var rect: (x: Float, y: Float, w: Float, h: Float) {
        return (x, y, width, height)
    }
}
