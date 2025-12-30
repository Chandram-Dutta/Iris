#if os(macOS)
import Metal
import QuartzCore
import simd

@MainActor
public class Renderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private weak var metalLayer: CAMetalLayer?
    
    private let pipelineState: MTLRenderPipelineState
    
    private let defaultClearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    
    public init?(metalLayer: CAMetalLayer) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("[Renderer] Metal is not supported on this device")
            return nil
        }
        
        guard let commandQueue = device.makeCommandQueue() else {
            print("[Renderer] Failed to create command queue")
            return nil
        }
        
        guard let pipelineState = Renderer.createPipelineState(device: device, metalLayer: metalLayer) else {
            print("[Renderer] Failed to create pipeline state")
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        self.metalLayer = metalLayer
        self.pipelineState = pipelineState
        
        configureMetalLayer()
    }
    
    private func configureMetalLayer() {
        guard let metalLayer = metalLayer else { return }
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
    }
    
    private static func createPipelineState(device: MTLDevice, metalLayer: CAMetalLayer) -> MTLRenderPipelineState? {
        let shaderSource = """
        #include <metal_stdlib>
        using namespace metal;
        
        struct VertexIn {
            float2 position [[attribute(0)]];
            float4 color [[attribute(1)]];
        };
        
        struct VertexOut {
            float4 position [[position]];
            float4 color;
        };
        
        vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
            VertexOut out;
            out.position = float4(in.position, 0.0, 1.0);
            out.color = in.color;
            return out;
        }
        
        fragment float4 fragment_main(VertexOut in [[stage_in]]) {
            return in.color;
        }
        """
        
        guard let library = try? device.makeLibrary(source: shaderSource, options: nil) else {
            print("[Renderer] Failed to compile shaders")
            return nil
        }
        
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = 8
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = 24
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
        
        return try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func render(commands: [DrawCommand]) {
        guard let metalLayer = metalLayer,
              let drawable = metalLayer.nextDrawable(),
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        let clearColor = findClearColor(in: commands)
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        let scale = metalLayer.contentsScale
        let screenSize = CGSize(
            width: metalLayer.drawableSize.width / scale,
            height: metalLayer.drawableSize.height / scale
        )
        
        for command in commands {
            switch command {
            case .clear:
                break
            case .fillRect(let x, let y, let width, let height, let color):
                drawRect(encoder: encoder, x: x, y: y, width: width, height: height, color: color, screenSize: screenSize)
            }
        }
        
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func findClearColor(in commands: [DrawCommand]) -> MTLClearColor {
        for command in commands {
            if case .clear(let color) = command {
                return MTLClearColor(red: Double(color.r), green: Double(color.g), blue: Double(color.b), alpha: Double(color.a))
            }
        }
        return defaultClearColor
    }
    
    private func drawRect(encoder: MTLRenderCommandEncoder, x: Float, y: Float, width: Float, height: Float, color: Color, screenSize: CGSize) {
        let screenWidth = Float(screenSize.width)
        let screenHeight = Float(screenSize.height)
        
        // Convert pixel coordinates (origin top-left, Y down) to NDC (origin center, Y up)
        let ndcX1 = (x / screenWidth) * 2.0 - 1.0
        let ndcY1 = 1.0 - (y / screenHeight) * 2.0
        let ndcX2 = ((x + width) / screenWidth) * 2.0 - 1.0
        let ndcY2 = 1.0 - ((y + height) / screenHeight) * 2.0
        
        let r = color.r, g = color.g, b = color.b, a = color.a
        
        let vertices: [Float] = [
            ndcX1, ndcY2,  r, g, b, a,
            ndcX2, ndcY2,  r, g, b, a,
            ndcX2, ndcY1,  r, g, b, a,
            ndcX1, ndcY2,  r, g, b, a,
            ndcX2, ndcY1,  r, g, b, a,
            ndcX1, ndcY1,  r, g, b, a,
        ]
        
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: []) else { return }
        
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}
#endif
