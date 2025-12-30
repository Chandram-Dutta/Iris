import Foundation

/// Protocol that defines the structure of an Iris game.
/// Classes or structs conforming to this protocol can be run by the `Engine`.
public protocol Game {
    /// Called once per frame to update game logic.
    /// - Parameters:
    ///   - deltaTime: The time elapsed since the last frame in seconds.
    ///   - debug: Information about the current frame status.
    func update(deltaTime: TimeInterval, debug: DebugInfo)

    /// Called once per frame after update to draw the game.
    /// - Parameters:
    ///   - g: The graphics context used for drawing.
    ///   - debug: Information about the current frame status.
    func draw(_ g: Graphics, debug: DebugInfo)
}
