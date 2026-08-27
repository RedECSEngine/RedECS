public struct SceneReducer: Reducer {
    public typealias State = SceneContext
    public typealias Action = SceneAction
    public typealias Environment = Void

    public init() { }

    public func reduce(
        state: inout SceneContext,
        action: SceneAction,
        environment: Void
    ) -> GameEffect<SceneContext, SceneAction> {
        switch action {
        case .presentScene(let sceneId, let transition):
            return present(&state, incoming: sceneId, transition: transition)
        case .dismissScene(let transition):
            return present(&state, incoming: nil, transition: transition)
        }
    }

    public func reduce(
        state: inout SceneContext,
        delta: Double,
        environment: Void
    ) -> GameEffect<SceneContext, SceneAction> {
        guard var active = state.sceneManager.transition else { return .none }
        active.elapsed += delta
        if active.isComplete {
            state.sceneManager.transition = nil
            state.sceneManager.activeSceneId = active.incomingSceneId
            return teardown(&state, sceneId: active.outgoingSceneId)
        }
        state.sceneManager.transition = active
        return .none
    }

    public func reduce(
        state: inout SceneContext,
        entityEvent: EntityEvent,
        environment: Void
    ) -> GameEffect<SceneContext, SceneAction> {
        guard case .didRemove(let id) = entityEvent else { return .none }
        if let active = state.sceneManager.transition {
            if active.outgoingSceneId == id {
                state.sceneManager.transition = nil
                state.sceneManager.activeSceneId = active.incomingSceneId
            } else if active.incomingSceneId == id {
                state.sceneManager.transition = nil
                state.sceneManager.activeSceneId = active.outgoingSceneId
            }
        }
        if state.sceneManager.activeSceneId == id {
            state.sceneManager.activeSceneId = nil
        }
        return .none
    }

    private func present(
        _ state: inout SceneContext,
        incoming: EntityId?,
        transition: SceneTransition?
    ) -> GameEffect<SceneContext, SceneAction> {
        if let incoming {
            guard state.scene[incoming] != nil,
                  state.entities[incoming] != nil,
                  state.entities.parent(of: incoming) == nil
            else {
                assertionFailure("presenting unknown or non-root scene '\(incoming)'")
                return .none
            }
        }

        var effects: [GameEffect<SceneContext, SceneAction>] = []
        if let active = state.sceneManager.transition {
            state.sceneManager.transition = nil
            state.sceneManager.activeSceneId = active.incomingSceneId
            effects.append(teardown(&state, sceneId: active.outgoingSceneId))
        }

        guard state.sceneManager.activeSceneId != incoming else {
            return .many(effects)
        }

        guard let transition, transition.duration > 0 else {
            let outgoing = state.sceneManager.activeSceneId
            state.sceneManager.activeSceneId = incoming
            effects.append(teardown(&state, sceneId: outgoing))
            return .many(effects)
        }

        state.sceneManager.transition = ActiveSceneTransition(
            outgoingSceneId: state.sceneManager.activeSceneId,
            incomingSceneId: incoming,
            transition: transition
        )
        return .many(effects)
    }

    private func teardown(
        _ state: inout SceneContext,
        sceneId: EntityId?
    ) -> GameEffect<SceneContext, SceneAction> {
        guard let sceneId,
              let component = state.scene[sceneId],
              !component.keepAliveOnDismiss
        else { return .none }

        var effects: [GameEffect<SceneContext, SceneAction>] = state.entities.hierarchy
            .children(of: sceneId)
            .map { .system(.removeEntity($0)) }
        if component.cancelsPendingEffectsOnDismiss {
            effects.append(.system(.cancelPendingEffects))
        }
        return .many(effects)
    }
}
