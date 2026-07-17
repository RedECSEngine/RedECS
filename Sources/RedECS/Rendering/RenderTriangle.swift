import Geometry
import GeometryAlgorithms

public struct RenderGroup {
    public enum FragmentType {
        case color(Color)
        case texture(TextureId)
    }

    /// Which projection the renderer applies to this group's vertices.
    /// `.world` goes through the primary camera; `.screen` maps viewport
    /// points (top-left origin, y-down) straight to clip space and always
    /// draws above all world groups.
    public enum ProjectionSpace {
        case world
        case screen
    }

    public let triangles: [RenderTriangle]
    public let transformMatrix: Matrix3
    public let fragmentType: FragmentType
    public let zIndex: Int
    public let opacity: Double
    public let projectionSpace: ProjectionSpace

    public init(
        triangles: [RenderTriangle],
        transformMatrix: Matrix3,
        fragmentType: FragmentType,
        zIndex: Int,
        opacity: Double = 1,
        projectionSpace: ProjectionSpace = .world
    ) {
        self.triangles = triangles
        self.transformMatrix = transformMatrix
        self.fragmentType = fragmentType
        self.zIndex = zIndex
        self.opacity = opacity
        self.projectionSpace = projectionSpace
    }
}

public extension RenderGroup {
    /// A copy of this group with a different model matrix; used to reparent
    /// a group into an ancestor's coordinate frame.
    func withTransformMatrix(_ matrix: Matrix3) -> RenderGroup {
        RenderGroup(
            triangles: triangles,
            transformMatrix: matrix,
            fragmentType: fragmentType,
            zIndex: zIndex,
            opacity: opacity,
            projectionSpace: projectionSpace
        )
    }

    /// A copy of this group re-slotted into a draw-order position and
    /// projection space; used when assembling screen-space HUD output.
    func with(zIndex: Int, projectionSpace: ProjectionSpace) -> RenderGroup {
        RenderGroup(
            triangles: triangles,
            transformMatrix: transformMatrix,
            fragmentType: fragmentType,
            zIndex: zIndex,
            opacity: opacity,
            projectionSpace: projectionSpace
        )
    }

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
