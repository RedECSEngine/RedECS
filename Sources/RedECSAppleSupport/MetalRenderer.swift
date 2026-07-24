import MetalKit
import QuartzCore
import RedECS
import Geometry
import GeometryAlgorithms

enum AAPLVertexInputIndex: Int {
    case indices = 0
    case uniforms = 1
    case textureCoordinates = 2
}

enum TextureIndex: Int {
    case colorMap = 0
}

//  This structure defines the layout of vertices sent to the vertex
//  shader. This header is shared between the .metal shader and C code, to guarantee that
//  the layout of the vertex array in the C code matches the layout that the .metal
//  vertex shader expects.
struct AAPLVertex {
    let position: vector_float2
    let color: vector_float4
}

struct TextureInfo {
    let texCoord: vector_float2
    let texSize: vector_float2
}

struct Uniforms {
    var projectionMatrix: matrix_float4x4
    var modelViewMatrix: matrix_float4x4
}

public class MetalRenderer: NSObject, MTKViewDelegate {
    static let fragmentParamsBufferIndex = 0 // fragment buffer slot for u_params

    var resourceManager: MetalResourceManager
    var device: MTLDevice
    var shaderRegistry: ShaderRegistry // effects to build pipelines for
    var pipelineStates: [ShaderId: MTLRenderPipelineState] // one pipeline per effect
    var passthroughPipelineState: MTLRenderPipelineState // fallback for unknown ids

    // The command queue used to pass commands to the device.
    var commandQueue: MTLCommandQueue
    
    // The current size of the view, used as an input to the vertex shader.
    public var viewportSize: Size = .init(width: 0, height: 0)
    
    public var queuedWork: [RenderGroup] = []
    
    public var deltaCallback: ((Double) -> Void)?
    
    var projectionMatrix: matrix_float4x4 = matrix_float4x4()
    /// Projection for `.screen` render groups (viewport points, top-left
    /// origin); tracks the drawable size, independent of the world camera.
    var screenProjectionMatrix: matrix_float4x4 = matrix_float4x4()
    
    private lazy var emptyTexture: MTLTexture = {
        creatyEmptyPixelTexture(device: device)!
    }()
    
    public init?(
        device: MTLDevice,
        pixelFormat: MTLPixelFormat,
        resourceManager: MetalResourceManager,
        shaderRegistry: ShaderRegistry = ShaderRegistry()
    ) {
        self.resourceManager = resourceManager
        self.shaderRegistry = shaderRegistry

        self.device = device

        // Compile one library holding every effect's fragment function.
        guard let library = Self.makeShaderLibrary(device: device, registry: shaderRegistry),
              let vertexFunction = library.makeFunction(name: "vertexShader") else {
            return nil
        }

        // Build a pipeline pairing the shared vertex fn with one fragment fn.
        func makePipeline(fragmentFunctionName: String) -> MTLRenderPipelineState? {
            guard let fragmentFunction = library.makeFunction(name: fragmentFunctionName) else {
                return nil
            }
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.label = "2D Rendering Pipeline: \(fragmentFunctionName)"
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat

            // Standard premultiplied-style alpha blending (unchanged).
            pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
            pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

            return try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }

        // Passthrough is the fallback, so build it explicitly.
        guard let passthrough = makePipeline(
            fragmentFunctionName: ShaderRegistry.passthroughDefinition.metalFragmentFunction
        ) else {
            return nil
        }
        self.passthroughPipelineState = passthrough

        // One pipeline per registered effect, keyed by id for per-group lookup.
        var states: [ShaderId: MTLRenderPipelineState] = [:]
        for definition in shaderRegistry.ordered {
            guard let state = makePipeline(fragmentFunctionName: definition.metalFragmentFunction) else {
                return nil
            }
            states[definition.id] = state
        }
        self.pipelineStates = states

        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }

        self.commandQueue = commandQueue
    }

    /// The base source (`baseMetalSource`) and each registered shader's
    /// `metalSource` are compiled together at runtime, so Xcode and
    /// `swift build`/`swift test` render identically — a precompiled
    /// default.metallib produced subtly different texture sampling than the
    /// runtime compiler, which broke snapshot references across the two
    /// (see known-issues.md). Compiling from an embedded string (rather than a
    /// bundled `Shaders.metal`) also means no resource lookup that Xcode fails
    /// to stage. Preset and game-defined fragment functions live in one library.
    private static func makeShaderLibrary(device: MTLDevice, registry: ShaderRegistry) -> MTLLibrary? {
        // Append each effect's MSL (empty for effects already in the base).
        let appended = registry.ordered
            .map(\.metalSource)
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        // Compile it all as one translation unit so appended fns see base types.
        let source = baseMetalSource + "\n\n" + appended
        return try? device.makeLibrary(source: source, options: nil)
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewportSize.width = size.width
        viewportSize.height = size.height
        if size.width > 0 && size.height > 0 {
            screenProjectionMatrix = Matrix3.screenProjection(size: viewportSize).asMatrix4x4
        }
    }
    
    // A *monotonic* timestamp (seconds). `Date()` is the wall clock and can jump
    // backward on NTP corrections, sleep/wake, or manual clock changes, which
    // produced negative frame deltas; `CACurrentMediaTime()` never goes back.
    var lastDrawTime: CFTimeInterval?

    public func updateDelta() {
        let now = CACurrentMediaTime()
        defer { lastDrawTime = now }
        guard let drawTime = lastDrawTime else { return }
        let delta = now - drawTime
        // Should always hold with a monotonic clock, but guard so two draws in
        // the same instant (delta == 0) can't trip sendDelta's `delta > 0`.
        guard delta > 0 else { return }
        deltaCallback?(delta)
    }
    
    public func draw(in view: MTKView) {
        
        guard !queuedWork.isEmpty else {
            updateDelta()
            return
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            fatalError("commandBuffer error")
        }
      
        commandBuffer.label = "Draw Command"
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            fatalError("renderPassDescriptor error")
        }
        
//            renderPassDescriptor.colorAttachments[0].texture = view.currentDrawable?.texture
//        renderPassDescriptor.colorAttachments[0].loadAction = .clear
//            renderPassDescriptor.colorAttachments[0].storeAction = .store
//        renderPassDescriptor.colorAttachments[0].clearColor = .init(red: 1, green: 1, blue: 1, alpha: 1)
        renderPassDescriptor.colorAttachments[0].clearColor = .init(red: 0, green: 0, blue: 0, alpha: 1)
//
//            renderPassDescriptor.depthAttachment.clearDepth = 1.0
//            renderPassDescriptor.depthAttachment.loadAction = .clear
//            renderPassDescriptor.depthAttachment.storeAction = .dontCare
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            fatalError("renderEncoder error")
        }
        
        renderEncoder.setViewport(.init(
            originX: 0,
            originY: 0,
            width: viewportSize.width,
            height: viewportSize.height,
            znear: 0,
            zfar: 1.0
        ))
        
        var lastBoundTexture: TextureId?
        var lastPipelineId: ShaderId? // skip redundant pipeline switches

        // Screen-space groups draw after (above) all world groups, each
        // space z-sorted within itself.
        let sortedWork = queuedWork.sorted { a, b in
            if a.projectionSpace != b.projectionSpace {
                return a.projectionSpace == .world
            }
            return a.zIndex < b.zIndex
        }
        for renderGroup in sortedWork {
            // Select this group's effect pipeline (falling back to passthrough).
            let shaderId = renderGroup.shader?.programId ?? .passthrough
            if lastPipelineId != shaderId {
                renderEncoder.setRenderPipelineState(pipelineStates[shaderId] ?? passthroughPipelineState)
                lastPipelineId = shaderId
            }

            let color = renderGroup.color?.asVectorFloat4 ?? vector_float4(0, 0, 0, Float(renderGroup.opacity))
            var triangleVertices: [AAPLVertex] = []
            var textureVertices: [TextureInfo] = []
            var uniforms = Uniforms(
                projectionMatrix: renderGroup.projectionSpace == .screen
                    ? screenProjectionMatrix
                    : projectionMatrix,
                modelViewMatrix: renderGroup.transformMatrix.asMatrix4x4
            )
            
            for renderTriangle in renderGroup.triangles {
                triangleVertices.append(contentsOf: [
                    AAPLVertex(
                        position: renderTriangle.triangle.a.asVectorFloat2,
                        color: color
                    ),
                    AAPLVertex(
                        position: renderTriangle.triangle.b.asVectorFloat2,
                        color: color
                    ),
                    AAPLVertex(
                        position: renderTriangle.triangle.c.asVectorFloat2,
                        color: color
                    )
                ])
                var texSize = vector_float2(0, 0)
                if let textureId = renderGroup.textureId,
                   let texture = resourceManager.textureImages[textureId] {
                    texSize.x = Float(texture.width)
                    texSize.y = Float(texture.height)
                }
                textureVertices.append(contentsOf: [
                    TextureInfo(
                        texCoord: (renderTriangle.textureTriangle ?? RenderTriangle.noTextureTriangle) .a.asVectorFloat2, texSize: texSize),
                    TextureInfo(
                        texCoord: (renderTriangle.textureTriangle ?? RenderTriangle.noTextureTriangle) .b.asVectorFloat2, texSize: texSize),
                    TextureInfo(
                        texCoord: (renderTriangle.textureTriangle ?? RenderTriangle.noTextureTriangle) .c.asVectorFloat2, texSize: texSize),
                ])
            }
            
            if let textureId = renderGroup.textureId {
                if lastBoundTexture != textureId,
                   let texture = resourceManager.textureImages[textureId] {
                    renderEncoder.setFragmentTexture(texture, index: TextureIndex.colorMap.rawValue)
                    lastBoundTexture = textureId
                } else {
//                    print("Texture not found: \(textureId)")
                }
            } else {
                renderEncoder.setFragmentTexture(emptyTexture, index: TextureIndex.colorMap.rawValue)
                lastBoundTexture = nil
            }
            
            // Pack this effect's parameters and bind them as u_params.
            if shaderRegistry[shaderId] != nil {
                var params = renderGroup.shader?.encodeUniforms() ?? []
                if !params.isEmpty { // passthrough encodes nothing and reads no buffer
                    renderEncoder.setFragmentBytes(
                        &params,
                        length: MemoryLayout<Float>.stride * params.count,
                        index: Self.fragmentParamsBufferIndex
                    )
                }
            }

            renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: AAPLVertexInputIndex.uniforms.rawValue)
            
            let chunkAmount = 3
            for i in 0..<(triangleVertices.count / chunkAmount) {
                let index = i * chunkAmount
                renderEncoder.setVertexBytes(Array(triangleVertices[index..<index+chunkAmount]), length:  MemoryLayout<AAPLVertex>.size * chunkAmount, index: AAPLVertexInputIndex.indices.rawValue)
                
                renderEncoder.setVertexBytes(Array(textureVertices[index..<index+chunkAmount]), length: MemoryLayout<TextureInfo>.size * chunkAmount, index: AAPLVertexInputIndex.textureCoordinates.rawValue)
                
                renderEncoder.drawPrimitives(
                    type: .triangle,
                    vertexStart: 0,
                    vertexCount: chunkAmount
                )
            }
        }
        
        renderEncoder.endEncoding()
        
        guard let drawable = view.currentDrawable else {
            fatalError("drawable not available")
        }
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        updateDelta()
    }
    
    func creatyEmptyPixelTexture(device: MTLDevice) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor()
        descriptor.width = 1
        descriptor.height = 1
        descriptor.usage = .shaderRead
        return device.makeTexture(descriptor: descriptor)
    }
    
    class func loadTexture(device: MTLDevice,
                           textureName: String) throws -> MTLTexture {
        /// Load texture data with optimal parameters for sampling
        
        let textureLoader = MTKTextureLoader(device: device)
        
        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue)
        ]
        
        return try textureLoader.newTexture(name: textureName,
                                            scaleFactor: 1.0,
                                            bundle: nil,
                                            options: textureLoaderOptions)
    }
}

extension MetalRenderer: Renderer {
    public func setProjectionMatrix(_ matrix: Matrix3) {
        projectionMatrix = matrix.asMatrix4x4
    }
}

extension Point {
    var asVectorFloat2: vector_float2 {
        vector_float2(x: Float(x), y: Float(y))
    }
}

public extension Matrix3 {
    /**
     V V 0 V
     V V 0 V
     0 0 1 0
     V V 0 v
     */
    var asMatrix4x4: matrix_float4x4 {
        return matrix_float4x4(columns: (
            .init(x: Float(values[0]), y: Float(values[1]), z: 0, w: Float(values[2])),
            .init(x: Float(values[3]), y: Float(values[4]), z: 0, w: Float(values[5])),
            .init(x: 0, y: 0, z: 1, w: 0),
            .init(x: Float(values[6]), y: Float(values[7]), z: 0, w: Float(values[8]))
        ))
    }
}

extension Color {
    var asVectorFloat4: vector_float4 {
        vector_float4(x: Float(red), y: Float(green), z: Float(blue), w: Float(alpha))
    }
}
