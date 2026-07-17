import XCTest
import Geometry
import RedECS
@testable import RedHUD

final class TextTests: XCTestCase {
    // A minimal two-glyph font: 'A' 20 wide advancing 24, 'B' 18 wide
    // advancing 22, space advancing 10, line height 40, baseline at 32.
    static let fontData = """
    info face="TestFont" size=32 bold=0 italic=0
    common lineHeight=40 base=32 scaleW=128 scaleH=128 pages=1
    page id=0 file="test-font.png"
    chars count=3
    char id=65 x=0 y=0 width=20 height=30 xoffset=0 yoffset=2 xadvance=24 page=0 chnl=0 letter="A"
    char id=66 x=20 y=0 width=18 height=30 xoffset=1 yoffset=2 xadvance=22 page=0 chnl=0 letter="B"
    char id=32 x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance=10 page=0 chnl=0 letter="space"
    """

    var context: HUDRenderContext {
        let font = try! BitmapFont(fromString: Self.fontData)
        return HUDRenderContext(fonts: ["TestFont": font], font: "TestFont")
    }

    func testMeasuresAdvancesAndLineHeight() {
        let size = Text("AB A").size(proposed: ProposedSize(), context: context)
        XCTAssertEqual(size, Size(width: 24 + 22 + 10 + 24, height: 40))
    }

    func testMissingFontOccupiesNoSpace() {
        let noFonts = HUDRenderContext()
        XCTAssertEqual(
            Text("AB").size(proposed: ProposedSize(), context: noFonts),
            .zero
        )
        XCTAssertTrue(Text("AB").render(context: noFonts, size: .zero).isEmpty)
    }

    func testExplicitFontOverridesContext() {
        let size = Text("A", font: "TestFont")
            .size(proposed: ProposedSize(), context: context)
        XCTAssertEqual(size.width, 24)
    }

    func testRenderFlipsIntoTopLeftYDownSpace() throws {
        let groups = Text("A").render(context: context, size: Size(width: 24, height: 40))
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].textureId, "test-font")

        // 'A': yoffset 2, height 30 → its top should sit 2pts below the
        // line top and its bottom at 32 in y-down local space.
        let ys = groups[0].triangles
            .flatMap { [$0.triangle.a, $0.triangle.b, $0.triangle.c] }
            .map { $0.multiplyingMatrix(groups[0].transformMatrix).y }
        XCTAssertEqual(ys.min(), 2)
        XCTAssertEqual(ys.max(), 32)
    }

    func testUnknownCharactersAreSkippedWithoutAdvance() {
        let size = Text("A?B").size(proposed: ProposedSize(), context: context)
        XCTAssertEqual(size.width, 24 + 22)
    }
}
