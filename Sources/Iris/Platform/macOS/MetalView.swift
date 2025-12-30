#if os(macOS)
    import AppKit
    import QuartzCore

    @MainActor
    class MetalView: NSView {
        var metalLayer: CAMetalLayer {
            return layer as! CAMetalLayer
        }

        override var acceptsFirstResponder: Bool { true }

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            setupLayer()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupLayer()
        }

        private func setupLayer() {
            wantsLayer = true
            layer = CAMetalLayer()
        }

        override func setBoundsSize(_ newSize: NSSize) {
            super.setBoundsSize(newSize)
            updateDrawableSize()
        }

        override func setFrameSize(_ newSize: NSSize) {
            super.setFrameSize(newSize)
            updateDrawableSize()
        }

        private func updateDrawableSize() {
            guard let window = window else { return }
            let scale = window.backingScaleFactor
            metalLayer.contentsScale = scale
            metalLayer.drawableSize = CGSize(
                width: bounds.width * scale,
                height: bounds.height * scale
            )
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            updateDrawableSize()
            window?.makeFirstResponder(self)
        }

        override func keyDown(with event: NSEvent) {
            Input.shared.keyDown(event.keyCode)
        }

        override func keyUp(with event: NSEvent) {
            Input.shared.keyUp(event.keyCode)
        }
    }
#endif
