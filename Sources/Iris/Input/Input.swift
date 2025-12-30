import Foundation

/// Enumeration of supported keyboard keys.
public enum Key: UInt16, Sendable {
    case left = 123
    case right = 124
    case down = 125
    case up = 126
    case space = 49
    case escape = 53
    case w = 13
    case a = 0
    case s = 1
    case d = 2
}

/// Manages keyboard input state.
public final class Input: @unchecked Sendable {
    /// The shared input manager instance.
    public static let shared = Input()

    private var keysDown: Set<UInt16> = []
    private let lock = NSLock()

    private init() {}

    /// Checks if a specific key is currently held down.
    /// - Parameter key: The key to check.
    /// - Returns: `true` if the key is down, `false` otherwise.
    public func isKeyDown(_ key: Key) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return keysDown.contains(key.rawValue)
    }

    func keyDown(_ keyCode: UInt16) {
        lock.lock()
        defer { lock.unlock() }
        keysDown.insert(keyCode)
    }

    func keyUp(_ keyCode: UInt16) {
        lock.lock()
        defer { lock.unlock() }
        keysDown.remove(keyCode)
    }
}
