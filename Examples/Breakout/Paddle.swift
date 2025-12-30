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
        g.fillRect(x: x, y: y, width: width, height: height, color: .white)
    }

    var rect: (x: Float, y: Float, w: Float, h: Float) {
        return (x, y, width, height)
    }
}
