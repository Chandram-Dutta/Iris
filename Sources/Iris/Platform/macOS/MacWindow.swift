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

        func create(config: WindowConfig) {
            let rect = NSRect(x: 0, y: 0, width: config.width, height: config.height)
            var styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable]
            if config.resizable {
                styleMask.insert(.resizable)
            }
            window = NSWindow(
                contentRect: rect,
                styleMask: styleMask,
                backing: .buffered,
                defer: false
            )
            window.title = config.title
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
