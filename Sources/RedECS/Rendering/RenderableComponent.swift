public protocol RenderableComponent {
    func renderGroups(transform: TransformComponent, resourceManager: ResourceManager) -> [RenderGroup]
}
