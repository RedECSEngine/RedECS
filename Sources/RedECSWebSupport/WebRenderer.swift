import JavaScriptKit
import RedECS
import Geometry
import GeometryAlgorithms

open class WebRenderer {
    public enum State {
        case loading
        case ready
    }
    
    public private(set) var size: Size
    public private(set) var canvasElement: JSValue = .undefined
    public private(set) var glContext: JSValue = .undefined
    
    public var webResourceManager: WebResourceManager
    public var shaderRegistry: ShaderRegistry // effects to compile programs for

    public var queuedWork: [RenderGroup] = []

    private(set) var projectionMatrix: Matrix3 = .identity
    /// Projection for `.screen` render groups (viewport points, top-left
    /// origin), independent of the world camera.
    var screenProjectionMatrix: Matrix3 {
        .screenProjection(size: size)
    }

    // One GL program per effect, compiled lazily on first draw and reused.
    lazy var programs: [ShaderId: Draw2DProgram] = {
        var result: [ShaderId: Draw2DProgram] = [:]
        for definition in shaderRegistry.ordered {
            result[definition.id] = Draw2DProgram(
                definition: definition,
                triangles: [],
                textureSize: .zero,
                image: .null,
                color: .clear,
                projectionMatrix: .identity,
                modelMatrix: .identity
            )
        }
        return result
    }()

    lazy var emptyImage: JSValue = {
        createEmptyImage(size: .init(width: 1, height: 1))
    }()

    public init(
        size: Size,
        resourceLoader: WebResourceManager,
        shaderRegistry: ShaderRegistry = ShaderRegistry()
    ) {
        self.size = size
        self.webResourceManager = resourceLoader
        self.shaderRegistry = shaderRegistry
        setUp()
    }
    
    private func setUp() {
        let document = JSObject.global.document
        self.canvasElement = document.createElement("canvas")
        canvasElement.id = "webgl-canvas"
        canvasElement.width = size.width.jsValue
        canvasElement.height = size.height.jsValue
        _ = document.body.appendChild(canvasElement)
        glContext = webGLContext()
    }
    
    public func draw() {
        do {
            clearCanvas()
            // Screen-space groups draw after (above) all world groups, each
            // space z-sorted within itself.
            let sortedWork = queuedWork.sorted { a, b in
                if a.projectionSpace != b.projectionSpace {
                    return a.projectionSpace == .world
                }
                return a.zIndex < b.zIndex
            }
            for renderGroup in sortedWork {
                let groupProjection = renderGroup.projectionSpace == .screen
                    ? screenProjectionMatrix
                    : projectionMatrix
                // Pick this group's effect program (falling back to passthrough).
                guard let program = programs[renderGroup.shader?.programId ?? .passthrough] ?? programs[.passthrough] else {
                    continue
                }
                // Pack its parameters for u_params.
                let params = renderGroup.shader?.encodeUniforms() ?? []
                switch renderGroup.fragmentType {
                case .color:
                    program.update(
                        triangles: renderGroup.triangles,
                        textureSize: .init(width: 1, height: 1),
                        image: emptyImage,
                        color: renderGroup.color ?? .clear,
                        params: params,
                        projectionMatrix: groupProjection,
                        modelMatrix: renderGroup.transformMatrix
                    )
                    try program.execute(with: self)
                case .texture(let textureId):
                    if let image = webResourceManager.textureImages[textureId],
                       let imageObject = image.object,
                       let width = imageObject.width.number,
                       let height = imageObject.height.number {
                        program.update(
                            triangles: renderGroup.triangles,
                            textureSize: .init(
                                width: width,
                                height: height
                            ),
                            image: image,
                            color: renderGroup.color ?? .init(red: 0, green: 0, blue: 0, alpha: renderGroup.opacity),
                            params: params,
                            projectionMatrix: groupProjection,
                            modelMatrix: renderGroup.transformMatrix
                        )
                        try program.execute(with: self)
                    } else {
                        print("no texture loaded for", textureId)
                        webResourceManager.startTextureLoadIfNeeded(textureId: textureId)
                    }
                }
            }
        } catch {
            print("⚠️ Draw error:", error)
            fatalError()
        }
    }

    private func webGLContext() -> JSValue {
        let document = JSObject.global.document
        let canvas = document.querySelector("#webgl-canvas")
        let gl = canvas.getContext("webgl")
        if gl.isNull {
            print("gl is null")
            fatalError()
        }
        return gl
    }
    
    private func clearCanvas() {
        // Clear the canvas
        _ = glContext.clearColor(0, 0, 0, 1)
        _ = glContext.clear(glContext.COLOR_BUFFER_BIT)
    }
    
    private func createEmptyImage(size: Size) -> JSValue {
        let document = JSObject.global.document
        let canvas = document.createElement("canvas")
        canvas.width = size.width.jsValue
        canvas.height = size.height.jsValue
        
        let ctx = canvas.getContext("2d")
        ctx.fillStyle = "rgba(0, 0, 0, 0)"
        _ = ctx.fillRect(0, 0, size.width.jsValue, size.height.jsValue)

        let img = JSObject.global.Image.function?.new(size.width.jsValue, size.height.jsValue)
        img?.src = canvas.toDataURL()
        return img?.jsValue ?? .null
      }
}

extension WebRenderer: Renderer {
    public var viewportSize: Size {
        size
    }
    
    public func setProjectionMatrix(_ matrix: Matrix3) {
       projectionMatrix = matrix
    }
}
