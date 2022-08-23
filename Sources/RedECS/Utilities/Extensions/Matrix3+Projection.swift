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
}
