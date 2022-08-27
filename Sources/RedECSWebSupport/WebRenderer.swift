import JavaScriptKit
import RedECS
import Geometry
import GeometryAlgorithms
import RedECSUIComponents

open class WebRenderer {
    public enum State {
        case loading
        case ready
    }
    
    public private(set) var size: Size
    public private(set) var canvasElement: JSValue = .undefined
    public private(set) var glContext: JSValue = .undefined
    
    public var webResourceManager: WebResourceManager
    
    public var queuedWork: [RenderGroup] = []
    
    private(set) var projectionMatrix: Matrix3 = .identity
    
    lazy var drawProgram: Draw2DProgram = {
        Draw2DProgram(
            triangles: [],
            textureSize: .zero,
            image: .null,
            color: .clear,
            projectionMatrix: .identity,
            modelMatrix: .identity
        )
    }()
    
    lazy var emptyImage: JSValue = {
        createEmptyImage(size: .init(width: 1, height: 1))
    }()
    
    public init(
        size: Size,
        resourceLoader: WebResourceManager
    ) {
        self.size = size
        self.webResourceManager = resourceLoader
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
            for renderGroup in queuedWork.sorted(by: { $0.zIndex < $1.zIndex }) {
                switch renderGroup.fragmentType {
                case .color(let color):
                    drawProgram.update(
                        triangles: renderGroup.triangles,
                        textureSize: .init(width: 1, height: 1),
                        image: emptyImage,
                        color: renderGroup.color ?? .clear,
                        projectionMatrix: projectionMatrix,
                        modelMatrix: renderGroup.transformMatrix
                    )
                    try drawProgram.execute(with: self)
                case .texture(let textureId):
                    if let image = webResourceManager.textureImages[textureId],
                       let imageObject = image.object,
                       let width = imageObject.width.number,
                       let height = imageObject.height.number {
                        drawProgram.update(
                            triangles: renderGroup.triangles,
                            textureSize: .init(
                                width: width,
                                height: height
                            ),
                            image: image,
                            color: renderGroup.color ?? .init(red: 0, green: 0, blue: 0, alpha: renderGroup.opacity),
                            projectionMatrix: projectionMatrix,
                            modelMatrix: renderGroup.transformMatrix
                        )
                        try drawProgram.execute(with: self)
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
        _ = glContext.clearColor(0, 0, 0, 0.1)
        _ = glContext.clear(glContext.COLOR_BUFFER_BIT)
    }
    
    private func createEmptyImage(size: Size) -> JSValue {
        let document = JSObject.global.document
        var canvas = document.createElement("canvas")
        canvas.width = size.width.jsValue
        canvas.height = size.height.jsValue
        
        var ctx = canvas.getContext("2d")
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
