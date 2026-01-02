#if os(macOS)
    import Metal
    import QuartzCore

    @MainActor
    class Renderer {
        private let device: MTLDevice
        private let commandQueue: MTLCommandQueue
        private weak var metalLayer: CAMetalLayer?

        // Pipeline State Obects Cache
        private var pipelineStates: [PipelineKey: MTLRenderPipelineState] = [:]

        private let samplerState: MTLSamplerState
        private let textSamplerState: MTLSamplerState

        private var textureCache: [UInt32: MTLTexture] = [:]
        private var glyphAtlasTextures: [UInt32: (texture: MTLTexture, version: UInt32)] = [:]

        private let defaultClearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)

        private var currentBlendMode: BlendMode = .normal

        private struct PipelineKey: Hashable {
            enum Kind { case color, texture, text, circle, strokeCircle, gradient }
            let kind: Kind
            let blendMode: BlendMode
        }

        init?(metalLayer: CAMetalLayer) {
            guard let device = MTLCreateSystemDefaultDevice() else {
                print("[Renderer] Metal is not supported on this device")
                return nil
            }

            guard let commandQueue = device.makeCommandQueue() else {
                print("[Renderer] Failed to create command queue")
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
            self.samplerState = sampler
            self.textSamplerState = textSampler

            configureMetalLayer()
            if !compileShaders() {
                return nil
            }
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

        private func compileShaders() -> Bool {
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

                struct TextureVertexIn {
                    float2 position [[attribute(0)]];
                    float2 texCoord [[attribute(1)]];
                };

                struct TextureVertexOut {
                    float4 position [[position]];
                    float2 texCoord;
                };

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

                struct CircleVertexIn {
                    float2 position [[attribute(0)]];
                    float2 uv [[attribute(1)]];
                    float4 color [[attribute(2)]];
                };

                struct CircleVertexOut {
                    float4 position [[position]];
                    float2 uv;
                    float4 color;
                };

                // --- Vertex Shaders ---

                vertex VertexOut vertex_color(VertexIn in [[stage_in]], constant float4x4 &matrix [[buffer(1)]]) {
                    VertexOut out;
                    out.position = matrix * float4(in.position, 0.0, 1.0);
                    out.color = in.color;
                    return out;
                }

                vertex TextureVertexOut vertex_texture(TextureVertexIn in [[stage_in]], constant float4x4 &matrix [[buffer(1)]]) {
                    TextureVertexOut out;
                    out.position = matrix * float4(in.position, 0.0, 1.0);
                    out.texCoord = in.texCoord;
                    return out;
                }

                vertex TextVertexOut vertex_text(TextVertexIn in [[stage_in]], constant float4x4 &matrix [[buffer(1)]]) {
                    TextVertexOut out;
                    out.position = matrix * float4(in.position, 0.0, 1.0);
                    out.texCoord = in.texCoord;
                    out.color = in.color;
                    return out;
                }

                vertex CircleVertexOut vertex_circle(CircleVertexIn in [[stage_in]], constant float4x4 &matrix [[buffer(1)]]) {
                    CircleVertexOut out;
                    out.position = matrix * float4(in.position, 0.0, 1.0);
                    out.uv = in.uv;
                    out.color = in.color;
                    return out;
                }

                // --- Fragment Shaders ---

                fragment float4 fragment_color(VertexOut in [[stage_in]]) {
                    return in.color;
                }

                fragment float4 fragment_texture(TextureVertexOut in [[stage_in]],
                                                 texture2d<float> tex [[texture(0)]],
                                                 sampler smp [[sampler(0)]]) {
                    return tex.sample(smp, in.texCoord);
                }

                fragment float4 fragment_text(TextVertexOut in [[stage_in]],
                                              texture2d<float> tex [[texture(0)]],
                                              sampler smp [[sampler(0)]]) {
                    float4 sampled = tex.sample(smp, in.texCoord);
                    return float4(in.color.rgb, in.color.a * sampled.a);
                }

                fragment float4 fragment_circle(CircleVertexOut in [[stage_in]]) {
                    float2 center = float2(0.5, 0.5);
                    float dist = distance(in.uv, center);
                    if (dist > 0.5) {
                        discard_fragment();
                    }
                    // Optional: Anti-aliasing
                    float delta = fwidth(dist);
                    float alpha = 1.0 - smoothstep(0.5 - delta, 0.5, dist);
                    return float4(in.color.rgb, in.color.a * alpha);
                }

                // Stroke Circle (annulus/ring)
                struct StrokeCircleVertexIn {
                    float2 position [[attribute(0)]];
                    float2 uv [[attribute(1)]];
                    float4 color [[attribute(2)]];
                    float innerRadius [[attribute(3)]];
                };

                struct StrokeCircleVertexOut {
                    float4 position [[position]];
                    float2 uv;
                    float4 color;
                    float innerRadius;
                };

                vertex StrokeCircleVertexOut vertex_stroke_circle(StrokeCircleVertexIn in [[stage_in]], constant float4x4 &matrix [[buffer(1)]]) {
                    StrokeCircleVertexOut out;
                    out.position = matrix * float4(in.position, 0.0, 1.0);
                    out.uv = in.uv;
                    out.color = in.color;
                    out.innerRadius = in.innerRadius;
                    return out;
                }

                fragment float4 fragment_stroke_circle(StrokeCircleVertexOut in [[stage_in]]) {
                    float2 center = float2(0.5, 0.5);
                    float dist = distance(in.uv, center);
                    
                    // Discard outside outer radius
                    if (dist > 0.5) {
                        discard_fragment();
                    }
                    
                    // Discard inside inner radius
                    if (dist < in.innerRadius) {
                        discard_fragment();
                    }
                    
                    // Anti-aliasing at both edges
                    float delta = fwidth(dist);
                    float alphaOuter = 1.0 - smoothstep(0.5 - delta, 0.5, dist);
                    float alphaInner = smoothstep(in.innerRadius - delta, in.innerRadius, dist);
                    float alpha = alphaOuter * alphaInner;
                    
                    return float4(in.color.rgb, in.color.a * alpha);
                }

                // Gradient
                struct GradientVertexIn {
                    float2 position [[attribute(0)]];
                    float2 texCoord [[attribute(1)]];
                    float4 color1 [[attribute(2)]];
                    float4 color2 [[attribute(3)]];
                };

                struct GradientVertexOut {
                    float4 position [[position]];
                    float2 texCoord;
                    float4 color1;
                    float4 color2;
                };

                vertex GradientVertexOut vertex_gradient(GradientVertexIn in [[stage_in]], constant float4x4 &matrix [[buffer(1)]]) {
                    GradientVertexOut out;
                    out.position = matrix * float4(in.position, 0.0, 1.0);
                    out.texCoord = in.texCoord;
                    out.color1 = in.color1;
                    out.color2 = in.color2;
                    return out;
                }

                fragment float4 fragment_gradient_linear(GradientVertexOut in [[stage_in]]) {
                    // Linear gradient along U axis
                    return mix(in.color1, in.color2, in.texCoord.x);
                }

                fragment float4 fragment_gradient_radial(GradientVertexOut in [[stage_in]]) {
                    // Radial gradient from center
                    float2 center = float2(0.5, 0.5);
                    float dist = distance(in.texCoord, center) * 2.0; // Normalized to 0-1
                    dist = clamp(dist, 0.0, 1.0);
                    return mix(in.color1, in.color2, dist);
                }
                """

            guard let library = try? device.makeLibrary(source: shaderSource, options: nil) else {
                print("[Renderer] Failed to compile shaders")
                return false
            }

            // --- Create Pipelines for all combinations ---

            let combinations: [(PipelineKey.Kind, String, String)] = [
                (.color, "vertex_color", "fragment_color"),
                (.texture, "vertex_texture", "fragment_texture"),
                (.text, "vertex_text", "fragment_text"),
                (.circle, "vertex_circle", "fragment_circle"),
                (.strokeCircle, "vertex_stroke_circle", "fragment_stroke_circle"),
                (.gradient, "vertex_gradient", "fragment_gradient_linear"),
            ]

            let blendModes: [BlendMode] = [.normal, .additive, .multiply]

            for (kind, vFunc, fFunc) in combinations {
                guard let vertexFunction = library.makeFunction(name: vFunc),
                    let fragmentFunction = library.makeFunction(name: fFunc)
                else {
                    continue
                }

                for mode in blendModes {
                    let descriptor = MTLRenderPipelineDescriptor()
                    descriptor.vertexFunction = vertexFunction
                    descriptor.fragmentFunction = fragmentFunction

                    // Configure Vertex Descriptor based on Kind
                    let vertexDescriptor = MTLVertexDescriptor()
                    switch kind {
                    case .color:
                        vertexDescriptor.attributes[0].format = .float2  // pos
                        vertexDescriptor.attributes[0].offset = 0
                        vertexDescriptor.attributes[0].bufferIndex = 0
                        vertexDescriptor.attributes[1].format = .float4  // color
                        vertexDescriptor.attributes[1].offset = 8
                        vertexDescriptor.attributes[1].bufferIndex = 0
                        vertexDescriptor.layouts[0].stride = 24
                    case .texture:
                        vertexDescriptor.attributes[0].format = .float2
                        vertexDescriptor.attributes[0].offset = 0
                        vertexDescriptor.attributes[0].bufferIndex = 0
                        vertexDescriptor.attributes[1].format = .float2  // proper UV
                        vertexDescriptor.attributes[1].offset = 8
                        vertexDescriptor.attributes[1].bufferIndex = 0
                        vertexDescriptor.layouts[0].stride = 16
                    case .text:
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
                    case .circle:
                        vertexDescriptor.attributes[0].format = .float2  // pos
                        vertexDescriptor.attributes[0].offset = 0
                        vertexDescriptor.attributes[0].bufferIndex = 0
                        vertexDescriptor.attributes[1].format = .float2  // uv
                        vertexDescriptor.attributes[1].offset = 8
                        vertexDescriptor.attributes[1].bufferIndex = 0
                        vertexDescriptor.attributes[2].format = .float4  // color
                        vertexDescriptor.attributes[2].offset = 16
                        vertexDescriptor.attributes[2].bufferIndex = 0
                        vertexDescriptor.layouts[0].stride = 32
                    case .strokeCircle:
                        vertexDescriptor.attributes[0].format = .float2  // pos
                        vertexDescriptor.attributes[0].offset = 0
                        vertexDescriptor.attributes[0].bufferIndex = 0
                        vertexDescriptor.attributes[1].format = .float2  // uv
                        vertexDescriptor.attributes[1].offset = 8
                        vertexDescriptor.attributes[1].bufferIndex = 0
                        vertexDescriptor.attributes[2].format = .float4  // color
                        vertexDescriptor.attributes[2].offset = 16
                        vertexDescriptor.attributes[2].bufferIndex = 0
                        vertexDescriptor.attributes[3].format = .float  // innerRadius
                        vertexDescriptor.attributes[3].offset = 32
                        vertexDescriptor.attributes[3].bufferIndex = 0
                        vertexDescriptor.layouts[0].stride = 36
                    case .gradient:
                        vertexDescriptor.attributes[0].format = .float2  // pos
                        vertexDescriptor.attributes[0].offset = 0
                        vertexDescriptor.attributes[0].bufferIndex = 0
                        vertexDescriptor.attributes[1].format = .float2  // texCoord
                        vertexDescriptor.attributes[1].offset = 8
                        vertexDescriptor.attributes[1].bufferIndex = 0
                        vertexDescriptor.attributes[2].format = .float4  // color1
                        vertexDescriptor.attributes[2].offset = 16
                        vertexDescriptor.attributes[2].bufferIndex = 0
                        vertexDescriptor.attributes[3].format = .float4  // color2
                        vertexDescriptor.attributes[3].offset = 32
                        vertexDescriptor.attributes[3].bufferIndex = 0
                        vertexDescriptor.layouts[0].stride = 48
                    }
                    descriptor.vertexDescriptor = vertexDescriptor

                    // Configure Blending
                    guard let metalLayer = metalLayer else { return false }
                    descriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
                    descriptor.colorAttachments[0].isBlendingEnabled = true

                    switch mode {
                    case .normal:
                        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                        descriptor.colorAttachments[0].destinationRGBBlendFactor =
                            .oneMinusSourceAlpha
                        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
                        descriptor.colorAttachments[0].destinationAlphaBlendFactor =
                            .oneMinusSourceAlpha
                    case .additive:
                        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
                        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
                        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
                    case .multiply:
                        descriptor.colorAttachments[0].sourceRGBBlendFactor = .destinationColor
                        descriptor.colorAttachments[0].destinationRGBBlendFactor = .zero
                        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
                        descriptor.colorAttachments[0].destinationAlphaBlendFactor =
                            .oneMinusSourceAlpha
                    }

                    if let pipeline = try? device.makeRenderPipelineState(descriptor: descriptor) {
                        pipelineStates[PipelineKey(kind: kind, blendMode: mode)] = pipeline
                    } else {
                        print("Failed to create pipeline for \(kind) \(mode)")
                    }
                }
            }

            return true
        }

        func render(commands: [DrawCommand]) {
            guard let metalLayer = metalLayer,
                let drawable = metalLayer.nextDrawable(),
                let commandBuffer = commandQueue.makeCommandBuffer()
            else { return }

            let clearColor = findClearColor(in: commands)

            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            renderPassDescriptor.colorAttachments[0].clearColor = clearColor

            guard
                let encoder = commandBuffer.makeRenderCommandEncoder(
                    descriptor: renderPassDescriptor)
            else { return }

            let scale = metalLayer.contentsScale
            let screenSize = CGSize(
                width: metalLayer.drawableSize.width / scale,
                height: metalLayer.drawableSize.height / scale
            )
            let screenWidth = Float(screenSize.width)
            let screenHeight = Float(screenSize.height)

            // Orthographic Projection: (0,0) at top-left, (w,h) at bottom-right
            // Metal NDC: -1 to 1.
            // x: 0 -> -1, w -> 1.  (x/w)*2 - 1
            // y: 0 -> 1, h -> -1.  1 - (y/h)*2
            let projectionMatrix = matrix_float4x4(
                columns: (
                    SIMD4<Float>(2.0 / screenWidth, 0, 0, 0),
                    SIMD4<Float>(0, -2.0 / screenHeight, 0, 0),
                    SIMD4<Float>(0, 0, 1, 0),
                    SIMD4<Float>(-1, 1, 0, 1)
                ))

            // Default blend mode
            currentBlendMode = .normal

            for command in commands {
                switch command {
                case .clear:
                    break
                case .setBlendMode(let mode):
                    currentBlendMode = mode
                case .fillRect(let x, let y, let width, let height, let color, let transform):
                    drawRect(
                        encoder: encoder, x: x, y: y, width: width, height: height, color: color,
                        transform: transform, projection: projectionMatrix)
                case .fillCircle(let x, let y, let radius, let color, let transform):
                    drawCircle(
                        encoder: encoder, x: x, y: y, radius: radius, color: color,
                        transform: transform, projection: projectionMatrix)
                case .drawLine(let x1, let y1, let x2, let y2, let width, let color, let transform):
                    drawLine(
                        encoder: encoder, x1: x1, y1: y1, x2: x2, y2: y2, width: width,
                        color: color, transform: transform, projection: projectionMatrix)
                case .fillPolygon(let points, let color, let transform):
                    drawPolygon(
                        encoder: encoder, points: points, color: color, transform: transform,
                        projection: projectionMatrix)
                case .strokeCircle(let x, let y, let radius, let width, let color, let transform):
                    drawStrokeCircle(
                        encoder: encoder, x: x, y: y, radius: radius, width: width, color: color,
                        transform: transform, projection: projectionMatrix)
                case .strokeRect(
                    let x, let y, let width, let height, let strokeWidth, let color, let transform):
                    drawStrokeRect(
                        encoder: encoder, x: x, y: y, width: width, height: height,
                        strokeWidth: strokeWidth,
                        color: color, transform: transform, projection: projectionMatrix)
                case .strokePolygon(let points, let width, let color, let transform):
                    drawStrokePolygon(
                        encoder: encoder, points: points, width: width, color: color,
                        transform: transform, projection: projectionMatrix)
                case .fillRectGradient(
                    let x, let y, let width, let height, let gradient, let transform):
                    drawRectGradient(
                        encoder: encoder, x: x, y: y, width: width, height: height,
                        gradient: gradient,
                        transform: transform, projection: projectionMatrix)
                case .drawImage(let image, let x, let y, let transform):
                    drawImage(
                        encoder: encoder, image: image, x: x, y: y, transform: transform,
                        projection: projectionMatrix)
                case .drawText(let text, let x, let y, let font, let color, let transform):
                    drawText(
                        encoder: encoder, text: text, x: x, y: y, font: font, color: color,
                        transform: transform, projection: projectionMatrix)
                }
            }

            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        private func findClearColor(in commands: [DrawCommand]) -> MTLClearColor {
            for command in commands {
                if case .clear(let color) = command {
                    return MTLClearColor(
                        red: Double(color.r), green: Double(color.g), blue: Double(color.b),
                        alpha: Double(color.a))
                }
            }
            return defaultClearColor
        }

        private func drawRect(
            encoder: MTLRenderCommandEncoder, x: Float, y: Float, width: Float, height: Float,
            color: Color, transform: matrix_float4x4, projection: matrix_float4x4
        ) {
            guard
                let pipeline = pipelineStates[
                    PipelineKey(kind: .color, blendMode: currentBlendMode)]
            else { return }

            let vertices: [Float] = [
                x, y + height, color.r, color.g, color.b, color.a,
                x + width, y + height, color.r, color.g, color.b, color.a,
                x + width, y, color.r, color.g, color.b, color.a,
                x, y + height, color.r, color.g, color.b, color.a,
                x + width, y, color.r, color.g, color.b, color.a,
                x, y, color.r, color.g, color.b, color.a,
            ]

            guard
                let vertexBuffer = device.makeBuffer(
                    bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: [])
            else { return }

            var mvp = matrix_multiply(projection, transform)

            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&mvp, length: MemoryLayout<matrix_float4x4>.size, index: 1)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }

        private func drawCircle(
            encoder: MTLRenderCommandEncoder, x: Float, y: Float, radius: Float, color: Color,
            transform: matrix_float4x4, projection: matrix_float4x4
        ) {
            guard
                let pipeline = pipelineStates[
                    PipelineKey(kind: .circle, blendMode: currentBlendMode)]
            else { return }

            let size = radius * 2
            let width = size
            let height = size
            let startX = x - radius
            let startY = y - radius

            // Quad covering the circle area
            let vertices: [Float] = [
                startX, startY + height, 0.0, 1.0, color.r, color.g, color.b, color.a,
                startX + width, startY + height, 1.0, 1.0, color.r, color.g, color.b, color.a,
                startX + width, startY, 1.0, 0.0, color.r, color.g, color.b, color.a,
                startX, startY + height, 0.0, 1.0, color.r, color.g, color.b, color.a,
                startX + width, startY, 1.0, 0.0, color.r, color.g, color.b, color.a,
                startX, startY, 0.0, 0.0, color.r, color.g, color.b, color.a,
            ]

            guard
                let vertexBuffer = device.makeBuffer(
                    bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: [])
            else { return }

            var mvp = matrix_multiply(projection, transform)

            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&mvp, length: MemoryLayout<matrix_float4x4>.size, index: 1)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }

        private func drawLine(
            encoder: MTLRenderCommandEncoder, x1: Float, y1: Float, x2: Float, y2: Float,
            width: Float, color: Color, transform: matrix_float4x4, projection: matrix_float4x4
        ) {
            guard
                let pipeline = pipelineStates[
                    PipelineKey(kind: .color, blendMode: currentBlendMode)]
            else { return }

            let dx = x2 - x1
            let dy = y2 - y1
            let length = sqrt(dx * dx + dy * dy)
            guard length > 0 else { return }

            let angle = atan2(dy, dx)
            let cx = (x1 + x2) / 2
            let cy = (y1 + y2) / 2

            // Calculate corner points of rotated rectangle (the line)
            let halfW = length / 2
            let halfH = width / 2

            let c = cos(angle)
            let s = sin(angle)

            func rotatePoint(_ px: Float, _ py: Float) -> (Float, Float) {
                return (px * c - py * s + cx, px * s + py * c + cy)
            }

            // Local coordinates relative to center, before rotation
            let p1 = rotatePoint(-halfW, -halfH)  // Top-Left
            let p2 = rotatePoint(halfW, -halfH)  // Top-Right
            let p3 = rotatePoint(halfW, halfH)  // Bottom-Right
            let p4 = rotatePoint(-halfW, halfH)  // Bottom-Left

            let vertices: [Float] = [
                p4.0, p4.1, color.r, color.g, color.b, color.a,
                p3.0, p3.1, color.r, color.g, color.b, color.a,
                p2.0, p2.1, color.r, color.g, color.b, color.a,
                p4.0, p4.1, color.r, color.g, color.b, color.a,
                p2.0, p2.1, color.r, color.g, color.b, color.a,
                p1.0, p1.1, color.r, color.g, color.b, color.a,
            ]

            guard
                let vertexBuffer = device.makeBuffer(
                    bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: [])
            else { return }

            var mvp = matrix_multiply(projection, transform)

            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&mvp, length: MemoryLayout<matrix_float4x4>.size, index: 1)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }

        private func drawPolygon(
            encoder: MTLRenderCommandEncoder, points: [SIMD2<Float>], color: Color,
            transform: matrix_float4x4, projection: matrix_float4x4
        ) {
            guard points.count >= 3 else { return }
            guard
                let pipeline = pipelineStates[
                    PipelineKey(kind: .color, blendMode: currentBlendMode)]
            else { return }

            // Use ear clipping triangulation for complex polygons
            let triangleIndices = PolygonTriangulator.triangulate(points)
            guard !triangleIndices.isEmpty else { return }

            var vertices: [Float] = []
            let r = color.r
            let g = color.g
            let b = color.b
            let a = color.a

            for index in triangleIndices {
                let p = points[index]
                vertices.append(contentsOf: [p.x, p.y, r, g, b, a])
            }

            guard
                let vertexBuffer = device.makeBuffer(
                    bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: [])
            else { return }

            var mvp = matrix_multiply(projection, transform)

            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&mvp, length: MemoryLayout<matrix_float4x4>.size, index: 1)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count / 6)
        }

        private func drawStrokeCircle(
            encoder: MTLRenderCommandEncoder, x: Float, y: Float, radius: Float, width: Float,
            color: Color, transform: matrix_float4x4, projection: matrix_float4x4
        ) {
            guard
                let pipeline = pipelineStates[
                    PipelineKey(kind: .strokeCircle, blendMode: currentBlendMode)]
            else { return }

            let size = radius * 2
            let outerRadius = radius
            let innerRadius = radius - width

            // Normalized inner radius for the shader (0-0.5 range)
            let normalizedInnerRadius = innerRadius / (outerRadius * 2.0)

            let startX = x - radius
            let startY = y - radius

            // Quad covering the circle area, with innerRadius as attribute
            let vertices: [Float] = [
                startX, startY + size, 0.0, 1.0, color.r, color.g, color.b, color.a,
                normalizedInnerRadius,
                startX + size, startY + size, 1.0, 1.0, color.r, color.g, color.b, color.a,
                normalizedInnerRadius,
                startX + size, startY, 1.0, 0.0, color.r, color.g, color.b, color.a,
                normalizedInnerRadius,
                startX, startY + size, 0.0, 1.0, color.r, color.g, color.b, color.a,
                normalizedInnerRadius,
                startX + size, startY, 1.0, 0.0, color.r, color.g, color.b, color.a,
                normalizedInnerRadius,
                startX, startY, 0.0, 0.0, color.r, color.g, color.b, color.a, normalizedInnerRadius,
            ]

            guard
                let vertexBuffer = device.makeBuffer(
                    bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: [])
            else { return }

            var mvp = matrix_multiply(projection, transform)

            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&mvp, length: MemoryLayout<matrix_float4x4>.size, index: 1)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }

        private func drawStrokeRect(
            encoder: MTLRenderCommandEncoder, x: Float, y: Float, width: Float, height: Float,
            strokeWidth: Float, color: Color, transform: matrix_float4x4,
            projection: matrix_float4x4
        ) {
            // Draw 4 lines for rectangle outline
            drawLine(
                encoder: encoder, x1: x, y1: y, x2: x + width, y2: y, width: strokeWidth,
                color: color, transform: transform, projection: projection)
            drawLine(
                encoder: encoder, x1: x + width, y1: y, x2: x + width, y2: y + height,
                width: strokeWidth, color: color, transform: transform, projection: projection)
            drawLine(
                encoder: encoder, x1: x + width, y1: y + height, x2: x, y2: y + height,
                width: strokeWidth, color: color, transform: transform, projection: projection)
            drawLine(
                encoder: encoder, x1: x, y1: y + height, x2: x, y2: y, width: strokeWidth,
                color: color, transform: transform, projection: projection)
        }

        private func drawStrokePolygon(
            encoder: MTLRenderCommandEncoder, points: [SIMD2<Float>], width: Float, color: Color,
            transform: matrix_float4x4, projection: matrix_float4x4
        ) {
            guard points.count >= 2 else { return }

            // Draw lines between consecutive points
            for i in 0..<points.count {
                let p1 = points[i]
                let p2 = points[(i + 1) % points.count]
                drawLine(
                    encoder: encoder, x1: p1.x, y1: p1.y, x2: p2.x, y2: p2.y, width: width,
                    color: color, transform: transform, projection: projection)
            }
        }

        private func drawRectGradient(
            encoder: MTLRenderCommandEncoder, x: Float, y: Float, width: Float, height: Float,
            gradient: Gradient, transform: matrix_float4x4, projection: matrix_float4x4
        ) {
            guard
                let pipeline = pipelineStates[
                    PipelineKey(kind: .gradient, blendMode: currentBlendMode)]
            else { return }

            let (c1, c2): (Color, Color)
            switch gradient {
            case .linear(_, _, _, _, let startColor, let endColor):
                c1 = startColor
                c2 = endColor
            case .radial(_, _, _, let innerColor, let outerColor):
                c1 = innerColor
                c2 = outerColor
            }

            let vertices: [Float] = [
                x, y + height, 0.0, 1.0, c1.r, c1.g, c1.b, c1.a, c2.r, c2.g, c2.b, c2.a,
                x + width, y + height, 1.0, 1.0, c1.r, c1.g, c1.b, c1.a, c2.r, c2.g, c2.b, c2.a,
                x + width, y, 1.0, 0.0, c1.r, c1.g, c1.b, c1.a, c2.r, c2.g, c2.b, c2.a,
                x, y + height, 0.0, 1.0, c1.r, c1.g, c1.b, c1.a, c2.r, c2.g, c2.b, c2.a,
                x + width, y, 1.0, 0.0, c1.r, c1.g, c1.b, c1.a, c2.r, c2.g, c2.b, c2.a,
                x, y, 0.0, 0.0, c1.r, c1.g, c1.b, c1.a, c2.r, c2.g, c2.b, c2.a,
            ]

            guard
                let vertexBuffer = device.makeBuffer(
                    bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: [])
            else { return }

            var mvp = matrix_multiply(projection, transform)

            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&mvp, length: MemoryLayout<matrix_float4x4>.size, index: 1)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }

        private func drawImage(
            encoder: MTLRenderCommandEncoder, image: Image, x: Float, y: Float,
            transform: matrix_float4x4, projection: matrix_float4x4
        ) {
            guard let texture = getOrCreateTexture(for: image),
                let pipeline = pipelineStates[
                    PipelineKey(kind: .texture, blendMode: currentBlendMode)]
            else { return }

            let width = Float(texture.width)
            let height = Float(texture.height)

            let vertices: [Float] = [
                x, y + height, 0.0, 1.0,
                x + width, y + height, 1.0, 1.0,
                x + width, y, 1.0, 0.0,
                x, y + height, 0.0, 1.0,
                x + width, y, 1.0, 0.0,
                x, y, 0.0, 0.0,
            ]

            guard
                let vertexBuffer = device.makeBuffer(
                    bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: [])
            else { return }

            var mvp = matrix_multiply(projection, transform)

            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setFragmentTexture(texture, index: 0)
            encoder.setFragmentSamplerState(samplerState, index: 0)
            encoder.setVertexBytes(&mvp, length: MemoryLayout<matrix_float4x4>.size, index: 1)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }

        private func drawText(
            encoder: MTLRenderCommandEncoder, text: String, x: Float, y: Float, font: Font,
            color: Color, transform: matrix_float4x4, projection: matrix_float4x4
        ) {
            // Text rendering needs to handle the atlas and vertices.
            // For simplicity, we use the same command generation but process vertices here.
            let atlas = GlyphAtlasManager.shared.getAtlas(for: font)
            atlas.ensureGlyphs(for: text)

            guard let atlasTexture = getOrUpdateAtlasTexture(for: font, atlas: atlas),
                let pipeline = pipelineStates[PipelineKey(kind: .text, blendMode: currentBlendMode)]
            else { return }

            var vertices: [Float] = []
            var cursorX = x
            let cursorY = y + font.size

            let r = color.r
            let g = color.g
            let b = color.b
            let a = color.a

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

                // Quad vertices
                let v1x = glyphX
                let v1y = glyphY + glyphH
                let v2x = glyphX + glyphW
                let v2y = glyphY + glyphH
                let v3x = glyphX + glyphW
                let v3y = glyphY
                let v4x = glyphX
                let v4y = glyphY

                let u0 = metrics.u0
                let v0 = metrics.v0
                let u1 = metrics.u1
                let v1 = metrics.v1

                vertices.append(contentsOf: [
                    v1x, v1y, u0, v1, r, g, b, a,
                    v2x, v2y, u1, v1, r, g, b, a,
                    v3x, v3y, u1, v0, r, g, b, a,
                    v1x, v1y, u0, v1, r, g, b, a,
                    v3x, v3y, u1, v0, r, g, b, a,
                    v4x, v4y, u0, v0, r, g, b, a,
                ])

                cursorX += metrics.advance
            }

            guard !vertices.isEmpty else { return }

            guard
                let vertexBuffer = device.makeBuffer(
                    bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: [])
            else { return }

            var mvp = matrix_multiply(projection, transform)

            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setFragmentTexture(atlasTexture, index: 0)
            encoder.setFragmentSamplerState(textSamplerState, index: 0)
            encoder.setVertexBytes(&mvp, length: MemoryLayout<matrix_float4x4>.size, index: 1)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count / 8)  // 8 floats per vertex
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
