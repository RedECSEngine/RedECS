public enum EntityEvent: Equatable {
    case added(EntityId)
    case willRemove(EntityId)
    case didRemove(EntityId)
}
