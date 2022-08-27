import RedECS
import Geometry

public struct OpacityOperation: Operation {
    public typealias Action = Int
    
    public enum Strategy: Equatable, Codable {
        case by(Double) // degrees
        case to(Double)
    }
    
    public var strategy: Strategy
    public var amount: Double = 0
    public var duration: Double
    public var currentTime: Double = 0
    
    public var isComplete: Bool { currentTime >= duration }
    
    public init(
        strategy: Strategy,
        duration: Double,
        currentTime: Double = 0
    ) {
        self.strategy = strategy
        self.duration = duration
        self.currentTime = currentTime
    }
    
    public mutating func run(
        id: EntityId,
        state: inout BasicOperationComponentContext,
        delta: Double
    ) -> GameEffect<BasicOperationComponentContext, Action> {
        if currentTime == 0 {
            switch strategy {
            case .by(let amount):
                self.amount = amount
            case .to(let opacity):
                let current = (state.sprite[id]?.opacity ?? 0)
                if opacity > current {
                    self.amount = opacity - current
                } else {
                    self.amount = -(current - opacity)
                }
            }
        }
        
        let percentage = delta / duration
        let opacityIncrement = amount * percentage
        state.sprite[id]?.opacity += opacityIncrement
        currentTime += delta
        return .none
    }
    
    public mutating func reset() {
        currentTime = 0
    }
}
