import Geometry
import GeometryAlgorithms

public protocol Renderer: AnyObject {
    var viewportSize: Size { get }
    var queuedWork: [RenderGroup] { get set }
    
    func setProjectionMatrix(_ matrix: Matrix3)
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
