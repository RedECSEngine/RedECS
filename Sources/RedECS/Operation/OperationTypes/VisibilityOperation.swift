import Geometry

public struct VisibilityOperation: OperationPayload {
    public static var operationTypeId: OperationTypeId { "engine.visibility" }

    
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
    
    public mutating func run<S: TransformProviding>(
        id: EntityId,
        state: inout S,
        delta: Double
    ) {
        guard !isComplete else { return }
        isComplete = true
        switch strategy {
        case .hide:
            state.transform[id]?.isHidden = true
        case .show:
            state.transform[id]?.isHidden = false
        case .toggle:
            state.transform[id]?.isHidden.toggle()
        }
    }
    
    public mutating func reset() {
        currentTime = 0
        isComplete = false
    }
}
