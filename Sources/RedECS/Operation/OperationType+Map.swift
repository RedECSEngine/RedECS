public extension OperationType {
    func map<NewAction: Equatable & Codable>(_ transform: (GameAction) -> NewAction) -> OperationType<NewAction> {
        switch self {
        case .move(let op): return .move(op)
        case .jump(let op): return .jump(op)
        case .followPath(let op): return .followPath(op)
        case .speed(let op): return .speed(op.map(transform))
        case .rotate(let op): return .rotate(op)
        case .scale(let op): return .scale(op)
        case .wait(let op): return .wait(op)
        case .animate(let op): return .animate(op)
        case .opacity(let op): return .opacity(op)
        case .visibility(let op): return .visibility(op)
        case .shaderEffect(let op): return .shaderEffect(op)
        case .subtreeShader(let op): return .subtreeShader(op)
        case .repeat(let op): return .repeat(op.map(transform))
        case .sequence(let op): return .sequence(op.map(transform))
        case .group(let op): return .group(op.map(transform))
        case .call(let op): return .call(op.map(transform))
        case .timing(let op): return .timing(op.map(transform))
        case .removeEntity(let op): return .removeEntity(op.map(transform))
        case .sound(let op): return .sound(op.map(transform))
        }
    }
}

public extension SpeedOperation {
    func map<NewAction: Equatable & Codable>(_ transform: (GameAction) -> NewAction) -> SpeedOperation<NewAction> {
        var mapped = SpeedOperation<NewAction>(multiplier: multiplier, operation: operation.map(transform))
        mapped.currentTime = currentTime
        return mapped
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

public extension SoundOperation {
    func map<NewAction: Equatable & Codable>(_ transform: (GameAction) -> NewAction) -> SoundOperation<NewAction> {
        let mappedStrategy: SoundOperation<NewAction>.Strategy
        switch strategy {
        case .play(let sound): mappedStrategy = .play(sound)
        case .stop(let sound): mappedStrategy = .stop(sound)
        case .stopAll: mappedStrategy = .stopAll
        }
        var mapped = SoundOperation<NewAction>(strategy: mappedStrategy)
        mapped.duration = duration
        mapped.currentTime = currentTime
        mapped.isComplete = isComplete
        return mapped
    }
}
