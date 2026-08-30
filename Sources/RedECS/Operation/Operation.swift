public protocol Operation: Codable & Equatable {
    associatedtype Action: Equatable & Codable
    
    var currentTime: Double { get }
    var duration: Double { get }
    var isComplete: Bool { get }
    
    mutating func run<State: BasicOperationCapableState>(
        id: EntityId,
        state: inout State,
        delta: Double
    ) -> GameEffect<State, Action>
    
    mutating func reset()
}

public extension Operation {
    static var InstantDuration: Double { 0 }
    static var InfiniteDuration: Double { -1 }
}
