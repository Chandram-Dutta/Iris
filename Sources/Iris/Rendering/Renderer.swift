#if os(macOS)
import Metal
import QuartzCore
import simd

@MainActor
class Renderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private weak var metalLayer: CAMetalLayer?
    
    private let colorPipelineState: MTLRenderPipelineState
    private let texturePipelineState: MTLRenderPipelineState
    private let textPipelineState: MTLRenderPipelineState
    private let samplerState: MTLSamplerState
    private let textSamplerState: MTLSamplerState
    
    private var textureCache: [UInt32: MTLTexture] = [:]
    private var glyphAtlasTextures: [UInt32: (texture: MTLTexture, version: UInt32)] = [:]
    
    private let defaultClearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    
    init?(metalLayer: CAMetalLayer) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("[Renderer] Metal is not supported on this device")
            return nil
        }
        
        guard let commandQueue = device.makeCommandQueue() else {
            print("[Renderer] Failed to create command queue")
            return nil
        }
        
        guard let colorPipeline = Renderer.createColorPipelineState(device: device, metalLayer: metalLayer) else {
            print("[Renderer] Failed to create color pipeline state")
            return nil
        }
        
        guard let texturePipeline = Renderer.createTexturePipelineState(device: device, metalLayer: metalLayer) else {
            print("[Renderer] Failed to create texture pipeline state")
            return nil
        }
        
        guard let textPipeline = Renderer.createTextPipelineState(device: device, metalLayer: metalLayer) else {
            print("[Renderer] Failed to create text pipeline state")
            return nil
        }
        
        guard let sampler = Renderer.createSamplerState(device: device) else {
            print("[Renderer] Failed to create sampler state")
            return nil
        }
        
        guard let textSampler = Renderer.createTextSamplerState(device: device) else {
            print("[Renderer] Failed to create text sampler state")
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        self.metalLayer = metalLayer
        self.colorPipelineState = colorPipeline
        self.texturePipelineState = texturePipeline
        self.textPipelineState = textPipeline
        self.samplerState = sampler
        self.textSamplerState = textSampler
        
        configureMetalLayer()
    }
    
    private func configureMetalLayer() {
        guard let metalLayer = metalLayer else { return }
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
    }
    
    private static func createSamplerState(device: MTLDevice) -> MTLSamplerState? {
        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .nearest
        descriptor.magFilter = .nearest
        descriptor.sAddressMode = .clampToEdge
        descriptor.tAddressMode = .clampToEdge
        return device.makeSamplerState(descriptor: descriptor)
    }
    
    private static func createTextSamplerState(device: MTLDevice) -> MTLSamplerState? {
        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .linear
        descriptor.magFilter = .linear
        descriptor.sAddressMode = .clampToEdge
        descriptor.tAddressMode = .clampToEdge
        return device.makeSamplerState(descriptor: descriptor)
    }
    
    private static func createColorPipelineState(device: MTLDevice, metalLayer: CAMetalLayer) -> MTLRenderPipelineState? {
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
        
        vertex VertexOut vertex_color(VertexIn in [[stage_in]]) {
            VertexOut out;
            out.position = float4(in.position, 0.0, 1.0);
            out.color = in.color;
            return out;
        }
        
        fragment float4 fragment_color(VertexOut in [[stage_in]]) {
            return in.color;
        }
        """
        
        guard let library = try? device.makeLibrary(source: shaderSource, options: nil) else {
            print("[Renderer] Failed to compile color shaders")
            return nil
        }
        
        let vertexFunction = library.makeFunction(name: "vertex_color")
        let fragmentFunction = library.makeFunction(name: "fragment_color")
        
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
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        return try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    private static func createTexturePipelineState(device: MTLDevice, metalLayer: CAMetalLayer) -> MTLRenderPipelineState? {
        let shaderSource = """
        #include <metal_stdlib>
        using namespace metal;
        
        struct TextureVertexIn {
            float2 position [[attribute(0)]];
            float2 texCoord [[attribute(1)]];
        };
        
        struct TextureVertexOut {
            float4 position [[position]];
            float2 texCoord;
        };
        
        vertex TextureVertexOut vertex_texture(TextureVertexIn in [[stage_in]]) {
            TextureVertexOut out;
            out.position = float4(in.position, 0.0, 1.0);
            out.texCoord = in.texCoord;
            return out;
        }
        
        fragment float4 fragment_texture(TextureVertexOut in [[stage_in]],
                                         texture2d<float> tex [[texture(0)]],
                                         sampler smp [[sampler(0)]]) {
            return tex.sample(smp, in.texCoord);
        }
        """
        
        guard let library = try? device.makeLibrary(source: shaderSource, options: nil) else {
            print("[Renderer] Failed to compile texture shaders")
            return nil
        }
        
        let vertexFunction = library.makeFunction(name: "vertex_texture")
        let fragmentFunction = library.makeFunction(name: "fragment_texture")
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = 8
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = 16
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        return try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    private static func createTextPipelineState(device: MTLDevice, metalLayer: CAMetalLayer) -> MTLRenderPipelineState? {
        let shaderSource = """
        #include <metal_stdlib>
        using namespace metal;
        
        struct TextVertexIn {
            float2 position [[attribute(0)]];
            float2 texCoord [[attribute(1)]];
            float4 color [[attribute(2)]];
        };
        
        struct TextVertexOut {
            float4 position [[position]];
            float2 texCoord;
            float4 color;
        };
        
        vertex TextVertexOut vertex_text(TextVertexIn in [[stage_in]]) {
            TextVertexOut out;
            out.position = float4(in.position, 0.0, 1.0);
            out.texCoord = in.texCoord;
            out.color = in.color;
            return out;
        }
        
        fragment float4 fragment_text(TextVertexOut in [[stage_in]],
                                      texture2d<float> tex [[texture(0)]],
                                      sampler smp [[sampler(0)]]) {
            float4 sampled = tex.sample(smp, in.texCoord);
            return float4(in.color.rgb, in.color.a * sampled.a);
        }
        """
        
        guard let library = try? device.makeLibrary(source: shaderSource, options: nil) else {
            print("[Renderer] Failed to compile text shaders")
            return nil
        }
        
        let vertexFunction = library.makeFunction(name: "vertex_text")
        let fragmentFunction = library.makeFunction(name: "fragment_text")
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = 8
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[2].format = .float4
        vertexDescriptor.attributes[2].offset = 16
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = 32
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
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
            case .drawImage(let image, let x, let y):
                drawImage(encoder: encoder, image: image, x: x, y: y, screenSize: screenSize)
            case .drawText(let text, let x, let y, let font, let color):
                drawText(encoder: encoder, text: text, x: x, y: y, font: font, color: color, screenSize: screenSize)
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
        
        encoder.setRenderPipelineState(colorPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    private func drawImage(encoder: MTLRenderCommandEncoder, image: Image, x: Float, y: Float, screenSize: CGSize) {
        guard let texture = getOrCreateTexture(for: image) else { return }
        
        let screenWidth = Float(screenSize.width)
        let screenHeight = Float(screenSize.height)
        let width = Float(texture.width)
        let height = Float(texture.height)
        
        let ndcX1 = (x / screenWidth) * 2.0 - 1.0
        let ndcY1 = 1.0 - (y / screenHeight) * 2.0
        let ndcX2 = ((x + width) / screenWidth) * 2.0 - 1.0
        let ndcY2 = 1.0 - ((y + height) / screenHeight) * 2.0
        
        let vertices: [Float] = [
            ndcX1, ndcY2,  0.0, 1.0,
            ndcX2, ndcY2,  1.0, 1.0,
            ndcX2, ndcY1,  1.0, 0.0,
            ndcX1, ndcY2,  0.0, 1.0,
            ndcX2, ndcY1,  1.0, 0.0,
            ndcX1, ndcY1,  0.0, 0.0,
        ]
        
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: []) else { return }
        
        encoder.setRenderPipelineState(texturePipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentSamplerState(samplerState, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    private func drawText(encoder: MTLRenderCommandEncoder, text: String, x: Float, y: Float, font: Font, color: Color, screenSize: CGSize) {
        let atlas = GlyphAtlasManager.shared.getAtlas(for: font)
        atlas.ensureGlyphs(for: text)
        
        guard let atlasTexture = getOrUpdateAtlasTexture(for: font, atlas: atlas) else { return }
        
        let screenWidth = Float(screenSize.width)
        let screenHeight = Float(screenSize.height)
        
        var vertices: [Float] = []
        var cursorX = x
        let cursorY = y + font.size
        
        let r = color.r, g = color.g, b = color.b, a = color.a
        
        for char in text {
            guard let metrics = atlas.getMetrics(for: char) else { continue }
            
            if metrics.width <= 0 || metrics.height <= 0 {
                cursorX += metrics.advance
                continue
            }
            
            let glyphX = cursorX + metrics.bearingX
            let glyphY = cursorY - metrics.bearingY
            let glyphW = metrics.width
            let glyphH = metrics.height
            
            let ndcX1 = (glyphX / screenWidth) * 2.0 - 1.0
            let ndcY1 = 1.0 - (glyphY / screenHeight) * 2.0
            let ndcX2 = ((glyphX + glyphW) / screenWidth) * 2.0 - 1.0
            let ndcY2 = 1.0 - ((glyphY + glyphH) / screenHeight) * 2.0
            
            let u0 = metrics.u0
            let v0 = metrics.v0
            let u1 = metrics.u1
            let v1 = metrics.v1
            
            vertices.append(contentsOf: [
                ndcX1, ndcY2,  u0, v1,  r, g, b, a,
                ndcX2, ndcY2,  u1, v1,  r, g, b, a,
                ndcX2, ndcY1,  u1, v0,  r, g, b, a,
                ndcX1, ndcY2,  u0, v1,  r, g, b, a,
                ndcX2, ndcY1,  u1, v0,  r, g, b, a,
                ndcX1, ndcY1,  u0, v0,  r, g, b, a,
            ])
            
            cursorX += metrics.advance
        }
        
        guard !vertices.isEmpty else { return }
        
        guard let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: []) else { return }
        
        encoder.setRenderPipelineState(textPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(atlasTexture, index: 0)
        encoder.setFragmentSamplerState(textSamplerState, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count / 8)
    }
    
    private func getOrCreateTexture(for image: Image) -> MTLTexture? {
        if let cached = textureCache[image.id] {
            return cached
        }
        
        guard let imageData = ImageCache.shared.getData(for: image) else {
            return nil
        }
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: imageData.width,
            height: imageData.height,
            mipmapped: false
        )
        descriptor.usage = .shaderRead
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            return nil
        }
        
        imageData.pixels.withUnsafeBytes { ptr in
            texture.replace(
                region: MTLRegion(
                    origin: MTLOrigin(x: 0, y: 0, z: 0),
                    size: MTLSize(width: imageData.width, height: imageData.height, depth: 1)
                ),
                mipmapLevel: 0,
                withBytes: ptr.baseAddress!,
                bytesPerRow: imageData.bytesPerRow
            )
        }
        
        textureCache[image.id] = texture
        return texture
    }
    
    private func getOrUpdateAtlasTexture(for font: Font, atlas: GlyphAtlas) -> MTLTexture? {
        if let cached = glyphAtlasTextures[font.id], cached.version == atlas.version {
            return cached.texture
        }
        
        let atlasData = atlas.getAtlasData()
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: atlasData.width,
            height: atlasData.height,
            mipmapped: false
        )
        descriptor.usage = .shaderRead
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            return nil
        }
        
        atlasData.pixels.withUnsafeBytes { ptr in
            texture.replace(
                region: MTLRegion(
                    origin: MTLOrigin(x: 0, y: 0, z: 0),
                    size: MTLSize(width: atlasData.width, height: atlasData.height, depth: 1)
                ),
                mipmapLevel: 0,
                withBytes: ptr.baseAddress!,
                bytesPerRow: atlasData.bytesPerRow
            )
        }
        
        glyphAtlasTextures[font.id] = (texture, atlas.version)
        return texture
    }
}
#endif
