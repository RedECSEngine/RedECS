import Foundation
@testable import RedECS
import Geometry
import RedECSBasicComponents
import RedECSAppleSupport

struct RenderingTestState: GameState {
    var entities: EntityRepository = .init()

    var transform: [EntityId: TransformComponent] = [:]
    var shape: [EntityId: ShapeComponent] = [:]
    var sprite: [EntityId: SpriteComponent] = [:]
    var camera: [EntityId: CameraComponent] = [:]
    
    var spriteContext: SpriteContext {
        get {
            SpriteContext(entities: entities, transform: transform, sprite: sprite)
        }
        set {
            self.transform = newValue.transform
            self.sprite = newValue.sprite
        }
    }
    
    var shapeContext: ShapeRenderingContext {
        get {
            ShapeRenderingContext(entities: entities, transform: transform, shape: shape)
        }
        set {
            self.transform = newValue.transform
            self.shape = newValue.shape
        }
    }
    
    var cameraContext: CameraReducerContext {
        get {
            CameraReducerContext(entities: entities, transform: transform, camera: camera)
        }
        set {
            self.transform = newValue.transform
            self.camera = newValue.camera
        }
    }
}

enum RenderingTestAction: Equatable {
    
}

struct RenderingTestEnvironment: RenderingEnvironment {
    var renderer: Renderer { metalRenderer }
    var resourceManager: ResourceManager { metalResourceManager }
    
    var metalRenderer: MetalRenderer
    var metalResourceManager: MetalResourceManager
}
