#if os(macOS)
import AppKit
import QuartzCore

@MainActor
public class MacWindow: NSObject, NSWindowDelegate {
    private var window: NSWindow!
    public private(set) var metalView: MetalView!
    public var onClose: (() -> Void)?
    
    public override init() {
        super.init()
    }
    
    public func create(width: Int = 800, height: Int = 600, title: String = "Iris") {
        let rect = NSRect(x: 0, y: 0, width: width, height: height)
        window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.delegate = self
        window.center()
        
        metalView = MetalView(frame: rect)
        window.contentView = metalView
    }
    
    public func show() {
        window.makeKeyAndOrderFront(nil)
    }
    
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        onClose?()
        NSApplication.shared.terminate(nil)
        return true
    }
}
#endif

