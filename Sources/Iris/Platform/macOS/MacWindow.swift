#if os(macOS)
import AppKit
import QuartzCore

@MainActor
class MacWindow: NSObject, NSWindowDelegate {
    private var window: NSWindow!
    private(set) var metalView: MetalView!
    var onClose: (() -> Void)?
    
    override init() {
        super.init()
    }
    
    func create(width: Int = 800, height: Int = 600, title: String = "Iris") {
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
    
    func show() {
        window.makeKeyAndOrderFront(nil)
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        onClose?()
        NSApplication.shared.terminate(nil)
        return true
    }
}
#endif

