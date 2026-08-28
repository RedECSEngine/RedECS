public enum SceneAction: Equatable, Codable {
    case presentScene(EntityId, SceneTransition?)
    case dismissScene(SceneTransition?)
}
