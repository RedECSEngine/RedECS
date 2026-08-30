import XCTest
import SnapshotTesting
import RedECS
import RedHUD
@testable import RedECSAppleSupport
import MetalKit
import Geometry
import GeometryAlgorithms

/// Snapshot harness for world-space HUD: a 480x480 Metal view driven by the
/// world `RenderingReducer` (which sets the camera projection) zipped with the
/// unified `HUDRenderingReducer` rendering a `WorldSpace` (whose leaves emit
/// `.world` groups). A camera entity must exist for `.world` groups to project
/// — seeded per test via `addCamera`. The HUD content is whatever `worldHUD`
/// holds.
@MainActor
final class HUDWorldStackTests: XCTestCase {
    var mtkView: MTKView!
    var renderer: MetalRenderer!
    var store: GameStore<AnyReducer<RenderingTestState, RenderingTestAction, RenderingTestEnvironment>>!
    var worldHUD: AnyHUDView?

    override func setUp() async throws {
        let device = MTLCreateSystemDefaultDevice()!
        mtkView = MTKView(
            frame: .init(origin: .zero, size: .init(width: 480, height: 480)),
            device: device
        )
        renderer = MetalRenderer(
            device: device,
            pixelFormat: mtkView.colorPixelFormat,
            resourceManager: MetalResourceManager(metalDevice: device)
        )
        mtkView.delegate = renderer
        renderer.mtkView(mtkView, drawableSizeWillChange: .init(width: 480, height: 480))

        let world = RenderingReducer(renderableComponentTypes: [
            .init(keyPath: \.sprite)
        ])
        .pullback(
            toLocalState: \.self,
            toLocalEnvironment: { $0 as RenderingEnvironment }
        ) as Pullback<RenderingTestState, RenderingTestAction, RenderingTestEnvironment, RenderingReducer<RenderingTestState>>

        let hudReducer = HUDRenderingReducer<RenderingTestState, RenderingTestAction>(baseZIndex: 1000) { [weak self] _ in
            self?.worldHUD
        }
        .pullback(
            toLocalState: \.self,
            toLocalAction: { (action: RenderingTestAction) in
                if case .hud(let hudAction) = action { return hudAction }
                return nil
            },
            toGlobalAction: { hudAction in
                if case .triggered(let action) = hudAction { return action }
                return .hud(hudAction)
            },
            toLocalEnvironment: { (environment: RenderingTestEnvironment) in
                environment as RenderingEnvironment
            }
        )

        let reducer: AnyReducer<RenderingTestState, RenderingTestAction, RenderingTestEnvironment> =
            zip(world, hudReducer, TestGameLogicReducer()).eraseToAnyReducer()

        store = GameStore(
            state: RenderingTestState(),
            environment: RenderingTestEnvironment(
                metalRenderer: renderer,
                metalResourceManager: renderer.resourceManager
            ),
            reducer: reducer,
            registeredComponentTypes: [
                .init(keyPath: \.transform),
                .init(keyPath: \.sprite),
                .init(keyPath: \.camera),
            ]
        )
    }

    /// Seeds the primary camera at a world position and zoom. Without it,
    /// `.world` groups have no projection to render through.
    private func addCamera(position: Point = .zero, zoom: Double = 1) {
        let id = newEntityId()
        store.sendSystemAction(.addEntity(id, []))
        store.sendSystemAction(.addComponent(TransformComponent(entity: id, position: position), into: \.transform))
        store.sendSystemAction(.addComponent(CameraComponent(entity: id, zoom: zoom), into: \.camera))
    }

    private func setWorldHUD(@WorldSpaceBuilder content: () -> [WorldPosition]) {
        worldHUD = AnyHUDView(WorldSpace(content: content))
    }

    private func snapshotFrame(
        named name: String? = nil,
        delta: Double = 1,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        renderer.clearQueue()
        store.sendDelta(delta)
        assertSnapshot(
            matching: mtkView,
            as: .image(renderer: renderer),
            named: name,
            file: file,
            testName: testName,
            line: line
        )
    }

    /// `WorldSpace`'s per-entry y-flip makes y-down content render upright with
    /// the VStack growing downward, so the label sits above the bar (a naive
    /// translate would render it mirrored).
    func testWorldStackOrientation() throws {
        addCamera()
        setWorldHUD {
            WorldPosition(x: -120, y: -80) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("World HUD")
                    Rectangle().frame(width: 90, height: 24).foregroundColor(.green)
                }
            }
        }
        snapshotFrame()
    }

    /// Two absolutely-placed entries at distinct world points, one holding a
    /// VStack of ForEach bars — stacks and ForEach work in world space.
    func testWorldStackTwoEntriesWithForEach() throws {
        addCamera()
        let bars: [(id: Int, color: Color)] = [(0, .red), (1, .green), (2, .blue)]
        setWorldHUD {
            WorldPosition(x: -180, y: -60) {
                Rectangle().frame(width: 60, height: 60).foregroundColor(.yellow)
            }
            WorldPosition(x: 20, y: -90) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(bars, id: \.id) { bar in
                        Rectangle().frame(width: 100, height: 20).foregroundColor(bar.color)
                    }
                }
            }
        }
        snapshotFrame()
    }

    /// The defining world-space property: the same content pans and zooms with
    /// the camera. Camera offset + zoom 1.5 shifts and enlarges the HUD versus
    /// the origin/zoom-1 orientation snapshot.
    func testWorldStackFollowsCameraPanZoom() throws {
        addCamera(position: Point(x: 60, y: 40), zoom: 1.5)
        setWorldHUD {
            WorldPosition(x: -120, y: -80) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("World HUD")
                    Rectangle().frame(width: 90, height: 24).foregroundColor(.green)
                }
            }
        }
        snapshotFrame()
    }

    /// World HUD groups share the `.world` sort bucket with sprites, ordered
    /// by zIndex. With `baseZIndex: 1000` the HUD entry paints ABOVE a world
    /// sprite occupying the same spot — locking in the layering knob.
    func testWorldHUDPaintsOverWorldSprite() throws {
        addCamera()
        let spriteId = newEntityId()
        store.sendSystemAction(.addEntity(spriteId, []))
        store.sendSystemAction(.addComponent(
            TransformComponent(entity: spriteId, position: .zero),
            into: \.transform
        ))
        store.sendSystemAction(.addComponent(
            SpriteComponent(
                entity: spriteId,
                shape: .rect(Rect(x: -80, y: -80, width: 160, height: 160)),
                fillColor: .blue,
                anchorPoint: .zero
            ),
            into: \.sprite
        ))
        setWorldHUD {
            WorldPosition(x: -40, y: 40) {
                Rectangle().frame(width: 80, height: 80).foregroundColor(.red)
            }
        }
        snapshotFrame()
    }

    /// Animation ticks in the world reducer: a scale-up over three frames,
    /// keyed and eased through the reused HUDCache exactly as on screen.
    func testWorldStackAnimatedScaleTimeline() throws {
        addCamera()
        setWorldHUD {
            WorldPosition(x: -40, y: -40) {
                Rectangle()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.green)
                    .scaleEffect(from: 1.0, to: 2.0)
                    .animated(duration: 1, timing: .linear, on: .appear)
            }
        }
        snapshotFrame(named: "start")               // 1.0x
        snapshotFrame(named: "middle", delta: 0.5)  // 1.5x
        snapshotFrame(named: "end", delta: 0.5)     // settled 2.0x
    }
}
