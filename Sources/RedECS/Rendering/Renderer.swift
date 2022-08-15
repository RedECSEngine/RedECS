import Geometry

public protocol Renderer: AnyObject {
    var cameraFrame: Rect { get }
    var queuedWork: [RenderGroup] { get set }
    
    func setCameraPosition(_ position: Point)
    func clearQueue()
    func enqueue(_ work: [RenderGroup])
}

public enum RendererProgram {
    case color
    case texture
}

public extension Renderer {
    func clearQueue() {
        queuedWork.removeAll()
    }
    
    func enqueue(_ work: [RenderGroup]) {
        queuedWork.append(contentsOf: work)
    }
    
//    func groupEnqueuedWork() -> [(program: RendererProgram, triangles: [RenderTriangle])] {
//        var batches: [(RendererProgram, [RenderTriangle])] = []
//        var lastTextureId: TextureId?
//        var currentBatch: [RenderTriangle] = []
//
//        for triangle in queuedTriangles.sorted(by: { $0.zIndex < $1.zIndex }) {
//            if lastTextureId == triangle.textureId {
//                currentBatch.append(triangle)
//            } else {
//                //append last batch
//                let batchProgram: RendererProgram = (lastTextureId == nil ? .color : .texture)
//                batches.append((batchProgram, currentBatch))
//                //prepare new batch
//                lastTextureId = triangle.textureId
//                currentBatch = []
//                currentBatch.append(triangle)
//            }
//        }
//
//        // append remaining from last batch
//        if let triangle = currentBatch.first {
//            let batchProgram: RendererProgram = (triangle.textureId == nil ? .color : .texture)
//            batches.append((batchProgram, currentBatch))
//        }
//
//        return batches
//    }
}
