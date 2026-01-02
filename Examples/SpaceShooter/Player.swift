import Iris

class Player {
    var x: Float
    var y: Float
    let width: Float = 64
    let height: Float = 64
    let speed: Float = 400

    let screenWidth: Float
    let screenHeight: Float

    var image: Image?

    /// Hitbox generated from image transparency (convex hull)
    var hitbox: Hitbox

    // Shooting cooldown
    var shootCooldown: Double = 0
    let shootRate: Double = 0.2  // Fire every 0.2 seconds

    init(screenWidth: Float, screenHeight: Float) {
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.x = screenWidth / 2 - width / 2
        self.y = screenHeight - height - 40
        self.image = Image.load(GameResources.imagePath("spaceship.png"))

        // Generate hitbox from image transparency or use fallback AABB
        if let img = image, let generatedHitbox = img.generateHitbox() {
            self.hitbox = generatedHitbox
        } else {
            // Fallback to AABB slightly smaller than visual bounds
            self.hitbox = Hitbox(x: 0, y: 0, shape: .aabb(width: width * 0.7, height: height * 0.8))
        }

        updateHitboxPosition()
    }

    func update(deltaTime: Double) {
        // Movement
        if Input.shared.isKeyDown(.left) || Input.shared.isKeyDown(.a) {
            x -= speed * Float(deltaTime)
        }
        if Input.shared.isKeyDown(.right) || Input.shared.isKeyDown(.d) {
            x += speed * Float(deltaTime)
        }
        if Input.shared.isKeyDown(.up) || Input.shared.isKeyDown(.w) {
            y -= speed * Float(deltaTime)
        }
        if Input.shared.isKeyDown(.down) || Input.shared.isKeyDown(.s) {
            y += speed * Float(deltaTime)
        }

        // Keep player in bounds
        x = max(0, min(screenWidth - width, x))
        y = max(100, min(screenHeight - height, y))

        // Update cooldown
        if shootCooldown > 0 {
            shootCooldown -= deltaTime
        }

        updateHitboxPosition()
    }

    private func updateHitboxPosition() {
        hitbox.position = SIMD2<Float>(x, y)
    }

    func canShoot() -> Bool {
        return shootCooldown <= 0
    }

    func shoot() {
        shootCooldown = shootRate
    }

    func draw(_ g: Graphics) {
        if let img = image {
            g.drawImage(img, x: x, y: y)
        } else {
            // Enhanced fallback: draw a gradient spaceship
            // Main body with gradient
            let bodyGradient = Gradient.linear(
                startX: x, startY: y,
                endX: x, endY: y + height,
                startColor: Color(r: 0.5, g: 0.8, b: 1.0),
                endColor: Color(r: 0.2, g: 0.4, b: 0.8)
            )
            g.fillRectGradient(
                x: x + width / 2 - 5, y: y, width: 10, height: height - 10,
                gradient: bodyGradient
            )

            // Base wings
            let wingsGradient = Gradient.linear(
                startX: x, startY: y + height - 20,
                endX: x, endY: y + height,
                startColor: Color(r: 0.4, g: 0.7, b: 0.9),
                endColor: Color(r: 0.2, g: 0.5, b: 0.7)
            )
            g.fillRectGradient(
                x: x, y: y + height - 20, width: width, height: 20,
                gradient: wingsGradient
            )

            // Add stroke outlines
            g.strokeRect(
                x: x + width / 2 - 5, y: y, width: 10, height: height - 10,
                strokeWidth: 1.5,
                color: Color(r: 0.7, g: 0.9, b: 1.0, a: 0.8)
            )
        }
    }

    var rect: (x: Float, y: Float, w: Float, h: Float) {
        return (x, y, width, height)
    }

    var centerX: Float { x + width / 2 }
    var centerY: Float { y }
}
