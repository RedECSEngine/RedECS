import Foundation
@testable import RedECS
import Geometry
import RedECSBasicComponents
import RedECSAppleSupport
import RedHUD

struct RenderingTestState: RenderableGameState {
    var entities: EntityRepository = .init()

    var transform: [EntityId: TransformComponent] = [:]
    var sprite: [EntityId: SpriteComponent] = [:]
    var camera: [EntityId: CameraComponent] = [:]
}

enum RenderingTestAction: Equatable {
    /// Pointer events in, `.triggered` back out; test buttons use String
    /// as the game-action type.
    case hud(HUDAction<String>)
}

struct RenderingTestEnvironment: RenderingEnvironment {
    var renderer: Renderer { metalRenderer }
    var resourceManager: ResourceManager { metalResourceManager }

    var metalRenderer: MetalRenderer
    var metalResourceManager: MetalResourceManager
}

extension SpriteComponent {
    init(entity: EntityId, shape: Shape, fillColor: Color, anchorPoint: Point = .init(x: 0.5, y: 0.5)) {
        self.init(entity: entity, type: .shape(shape), anchorPoint: anchorPoint)
        self.fillColor = fillColor
    }

    var shapeValue: Shape? {
        guard case let .shape(shape) = type else { return nil }
        return shape
    }
}
