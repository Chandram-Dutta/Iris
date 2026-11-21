struct PauseToggle {
    private(set) var isPaused = false
    private var wasKeyDown = false

    @discardableResult
    mutating func update(isKeyDown: Bool) -> Bool {
        defer { wasKeyDown = isKeyDown }
        if isKeyDown && !wasKeyDown {
            isPaused.toggle()
            return true
        }
        return false
    }
}
