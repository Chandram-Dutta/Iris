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
            // Enhanced fallback with expanding stroke circles and gradients
            let alpha = Float(lifetime / 0.3)
            let centerX = x
            let centerY = y

            // Draw multiple expanding rings
            for i in 0..<3 {
                let ringScale = scale * (1.0 + Float(i) * 0.3)
                let ringAlpha = alpha * (1.0 - Float(i) * 0.3)
                let ringRadius = (width / 2) * ringScale

                g.strokeCircle(
                    x: centerX, y: centerY,
                    radius: ringRadius,
                    width: 3.0,
                    color: Color(r: 1.0, g: 0.6, b: 0.1, a: ringAlpha)
                )
            }

            // Inner core with radial gradient
            let coreSize = width * scale * 0.6
            let coreGradient = Gradient.radial(
                centerX: centerX, centerY: centerY,
                radius: coreSize / 2,
                innerColor: Color(r: 1.0, g: 1.0, b: 0.8, a: alpha),
                outerColor: Color(r: 1.0, g: 0.4, b: 0.0, a: alpha * 0.5)
            )
            g.fillRectGradient(
                x: centerX - coreSize / 2,
                y: centerY - coreSize / 2,
                width: coreSize,
                height: coreSize,
                gradient: coreGradient
            )
        }
    }
}
