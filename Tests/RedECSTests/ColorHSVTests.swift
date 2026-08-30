import XCTest
@testable import RedECS

final class ColorHSVTests: XCTestCase {
    private let samplePalette = [
        0xE4F1FA, 0xC9E6F9, 0x244E69, 0xA7D1EC, 0x7C9DB2,
        0xA26D40, 0x342315, 0x6A411E, 0x251609,
        0xE84D4D, 0xD84242, 0xC71E1E, 0x8D1212, 0x982222
    ].map { Color(hex: $0) }

    func testHSVRoundTripPreservesRGB() {
        for color in samplePalette {
            let restored = Color(hsv: color.hsv)
            XCTAssertEqual(restored.red, color.red, accuracy: 1e-9)
            XCTAssertEqual(restored.green, color.green, accuracy: 1e-9)
            XCTAssertEqual(restored.blue, color.blue, accuracy: 1e-9)
            XCTAssertEqual(restored.alpha, color.alpha, accuracy: 1e-9)
        }
    }

    func testKnownConversions() {
        let pureRed = Color.red.hsv
        XCTAssertEqual(pureRed.hue, 0, accuracy: 1e-9)
        XCTAssertEqual(pureRed.saturation, 1, accuracy: 1e-9)
        XCTAssertEqual(pureRed.value, 1, accuracy: 1e-9)

        let steelBlue = Color(hex: 0x7C9DB2).hsv
        XCTAssertEqual(steelBlue.hue, 203.333, accuracy: 1e-2)
        XCTAssertEqual(steelBlue.saturation, 54.0 / 178.0, accuracy: 1e-9)
        XCTAssertEqual(steelBlue.value, 178.0 / 255.0, accuracy: 1e-9)
    }

    func testRotatingHuePreservesSaturationAndValue() {
        for color in samplePalette {
            let rotated = color.rotatingHue(by: -84).hsv
            let original = color.hsv
            XCTAssertEqual(rotated.saturation, original.saturation, accuracy: 1e-9)
            XCTAssertEqual(rotated.value, original.value, accuracy: 1e-9)
            var expectedHue = (original.hue - 84).truncatingRemainder(dividingBy: 360)
            if expectedHue < 0 { expectedHue += 360 }
            XCTAssertEqual(rotated.hue, expectedHue, accuracy: 1e-6)
        }
    }

    func testFullRotationIsIdentity() {
        for color in samplePalette {
            let rotated = color.rotatingHue(by: 360)
            XCTAssertEqual(rotated.red, color.red, accuracy: 1e-9)
            XCTAssertEqual(rotated.green, color.green, accuracy: 1e-9)
            XCTAssertEqual(rotated.blue, color.blue, accuracy: 1e-9)
        }
    }

    func testGrayIsHueInvariant() {
        let gray = Color(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        XCTAssertEqual(gray.hsv.saturation, 0, accuracy: 1e-9)
        let rotated = gray.rotatingHue(by: 123)
        XCTAssertEqual(rotated.red, 0.5, accuracy: 1e-9)
        XCTAssertEqual(rotated.green, 0.5, accuracy: 1e-9)
        XCTAssertEqual(rotated.blue, 0.5, accuracy: 1e-9)
    }

    func testAlphaSurvivesConversion() {
        let translucent = Color(hex: 0x244E69, alpha: 0.5)
        XCTAssertEqual(Color(hsv: translucent.hsv).alpha, 0.5, accuracy: 1e-9)
        XCTAssertEqual(translucent.rotatingHue(by: 90).alpha, 0.5, accuracy: 1e-9)
    }

    func testNegativeHueInputNormalizes() {
        let fromNegative = Color(hsv: .init(hue: -156, saturation: 0.5, value: 0.5))
        let fromPositive = Color(hsv: .init(hue: 204, saturation: 0.5, value: 0.5))
        XCTAssertEqual(fromNegative.red, fromPositive.red, accuracy: 1e-9)
        XCTAssertEqual(fromNegative.green, fromPositive.green, accuracy: 1e-9)
        XCTAssertEqual(fromNegative.blue, fromPositive.blue, accuracy: 1e-9)
    }
}
