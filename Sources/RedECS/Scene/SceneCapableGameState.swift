public protocol SceneCapableGameState: GameState {
    var scene: [EntityId: SceneComponent] { get set }
    var sceneManager: SceneManagerState { get set }
}

public struct SceneContext: GameState {
    public var entities: EntityRepository
    public var scene: [EntityId: SceneComponent]
    public var sceneManager: SceneManagerState

    public init(
        entities: EntityRepository,
        scene: [EntityId: SceneComponent],
        sceneManager: SceneManagerState
    ) {
        self.entities = entities
        self.scene = scene
        self.sceneManager = sceneManager
    }
}

public extension SceneCapableGameState {
    var sceneContext: SceneContext {
        get {
            SceneContext(
                entities: entities,
                scene: scene,
                sceneManager: sceneManager
            )
        }
        set {
            scene = newValue.scene
            sceneManager = newValue.sceneManager
        }
    }
}
