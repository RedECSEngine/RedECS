import Foundation

public protocol RenderingEnvironment {
    var renderer: Renderer { get }
    var resourceManager: ResourceManager { get }
}
