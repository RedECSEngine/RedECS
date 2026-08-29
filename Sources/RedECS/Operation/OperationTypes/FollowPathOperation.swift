import Geometry

public struct FollowPathOperation: OperationPayload {
    public static var operationTypeId: OperationTypeId { "engine.followPath" }


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

    public mutating func run<S: TransformProviding>(
        id: EntityId,
        state: inout S,
        delta: Double
    ) {
        guard currentIndex < path.count else { return }
        guard let position = state.transform[id]?.position else {
            currentIndex = path.count
            return
        }

        currentTime += delta

        let target = path[currentIndex]
        let distance = position.distanceFrom(target)
        let step = travelSpeed * delta
        if distance <= max(proximityVariance, step) {
            state.transform[id]?.position = target
            currentIndex += 1
            return
        }

        let direction = target.diffOf(position) / distance
        state.transform[id]?.position = position + direction * step
    }

    public mutating func reset() {
        currentTime = 0
        currentIndex = 0
    }
}
