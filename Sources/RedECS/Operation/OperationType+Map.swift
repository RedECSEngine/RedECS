public extension OperationType {
    func map<NewAction: Equatable & Codable>(_ transform: (GameAction) -> NewAction) -> OperationType<NewAction> {
        switch self {
        case .move(let op): return .move(op)
        case .jump(let op): return .jump(op)
        case .rotate(let op): return .rotate(op)
        case .scale(let op): return .scale(op)
        case .wait(let op): return .wait(op)
        case .animate(let op): return .animate(op)
        case .opacity(let op): return .opacity(op)
        case .visibility(let op): return .visibility(op)
        case .shaderEffect(let op): return .shaderEffect(op)
        case .repeat(let op): return .repeat(op.map(transform))
        case .sequence(let op): return .sequence(op.map(transform))
        case .group(let op): return .group(op.map(transform))
        case .call(let op): return .call(op.map(transform))
        case .timing(let op): return .timing(op.map(transform))
        case .removeEntity(let op): return .removeEntity(op.map(transform))
        case .playSound(let op): return .playSound(op.map(transform))
        }
    }
}

public extension CallOperation {
    func map<NewAction: Equatable & Codable>(_ transform: (GameAction) -> NewAction) -> CallOperation<NewAction> {
        var mapped = CallOperation<NewAction>(action: transform(action))
        mapped.currentTime = currentTime
        mapped.isComplete = isComplete
        return mapped
    }
}

public extension SequenceOperation {
    func map<NewAction: Equatable & Codable>(_ transform: (GameAction) -> NewAction) -> SequenceOperation<NewAction> {
        var mapped = SequenceOperation<NewAction>(operations: operations.map { $0.map(transform) })
        mapped.currentTime = currentTime
        mapped.currentOperationIndex = currentOperationIndex
        return mapped
    }
}

public extension GroupOperation {
    func map<NewAction: Equatable & Codable>(_ transform: (GameAction) -> NewAction) -> GroupOperation<NewAction> {
        var mapped = GroupOperation<NewAction>(operations: operations.map { $0.map(transform) })
        mapped.currentTime = currentTime
        mapped.currentOperationCompletionCount = currentOperationCompletionCount
        return mapped
    }
}

public extension RepeatOperation {
    func map<NewAction: Equatable & Codable>(_ transform: (GameAction) -> NewAction) -> RepeatOperation<NewAction> {
        let mappedStrategy: RepeatOperation<NewAction>.Strategy
        switch strategy {
        case .forever: mappedStrategy = .forever
        case .times(let times): mappedStrategy = .times(times)
        }
        var mapped = RepeatOperation<NewAction>(strategy: mappedStrategy, operation: operation.map(transform))
        mapped.totalTime = totalTime
        mapped.currentTime = currentTime
        mapped.isComplete = isComplete
        return mapped
    }
}

public extension TimingOperation {
    func map<NewAction: Equatable & Codable>(_ transform: (GameAction) -> NewAction) -> TimingOperation<NewAction> {
        let mappedStrategy: TimingOperation<NewAction>.Strategy
        switch strategy {
        case .easeIn: mappedStrategy = .easeIn
        case .easeOut: mappedStrategy = .easeOut
        case .easeInOut: mappedStrategy = .easeInOut
        }
        var mapped = TimingOperation<NewAction>(strategy: mappedStrategy, operation: operation.map(transform))
        mapped.duration = duration
        mapped.currentTime = currentTime
        mapped.previousPercentage = previousPercentage
        return mapped
    }
}

public extension RemoveEntityOperation {
    func map<NewAction: Equatable & Codable>(_ transform: (GameAction) -> NewAction) -> RemoveEntityOperation<NewAction> {
        var mapped = RemoveEntityOperation<NewAction>(removeEntityId: removeEntityId)
        mapped.duration = duration
        mapped.currentTime = currentTime
        mapped.isComplete = isComplete
        return mapped
    }
}

public extension PlaySoundOperation {
    func map<NewAction: Equatable & Codable>(_ transform: (GameAction) -> NewAction) -> PlaySoundOperation<NewAction> {
        var mapped = PlaySoundOperation<NewAction>(sound: sound)
        mapped.duration = duration
        mapped.currentTime = currentTime
        mapped.isComplete = isComplete
        return mapped
    }
}
