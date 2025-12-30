import Foundation

public protocol Game {
    func update(deltaTime: TimeInterval)
    func draw(_ g: Graphics)
}
