import Geometry

public struct FollowPathOperation: Operation {
    public typealias Action = Int

    public var path: [Point]
    public var remaining: [Point]
    public var speed: Double
    public var proximityVariance: Double
    public var currentTime: Double = 0

    public var duration: Double { Self.InfiniteDuration }
    public var isComplete: Bool { remaining.isEmpty }

    public init(
        path: [Point],
        speed: Double = 1,
        proximityVariance: Double = 1
    ) {
        self.path = path
        self.remaining = path
        self.speed = speed
        self.proximityVariance = proximityVariance
    }

    public mutating func run(
        id: EntityId,
        state: inout BasicOperationComponentContext,
        delta: Double
    ) -> GameEffect<BasicOperationComponentContext, Action> {
        guard let target = remaining.first else { return .none }
        guard let position = state.transform[id]?.position,
              let movement = state.movement[id] else {
            remaining = []
            return .none
        }

        currentTime += delta

        let stepSize = movement.travelSpeed * speed * delta
        if position.distanceFrom(target) <= max(proximityVariance, stepSize) {
            state.transform[id]?.position = target
            state.movement[id]?.velocity = .zero
            remaining.removeFirst()
            return .none
        }

        let diffPos = position.diffOf(target)
        let maxDirectionalDistance = max(abs(diffPos.x), abs(diffPos.y))
        var velocity: Point = .zero
        velocity.x -= diffPos.x != 0 ? max(min(diffPos.x / maxDirectionalDistance, 1), -1) : 0
        velocity.y -= diffPos.y != 0 ? max(min(diffPos.y / maxDirectionalDistance, 1), -1) : 0
        state.movement[id]?.velocity = velocity * speed

        return .none
    }

    public mutating func reset() {
        currentTime = 0
        remaining = path
    }
}
