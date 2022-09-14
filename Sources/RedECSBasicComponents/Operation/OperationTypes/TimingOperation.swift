import RedECS
import Geometry

public struct TimingOperation<GameAction: Equatable & Codable>: Operation {
    public typealias Action = GameAction
    
    public enum Strategy: Equatable, Codable {
        case easeIn
        case easeOut
        case easeInOut
    }
    
    public var strategy: Strategy
    public var operation: OperationType<GameAction>
    public var duration: Double
    public var currentTime: Double = 0
    
    public var previousPercentage: Double = 0
    
    public var isComplete: Bool { currentTime >= duration }
    
    public init(strategy: Strategy, operation: OperationType<GameAction>) {
        self.strategy = strategy
        self.operation = operation
        self.duration = operation.duration
    }
    
    public mutating func run(id: EntityId, state: inout BasicOperationComponentContext, delta: Double) -> GameEffect<BasicOperationComponentContext, Action> {
        
        let adjustedPercent = strategy.timing(currentTime / duration + delta / duration)
        let deltaPercent = adjustedPercent - previousPercentage
        let effect = operation.run(id: id, state: &state, delta: deltaPercent * duration)
        previousPercentage = adjustedPercent
        
        currentTime += delta
        
        return effect
    }
    
    public mutating func reset() {
        currentTime = 0
        previousPercentage = 0
        operation.reset()
    }
}

public extension TimingOperation.Strategy {
    func timing(_ t: Double) -> Double {
        switch self {
        case .easeIn:
            return easeIn(t)
        case .easeOut:
            return easeOut(t)
        case .easeInOut:
            return lerp(easeIn(t), easeOut(t), t)
        }
    }
    
    func easeIn(_ t: Double) -> Double {
        square(t)
    }
    
    func easeOut(_ t: Double) -> Double {
        flip(square(flip(t)))
    }
    
    func flip(_ t: Double) -> Double {
       1 - t
    }
    
    func square(_ t: Double) -> Double {
        t * t
    }
    
    func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        ((b - a) * t) + a
    }
}
