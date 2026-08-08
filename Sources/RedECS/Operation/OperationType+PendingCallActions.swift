public extension OperationType {
    var pendingCallActions: [GameAction] {
        switch self {
        case .call(let call):
            return call.isComplete ? [] : [call.action]
        case .sequence(let sequence):
            guard sequence.currentOperationIndex < sequence.operations.count else { return [] }
            return sequence.operations[sequence.currentOperationIndex...]
                .flatMap(\.pendingCallActions)
        case .group(let group):
            return group.operations.flatMap(\.pendingCallActions)
        case .repeat(let repeatOperation):
            return repeatOperation.isComplete ? [] : repeatOperation.operation.pendingCallActions
        case .timing(let timing):
            return timing.operation.pendingCallActions
        case .speed(let speed):
            return speed.operation.pendingCallActions
        case .move, .jump, .followPath, .rotate, .scale, .wait, .animate,
             .opacity, .visibility, .removeEntity, .shaderEffect, .sound:
            return []
        }
    }
}
