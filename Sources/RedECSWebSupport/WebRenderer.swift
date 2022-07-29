import JavaScriptKit
import RedECS
import Geometry
import RedECSRenderingComponents

public enum WebRendererProgram {
    case color
    case texture
}

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
    
    private var queuedTriangles: [RenderTriangle] = []
    
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
                    guard let textureId = job.triangles.first?.textureId else { break }
                    
                    if let textureMap = webResourceManager.getTexture(textureId: textureId),
                        let image = webResourceManager.textureImages[textureId] {
                        try DrawTextureProgram(triangles: job.triangles, textureMap: textureMap, image: image)
                            .execute(with: self)
                    } else {
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
    
    private func groupEnqueuedWork() -> [(program: WebRendererProgram, triangles: [RenderTriangle])] {
        var batches: [(WebRendererProgram, [RenderTriangle])] = []
        var lastTextureId: TextureId?
        var currentBatch: [RenderTriangle] = []
        
        for triangle in queuedTriangles.sorted(by: { $0.zIndex < $1.zIndex }) {
            if lastTextureId == triangle.textureId {
                currentBatch.append(triangle)
            } else {
                //append last batch
                let batchProgram: WebRendererProgram = (lastTextureId == nil ? .color : .texture)
                batches.append((batchProgram, currentBatch))
                //prepare new batch
                lastTextureId = triangle.textureId
                currentBatch = []
                currentBatch.append(triangle)
            }
        }
        
        // append remaining from last batch
        if let triangle = currentBatch.first {
            let batchProgram: WebRendererProgram = (triangle.textureId == nil ? .color : .texture)
            batches.append((batchProgram, currentBatch))
        }
        
        return batches
    }
}

extension WebRenderer: Renderer {
    public var cameraFrame: Rect {
        Rect(center: cameraPosition, size: size)
    }
    
    public func setCameraPosition(_ position: Point) {
        cameraPosition = position
    }
    
    public func clearTriangleQueue() {
        queuedTriangles.removeAll()
    }
    public func enqueueTriangles(_ triangles: [RenderTriangle]) {
        queuedTriangles.append(contentsOf: triangles)
    }
}

extension RenderTriangle {
    var textureId: TextureId? {
        switch fragmentType {
        case .texture(let id, _):
            return id
        case .color:
            return nil
        }
    }
}
