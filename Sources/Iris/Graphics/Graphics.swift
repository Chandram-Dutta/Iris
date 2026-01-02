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

/// Represents a color gradient for advanced rendering.
public enum Gradient: Sendable {
    /// Linear gradient from one point to another with two colors.
    case linear(
        startX: Float, startY: Float, endX: Float, endY: Float, startColor: Color, endColor: Color)
    /// Radial gradient from center point with inner and outer colors.
    case radial(centerX: Float, centerY: Float, radius: Float, innerColor: Color, outerColor: Color)
}

/// Blend modes determine how new content is drawn over existing content.
public enum BlendMode: Sendable {
    /// Standard alpha blending (default).
    case normal
    /// Additive blending (good for glowing effects).
    case additive
    /// Multiply blending (good for shadows).
    case multiply
}

/// The primary interface for drawing 2D primitives, images, and text.
/// Coordination system: Top-left origin (0,0), X right, Y down. Units are in pixels.
public protocol Graphics {
    /// Clears the screen with a specific color.
    func clear(_ color: Color)

    /// Draws a solid rectangle.
    func fillRect(x: Float, y: Float, width: Float, height: Float, color: Color)

    /// Draws a solid circle.
    func fillCircle(x: Float, y: Float, radius: Float, color: Color)

    /// Draws a line between two points.
    func drawLine(x1: Float, y1: Float, x2: Float, y2: Float, width: Float, color: Color)

    /// Draws a filled polygon.
    func fillPolygon(points: [SIMD2<Float>], color: Color)

    /// Draws a circle outline.
    func strokeCircle(x: Float, y: Float, radius: Float, width: Float, color: Color)

    /// Draws a rectangle outline.
    func strokeRect(
        x: Float, y: Float, width: Float, height: Float, strokeWidth: Float, color: Color)

    /// Draws a polygon outline.
    func strokePolygon(points: [SIMD2<Float>], width: Float, color: Color)

    /// Fills a rectangle with a gradient.
    func fillRectGradient(x: Float, y: Float, width: Float, height: Float, gradient: Gradient)

    /// Draws an image at the specified position.
    func drawImage(_ image: Image, x: Float, y: Float)

    /// Draws a string of text.
    func drawText(_ text: String, x: Float, y: Float, font: Font, color: Color)

    /// Rotates the current coordinate system.
    /// - Parameter angle: Rotation angle in radians.
    func rotate(angle: Float)

    /// Scales the current coordinate system.
    func scale(x: Float, y: Float)

    /// Translates the current coordinate system.
    func translate(x: Float, y: Float)

    /// Saves the current graphics state (transform, blend mode).
    func save()

    /// Restores the last saved graphics state.
    func restore()

    /// Sets the current blend mode.
    func setBlendMode(_ mode: BlendMode)
}
