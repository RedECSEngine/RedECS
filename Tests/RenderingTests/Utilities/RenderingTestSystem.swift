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

    /// Button fires observed by TestGameLogicReducer, proving triggered
    /// actions round-trip out of the HUD and into game logic.
    var firedActions: [String] = []
}

/// Stands in for a game's own logic reducer: receives button fires as
/// plain game actions (the HUD pullback's toGlobalAction unwraps
/// `.triggered` before they reach the store).
struct TestGameLogicReducer: Reducer {
    typealias State = RenderingTestState
    typealias Action = RenderingTestAction
    typealias Environment = RenderingTestEnvironment

    func reduce(
        state: inout RenderingTestState,
        delta: Double,
        environment: RenderingTestEnvironment
    ) -> GameEffect<RenderingTestState, RenderingTestAction> {
        .none
    }

    func reduce(
        state: inout RenderingTestState,
        action: RenderingTestAction,
        environment: RenderingTestEnvironment
    ) -> GameEffect<RenderingTestState, RenderingTestAction> {
        if case .buttonFired(let name) = action {
            state.firedActions.append(name)
        }
        return .none
    }
}

/// The "top-level actions directly" wiring from the HUDAction docs: buttons
/// carry this enum itself, so the embedding case makes it recursive —
/// hence `indirect`.
indirect enum RenderingTestAction: Equatable {
    case hud(HUDAction<Self>)
    /// What test buttons fire; arrives unwrapped via `toGlobalAction`.
    case buttonFired(String)
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
