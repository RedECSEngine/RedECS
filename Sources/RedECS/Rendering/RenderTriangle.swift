import Geometry
import GeometryAlgorithms

public struct RenderTriangle {
    public enum FragmentType {
        case color(Color)
        case texture(TextureId, Triangle)
    }
    
    public let triangle: Triangle
    public let fragmentType: FragmentType
    public let transformMatrix: Matrix3
    public let zIndex: Int
    
    public init(
        triangle: Triangle,
        fragmentType: FragmentType,
        transformMatrix: Matrix3,
        zIndex: Int = 0
    ) {
        self.triangle = triangle
        self.fragmentType = fragmentType
        self.transformMatrix = transformMatrix
        self.zIndex = zIndex
    }
}
