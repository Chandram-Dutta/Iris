import Foundation
import Iris

class TestGame: Game {
    var rectX: Float = 100
    var rectY: Float = 100
    var velocityX: Float = 200
    var velocityY: Float = 150
    
    func update(deltaTime: TimeInterval) {
        rectX += velocityX * Float(deltaTime)
        rectY += velocityY * Float(deltaTime)
        
        if rectX < 0 || rectX > 700 { velocityX = -velocityX }
        if rectY < 0 || rectY > 500 { velocityY = -velocityY }
    }
    
    func draw(_ g: Graphics) {
        g.clear(Color(r: 0.1, g: 0.1, b: 0.15))
        g.fillRect(x: rectX, y: rectY, width: 100, height: 100, color: .red)
        g.fillRect(x: 50, y: 50, width: 60, height: 60, color: .green)
        g.fillRect(x: 300, y: 200, width: 80, height: 40, color: .blue)
    }
}

@MainActor
func main() {
    let engine = Engine()
    engine.run(game: TestGame())
}

main()
