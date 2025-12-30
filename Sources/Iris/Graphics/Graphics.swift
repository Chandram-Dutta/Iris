import Foundation

// MARK: - Coordinate System
// Origin: Top-left corner
// X: Increases to the right
// Y: Increases downward
// Units: Pixels

public struct Color: Sendable {
    public let r: Float
    public let g: Float
    public let b: Float
    public let a: Float
    
    public init(r: Float, g: Float, b: Float, a: Float = 1.0) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
    
    public static let white = Color(r: 1, g: 1, b: 1)
    public static let black = Color(r: 0, g: 0, b: 0)
    public static let red = Color(r: 1, g: 0, b: 0)
    public static let green = Color(r: 0, g: 1, b: 0)
    public static let blue = Color(r: 0, g: 0, b: 1)
}

public protocol Graphics {
    func clear(_ color: Color)
    func fillRect(x: Float, y: Float, width: Float, height: Float, color: Color)
}

