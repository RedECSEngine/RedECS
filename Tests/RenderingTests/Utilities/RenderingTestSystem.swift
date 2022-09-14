import Foundation
@testable import RedECS
import Geometry
import RedECSBasicComponents
import RedECSAppleSupport

struct RenderingTestState: RenderableGameState {
    var entities: EntityRepository = .init()

    var transform: [EntityId: TransformComponent] = [:]
    var shape: [EntityId: ShapeComponent] = [:]
    var sprite: [EntityId: SpriteComponent] = [:]
    var label: [EntityId: LabelComponent] = [:]
    var camera: [EntityId: CameraComponent] = [:]
    
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
