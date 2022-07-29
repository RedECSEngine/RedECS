import Geometry

public protocol Renderer {
    var cameraFrame: Rect { get }
    
    func setCameraPosition(_ position: Point)
    func clearTriangleQueue()
    func enqueueTriangles(_ triangles: [RenderTriangle])
}
