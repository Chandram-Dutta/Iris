import Foundation

public class Engine {
    public private(set) var isRunning = false
    private var lastTime: UInt64 = 0
    private let maxDeltaTime: Double = 0.1
    
    private var debugAccumulator: Double = 0
    private var frameCount: Int = 0
    
    private var game: Game?
    private let graphics = GraphicsContext()
    
    #if os(macOS)
    public private(set) var app: MacApp?
    private var renderer: Renderer?
    #endif
    
    public init() {}
    
    @MainActor
    public func run(game: Game) {
        #if os(macOS)
        app = MacApp(engine: self)
        start(game: game)
        
        if let metalLayer = app?.window.metalView.metalLayer {
            renderer = Renderer(metalLayer: metalLayer)
        }
        
        app?.run()
        #endif
    }
    
    func start(game: Game) {
        self.game = game
        isRunning = true
        lastTime = DispatchTime.now().uptimeNanoseconds
    }
    
    @MainActor
    public func tick() {
        guard isRunning, let game = game else { return }
        
        let currentTime = DispatchTime.now().uptimeNanoseconds
        var deltaTime = Double(currentTime - lastTime) / 1_000_000_000.0
        lastTime = currentTime
        
        deltaTime = min(deltaTime, maxDeltaTime)
        
        game.update(deltaTime: deltaTime)
        
        graphics.reset()
        game.draw(graphics)
        
        #if os(macOS)
        renderer?.render(commands: graphics.commands)
        #endif
        
        logDebugInfo(deltaTime: deltaTime)
    }
    
    public func stop() {
        isRunning = false
        game = nil
    }
    
    private func logDebugInfo(deltaTime: Double) {
        debugAccumulator += deltaTime
        frameCount += 1
        
        if debugAccumulator >= 1.0 {
            let avgDelta = debugAccumulator / Double(frameCount)
            let fps = 1.0 / avgDelta
            print("[Engine] FPS: \(Int(fps)) | Avg delta: \(String(format: "%.4f", avgDelta))s")
            debugAccumulator = 0
            frameCount = 0
        }
    }
}
