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
    
    lazy var textureProgram: DrawTextureProgram = {
        DrawTextureProgram(
            triangles: [],
            textureSize: .zero,
            image: .null,
            projectionMatrix: .identity,
            modelMatrix: .identity
        )
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
                    try DrawTrianglesProgram(
                        triangles: renderGroup.triangles,
                        color: color,
                        projectionMatrix: projectionMatrix,
                        modelMatrix: renderGroup.transformMatrix
                    )
                        .execute(with: self)
                case .texture(let textureId):
                    if let image = webResourceManager.textureImages[textureId],
                       let imageObject = image.object,
                       let width = imageObject.width.number,
                       let height = imageObject.height.number {
                        textureProgram.update(
                            triangles: renderGroup.triangles,
                            textureSize: .init(
                                width: width,
                                height: height
                            ),
                            image: image,
                            projectionMatrix: projectionMatrix,
                            modelMatrix: renderGroup.transformMatrix
                        )
                        try textureProgram.execute(with: self)
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
}

extension WebRenderer: Renderer {
    public var viewportSize: Size {
        size
    }
    
    public func setProjectionMatrix(_ matrix: Matrix3) {
       projectionMatrix = matrix
    }
}
