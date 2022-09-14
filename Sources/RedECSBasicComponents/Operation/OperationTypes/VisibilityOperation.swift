import RedECS
import Geometry

public struct VisibilityOperation: Operation {
    public typealias Action = Int
    
    public enum Strategy: Equatable, Codable {
        case show
        case hide
        case toggle
    }
    
    public var strategy: Strategy
    public var currentTime: Double = 0
    public var duration: Double { Self.InstantDuration }
    public var isComplete: Bool = false
    
    public init(strategy: Strategy) {
        self.strategy = strategy
    }
    
    public mutating func run(
        id: EntityId,
        state: inout BasicOperationComponentContext,
        delta: Double
    ) -> GameEffect<BasicOperationComponentContext, Action> {
        guard !isComplete else { return .none }
        isComplete = true
        switch strategy {
        case .hide:
            state.transform[id]?.isHidden = true
        case .show:
            state.transform[id]?.isHidden = false
        case .toggle:
            state.transform[id]?.isHidden.toggle()
        }
        return .none
    }
    
    public mutating func reset() {
        currentTime = 0
        isComplete = false
    }
}
