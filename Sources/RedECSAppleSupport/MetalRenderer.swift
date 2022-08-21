import MetalKit
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
    var resourceManager: MetalResourceManager
    var device: MTLDevice
    var pipelineState: MTLRenderPipelineState
    
    // The command queue used to pass commands to the device.
    var commandQueue: MTLCommandQueue
    
    // The current size of the view, used as an input to the vertex shader.
    public var viewportSize: Size = .init(width: 0, height: 0)
    
    public var queuedWork: [RenderGroup] = []
    
    public var deltaCallback: ((Double) -> Void)?
    
    var projectionMatrix: matrix_float4x4 = matrix_float4x4()
    
    public init?(
        device: MTLDevice,
        pixelFormat: MTLPixelFormat,
        resourceManager: MetalResourceManager
    ) {
        self.resourceManager = resourceManager
        
        self.device = device
        
        guard let defaultLibrary = try? device.makeDefaultLibrary(bundle: .module) else {
            return nil
        }
        
        let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary.makeFunction(name: "fragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "2D Rendering Pipeline"
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            try self.pipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            return nil
        }
        
        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.commandQueue = commandQueue
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewportSize.width = size.width
        viewportSize.height = size.height
    }
    
    var lastDrawTime: Date?
    
    public func updateDelta() {
        guard let drawTime = lastDrawTime else {
            lastDrawTime = Date()
            return
        }
        let delta = Date().timeIntervalSince(drawTime)
        deltaCallback?(delta)
        lastDrawTime = Date()
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
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        var lastBoundTexture: TextureId?

        for renderGroup in queuedWork.sorted(by: { $0.zIndex < $1.zIndex }) {
            var triangleVertices: [AAPLVertex] = []
            var textureVertices: [TextureInfo] = []
            var uniforms = Uniforms(
                projectionMatrix: projectionMatrix,
                modelViewMatrix: renderGroup.transformMatrix.asMatrix4x4
            )
            
            for renderTriangle in renderGroup.triangles {
                triangleVertices.append(contentsOf: [
                    AAPLVertex(
                        position: renderTriangle.triangle.a.asVectorFloat2,
                        color: (renderGroup.color ?? .clear).asVectorFloat4
                    ),
                    AAPLVertex(
                        position: renderTriangle.triangle.b.asVectorFloat2,
                        color: (renderGroup.color ?? .clear).asVectorFloat4
                    ),
                    AAPLVertex(
                        position: renderTriangle.triangle.c.asVectorFloat2,
                        color: (renderGroup.color ?? .clear).asVectorFloat4
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
            
            if let textureId = renderGroup.textureId,
               lastBoundTexture != textureId {
                if let texture = resourceManager.textureImages[textureId] {
                    renderEncoder.setFragmentTexture(texture, index: TextureIndex.colorMap.rawValue)
                    lastBoundTexture = textureId
                } else {
//                    print("Texture not found: \(textureId)")
                }
            }
            
            renderEncoder.setVertexBytes(triangleVertices, length: triangleVertices.count *  MemoryLayout<AAPLVertex>.size, index: AAPLVertexInputIndex.indices.rawValue)
            renderEncoder.setVertexBytes(textureVertices, length: textureVertices.count * MemoryLayout<TextureInfo>.size, index: AAPLVertexInputIndex.textureCoordinates.rawValue)
            
            renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: AAPLVertexInputIndex.uniforms.rawValue)
            
            renderEncoder.drawPrimitives(
                type: .triangle,
                vertexStart: 0,
                vertexCount: triangleVertices.count
            )
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
    var asMatrix4x4: matrix_float4x4 {
//        return  matrix_float4x4(columns: (
//            .init(x: 1, y: 0, z: 0, w: 0),
//            .init(x: 0, y: 1, z: 0, w: 0),
//            .init(x: 0, y: 0, z: 1, w: 0),
//            .init(x: 0, y: 0, z: 0, w: 1)
//        ))
        
        /*
         V V 0 V
         V V 0 V
         0 0 1 0
         V V 0 v
         */
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
