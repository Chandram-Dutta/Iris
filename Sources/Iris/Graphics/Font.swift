import Foundation

public struct Font: Equatable, Hashable, Sendable {
    let id: UInt32
    let size: Float
    
    init(id: UInt32, size: Float) {
        self.id = id
        self.size = size
    }
    
    public static func system(size: Float) -> Font {
        return FontCache.shared.getSystemFont(size: size)
    }
}

final class FontCache: @unchecked Sendable {
    static let shared = FontCache()
    
    private var fonts: [FontKey: Font] = [:]
    private var nextId: UInt32 = 1
    private let lock = NSLock()
    
    private init() {}
    
    func getSystemFont(size: Float) -> Font {
        lock.lock()
        defer { lock.unlock() }
        
        let key = FontKey(name: "system", size: size)
        
        if let existing = fonts[key] {
            return existing
        }
        
        let font = Font(id: nextId, size: size)
        nextId += 1
        fonts[key] = font
        
        return font
    }
}

private struct FontKey: Hashable {
    let name: String
    let size: Float
}

