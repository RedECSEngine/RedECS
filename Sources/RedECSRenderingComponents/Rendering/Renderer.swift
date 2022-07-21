import Geometry

public protocol Renderer {
    func clearTriangleQueue()
    func enqueueTriangles(_ triangles: [RenderTriangle])
}
