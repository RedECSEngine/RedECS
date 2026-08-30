import Geometry
import GeometryAlgorithms

public extension Matrix3 {
    static func projection(
        rect: Rect,
        zoom: Double = 1
    ) -> Matrix3 {
        Matrix3.identity
            .scaledBy(sx: 1, sy: -1) // y flip
            .translatedBy(tx: -1, ty: 1) // translating from -1 to 1
            .scaledBy(sx: 2 / rect.size.width, sy: -2 / rect.size.height) // viewport size
            .scaledBy(sx: zoom, sy: zoom) // camera scale
            .translatedBy(
                tx: (rect.size.width/2 / zoom) - rect.center.x,
                ty: (rect.size.height/2 / zoom) - rect.center.y
            ) // camera position
    }

    /// Projection for `RenderGroup.ProjectionSpace.screen` groups: maps
    /// viewport points with a top-left origin and y pointing down to clip
    /// space, independent of any camera. (0,0) is the top-left corner of
    /// the screen; (size.width, size.height) the bottom-right.
    static func screenProjection(size: Size) -> Matrix3 {
        Matrix3.identity
            .translatedBy(tx: -1, ty: 1)
            .scaledBy(sx: 2 / size.width, sy: -2 / size.height)
    }
}
