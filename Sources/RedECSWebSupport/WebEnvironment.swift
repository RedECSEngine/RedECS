import RedECS

public struct WebEnvironment: RenderingEnvironment {
    public var renderer: Renderer { webRenderer }
    public var resourceManager: ResourceManager { webResourceManager }
    
    public var webRenderer: WebRenderer
    public var webResourceManager: WebResourceManager
    
    public init(
        webRenderer: WebRenderer,
        webResourceManager: WebResourceManager
    ) {
        self.webRenderer = webRenderer
        self.webResourceManager = webResourceManager
    }
}
