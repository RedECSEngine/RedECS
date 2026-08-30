import Geometry

public struct FollowPathOperation: Operation {
    public typealias Action = Int

    public var path: [Point]
    public var currentIndex: Int = 0
    public var travelSpeed: Double
    public var proximityVariance: Double
    public var currentTime: Double = 0

    public var duration: Double { Self.InfiniteDuration }
    public var isComplete: Bool { currentIndex >= path.count }

    public init(
        path: [Point],
        travelSpeed: Double,
        proximityVariance: Double = 1
    ) {
        self.path = path
        self.travelSpeed = travelSpeed
        self.proximityVariance = proximityVariance
    }

    public mutating func run<State: BasicOperationCapableState>(
        id: EntityId,
        state: inout State,
        delta: Double
    ) -> GameEffect<State, Action> {
        guard currentIndex < path.count else { return .none }
        guard let position = state.transform[id]?.position else {
            currentIndex = path.count
            return .none
        }

        currentTime += delta

        let target = path[currentIndex]
        let distance = position.distanceFrom(target)
        let step = travelSpeed * delta
        if distance <= max(proximityVariance, step) {
            state.transform[id]?.position = target
            currentIndex += 1
            return .none
        }

        let direction = target.diffOf(position) / distance
        state.transform[id]?.position = position + direction * step
        return .none
    }

    public mutating func reset() {
        currentTime = 0
        currentIndex = 0
    }
}
