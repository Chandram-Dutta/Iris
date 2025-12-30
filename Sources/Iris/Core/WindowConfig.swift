#if os(macOS)
    import Foundation
#endif

/// Configuration for the game window.
public struct WindowConfig: Sendable {
    /// Window width in pixels.
    public let width: Int

    /// Window height in pixels.
    public let height: Int

    /// Window title displayed in the title bar.
    public let title: String

    /// Whether the window can be resized by the user.
    public let resizable: Bool

    /// Creates a new window configuration.
    /// - Parameters:
    ///   - width: Window width in pixels. Default is 800.
    ///   - height: Window height in pixels. Default is 600.
    ///   - title: Window title. Default is "Iris".
    ///   - resizable: Whether the window can be resized. Default is false.
    public init(
        width: Int = 800,
        height: Int = 600,
        title: String = "Iris",
        resizable: Bool = false
    ) {
        self.width = width
        self.height = height
        self.title = title
        self.resizable = resizable
    }

    /// Default window configuration (800x600, titled "Iris", non-resizable).
    public static let `default` = WindowConfig()
}
