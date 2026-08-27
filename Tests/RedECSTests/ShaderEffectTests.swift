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
            webGLFragmentSource: ""
        )
        registry.register(custom)
        XCTAssertEqual(registry[.tint]?.metalFragmentFunction, "customTint")
    }

    func testProgramIdMatchesEffect() {
        XCTAssertEqual(ShaderEffect.tint(.white).programId, .tint)
        XCTAssertEqual(ShaderEffect.paletteRemap([]).programId, .paletteRemap)
        XCTAssertEqual(
            ShaderEffect.custom("waves", params: [1, 2]).programId,
            ShaderId(rawValue: "waves")
        )
    }

    func testTintEncodesRGBA() {
        let encoded = ShaderEffect.tint(
            Color(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.4)
        ).encodeUniforms()
        XCTAssertEqual(encoded.count, 4)
        XCTAssertEqual(encoded[0], 0.1, accuracy: 1e-6)
        XCTAssertEqual(encoded[1], 0.2, accuracy: 1e-6)
        XCTAssertEqual(encoded[2], 0.3, accuracy: 1e-6)
        XCTAssertEqual(encoded[3], 0.4, accuracy: 1e-6)
    }

    func testPaletteRemapEncodesCountThenKeyPairs() {
        let encoded = ShaderEffect.paletteRemap([
            .init(
                from: Color(red: 1, green: 0, blue: 0, alpha: 1),
                to: Color(red: 0, green: 0, blue: 1, alpha: 1)
            ),
            .init(
                from: Color(red: 0, green: 1, blue: 0, alpha: 1),
                to: Color(red: 1, green: 1, blue: 0, alpha: 1)
            )
        ]).encodeUniforms()
        XCTAssertEqual(encoded, [2, 1, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 0])
    }

    func testPaletteRemapClampsToMaxKeys() {
        let key = ShaderEffect.ColorKey(from: .white, to: .black)
        let encoded = ShaderEffect.paletteRemap(
            Array(repeating: key, count: ShaderRegistry.paletteRemapMaxKeys + 5)
        ).encodeUniforms()
        XCTAssertEqual(Int(encoded[0]), ShaderRegistry.paletteRemapMaxKeys)
        XCTAssertEqual(encoded.count, 1 + ShaderRegistry.paletteRemapMaxKeys * 6)
    }

    func testPaletteRemapWebGLSourceMatchesMaxKeys() {
        let source = ShaderRegistry.paletteRemapDefinition.webGLFragmentSource
        XCTAssertTrue(source.contains("const int MAX_KEYS = \(ShaderRegistry.paletteRemapMaxKeys);"))
        XCTAssertTrue(source.contains("uniform float u_params[\(1 + ShaderRegistry.paletteRemapMaxKeys * 6)];"))
    }

    func testRenderGroupDefaultsToNilShader() {
        let group = RenderGroup(
            triangles: [],
            transformMatrix: .identity,
            fragmentType: .color(.white),
            zIndex: 0
        )
        XCTAssertNil(group.shader)
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
        XCTAssertEqual(group.withClipRect(Rect(x: 0, y: 0, width: 10, height: 10)).shader, shader)
        XCTAssertEqual(group.applyingClip(Rect(x: 0, y: 0, width: 10, height: 10)).shader, shader)
    }

    func testWithShaderOverridesAndClears() {
        let group = RenderGroup(
            triangles: [],
            transformMatrix: .identity,
            fragmentType: .texture("atlas"),
            zIndex: 2,
            shader: .tint(.green)
        )
        XCTAssertEqual(group.withShader(.ripple(time: 0.5)).shader, .ripple(time: 0.5))
        XCTAssertNil(group.withShader(nil).shader)
        XCTAssertEqual(group.withShader(.ripple(time: 0.5)).zIndex, 2)
    }

    func testWithZIndexOffsetShiftsOnlyZIndex() {
        let group = RenderGroup(
            triangles: [],
            transformMatrix: .identity,
            fragmentType: .texture("atlas"),
            zIndex: 5,
            opacity: 0.5,
            shader: .tint(.green)
        )
        let offset = group.withZIndexOffset(-1_000_000)
        XCTAssertEqual(offset.zIndex, -999_995)
        XCTAssertEqual(offset.shader, .tint(.green))
        XCTAssertEqual(offset.opacity, 0.5)
        XCTAssertEqual(group.withZIndexOffset(0).zIndex, 5)
    }
}
