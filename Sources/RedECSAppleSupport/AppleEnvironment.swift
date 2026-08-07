import RedECS

public struct AppleEnvironment: RenderingEnvironment, SoundEnvironment {
    public var renderer: Renderer { metalRenderer }
    public var resourceManager: ResourceManager { metalResourceManager }
    public var soundEngine: SoundEngine { appleSoundEngine }

    public var metalRenderer: MetalRenderer
    public var metalResourceManager: MetalResourceManager
    public var appleSoundEngine: AppleSoundEngine

    public init(
        metalRenderer: MetalRenderer,
        metalResourceManager: MetalResourceManager,
        appleSoundEngine: AppleSoundEngine
    ) {
        self.metalRenderer = metalRenderer
        self.metalResourceManager = metalResourceManager
        self.appleSoundEngine = appleSoundEngine
    }
}
