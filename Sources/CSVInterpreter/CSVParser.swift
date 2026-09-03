enum CSVParser {
    static func parse(_ text: String, delimiter: Character) throws -> [[String]] {
        var rows: [[String]] = []
        var fields: [String] = []
        var field = ""
        var inQuotes = false
        var rowHasContent = false
        var line = 1
        var quoteStartLine = 1

        var index = text.startIndex
        if text.first == "\u{FEFF}" {
            index = text.index(after: index)
        }

        while index < text.endIndex {
            let character = text[index]

            if inQuotes {
                if character == "\"" {
                    let next = text.index(after: index)
                    if next < text.endIndex, text[next] == "\"" {
                        field.append("\"")
                        index = text.index(after: next)
                    } else {
                        inQuotes = false
                        index = next
                    }
                } else {
                    if character.isCSVRowTerminator { line += 1 }
                    field.append(character)
                    index = text.index(after: index)
                }
                continue
            }

            switch character {
            case "\"":
                guard field.isEmpty else { throw CSVError.unexpectedQuote(line: line) }
                inQuotes = true
                quoteStartLine = line
                rowHasContent = true
            case delimiter:
                fields.append(field)
                field = ""
                rowHasContent = true
            case let terminator where terminator.isCSVRowTerminator:
                fields.append(field)
                field = ""
                if rowHasContent { rows.append(fields) }
                fields = []
                rowHasContent = false
                line += 1
            default:
                field.append(character)
                rowHasContent = true
            }
            index = text.index(after: index)
        }

        guard !inQuotes else { throw CSVError.unterminatedQuote(line: quoteStartLine) }

        if rowHasContent {
            fields.append(field)
            rows.append(fields)
        }

        return rows
    }
}
