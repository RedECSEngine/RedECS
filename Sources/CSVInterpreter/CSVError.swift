public enum CSVError: Error, Equatable, Sendable {
    case emptyDocument
    case unterminatedQuote(line: Int)
    case unexpectedQuote(line: Int)
    case emptyColumnName(index: Int)
    case duplicateColumn(String)
    case conflictingColumn(String)
    case tooManyValues(row: Int, expected: Int, found: Int)
    case expectedSingleRow(found: Int)
}
