import Iris

struct Star {
    var x: Float
    var y: Float
    let size: Float
    let speed: Float
    let brightness: Float

    init(screenWidth: Float, screenHeight: Float, randomY: Bool = true) {
        self.x = Float.random(in: 0...screenWidth)
        self.y = randomY ? Float.random(in: 0...screenHeight) : -5
        self.size = Float.random(in: 1...3)
        self.speed = Float.random(in: 50...200)
        self.brightness = Float.random(in: 0.3...1.0)
    }

    mutating func update(deltaTime: Double, screenWidth: Float, screenHeight: Float) {
        y += speed * Float(deltaTime)

        if y > screenHeight {
            // Reset to top
            y = -5
            x = Float.random(in: 0...screenWidth)
        }
    }

    func draw(_ g: Graphics) {
        let color = Color(r: brightness, g: brightness, b: brightness * 1.1)
        g.fillRect(x: x, y: y, width: size, height: size, color: color)
    }
}
