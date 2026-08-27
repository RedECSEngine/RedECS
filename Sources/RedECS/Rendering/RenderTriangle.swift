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
    public let shader: ShaderEffect? // which fragment effect draws this group; nil = passthrough
    /// Set by scrolling/clipping containers; the renderer applies it as a scissor. . `nil` draws unclipped.
    public let clipRect: Rect?

    public init(
        triangles: [RenderTriangle],
        transformMatrix: Matrix3,
        fragmentType: FragmentType,
        zIndex: Int,
        opacity: Double = 1,
        projectionSpace: ProjectionSpace = .world,
        shader: ShaderEffect? = nil,
        clipRect: Rect? = nil
    ) {
        self.triangles = triangles
        self.transformMatrix = transformMatrix
        self.fragmentType = fragmentType
        self.zIndex = zIndex
        self.opacity = opacity
        self.projectionSpace = projectionSpace
        self.shader = shader
        self.clipRect = clipRect
    }
}

public extension Array where Element == RenderGroup {
    func sortedForDrawing() -> [RenderGroup] {
        enumerated()
            .sorted { a, b in
                if a.element.projectionSpace != b.element.projectionSpace {
                    return a.element.projectionSpace == .world
                }
                if a.element.zIndex != b.element.zIndex {
                    return a.element.zIndex < b.element.zIndex
                }
                return a.offset < b.offset
            }
            .map(\.element)
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
            projectionSpace: projectionSpace,
            shader: shader, // reparenting must keep the effect, e.g. a nested hero sprite
            clipRect: clipRect
        )
    }

    /// A copy of this group at a different opacity.
    func withOpacity(_ opacity: Double) -> RenderGroup {
        RenderGroup(
            triangles: triangles,
            transformMatrix: transformMatrix,
            fragmentType: fragmentType,
            zIndex: zIndex,
            opacity: opacity,
            projectionSpace: projectionSpace,
            shader: shader, // preserve the effect across the copy
            clipRect: clipRect
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
            projectionSpace: projectionSpace,
            shader: shader, // preserve the effect when re-slotting into HUD draw order
            clipRect: clipRect
        )
    }

    /// A copy carrying `clipRect` verbatim (used when translating a clip as a
    /// subtree is reparented). Prefer `applyingClip` to establish a clip.
    func withClipRect(_ clipRect: Rect?) -> RenderGroup {
        RenderGroup(
            triangles: triangles,
            transformMatrix: transformMatrix,
            fragmentType: fragmentType,
            zIndex: zIndex,
            opacity: opacity,
            projectionSpace: projectionSpace,
            shader: shader,
            clipRect: clipRect
        )
    }

    /// A copy clipped to `rect` (in this group's post-projection space),
    /// intersecting with any clip already present so nested clips compound.
    func applyingClip(_ rect: Rect) -> RenderGroup {
        let clipped = clipRect.map { intersection($0, rect) } ?? rect
        return RenderGroup(
            triangles: triangles,
            transformMatrix: transformMatrix,
            fragmentType: fragmentType,
            zIndex: zIndex,
            opacity: opacity,
            projectionSpace: projectionSpace,
            shader: shader,
            clipRect: clipped
        )
    }

    func withShader(_ shader: ShaderEffect?) -> RenderGroup {
        RenderGroup(
            triangles: triangles,
            transformMatrix: transformMatrix,
            fragmentType: fragmentType,
            zIndex: zIndex,
            opacity: opacity,
            projectionSpace: projectionSpace,
            shader: shader,
            clipRect: clipRect
        )
    }

    func withZIndexOffset(_ offset: Int) -> RenderGroup {
        RenderGroup(
            triangles: triangles,
            transformMatrix: transformMatrix,
            fragmentType: fragmentType,
            zIndex: zIndex + offset,
            opacity: opacity,
            projectionSpace: projectionSpace,
            shader: shader,
            clipRect: clipRect
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

/// Overlap of two rects (empty if they don't overlap). Local to clipping;
/// kept here rather than in Geometry to avoid touching that upstream package.
func intersection(_ a: Rect, _ b: Rect) -> Rect {
    let minX = max(a.minX, b.minX)
    let minY = max(a.minY, b.minY)
    let maxX = min(a.maxX, b.maxX)
    let maxY = min(a.maxY, b.maxY)
    return Rect(x: minX, y: minY, width: max(0, maxX - minX), height: max(0, maxY - minY))
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
