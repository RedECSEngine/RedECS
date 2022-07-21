import Foundation

public protocol RenderingEnvironment {
    var renderer: Renderer { get }
    var textures: [TextureId: TextureMap] { get }
}
