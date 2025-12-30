#if os(macOS)
import AppKit
import QuartzCore

@MainActor
public class MetalView: NSView {
    public var metalLayer: CAMetalLayer {
        return layer as! CAMetalLayer
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    private func setupLayer() {
        wantsLayer = true
        layer = CAMetalLayer()
    }
    
    public override func setBoundsSize(_ newSize: NSSize) {
        super.setBoundsSize(newSize)
        updateDrawableSize()
    }
    
    public override func setFrameSize(_ newSize: NSSize) {
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
    
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateDrawableSize()
    }
}
#endif

