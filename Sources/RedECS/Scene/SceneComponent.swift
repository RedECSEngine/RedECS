public struct SceneComponent: GameComponent {
    public var entity: EntityId
    public var keepAliveOnDismiss: Bool
    public var cancelsPendingEffectsOnDismiss: Bool

    public init(entity: EntityId) {
        self.init(entity: entity, keepAliveOnDismiss: false)
    }

    public init(
        entity: EntityId,
        keepAliveOnDismiss: Bool = false,
        cancelsPendingEffectsOnDismiss: Bool = false
    ) {
        self.entity = entity
        self.keepAliveOnDismiss = keepAliveOnDismiss
        self.cancelsPendingEffectsOnDismiss = cancelsPendingEffectsOnDismiss
    }
}
