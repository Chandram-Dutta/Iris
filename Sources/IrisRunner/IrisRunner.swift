import Foundation
import Iris

class TestGame: Game {
    func update(deltaTime: TimeInterval) {}
    func draw() {}
}

@MainActor
func main() {
    let engine = Engine()
    engine.run(game: TestGame())
}

main()

