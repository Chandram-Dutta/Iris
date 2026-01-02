import Iris

class Bullet {
    var x: Float
    var y: Float
    let width: Float = 8
    let height: Float = 24
    let speed: Float = 600
    var isActive: Bool = true

    static nonisolated(unsafe) var image: Image?

    /// Circle hitbox for the bullet (more accurate than rectangular)
    var hitbox: Hitbox

    init(x: Float, y: Float) {
        self.x = x - width / 2
        self.y = y

        // Use circle hitbox for bullet (centered)
        let centerX = x
        let centerY = y + height / 2
        self.hitbox = Hitbox(x: centerX, y: centerY, shape: .circle(radius: width / 2))

        if Bullet.image == nil {
            Bullet.image = Image.load(GameResources.imagePath("bullet.png"))
        }
    }

    func update(deltaTime: Double) {
        y -= speed * Float(deltaTime)

        if y < -height {
            isActive = false
        }

        // Update hitbox position
        hitbox.position = SIMD2<Float>(x + width / 2, y + height / 2)
    }

    func draw(_ g: Graphics) {
        if let img = Bullet.image {
            g.drawImage(img, x: x, y: y)
        } else {
            // Enhanced fallback with gradient and glow
            let centerX = x + width / 2
            let centerY = y + height / 2

            // Outer glow with stroke circle
            g.strokeCircle(
                x: centerX, y: centerY,
                radius: width,
                width: 2.0,
                color: Color(r: 0.3, g: 0.9, b: 1.0, a: 0.4)
            )

            // Inner bullet with radial gradient
            let gradient = Gradient.radial(
                centerX: centerX, centerY: centerY,
                radius: width / 2,
                innerColor: Color(r: 0.8, g: 1.0, b: 1.0),
                outerColor: Color(r: 0.3, g: 0.9, b: 1.0)
            )
            g.fillRectGradient(
                x: x, y: y, width: width, height: height,
                gradient: gradient
            )
        }
    }

    var rect: (x: Float, y: Float, w: Float, h: Float) {
        return (x, y, width, height)
    }
}
