import Geometry
import GeometryAlgorithms

public extension Matrix3 {
    /// Flips engine geometry authored **y-up** — bitmap glyph quads and
    /// texture quads both arrive that way — into the HUD's **y-down** local
    /// space, scaling native units up to the rendered size. The content's top
    /// edge lands at the local origin. Shared by the `Text` and `Sprite`
    /// leaves; this is leaf-internal (engine → local) and unrelated to the
    /// screen/world boundary flip, which lives in `WorldSpace`.
    static func flippingYUpToLocal(height: Double, scale: Double = 1) -> Matrix3 {
        Matrix3.identity
            .scaledBy(sx: scale, sy: scale)
            .translatedBy(tx: 0, ty: height)
            .scaledBy(sx: 1, sy: -1)
    }
}
