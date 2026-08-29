import Geometry

/// A parabolic jump, ported from cocos2d's `CCActionJumpBy` / `CCActionJumpTo`.
///
/// Like `MoveOperation`, the horizontal (and any linear vertical) translation is
/// described by a single `delta`, resolved from the `Strategy`:
/// - `.by(delta)`  — jump *by* an offset relative to the current position.
/// - `.to(point)`  — jump *to* an absolute position (delta = point - current).
///
/// On top of that translation, `height` adds a parabolic arc that peaks `jumps`
/// times over the duration. `CCJumpTo` is a subclass of `CCJumpBy` in cocos2d;
/// here both are the one operation, distinguished only by how `delta` is resolved.
public struct JumpOperation: OperationPayload {
    public static var operationTypeId: OperationTypeId { "engine.jump" }


    public enum Strategy: Equatable, Codable {
        case by(Point)
        case to(Point)
    }

    public var strategy: Strategy
    public var height: Double
    public var jumps: Int
    public var duration: Double
    public var currentTime: Double = 0

    /// Resolved translation (see `Strategy`), computed once at `currentTime == 0`.
    public var delta: Point = .zero
    /// The parabolic offset applied on the previous frame. Positions are mutated
    /// incrementally, so each frame we apply the difference against this.
    public var previousOffset: Point = .zero

    public var isComplete: Bool { currentTime >= duration }

    public init(
        strategy: Strategy,
        height: Double,
        jumps: Int = 1,
        duration: Double,
        currentTime: Double = 0
    ) {
        self.strategy = strategy
        self.height = height
        self.jumps = jumps
        self.duration = duration
        self.currentTime = currentTime
    }

    public mutating func run<S: TransformProviding>(
        id: EntityId,
        state: inout S,
        delta: Double
    ) {
        if currentTime == 0 {
            switch strategy {
            case .by(let amount):
                self.delta = amount
            case .to(let location):
                let currentPos = (state.transform[id]?.position ?? .zero)
                self.delta = location.diffOf(currentPos)
            }
            previousOffset = .zero
        }

        currentTime += delta
        // Normalized progress through the jump, clamped so the final frame lands
        // exactly on `delta` (parabola returns to 0 at whole `jumps`).
        let t = min(currentTime / duration, 1)

        // Parabolic jump (matches cocos2d's CCActionJumpBy.update):
        //   frac = (t * jumps) mod 1
        //   y    = height * 4 * frac * (1 - frac) + delta.y * t
        //   x    = delta.x * t
        let frac = (t * Double(jumps)).truncatingRemainder(dividingBy: 1.0)
        let offset = Point(
            x: self.delta.x * t,
            y: height * 4 * frac * (1 - frac) + self.delta.y * t
        )

        state.transform[id]?.position += offset - previousOffset
        previousOffset = offset
    }

    public mutating func reset() {
        currentTime = 0
        previousOffset = .zero
    }
}
