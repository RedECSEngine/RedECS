import RedECS

public struct WebEnvironment: RenderingEnvironment, SoundEnvironment {
    public var renderer: Renderer { webRenderer }
    public var resourceManager: ResourceManager { webResourceManager }
    public var soundEngine: SoundEngine { noOpSoundEngine }

    public var webRenderer: WebRenderer
    public var webResourceManager: WebResourceManager
    private let noOpSoundEngine = NoOpSoundEngine()

    public init(
        webRenderer: WebRenderer,
        webResourceManager: WebResourceManager
    ) {
        self.webRenderer = webRenderer
        self.webResourceManager = webResourceManager
    }
}
