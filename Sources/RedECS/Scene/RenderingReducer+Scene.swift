public extension RenderingReducer where ContextState: SceneCapableGameState {
    static var incomingSceneZIndexOffset: Int { -1_000_000 }

    static func sceneAware(
        renderableComponentTypes: [RenderableComponentType<ContextState>],
        rootDrawOrder: ((EntityId, ContextState) -> Double)? = nil
    ) -> RenderingReducer<ContextState> {
        RenderingReducer(
            renderableComponentTypes: renderableComponentTypes,
            rootDrawOrder: rootDrawOrder,
            rootDrawDisposition: { entityId, state in
                sceneDisposition(of: entityId, in: state)
            }
        )
    }

    private static func sceneDisposition(
        of entityId: EntityId,
        in state: ContextState
    ) -> RootDrawDisposition {
        let isScene = state.scene[entityId] != nil

        guard let active = state.sceneManager.transition else {
            if let activeSceneId = state.sceneManager.activeSceneId {
                return entityId == activeSceneId ? .drawn : .hidden
            }
            return isScene ? .hidden : .drawn
        }

        if belongs(entityId, isScene: isScene, toSide: active.outgoingSceneId) {
            guard active.drawsOutgoing else { return .hidden }
            return RootDrawDisposition(shaderOverride: active.outgoingShader())
        }
        if belongs(entityId, isScene: isScene, toSide: active.incomingSceneId) {
            guard active.drawsIncoming else { return .hidden }
            return RootDrawDisposition(
                shaderOverride: active.incomingShader(),
                zIndexOffset: incomingSceneZIndexOffset
            )
        }
        return .hidden
    }

    private static func belongs(
        _ entityId: EntityId,
        isScene: Bool,
        toSide sceneId: EntityId?
    ) -> Bool {
        if let sceneId {
            return entityId == sceneId
        }
        return !isScene
    }
}
