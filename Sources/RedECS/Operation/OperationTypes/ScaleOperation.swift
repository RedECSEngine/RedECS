import Geometry

public struct ScaleOperation: OperationPayload {
    public static var operationTypeId: OperationTypeId { "engine.scale" }

    public enum Strategy: Equatable, Codable {
        case by(Point)
        case to(Point)
    }
    
    
    public var strategy: Strategy
    public var amount: Point = .zero
    public var duration: Double
    public var currentTime: Double = 0
    
    public var isComplete: Bool { currentTime >= duration }
    
    public init(strategy: Strategy, duration: Double, currentTime: Double = 0) {
        self.strategy = strategy
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
            case .by(let point):
                self.amount = point
            case .to(let point):
                let scale = state.transform[id]?.scale ?? .zero
                self.amount = point - scale
            }
        }
        
        // Clamp this step to the time actually remaining so a sub-frame
        // `duration` (delta > duration) can't drive `percentage` past 1 and
        // overshoot the target. A `.to` operation then lands exactly on its
        // target on the completing frame instead of flying past it.
        let remaining = max(0, duration - currentTime)
        let step = min(delta, remaining)
        let percentage = duration > 0 ? step / duration : 1
        let scaleIncrement = amount * percentage
        state.transform[id]?.scale += scaleIncrement
        currentTime += delta
    }
    
    public mutating func reset() {
        currentTime = 0
    }
}
