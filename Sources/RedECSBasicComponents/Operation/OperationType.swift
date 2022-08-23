import RedECS
import Geometry

public indirect enum OperationType<GameAction: Equatable & Codable>: Codable & Equatable {
    case moveBy(MoveByOperation)
    case rotateBy(RotateByOperation)
    case wait(WaitOperation)
    case repeatForever(RepeatForeverOperation<GameAction>)
    case sequence(SequenceOperation<GameAction>)
    case group(GroupOperation<GameAction>)
    case call(CallOperation<GameAction>)
    
    public var isComplete: Bool {
        switch self {
        case .moveBy(let moveOperation):
            return moveOperation.isComplete
        case .rotateBy(let rotateOperation):
            return rotateOperation.isComplete
        case .wait(let waitOperation):
            return waitOperation.isComplete
        case .sequence(let sequenceOperation):
            return sequenceOperation.isComplete
        case .group(let groupOp):
            return groupOp.isComplete
        case .repeatForever(let repeatOp):
            return repeatOp.isComplete
        case .call(let callOp):
            return callOp.isComplete
        }
    }
    
    public mutating func run(
        id: EntityId,
        state: inout BasicOperationComponentContext,
        delta: Double
    ) -> GameEffect<BasicOperationComponentContext, GameAction> {
        switch self {
        case .wait(var wait):
            _ = wait.run(id: id, state: &state, delta: delta)
            self = .wait(wait)
            return .none
        case .rotateBy(var rotate):
            _ = rotate.run(id: id, state: &state, delta: delta)
            self = .rotateBy(rotate)
            return .none
        case .repeatForever(var rp):
            let effect = rp.run(id: id, state: &state, delta: delta)
            self = .repeatForever(rp)
            return effect
        case .moveBy(var move):
            _ = move.run(id: id, state: &state, delta: delta)
            self = .moveBy(move)
            return .none
        case .sequence(var sequence):
            let effect = sequence.run(id: id, state: &state, delta: delta)
            self = .sequence(sequence)
            return effect
        case .group(var group):
            let effect = group.run(id: id, state: &state, delta: delta)
            self = .group(group)
            return effect
        case .call(var call):
            let effect = call.run(id: id, state: &state, delta: delta)
            self = .call(call)
            return effect
        }
    }
    
    public mutating func reset() {
        switch self {
        case .wait(var wait):
            wait.reset()
            self = .wait(wait)
        case .rotateBy(var rotate):
            rotate.reset()
            self = .rotateBy(rotate)
        case .repeatForever(var rp):
            rp.reset()
            self = .repeatForever(rp)
        case .moveBy(var move):
            move.reset()
            self = .moveBy(move)
        case .sequence(var sequence):
            sequence.reset()
            self = .sequence(sequence)
        case .group(var group):
            group.reset()
            self = .group(group)
        case .call(var call):
            call.reset()
            self = .call(call)
        }
    }
    
    mutating func appendOperation(_ type: OperationType<GameAction>) {
        if case .sequence(var seq) = self {
            seq.operations.append(type)
            self = .sequence(seq)
        } else {
            self = .sequence(.init(operations: [self, type]))
        }
    }
}

public extension OperationType {
    static func sequence(_ operations: [OperationType<GameAction>]) -> Self {
        .sequence(SequenceOperation(operations: operations))
    }
    
    func sequence(_ operations: [OperationType<GameAction>]) -> Self {
        var component = self
        let op = SequenceOperation(operations: operations)
        component.appendOperation(.sequence(op))
        return component
    }
}


public extension OperationType {
    static func group(_ operations: [OperationType<GameAction>]) -> Self {
        .group(GroupOperation(operations: operations))
    }
    
    func group(_ operations: [OperationType<GameAction>]) -> Self {
        var component = self
        let op = GroupOperation(operations: operations)
        component.appendOperation(.group(op))
        return component
    }
}

public extension OperationType {
    static func moveBy(_ amount: Point, duration: Double) -> Self {
        .moveBy(MoveByOperation(moveBy: amount, duration: duration))
    }
    
    func moveBy(_ amount: Point, duration: Double) -> Self {
        var component = self
        let moveOp = MoveByOperation(moveBy: amount, duration: duration)
        component.appendOperation(.moveBy(moveOp))
        return component
    }
}


public extension OperationType {
    static func rotateBy(_ amount: Double, duration: Double) -> Self {
        .rotateBy(RotateByOperation(rotateBy: amount, duration: duration))
    }
    
    func rotateBy(_ amount: Double, duration: Double) -> Self {
        var component = self
        let rotateOp = RotateByOperation(rotateBy: amount, duration: duration)
        component.appendOperation(.rotateBy(rotateOp))
        return component
    }
}


public extension OperationType {
    static func wait(duration: Double) -> Self {
        .wait(WaitOperation(duration: duration))
    }
    
    func wait(duration: Double) -> Self {
        var component = self
        let waitOp = WaitOperation(duration: duration)
        component.appendOperation(.wait(waitOp))
        return component
    }
}

public extension OperationType {
    func repeatForever() -> Self {
        if case .repeatForever = self {
            return self
        }
        
        var component = self
        let repeatOp = RepeatForeverOperation(operation: self)
        component.appendOperation(.repeatForever(repeatOp))
        return component
    }
}

public extension OperationType {
    static func call(_ action: GameAction) -> Self {
        return .call(CallOperation(action: action))
    }
    
    func call(_ action: GameAction) -> Self {
        var component = self
        component.appendOperation(.call(CallOperation(action: action)))
        return component
    }
}
