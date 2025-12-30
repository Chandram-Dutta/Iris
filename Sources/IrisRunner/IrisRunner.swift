import Foundation
import Iris

class TestGame: Game {
    var spriteX: Float = 300
    var spriteY: Float = 200
    let speed: Float = 200
    
    var sprite: Image?
    let debugFont: Font
    let titleFont: Font
    
    init() {
        sprite = Image.load("player.png")
        if sprite == nil {
            print("[TestGame] Could not load player.png - will use fallback rectangle")
        }
        
        debugFont = Font.system(size: 14)
        titleFont = Font.system(size: 24)
    }
    
    func update(deltaTime: TimeInterval, debug: DebugInfo) {
        let dt = Float(deltaTime)
        
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
        
        g.fillRect(x: 50, y: 50, width: 700, height: 500, color: Color(r: 0.15, g: 0.15, b: 0.2))
        
        if let sprite = sprite {
            g.drawImage(sprite, x: spriteX, y: spriteY)
        } else {
            g.fillRect(x: spriteX, y: spriteY, width: 32, height: 32, color: .red)
        }
        
        g.drawText("Iris Engine", x: 60, y: 60, font: titleFont, color: .white)
        g.drawText("Use WASD or Arrow Keys to move", x: 60, y: 90, font: debugFont, color: Color(r: 0.7, g: 0.7, b: 0.7))
        
        g.drawText("FPS: \(debug.fps)", x: 650, y: 60, font: debugFont, color: .green)
        g.drawText("Frame: \(debug.frameNumber)", x: 620, y: 80, font: debugFont, color: Color(r: 0.5, g: 0.5, b: 0.5))
        
        g.drawText("Position: (\(Int(spriteX)), \(Int(spriteY)))", x: 60, y: 530, font: debugFont, color: Color(r: 0.6, g: 0.6, b: 0.8))
    }
}

@MainActor
func main() {
    let engine = Engine()
    engine.run(game: TestGame())
}

main()
