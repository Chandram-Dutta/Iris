#if os(macOS)
    import AppKit

    @MainActor
    class MacAppDelegate: NSObject, NSApplicationDelegate {
        weak var macApp: MacApp?

        func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return true
        }

        func applicationWillTerminate(_ notification: Notification) {
            macApp?.stop()
        }
    }

    @MainActor
    class MacApp {
        private let delegate = MacAppDelegate()
        let window: MacWindow
        private unowned let engine: Engine
        private let config: WindowConfig

        private var displayLink: CVDisplayLink?

        init(engine: Engine, config: WindowConfig) {
            self.engine = engine
            self.config = config
            window = MacWindow()
            window.onClose = { [weak self] in
                self?.stop()
            }
            delegate.macApp = self

            window.create(config: config)
        }

        func run() {
            let app = NSApplication.shared
            app.delegate = delegate
            app.setActivationPolicy(.regular)

            window.show()

            startDisplayLink()

            app.activate(ignoringOtherApps: true)
            app.run()
        }

        func stop() {
            stopDisplayLink()
            engine.stop()
        }

        private func startDisplayLink() {
            CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
            guard let displayLink = displayLink else { return }

            let callback: CVDisplayLinkOutputCallback = { _, _, _, _, _, userInfo in
                let app = Unmanaged<MacApp>.fromOpaque(userInfo!).takeUnretainedValue()
                DispatchQueue.main.sync {
                    app.engine.tick()
                }
                return kCVReturnSuccess
            }

            let userInfo = Unmanaged.passUnretained(self).toOpaque()
            CVDisplayLinkSetOutputCallback(displayLink, callback, userInfo)
            CVDisplayLinkStart(displayLink)
        }

        private func stopDisplayLink() {
            guard let displayLink = displayLink else { return }
            CVDisplayLinkStop(displayLink)
            self.displayLink = nil
        }
    }
#endif
