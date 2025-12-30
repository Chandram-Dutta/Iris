import Foundation

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

public final class Input: @unchecked Sendable {
    public static let shared = Input()
    
    private var keysDown: Set<UInt16> = []
    private let lock = NSLock()
    
    private init() {}
    
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

