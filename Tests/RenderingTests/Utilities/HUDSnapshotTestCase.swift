import XCTest
import SnapshotTesting
import RedECS
import RedHUD
@testable import RedECSAppleSupport
import MetalKit
import Geometry
import GeometryAlgorithms

/// Shared harness for RedHUD snapshot tests: a 480x480 Metal view driven by
/// the world RenderingReducer zipped with a HUDRenderingReducer, mirroring
/// how a game composes them. The reducer derives the HUD from state via its
/// content function; here that function reads `hudView`, which tests set
/// with `setHUD` (nil renders no HUD).
@MainActor
class HUDSnapshotTestCase: XCTestCase {
    var mtkView: MTKView!
    var renderer: MetalRenderer!
    var store: GameStore<AnyReducer<RenderingTestState, RenderingTestAction, RenderingTestEnvironment>>!
    var hudView: AnyHUDView?

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

        let hud = HUDRenderingReducer<RenderingTestState, RenderingTestAction> { [weak self] _ in
            self?.hudView
        }
        .pullback(
            toLocalState: \.self,
            toLocalAction: { (action: RenderingTestAction) in
                if case .hud(let hudAction) = action { return hudAction }
                return nil
            },
            toGlobalAction: { hudAction in
                if case .triggered(let action) = hudAction { return action }
                return .hud(hudAction)  // unreachable: only .triggered is emitted
            },
            toLocalEnvironment: { (environment: RenderingTestEnvironment) in
                environment as RenderingEnvironment
            }
        )

        let reducer: AnyReducer<RenderingTestState, RenderingTestAction, RenderingTestEnvironment> =
            zip(world, hud, TestGameLogicReducer()).eraseToAnyReducer()

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

    func preloadFont() {
        preloadResources([.init(name: "pt-mono.fnt", type: .bitmapFont)])
    }

    func preloadResources(_ resources: [LoadableResource]) {
        let exp = expectation(description: "resource preload")
        renderer.resourceManager.resourceBundle = .module
        renderer.resourceManager.preload(resources)
            .subscribe { result in
                if case .failure(let err) = result {
                    XCTFail("\(err)")
                }
                exp.fulfill()
            }
        waitForExpectations(timeout: 2)
    }

    func setHUD(@HUDViewBuilder content: () -> [AnyHUDView]) {
        let views = content()
        if views.count == 1 {
            hudView = views[0]
        } else if views.isEmpty {
            hudView = nil
        } else {
            hudView = AnyHUDView(VStack { views })
        }
    }

    func snapshotFrame(
        named name: String? = nil,
        record: Bool = false,
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
            record: record,
            file: file,
            testName: testName,
            line: line
        )
    }
}
