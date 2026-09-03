public struct CSVDecoder: Sendable {
    public var delimiter: Character

    public init(delimiter: Character = ",") {
        self.delimiter = delimiter
    }

    public func decode<T: Decodable>(_ type: T.Type, from text: String) throws -> T {
        try decode(type, from: CSVTable.parse(text, delimiter: delimiter))
    }

    public func decode<T: Decodable>(_ type: T.Type, from table: CSVTable) throws -> T {
        try T(from: CSVTableDecoder(table: table))
    }
}
