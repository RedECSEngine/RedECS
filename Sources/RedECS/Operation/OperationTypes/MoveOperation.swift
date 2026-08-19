import Geometry

public struct MoveOperation: OperationPayload {
    public static var operationTypeId: OperationTypeId { "engine.move" }

    
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
            case .by(let amount):
                self.amount = amount
            case .to(let location):
                let currentPos = (state.transform[id]?.position ?? .zero)
                self.amount = location.diffOf(currentPos)
            }
        }
        
        let percentage = delta / duration
        let moveByIncrement = amount * percentage
        state.transform[id]?.position += moveByIncrement
        currentTime += delta
    }
    
    public mutating func reset() {
        currentTime = 0
    }
}
