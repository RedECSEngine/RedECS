import RedECSSpriteKitSupport

public final class ExampleGameEnvironment: SpriteKitRenderingEnvironment {
    public var renderer: SpriteKitRenderer
    
    public init(renderer: SpriteKitRenderer) {
        self.renderer = renderer
    }
}
