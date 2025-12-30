import Foundation

public struct DebugInfo {
    public let fps: Int
    public let deltaTime: Double
    public let frameNumber: UInt64
}

public class Engine {
    public private(set) var isRunning = false
    public private(set) var debugInfo = DebugInfo(fps: 0, deltaTime: 0, frameNumber: 0)

    private var lastTime: UInt64 = 0
    private let maxDeltaTime: Double = 0.1

    private var debugAccumulator: Double = 0
    private var frameCountForFPS: Int = 0
    private var totalFrameCount: UInt64 = 0
    private var currentFPS: Int = 0

    private var game: Game?
    private let graphics = GraphicsContext()

    #if os(macOS)
        private var app: MacApp?
        private var renderer: Renderer?
    #endif

    public init() {}

    @MainActor
    public func run(game: Game, config: WindowConfig = .default) {
        #if os(macOS)
            app = MacApp(engine: self, config: config)
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
    func tick() {
        guard isRunning, let game = game else { return }

        let currentTime = DispatchTime.now().uptimeNanoseconds
        var deltaTime = Double(currentTime - lastTime) / 1_000_000_000.0
        lastTime = currentTime

        deltaTime = min(deltaTime, maxDeltaTime)

        totalFrameCount += 1
        updateDebugInfo(deltaTime: deltaTime)

        game.update(deltaTime: deltaTime, debug: debugInfo)

        graphics.reset()
        game.draw(graphics, debug: debugInfo)

        #if os(macOS)
            renderer?.render(commands: graphics.commands)
        #endif
    }

    public func stop() {
        isRunning = false
        game = nil
    }

    private func updateDebugInfo(deltaTime: Double) {
        debugAccumulator += deltaTime
        frameCountForFPS += 1

        if debugAccumulator >= 1.0 {
            let avgDelta = debugAccumulator / Double(frameCountForFPS)
            currentFPS = Int(1.0 / avgDelta)
            debugAccumulator = 0
            frameCountForFPS = 0
        }

        debugInfo = DebugInfo(fps: currentFPS, deltaTime: deltaTime, frameNumber: totalFrameCount)
    }
}
