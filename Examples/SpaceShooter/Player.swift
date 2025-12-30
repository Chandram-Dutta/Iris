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

    // Shooting cooldown
    var shootCooldown: Double = 0
    let shootRate: Double = 0.2  // Fire every 0.2 seconds

    init(screenWidth: Float, screenHeight: Float) {
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.x = screenWidth / 2 - width / 2
        self.y = screenHeight - height - 40
        self.image = Image.load(GameResources.imagePath("spaceship.png"))
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
            // Fallback: draw a simple triangle-ish shape
            g.fillRect(
                x: x + width / 2 - 5, y: y, width: 10, height: height - 10,
                color: Color(r: 0.3, g: 0.6, b: 1.0))
            g.fillRect(
                x: x, y: y + height - 20, width: width, height: 20,
                color: Color(r: 0.3, g: 0.6, b: 1.0))
        }
    }

    var rect: (x: Float, y: Float, w: Float, h: Float) {
        return (x, y, width, height)
    }

    var centerX: Float { x + width / 2 }
    var centerY: Float { y }
}
