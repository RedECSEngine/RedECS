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

        let reducer: AnyReducer<RenderingTestState, RenderingTestAction, RenderingTestEnvironment> =
            zip(
                RenderingReducer(renderableComponentTypes: [
                    .init(keyPath: \.sprite)
                ]),
                HUDRenderingReducer { [weak self] (_: RenderingTestState) in
                    self?.hudView
                }
            )
            .pullback(
                toLocalState: \.self,
                toLocalEnvironment: { $0 as RenderingEnvironment }
            )
            .eraseToAnyReducer()

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
        let exp = expectation(description: "font preload")
        renderer.resourceManager.resourceBundle = .module
        renderer.resourceManager.preload([.init(name: "pt-mono.fnt", type: .bitmapFont)])
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
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        renderer.clearQueue()
        store.sendDelta(1)
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
