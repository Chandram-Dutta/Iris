import Iris

class Bullet {
    var x: Float
    var y: Float
    let width: Float = 8
    let height: Float = 24
    let speed: Float = 600
    var isActive: Bool = true

    static nonisolated(unsafe) var image: Image?

    init(x: Float, y: Float) {
        self.x = x - width / 2
        self.y = y

        if Bullet.image == nil {
            Bullet.image = Image.load(GameResources.imagePath("bullet.png"))
        }
    }

    func update(deltaTime: Double) {
        y -= speed * Float(deltaTime)

        if y < -height {
            isActive = false
        }
    }

    func draw(_ g: Graphics) {
        if let img = Bullet.image {
            g.drawImage(img, x: x, y: y)
        } else {
            // Fallback: cyan rectangle
            g.fillRect(
                x: x, y: y, width: width, height: height, color: Color(r: 0.3, g: 0.9, b: 1.0))
        }
    }

    var rect: (x: Float, y: Float, w: Float, h: Float) {
        return (x, y, width, height)
    }
}
