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
    public private(set) var canvasElement: JSValue = .undefined
    public private(set) var glContext: JSValue = .undefined
    
    private var queuedTriangles: [RenderTriangle] = []
    
    public init(size: Size) {
        self.size = size
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
            let work = groupEnqueuedWork()
            for job in work {
                switch job.program {
                case .color:
                    try DrawTrianglesProgram(triangles: queuedTriangles).execute(with: self)
                case .texture:
                    fatalError("not implemented")
                }
            }
        } catch {
            print("⚠️ Draw error:", error)
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
    
    private func groupEnqueuedWork() -> [(program: WebRendererProgram, triangles: [RenderTriangle])] {
        var batches: [(WebRendererProgram, [RenderTriangle])] = []
        
        var lastTextureId: TextureId?
        var currentBatch: [RenderTriangle] = []
        
        for triangle in queuedTriangles {
            if lastTextureId == triangle.textureId {
                currentBatch.append(triangle)
            } else {
                let batchProgram: WebRendererProgram = (triangle.textureId == nil ? .color : .texture)
                batches.append((batchProgram, currentBatch))
                
                lastTextureId = triangle.textureId
                currentBatch = []
                currentBatch.append(triangle)
            }
        }
        
        return batches
    }
}

extension WebRenderer: Renderer {
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
