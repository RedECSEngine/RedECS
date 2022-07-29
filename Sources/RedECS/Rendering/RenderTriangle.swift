import Geometry

public struct RenderTriangle {
    public enum FragmentType {
        case color(Color)
        case texture(TextureId, Triangle)
    }
    
    public let triangle: Triangle
    public let fragmentType: FragmentType
    public let zIndex: Int
    
    public init(
        triangle: Triangle,
        fragmentType: FragmentType,
        zIndex: Int = 0
    ) {
        self.triangle = triangle
        self.fragmentType = fragmentType
        self.zIndex = zIndex
    }
}
