import RedECS

public struct MetalEnvironment: RenderingEnvironment {
    public var renderer: Renderer { metalRenderer }
    public var resourceManager: ResourceManager { metalResourceManager }
    
    public var metalRenderer: MetalRenderer
    public var metalResourceManager: MetalResourceManager
    
    public init(
        metalRenderer: MetalRenderer,
        metalResourceManager: MetalResourceManager
    ) {
        self.metalRenderer = metalRenderer
        self.metalResourceManager = metalResourceManager
    }
}
