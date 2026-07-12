import XCTest
import SnapshotTesting
import RedECS
@testable import RedECSAppleSupport
import MetalKit
import CoreImage
import CoreGraphics
import Geometry
import GeometryAlgorithms
import RedECSBasicComponents

@MainActor
class BitmapFontTests: XCTestCase {
    var mtkView: MTKView!
    var renderer: MetalRenderer!
    var store: GameStore<AnyReducer<RenderingTestState, RenderingTestAction, RenderingTestEnvironment>>!

    override func setUp() async throws {

        let device = MTLCreateSystemDefaultDevice()!
        self.mtkView = MTKView(
            frame: .init(origin: .zero, size: .init(width: 600, height: 480)),
            device: device
        )
        self.renderer = MetalRenderer(
            device: device,
            pixelFormat: mtkView.colorPixelFormat,
            resourceManager: MetalResourceManager(metalDevice: device)
        )
        mtkView.delegate = renderer
        renderer.mtkView(mtkView, drawableSizeWillChange: .init(width: 600, height: 480))

        let reducer: AnyReducer<RenderingTestState, RenderingTestAction, RenderingTestEnvironment> =
        RenderingReducer(renderableComponentTypes: [
            .init(keyPath: \.sprite)
        ])
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
            ])
    }

    func testLoadFontFile() throws {
        let fontFile = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .appendingPathComponent("pt-mono.fnt")

        guard let fontData = FileManager.default.contents(atPath: fontFile.path),
            let fontString = String(data: fontData, encoding: .utf8) else {
            XCTFail()
            return
        }

        let font = try BitmapFont(fromString: fontString)

        XCTAssertEqual(font.info.face, "PT-Mono")
        XCTAssertEqual(font.page.file, "pt-mono.png")
        XCTAssertEqual(font.characters.count, 95)
    }

    func testBitmapFontRender() throws {
        snapshotText("Welcome")
        snapshotText("Bitmap Font")
        snapshotText("Chars--@!_=+?\"'\\")
    }

    func snapshotText(_ text: String) {
        let exp = expectation(description: "wait for async")
        renderer.resourceManager.resourceBundle = .module
        renderer.resourceManager.preload([.init(name: "pt-mono.fnt", type: .bitmapFont)])
            .subscribe { result in
                switch result {
                case .success:
                    break
                case .failure(let err):
                    XCTFail("\(err)")
                }
                exp.fulfill()
            }
        waitForExpectations(timeout: 2)

        let entityId = "TextEntity"
        let label = SpriteComponent(entity: entityId, type: .label(font: "PT-Mono", text: text), anchorPoint: .init(x: 0.5, y: 0))
        let transform = TransformComponent(
            entity: entityId,
            position: .zero
        )
        let camera = CameraComponent(entity: entityId)

        store.sendSystemAction(.removeEntity(entityId))
        store.sendSystemAction(.addEntity(entityId, []))
        store.sendSystemAction(.addComponent(transform, into: \.transform))
        store.sendSystemAction(.addComponent(label, into: \.sprite))
        store.sendSystemAction(.addComponent(camera, into: \.camera))

        renderer.clearQueue()
        enqueueLine(into: renderer)
        store.sendDelta(1)
        assertSnapshot(matching: mtkView, as: .image(renderer: renderer), named: text)
    }

}
