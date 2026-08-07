import Geometry

public indirect enum OperationType<GameAction: Equatable & Codable>: Codable & Equatable {
    case move(MoveOperation)
    case jump(JumpOperation)
    case rotate(RotateOperation)
    case scale(ScaleOperation)
    case wait(WaitOperation)
    case `repeat`(RepeatOperation<GameAction>)
    case sequence(SequenceOperation<GameAction>)
    case group(GroupOperation<GameAction>)
    case call(CallOperation<GameAction>)
    case animate(AnimateOperation)
    case opacity(OpacityOperation)
    case visibility(VisibilityOperation)
    case timing(TimingOperation<GameAction>)
    case removeEntity(RemoveEntityOperation<GameAction>)
    case shaderEffect(ShaderEffectOperation)
    case sound(SoundOperation<GameAction>)
    
    public var duration: Double {
        switch self {
        case .move(let moveOperation):
            return moveOperation.duration
        case .jump(let jumpOperation):
            return jumpOperation.duration
        case .rotate(let rotateOperation):
            return rotateOperation.duration
        case .scale(let scaleOperation):
            return scaleOperation.duration
        case .wait(let waitOperation):
            return waitOperation.duration
        case .sequence(let sequenceOperation):
            return sequenceOperation.duration
        case .group(let groupOp):
            return groupOp.duration
        case .repeat(let repeatOp):
            return repeatOp.duration
        case .call(let callOp):
            return callOp.duration
        case .animate(let animOp):
            return animOp.duration
        case .opacity(let opOp):
            return opOp.duration
        case .visibility(let visOp):
            return visOp.duration
        case .timing(let timing):
            return timing.duration
        case .removeEntity:
            return 0
        case .shaderEffect(let shaderOp):
            return shaderOp.duration
        case .sound:
            return 0
        }
    }
    
    public var isComplete: Bool {
        switch self {
        case .move(let moveOperation):
            return moveOperation.isComplete
        case .jump(let jumpOperation):
            return jumpOperation.isComplete
        case .rotate(let rotateOperation):
            return rotateOperation.isComplete
        case .scale(let scaleOperation):
            return scaleOperation.isComplete
        case .wait(let waitOperation):
            return waitOperation.isComplete
        case .sequence(let sequenceOperation):
            return sequenceOperation.isComplete
        case .group(let groupOp):
            return groupOp.isComplete
        case .repeat(let repeatOp):
            return repeatOp.isComplete
        case .call(let callOp):
            return callOp.isComplete
        case .animate(let animOp):
            return animOp.isComplete
        case .opacity(let opOp):
            return opOp.isComplete
        case .visibility(let visOp):
            return visOp.isComplete
        case .timing(let timing):
            return timing.isComplete
        case .removeEntity(let remove):
            return remove.isComplete
        case .shaderEffect(let shaderOp):
            return shaderOp.isComplete
        case .sound(let sound):
            return sound.isComplete
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
        case .rotate(var rotate):
            _ = rotate.run(id: id, state: &state, delta: delta)
            self = .rotate(rotate)
            return .none
        case .scale(var scale):
            _ = scale.run(id: id, state: &state, delta: delta)
            self = .scale(scale)
            return .none
        case .repeat(var rp):
            let effect = rp.run(id: id, state: &state, delta: delta)
            self = .repeat(rp)
            return effect
        case .move(var move):
            _ = move.run(id: id, state: &state, delta: delta)
            self = .move(move)
            return .none
        case .jump(var jump):
            _ = jump.run(id: id, state: &state, delta: delta)
            self = .jump(jump)
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
        case .animate(var anim):
            _ = anim.run(id: id, state: &state, delta: delta)
            self = .animate(anim)
            return .none
        case .opacity(var opacity):
            _ = opacity.run(id: id, state: &state, delta: delta)
            self = .opacity(opacity)
            return .none
        case .visibility(var visibility):
            _ = visibility.run(id: id, state: &state, delta: delta)
            self = .visibility(visibility)
            return .none
        case .timing(var timing):
            _ = timing.run(id: id, state: &state, delta: delta)
            self = .timing(timing)
            return .none
        case .removeEntity(var remove):
            let effect = remove.run(id: id, state: &state, delta: delta)
            self = .removeEntity(remove)
            return effect
        case .shaderEffect(var shaderOp):
            _ = shaderOp.run(id: id, state: &state, delta: delta)
            self = .shaderEffect(shaderOp)
            return .none
        case .sound(var sound):
            let effect = sound.run(id: id, state: &state, delta: delta)
            self = .sound(sound)
            return effect
        }
    }
    
    public mutating func reset() {
        switch self {
        case .wait(var wait):
            wait.reset()
            self = .wait(wait)
        case .rotate(var rotate):
            rotate.reset()
            self = .rotate(rotate)
        case .scale(var scale):
            scale.reset()
            self = .scale(scale)
        case .repeat(var rp):
            rp.reset()
            self = .repeat(rp)
        case .move(var move):
            move.reset()
            self = .move(move)
        case .jump(var jump):
            jump.reset()
            self = .jump(jump)
        case .sequence(var sequence):
            sequence.reset()
            self = .sequence(sequence)
        case .group(var group):
            group.reset()
            self = .group(group)
        case .call(var call):
            call.reset()
            self = .call(call)
        case .animate(var anim):
            anim.reset()
            self = .animate(anim)
        case .opacity(var opacity):
            opacity.reset()
            self = .opacity(opacity)
        case .visibility(var visibility):
            visibility.reset()
            self = .visibility(visibility)
        case .timing(var timing):
            timing.reset()
            self = .timing(timing)
        case .removeEntity(var remove):
            remove.reset()
        case .shaderEffect(var shaderOp):
            shaderOp.reset()
            self = .shaderEffect(shaderOp)
        case .sound(var sound):
            sound.reset()
            self = .sound(sound)
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
    static func move(_ strategy: MoveOperation.Strategy, duration: Double) -> Self {
        .move(MoveOperation(strategy: strategy, duration: duration))
    }
    
    func move(_ strategy: MoveOperation.Strategy, duration: Double) -> Self {
        var component = self
        let moveOp = MoveOperation(strategy: strategy, duration: duration)
        component.appendOperation(.move(moveOp))
        return component
    }
}

public extension OperationType {
    static func jump(
        _ strategy: JumpOperation.Strategy,
        height: Double,
        jumps: Int = 1,
        duration: Double
    ) -> Self {
        .jump(JumpOperation(strategy: strategy, height: height, jumps: jumps, duration: duration))
    }

    func jump(
        _ strategy: JumpOperation.Strategy,
        height: Double,
        jumps: Int = 1,
        duration: Double
    ) -> Self {
        var component = self
        let jumpOp = JumpOperation(strategy: strategy, height: height, jumps: jumps, duration: duration)
        component.appendOperation(.jump(jumpOp))
        return component
    }
}

public extension OperationType {
    static func rotate(_ strategy: RotateOperation.Strategy, duration: Double) -> Self {
        .rotate(RotateOperation(strategy: strategy, duration: duration))
    }
    
    func rotate(_ strategy: RotateOperation.Strategy, duration: Double) -> Self {
        var component = self
        let rotateOp = RotateOperation(strategy: strategy, duration: duration)
        component.appendOperation(.rotate(rotateOp))
        return component
    }
}

public extension OperationType {
    static func scale(_ strategy: ScaleOperation.Strategy, duration: Double) -> Self {
        .scale(ScaleOperation(strategy: strategy, duration: duration))
    }
    
    func scale(_ strategy: ScaleOperation.Strategy, duration: Double) -> Self {
        var component = self
        let scale = ScaleOperation(strategy: strategy, duration: duration)
        component.appendOperation(.scale(scale))
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
    func `repeat`(_ strategy: RepeatOperation<GameAction>.Strategy) -> Self {
        if case .repeat(let op) = self, op.strategy == .forever {
            return self
        }
        
        var component = self
        let repeatOp = RepeatOperation(strategy: strategy, operation: self)
        component.appendOperation(.repeat(repeatOp))
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

public extension OperationType {
    static func animate(_ frames: [AnimateOperation.FrameData]) -> Self {
        return .animate(AnimateOperation(frames: frames))
    }
    
    func animate(_ frames: [AnimateOperation.FrameData]) -> Self {
        var component = self
        component.appendOperation(.animate(AnimateOperation(frames: frames)))
        return component
    }
}

public extension OperationType {
    static func visibility(_ strategy: VisibilityOperation.Strategy) -> Self {
        return .visibility(VisibilityOperation(strategy: strategy))
    }
    
    func visibility(_ strategy: VisibilityOperation.Strategy) -> Self {
        var component = self
        component.appendOperation(.visibility(VisibilityOperation(strategy: strategy)))
        return component
    }
}

public extension OperationType {
    static func opacity(_ strategy: OpacityOperation.Strategy, duration: Double) -> Self {
        return .opacity(OpacityOperation(strategy: strategy, duration: duration))
    }
    
    func opacity(_ strategy: OpacityOperation.Strategy, duration: Double) -> Self {
        var component = self
        component.appendOperation(.opacity(OpacityOperation(strategy: strategy, duration: duration)))
        return component
    }
}

public extension OperationType {
    func timing(_ strategy: TimingOperation<GameAction>.Strategy) -> Self {
        .timing(TimingOperation(strategy: strategy, operation: self))
    }
}


public extension OperationType {
    static func removeEntity(removeEntityId: EntityId? = nil) -> Self {
        .removeEntity(.init(removeEntityId: removeEntityId))
    }
    
    func removeEntity(removeEntityId: EntityId? = nil) -> Self {
        var component = self
        let removeOp = RemoveEntityOperation<GameAction>(removeEntityId: removeEntityId)
        component.appendOperation(.removeEntity(removeOp))
        return component
    }
}


public extension OperationType {
    static func shaderEffect(_ effect: ShaderEffect, animated: Bool = false, duration: Double = 1) -> Self {
        .shaderEffect(ShaderEffectOperation(effect: effect, animated: animated, duration: duration))
    }

    func shaderEffect(_ effect: ShaderEffect, animated: Bool = false, duration: Double = 1) -> Self {
        var component = self
        component.appendOperation(.shaderEffect(ShaderEffectOperation(effect: effect, animated: animated, duration: duration)))
        return component
    }
}

public extension OperationType {
    static func sound(_ strategy: SoundOperation<GameAction>.Strategy) -> Self {
        .sound(SoundOperation(strategy: strategy))
    }

    func sound(_ strategy: SoundOperation<GameAction>.Strategy) -> Self {
        var component = self
        component.appendOperation(.sound(SoundOperation(strategy: strategy)))
        return component
    }

    static func playSound(_ sound: SoundId) -> Self {
        .sound(.play(sound))
    }

    func playSound(_ sound: SoundId) -> Self {
        self.sound(.play(sound))
    }

    static func stopSound(_ sound: SoundId) -> Self {
        .sound(.stop(sound))
    }

    func stopSound(_ sound: SoundId) -> Self {
        self.sound(.stop(sound))
    }

    static func stopAllSounds() -> Self {
        .sound(.stopAll)
    }

    func stopAllSounds() -> Self {
        self.sound(.stopAll)
    }
}
