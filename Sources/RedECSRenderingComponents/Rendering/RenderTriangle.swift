import Geometry

public struct RenderTriangle {
    public enum FragmentType {
        case color(Color)
        case texture(TextureId, Triangle)
    }
    
    public let triangle: Triangle
    public let fragmentType: FragmentType
    
    public init(
        triangle: Triangle,
        fragmentType: FragmentType
    ) {
        self.triangle = triangle
        self.fragmentType = fragmentType
    }
}
