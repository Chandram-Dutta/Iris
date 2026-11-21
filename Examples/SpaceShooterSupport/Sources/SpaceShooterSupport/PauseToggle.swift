public struct PauseToggle {
    public private(set) var isPaused = false
    private var wasKeyDown = false

    public init() {}

    @discardableResult
    public mutating func update(isKeyDown: Bool) -> Bool {
        defer { wasKeyDown = isKeyDown }
        if isKeyDown && !wasKeyDown {
            isPaused.toggle()
            return true
        }
        return false
    }
}
