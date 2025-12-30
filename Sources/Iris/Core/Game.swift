import Foundation

public protocol Game {
    func update(deltaTime: TimeInterval, debug: DebugInfo)
    func draw(_ g: Graphics, debug: DebugInfo)
}
