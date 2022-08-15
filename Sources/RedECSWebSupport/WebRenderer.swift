import JavaScriptKit
import RedECS
import Geometry
import RedECSRenderingComponents

open class WebRenderer {
    public enum State {
        case loading
        case ready
    }
    
    public private(set) var size: Size
    public private(set) var cameraPosition: Point
    
    public private(set) var canvasElement: JSValue = .undefined
    public private(set) var glContext: JSValue = .undefined
    
    public var webResourceManager: WebResourceManager
    
    public var queuedTriangles: [RenderTriangle] = []
    
    public init(
        size: Size,
        resourceLoader: WebResourceManager
    ) {
        self.size = size
        self.cameraPosition = Point(x: size.width / 2, y: size.height / 2)
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
            let work = groupEnqueuedWork()
            for job in work {
                switch job.program {
                case .color:
                    try DrawTrianglesProgram(triangles: job.triangles)
                        .execute(with: self)
                case .texture:
                    guard let textureId = job.triangles.first?.textureId else {
                        print("no texture")
                        fatalError()
                        break
                    }
                    if let image = webResourceManager.textureImages[textureId],
                       let imageObject = image.object,
                       let width = imageObject.width.number,
                       let height = imageObject.height.number {
                        try DrawTextureProgram(
                            triangles: job.triangles,
                            textureSize: .init(
                                width: width,
                                height: height
                            ),
                            image: image
                        )
                        .execute(with: self)
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
    public var cameraFrame: Rect {
        Rect(center: cameraPosition, size: size)
    }
    
    public func setCameraPosition(_ position: Point) {
        cameraPosition = position
    }
}
