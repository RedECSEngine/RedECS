import Foundation

public struct PendingGameEffect<State: GameState, Action: Equatable> {
    public var outstandingActions: [Action]
    public let effect: GameEffect<State, Action>
    
    public init(
        outstandingActions: [Action],
        effect: GameEffect<State, Action>
    ) {
        self.outstandingActions = outstandingActions
        self.effect = effect
    }
    
    public init(
        outstandingAction: Action,
        effect: GameEffect<State, Action>
    ) {
        self.outstandingActions = [outstandingAction]
        self.effect = effect
    }
    
    public mutating func evaluateCompleteness(_ action: Action) -> Bool {
        guard let index = outstandingActions.firstIndex(where: { $0 == action }) else { return false }
        outstandingActions.remove(at: index)
        if outstandingActions.isEmpty {
            return true
        } else {
            return false
        }
    }
    
    public func map<S: GameState, A>(
        stateTransform: WritableKeyPath<S, State>,
        actionTransform: @escaping (Action) -> A
    ) -> PendingGameEffect<S, A> {
        .init(
            outstandingActions: outstandingActions.map(actionTransform),
            effect: effect.map(stateTransform: stateTransform, actionTransform: actionTransform)
        )
    }
}
