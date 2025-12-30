import Foundation

/// Represents an RGBA color with components in range [0, 1].
public struct Color: Sendable {
    public let r: Float
    public let g: Float
    public let b: Float
    public let a: Float

    /// Creates a new color with specified RGBA components.
    /// - Parameters:
    ///   - r: Red component (0.0 - 1.0)
    ///   - g: Green component (0.0 - 1.0)
    ///   - b: Blue component (0.0 - 1.0)
    ///   - a: Alpha component (0.0 - 1.0, default is 1.0)
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

/// The primary interface for drawing 2D primitives, images, and text.
/// Coordination system: Top-left origin (0,0), X right, Y down. Units are in pixels.
public protocol Graphics {
    /// Clears the screen with a specific color.
    func clear(_ color: Color)

    /// Draws a solid rectangle.
    func fillRect(x: Float, y: Float, width: Float, height: Float, color: Color)

    /// Draws an image at the specified position.
    func drawImage(_ image: Image, x: Float, y: Float)

    /// Draws a string of text.
    func drawText(_ text: String, x: Float, y: Float, font: Font, color: Color)
}
