import Foundation
import Iris

class TestGame: Game {
    var spriteX: Float = 300
    var spriteY: Float = 200
    let speed: Float = 200
    var rotation: Float = 0
    var pulse: Float = 0

    var sprite: Image?
    let debugFont: Font
    let titleFont: Font

    init() {
        sprite = Image.load("Assets/player.png")
        debugFont = Font.system(size: 14)
        titleFont = Font.system(size: 24)
    }

    func update(deltaTime: TimeInterval, debug: DebugInfo) {
        let dt = Float(deltaTime)
        rotation += dt
        pulse += dt * 2

        if Input.shared.isKeyDown(.left) || Input.shared.isKeyDown(.a) {
            spriteX -= speed * dt
        }
        if Input.shared.isKeyDown(.right) || Input.shared.isKeyDown(.d) {
            spriteX += speed * dt
        }
        if Input.shared.isKeyDown(.up) || Input.shared.isKeyDown(.w) {
            spriteY -= speed * dt
        }
        if Input.shared.isKeyDown(.down) || Input.shared.isKeyDown(.s) {
            spriteY += speed * dt
        }

        spriteX = max(0, min(spriteX, 750))
        spriteY = max(0, min(spriteY, 550))
    }

    func draw(_ g: Graphics, debug: DebugInfo) {
        g.clear(Color(r: 0.1, g: 0.1, b: 0.15))

        // 1. Filled Circles
        g.drawText("Fill", x: 50, y: 100, font: debugFont, color: .white)
        for i in 0..<3 {
            let size = 15.0 + Float(i) * 5.0
            g.fillCircle(
                x: 60 + Float(i) * 50,
                y: 130,
                radius: size,
                color: Color(r: Float(i) / 3.0, g: 0.5, b: 0.8)
            )
        }

        // 2. Stroke Circles
        g.drawText("Stroke", x: 250, y: 100, font: debugFont, color: .white)
        for i in 0..<3 {
            let size = 15.0 + Float(i) * 5.0
            g.strokeCircle(
                x: 260 + Float(i) * 50,
                y: 130,
                radius: size,
                width: 3,
                color: Color(r: 1.0, g: Float(i) / 3.0, b: 0.5)
            )
        }

        // 3. Transformed Shapes (Rotating Square)
        g.save()
        g.translate(x: 600, y: 150)
        g.rotate(angle: rotation)

        g.strokeRect(
            x: -40, y: -40, width: 80, height: 80, strokeWidth: 3, color: Color(r: 1, g: 0.5, b: 0))
        g.drawLine(x1: -50, y1: 0, x2: 50, y2: 0, width: 2, color: .white)
        g.drawLine(x1: 0, y1: -50, x2: 0, y2: 50, width: 2, color: .white)

        g.restore()
        g.drawText("Transforms", x: 550, y: 100, font: debugFont, color: .white)

        // 4. Gradients
        g.drawText("Gradients", x: 50, y: 220, font: debugFont, color: .white)
        g.fillRectGradient(
            x: 50, y: 250, width: 150, height: 100,
            gradient: .linear(
                startX: 50, startY: 250, endX: 200, endY: 250,
                startColor: Color(r: 1, g: 0, b: 0),
                endColor: Color(r: 0, g: 0, b: 1)
            )
        )

        g.fillRectGradient(
            x: 220, y: 250, width: 100, height: 100,
            gradient: .radial(
                centerX: 270, centerY: 300, radius: 50,
                innerColor: Color(r: 1, g: 1, b: 0),
                outerColor: Color(r: 1, g: 0, b: 1)
            )
        )

        // 5. Complex Polygon (Concave - Star shape)
        g.drawText("Complex Polygon", x: 370, y: 220, font: debugFont, color: .white)
        let starX: Float = 450
        let starY: Float = 300
        let outerRadius: Float = 40
        let innerRadius: Float = 18
        var starPoints: [SIMD2<Float>] = []
        for i in 0..<10 {
            let angle = Float(i) * Float.pi / 5.0 - Float.pi / 2
            let radius = (i % 2 == 0) ? outerRadius : innerRadius
            starPoints.append(
                SIMD2(
                    starX + cos(angle) * radius,
                    starY + sin(angle) * radius
                ))
        }
        g.fillPolygon(points: starPoints, color: Color(r: 1, g: 0.8, b: 0))

        // Stroke version of the star
        g.strokePolygon(points: starPoints, width: 2, color: Color(r: 0.5, g: 0.3, b: 0))

        // 6. Blend Modes
        let blendX: Float = 600
        let blendY: Float = 450

        g.setBlendMode(.additive)
        let glowSize = 35.0 + sin(pulse) * 8

        // RGB Additive Circles
        g.fillCircle(
            x: blendX, y: blendY - 15, radius: glowSize, color: Color(r: 1, g: 0, b: 0, a: 0.6))
        g.fillCircle(
            x: blendX - 20, y: blendY + 15, radius: glowSize, color: Color(r: 0, g: 1, b: 0, a: 0.6)
        )
        g.fillCircle(
            x: blendX + 20, y: blendY + 15, radius: glowSize, color: Color(r: 0, g: 0, b: 1, a: 0.6)
        )

        g.setBlendMode(.normal)
        g.drawText("Additive", x: 560, y: 380, font: debugFont, color: .white)

        // Player / Sprite
        if let sprite = sprite {
            g.drawImage(sprite, x: spriteX, y: spriteY)
        }

        // HUD
        g.drawText(
            "Iris - Strokes, Gradients & Complex Polygons", x: 50, y: 40, font: titleFont,
            color: .white)
        g.drawText("FPS: \(debug.fps)", x: 650, y: 40, font: debugFont, color: .green)
    }
}

@MainActor
func main() {
    let engine = Engine()
    engine.run(game: TestGame())
}

main()
