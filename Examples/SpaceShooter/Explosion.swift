import Iris

class Explosion {
    let x: Float
    let y: Float
    let width: Float = 48
    let height: Float = 48
    var lifetime: Double = 0.3
    var isActive: Bool = true
    var scale: Float = 1.0

    static nonisolated(unsafe) var image: Image?

    init(x: Float, y: Float) {
        self.x = x
        self.y = y

        if Explosion.image == nil {
            Explosion.image = Image.load(GameResources.imagePath("explosion.png"))
        }
    }

    func update(deltaTime: Double) {
        lifetime -= deltaTime
        scale = Float(lifetime / 0.3) * 1.5

        if lifetime <= 0 {
            isActive = false
        }
    }

    func draw(_ g: Graphics) {
        let offsetX = x - (width * scale) / 2
        let offsetY = y - (height * scale) / 2

        if let img = Explosion.image {
            g.drawImage(img, x: offsetX, y: offsetY)
        } else {
            // Fallback: orange/yellow circles
            let alpha = Float(lifetime / 0.3)
            g.fillRect(
                x: offsetX, y: offsetY, width: width * scale, height: height * scale,
                color: Color(r: 1.0, g: 0.6, b: 0.1, a: alpha))
        }
    }
}
