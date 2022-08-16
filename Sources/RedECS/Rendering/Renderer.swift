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
}
