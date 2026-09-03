public struct CSVTable: Equatable, Sendable {
    public let headers: [String]
    public let rows: [[String]]
    let columns: CSVColumnTree

    public init(headers: [String], rows: [[String]]) throws {
        let names = headers.map(CSVText.trimmed)
        for (index, row) in rows.enumerated() where row.count > names.count {
            throw CSVError.tooManyValues(
                row: index,
                expected: names.count,
                found: row.count
            )
        }
        self.headers = names
        self.rows = rows
        self.columns = try CSVColumnTree.build(headers: names)
    }

    public static func parse(
        _ text: String,
        delimiter: Character = ","
    ) throws -> CSVTable {
        let lines = try CSVParser.parse(text, delimiter: delimiter)
        guard let header = lines.first else { throw CSVError.emptyDocument }
        return try CSVTable(headers: header, rows: Array(lines.dropFirst()))
    }

    public func serialized(
        delimiter: Character = ",",
        lineTerminator: String = "\n"
    ) -> String {
        guard !headers.isEmpty else { return "" }
        var output = ""
        append(headers, to: &output, delimiter: delimiter, lineTerminator: lineTerminator)
        for row in rows {
            append(row, to: &output, delimiter: delimiter, lineTerminator: lineTerminator)
        }
        return output
    }

    private func append(
        _ values: [String],
        to output: inout String,
        delimiter: Character,
        lineTerminator: String
    ) {
        for (index, value) in values.enumerated() {
            if index > 0 { output.append(delimiter) }
            output.append(CSVTable.escaped(value, delimiter: delimiter))
        }
        output.append(contentsOf: lineTerminator)
    }

    static func escaped(_ value: String, delimiter: Character) -> String {
        var needsQuotes = value.first == " " || value.last == " "
        if !needsQuotes {
            for character in value {
                if character == delimiter
                    || character == "\""
                    || character.isCSVRowTerminator {
                    needsQuotes = true
                    break
                }
            }
        }
        guard needsQuotes else { return value }
        var quoted = "\""
        for character in value {
            if character == "\"" { quoted.append("\"") }
            quoted.append(character)
        }
        quoted.append("\"")
        return quoted
    }
}
