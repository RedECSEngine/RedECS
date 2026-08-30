import RedECS

struct OperationTestContext: BasicOperationCapableState {
    var entities: EntityRepository = .init()
    var transform: [EntityId: TransformComponent] = [:]
    var sprite: [EntityId: SpriteComponent] = [:]
}
