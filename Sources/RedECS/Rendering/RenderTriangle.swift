import Geometry
import GeometryAlgorithms

public struct RenderGroup {
    public enum FragmentType {
        case color(Color)
        case texture(TextureId)
    }
    
    public let triangles: [RenderTriangle]
    public let transformMatrix: Matrix3
    public let fragmentType: FragmentType
    public let zIndex: Int
    public let opacity: Double
    
    public init(
        triangles: [RenderTriangle],
        transformMatrix: Matrix3,
        fragmentType: FragmentType,
        zIndex: Int,
        opacity: Double = 1
    ) {
        self.triangles = triangles
        self.transformMatrix = transformMatrix
        self.fragmentType = fragmentType
        self.zIndex = zIndex
        self.opacity = opacity
    }
}

public extension RenderGroup {
    var textureId: TextureId? {
        switch fragmentType {
        case .texture(let id):
            return id
        case .color:
            return nil
        }
    }
    
    var color: Color? {
        switch fragmentType {
        case .texture:
            return nil
        case .color(let color):
            return color
        }
    }
}

public struct RenderTriangle {

    public let triangle: Triangle
    public let textureTriangle: Triangle?
    
    public init(
        triangle: Triangle,
        textureTriangle: Triangle? = nil
    ) {
        self.triangle = triangle
        self.textureTriangle = textureTriangle
    }
}

public extension RenderTriangle {
    static var noTextureTriangle: Triangle {
        Triangle(a: .init(x: -1, y: -1), b: .init(x: -1, y: -1), c: .init(x: -1, y: -1))
    }
}
