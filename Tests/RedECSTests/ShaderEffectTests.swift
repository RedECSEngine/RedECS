import XCTest
import Geometry
@testable import RedECS

final class ShaderEffectTests: XCTestCase {
    func testBuiltinsRegistered() {
        let registry = ShaderRegistry()
        XCTAssertNotNil(registry[.passthrough])
        XCTAssertNotNil(registry[.tint])
        XCTAssertNotNil(registry[.paletteRemap])
        XCTAssertEqual(registry[.tint]?.metalFragmentFunction, "tintFragment")
        XCTAssertEqual(registry[.paletteRemap]?.metalFragmentFunction, "paletteRemapFragment")
    }

    func testRegisterOverridesById() {
        let registry = ShaderRegistry()
        let custom = ShaderDefinition(
            id: .tint,
            metalFragmentFunction: "customTint",
            metalSource: "",
            webGLFragmentSource: "",
            encodeUniforms: { _ in [42] }
        )
        registry.register(custom)
        XCTAssertEqual(registry[.tint]?.metalFragmentFunction, "customTint")
        XCTAssertEqual(registry[.tint]?.encodeUniforms(.init()), [42])
    }

    func testPassthroughEncodesNoUniforms() {
        XCTAssertEqual(ShaderRegistry.passthroughDefinition.encodeUniforms(.init()), [])
    }

    func testTintEncodesRGBA() {
        let params = ShaderParameters(color: Color(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.4))
        let encoded = ShaderRegistry.tintDefinition.encodeUniforms(params)
        XCTAssertEqual(encoded.count, 4)
        XCTAssertEqual(encoded[0], 0.1, accuracy: 1e-6)
        XCTAssertEqual(encoded[1], 0.2, accuracy: 1e-6)
        XCTAssertEqual(encoded[2], 0.3, accuracy: 1e-6)
        XCTAssertEqual(encoded[3], 0.4, accuracy: 1e-6)
    }

    func testPaletteRemapEncodesCountThenKeyPairs() {
        let params = ShaderParameters(colorKeys: [
            .init(
                from: Color(red: 1, green: 0, blue: 0, alpha: 1),
                to: Color(red: 0, green: 0, blue: 1, alpha: 1)
            ),
            .init(
                from: Color(red: 0, green: 1, blue: 0, alpha: 1),
                to: Color(red: 1, green: 1, blue: 0, alpha: 1)
            )
        ])
        let encoded = ShaderRegistry.paletteRemapDefinition.encodeUniforms(params)
        XCTAssertEqual(encoded, [2, 1, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 0])
    }

    func testPaletteRemapClampsToMaxKeys() {
        let key = ShaderParameters.ColorKey(from: .white, to: .black)
        let params = ShaderParameters(colorKeys: Array(repeating: key, count: ShaderRegistry.paletteRemapMaxKeys + 5))
        let encoded = ShaderRegistry.paletteRemapDefinition.encodeUniforms(params)
        XCTAssertEqual(Int(encoded[0]), ShaderRegistry.paletteRemapMaxKeys)
        XCTAssertEqual(encoded.count, 1 + ShaderRegistry.paletteRemapMaxKeys * 6)
    }

    func testRenderGroupDefaultsToPassthrough() {
        let group = RenderGroup(
            triangles: [],
            transformMatrix: .identity,
            fragmentType: .color(.white),
            zIndex: 0
        )
        XCTAssertEqual(group.shader, .none)
        XCTAssertEqual(group.shader.id, .passthrough)
    }

    func testCopyHelpersPreserveShader() {
        let shader = ShaderEffect.tint(.green)
        let group = RenderGroup(
            triangles: [],
            transformMatrix: .identity,
            fragmentType: .texture("atlas"),
            zIndex: 0,
            shader: shader
        )
        XCTAssertEqual(group.withTransformMatrix(.identity).shader, shader)
        XCTAssertEqual(group.withOpacity(0.5).shader, shader)
        XCTAssertEqual(group.with(zIndex: 3, projectionSpace: .screen).shader, shader)
    }
}
