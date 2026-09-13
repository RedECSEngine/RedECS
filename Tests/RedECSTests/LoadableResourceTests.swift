import XCTest
import RedECS

final class LoadableResourceTests: XCTestCase {
    func testFileNameSplitsOnTheLastDot() {
        let resource = LoadableResource(fileName: "skeleton.boss.png", type: .image)

        XCTAssertEqual(resource, LoadableResource(name: "skeleton.boss", ext: "png", type: .image))
        XCTAssertEqual(resource.fileName, "skeleton.boss.png")
    }

    func testFileNameWithoutExtension() {
        let resource = LoadableResource(fileName: "README", type: .csv)

        XCTAssertEqual(resource.name, "README")
        XCTAssertEqual(resource.ext, "")
        XCTAssertEqual(resource.fileName, "README")
    }

    func testLeadingDotIsPartOfTheName() {
        let resource = LoadableResource(fileName: ".hidden", type: .json)

        XCTAssertEqual(resource.name, ".hidden")
        XCTAssertEqual(resource.ext, "")
    }
}
