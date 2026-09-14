public extension GameEffect {
    static func presentScene(
        hide outgoing: EntityId? = nil,
        show incoming: EntityId,
        transition: SceneTransition? = nil,
        destroyOutgoing: Bool = false
    ) -> GameEffect<State, LogicAction> {
        guard let transition, transition.duration > 0 else {
            return immediatePresent(hide: outgoing, show: incoming, destroyOutgoing: destroyOutgoing)
        }
        switch transition.phasing {
        case .sequential:
            return sequentialPresent(hide: outgoing, show: incoming, transition: transition, destroyOutgoing: destroyOutgoing)
        case .crossover:
            return crossoverPresent(hide: outgoing, show: incoming, transition: transition, destroyOutgoing: destroyOutgoing)
        }
    }

    private static func immediatePresent(
        hide outgoing: EntityId?,
        show incoming: EntityId,
        destroyOutgoing: Bool
    ) -> GameEffect<State, LogicAction> {
        var effects: [GameEffect<State, LogicAction>] = [
            .removeOperation(incoming, key: SceneTransition.operationKey),
            .system(.setHidden(incoming, false))
        ]
        if let outgoing {
            if destroyOutgoing {
                effects.append(.system(.removeEntity(outgoing)))
            } else {
                effects.append(.removeOperation(outgoing, key: SceneTransition.operationKey))
                effects.append(.system(.setHidden(outgoing, true)))
            }
        }
        return .many(effects)
    }

    private static func sequentialPresent(
        hide outgoing: EntityId?,
        show incoming: EntityId,
        transition: SceneTransition,
        destroyOutgoing: Bool
    ) -> GameEffect<State, LogicAction> {
        let half = transition.duration / 2
        var effects: [GameEffect<State, LogicAction>] = [.system(.setHidden(incoming, true))]

        if let outgoing {
            let fadeOut: OperationType<LogicAction> = transition.outEffect
                .map { .subtreeShader($0, duration: half) }
                ?? .wait(duration: half)
            effects.append(.operation(
                outgoing,
                key: SceneTransition.operationKey,
                destroyOutgoing ? fadeOut.removeEntity() : fadeOut.visibility(.hide)
            ))
        }

        var fadeIn: OperationType<LogicAction> = OperationType
            .wait(duration: outgoing == nil ? 0 : half)
            .visibility(.show)
        if let inEffect = transition.inEffect {
            fadeIn = fadeIn.subtreeShader(inEffect, duration: half, reversed: true)
        }
        effects.append(.operation(incoming, key: SceneTransition.operationKey, fadeIn))
        return .many(effects)
    }

    private static func crossoverPresent(
        hide outgoing: EntityId?,
        show incoming: EntityId,
        transition: SceneTransition,
        destroyOutgoing: Bool
    ) -> GameEffect<State, LogicAction> {
        var effects: [GameEffect<State, LogicAction>] = [.system(.setHidden(incoming, false))]

        if let inEffect = transition.inEffect {
            effects.append(.operation(
                incoming,
                key: SceneTransition.operationKey,
                .subtreeShader(inEffect, duration: transition.duration, reversed: true)
            ))
        } else {
            effects.append(.removeOperation(incoming, key: SceneTransition.operationKey))
        }

        if let outgoing {
            effects.append(.system(.setParent(outgoing, nil)))
            let fadeOut: OperationType<LogicAction> = transition.outEffect
                .map { .subtreeShader($0, duration: transition.duration) }
                ?? .wait(duration: transition.duration)
            effects.append(.operation(
                outgoing,
                key: SceneTransition.operationKey,
                destroyOutgoing ? fadeOut.removeEntity() : fadeOut.visibility(.hide)
            ))
        }
        return .many(effects)
    }
}
