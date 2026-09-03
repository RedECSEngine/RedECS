import XCTest
@testable import CSVInterpreter

private struct Stats: Codable, Equatable {
    var hp: Int
    var strength: Int
}

private enum School: String, Codable {
    case fire
    case frost
}

private struct Ability: Codable, Equatable {
    var code: String
    var name: String
    var cooldown: Double
    var isPassive: Bool
    var stats: Stats
    var tags: [String]
    var nickname: String?
}

final class CSVTableTests: XCTestCase {
    func testQuotedFieldsWithDelimitersNewlinesAndEscapes() throws {
        let csv = "a,b,c\r\n"
            + "\"x,y\",\"he said \"\"hi\"\"\",\"line\ntwo\"\r\n"
        let table = try CSVTable.parse(csv)
        XCTAssertEqual(table.headers, ["a", "b", "c"])
        XCTAssertEqual(table.rows, [["x,y", "he said \"hi\"", "line\ntwo"]])
    }

    func testBlankLinesAndBOMAreIgnored() throws {
        let table = try CSVTable.parse("\u{FEFF}a,b\n\n1,2\n\n")
        XCTAssertEqual(table.headers, ["a", "b"])
        XCTAssertEqual(table.rows, [["1", "2"]])
    }

    func testShortRowsAreKeptAndLongRowsThrow() throws {
        XCTAssertEqual(try CSVTable.parse("a,b,c\n1,2").rows, [["1", "2"]])
        XCTAssertThrowsError(try CSVTable.parse("a,b\n1,2,3")) { error in
            XCTAssertEqual(error as? CSVError, .tooManyValues(row: 0, expected: 2, found: 3))
        }
    }

    func testUnterminatedQuoteReportsWhereItOpened() {
        XCTAssertThrowsError(try CSVTable.parse("a\n\"oops\n")) { error in
            XCTAssertEqual(error as? CSVError, .unterminatedQuote(line: 2))
        }
    }

    func testDuplicateAndConflictingColumnsThrow() {
        XCTAssertThrowsError(try CSVTable.parse("a,a\n1,2")) { error in
            XCTAssertEqual(error as? CSVError, .duplicateColumn("a"))
        }
        XCTAssertThrowsError(try CSVTable.parse("s,s.hp\n1,2")) { error in
            XCTAssertEqual(error as? CSVError, .conflictingColumn("s.hp"))
        }
        XCTAssertThrowsError(try CSVTable.parse("s.hp,s\n1,2")) { error in
            XCTAssertEqual(error as? CSVError, .conflictingColumn("s"))
        }
    }

    func testCustomDelimiter() throws {
        let table = try CSVTable.parse("a;b\n1;2", delimiter: ";")
        XCTAssertEqual(table.rows, [["1", "2"]])
    }

    func testSerializationQuotesOnlyWhereNeededAndSurvivesReparsing() throws {
        let table = try CSVTable(
            headers: ["a", "b", "c"],
            rows: [
                ["plain", "has,comma", "has\"quote"],
                [" pad ", "line\nbreak", ""]
            ]
        )
        XCTAssertEqual(table.serialized(), """
        a,b,c
        plain,"has,comma","has""quote"
        " pad ","line\nbreak",

        """)
        XCTAssertEqual(try CSVTable.parse(table.serialized()).rows, table.rows)
    }
}

final class CSVDecoderTests: XCTestCase {
    func testDecodesNestedRows() throws {
        let csv = """
        code,name,cooldown,isPassive,stats.hp,stats.strength,tags.0,tags.1,nickname
        fire,Fire,2500,false,10,4,magical,fire,Boom
        heal,Heal, 1000 ,TRUE,12,1,magical,,
        """
        let abilities = try CSVDecoder().decode([Ability].self, from: csv)

        XCTAssertEqual(abilities.count, 2)
        XCTAssertEqual(abilities[0], Ability(
            code: "fire",
            name: "Fire",
            cooldown: 2500,
            isPassive: false,
            stats: Stats(hp: 10, strength: 4),
            tags: ["magical", "fire"],
            nickname: "Boom"
        ))
        XCTAssertEqual(abilities[1].cooldown, 1000)
        XCTAssertEqual(abilities[1].isPassive, true)
        XCTAssertEqual(abilities[1].tags, ["magical"])
        XCTAssertNil(abilities[1].nickname)
    }

    func testEmptyCellIsNilForOptionalAndEmptyStringForRequired() throws {
        struct Row: Codable { var name: String; var nickname: String? }
        let rows = try CSVDecoder().decode([Row].self, from: "name,nickname\n,\n")
        XCTAssertEqual(rows[0].name, "")
        XCTAssertNil(rows[0].nickname)
    }

    func testRawRepresentableEnum() throws {
        struct Row: Codable { var school: School }
        let rows = try CSVDecoder().decode([Row].self, from: "school\nfrost")
        XCTAssertEqual(rows[0].school, .frost)
    }

    func testInteriorBlankSurvivesAndTrailingBlankTrims() throws {
        struct Row: Codable { var tags: [String?] }
        let rows = try CSVDecoder().decode(
            [Row].self,
            from: "tags.0,tags.1,tags.2\na,,c\na,,\n"
        )
        XCTAssertEqual(rows[0].tags, ["a", nil, "c"])
        XCTAssertEqual(rows[1].tags, ["a"])
    }

    func testSparseIndicesCollapseInSortedOrder() throws {
        struct Row: Codable { var tags: [String] }
        let rows = try CSVDecoder().decode(
            [Row].self,
            from: "tags.2,tags.0\nlast,first\n"
        )
        XCTAssertEqual(rows[0].tags, ["first", "last"])
    }

    func testEmptyLeafDecodesAsEmptyArrayAndNonEmptyLeafThrows() throws {
        struct Row: Codable { var code: String; var tags: [String] }
        let rows = try CSVDecoder().decode([Row].self, from: "code,tags\na,\n")
        XCTAssertEqual(rows[0].tags, [])
        XCTAssertThrowsError(try CSVDecoder().decode([Row].self, from: "code,tags\na,boom\n"))
    }

    func testOptionalNestedGroupIsNilWhenWhollyEmpty() throws {
        struct Row: Codable { var code: String; var stats: Stats? }
        let rows = try CSVDecoder().decode(
            [Row].self,
            from: "code,stats.hp,stats.strength\na,,\nb,1,2"
        )
        XCTAssertNil(rows[0].stats)
        XCTAssertEqual(rows[1].stats, Stats(hp: 1, strength: 2))
    }

    func testSingleRowDecodesIntoAStruct() throws {
        let stats = try CSVDecoder().decode(Stats.self, from: "hp,strength\n3,4")
        XCTAssertEqual(stats, Stats(hp: 3, strength: 4))
        XCTAssertThrowsError(
            try CSVDecoder().decode(Stats.self, from: "hp,strength\n3,4\n5,6")
        ) { error in
            XCTAssertEqual(error as? CSVError, .expectedSingleRow(found: 2))
        }
    }

    func testMissingColumnReportsKeyNotFound() {
        XCTAssertThrowsError(
            try CSVDecoder().decode([Stats].self, from: "hp\n3")
        ) { error in
            guard case let .keyNotFound(key, _)? = error as? DecodingError else {
                return XCTFail("expected keyNotFound, got \(error)")
            }
            XCTAssertEqual(key.stringValue, "strength")
        }
    }

    func testBadNumberReportsCodingPath() {
        XCTAssertThrowsError(
            try CSVDecoder().decode([Stats].self, from: "hp,strength\nx,4")
        ) { error in
            guard case let .typeMismatch(_, context)? = error as? DecodingError else {
                return XCTFail("expected typeMismatch, got \(error)")
            }
            XCTAssertEqual(context.codingPath.map(\.stringValue), ["0", "hp"])
        }
    }

    func testHeaderOnlyDecodesAsEmptyArray() throws {
        XCTAssertEqual(try CSVDecoder().decode([Stats].self, from: "hp,strength\n"), [])
    }
}
