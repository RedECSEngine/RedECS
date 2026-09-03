struct CSVTableDecoder: Decoder {
    let table: CSVTable

    var codingPath: [CodingKey] { [] }
    var userInfo: [CodingUserInfoKey: Any] { [:] }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        CSVRowsDecodingContainer(table: table)
    }

    func container<Key: CodingKey>(
        keyedBy type: Key.Type
    ) throws -> KeyedDecodingContainer<Key> {
        try singleRowDecoder().container(keyedBy: type)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        try singleRowDecoder().singleValueContainer()
    }

    private func singleRowDecoder() throws -> CSVRowDecoder {
        guard table.rows.count == 1 else {
            throw CSVError.expectedSingleRow(found: table.rows.count)
        }
        return CSVRowDecoder(columns: table.columns, row: table.rows[0], codingPath: [])
    }
}

struct CSVRowsDecodingContainer: UnkeyedDecodingContainer {
    let table: CSVTable
    let codingPath: [CodingKey] = []
    var currentIndex: Int = 0

    var count: Int? { table.rows.count }
    var isAtEnd: Bool { currentIndex >= table.rows.count }

    mutating func decodeNil() throws -> Bool { false }

    mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try T(from: nextDecoder())
    }

    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy type: NestedKey.Type
    ) throws -> KeyedDecodingContainer<NestedKey> {
        try nextDecoder().container(keyedBy: type)
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        try nextDecoder().unkeyedContainer()
    }

    mutating func superDecoder() throws -> Decoder {
        try nextDecoder()
    }

    private mutating func nextDecoder() throws -> CSVRowDecoder {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Any.self, .init(
                codingPath: codingPath,
                debugDescription: "No row at index \(currentIndex)"
            ))
        }
        let index = currentIndex
        currentIndex += 1
        return CSVRowDecoder(
            columns: table.columns,
            row: table.rows[index],
            codingPath: [CSVCodingKey(intValue: index)]
        )
    }
}

struct CSVRowDecoder: Decoder {
    let columns: CSVColumnTree
    let row: [String]
    let codingPath: [CodingKey]

    var userInfo: [CodingUserInfoKey: Any] { [:] }

    func container<Key: CodingKey>(
        keyedBy type: Key.Type
    ) throws -> KeyedDecodingContainer<Key> {
        guard columns.columnIndex == nil else {
            throw DecodingError.typeMismatch([String: Any].self, .init(
                codingPath: codingPath,
                debugDescription: "\"\(pathDescription)\" is a single column; "
                    + "expected sub-columns such as \"\(pathDescription).<field>\""
            ))
        }
        return KeyedDecodingContainer(CSVKeyedDecodingContainer<Key>(
            columns: columns,
            row: row,
            codingPath: codingPath
        ))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        try CSVIndexedDecodingContainer(
            columns: columns,
            row: row,
            codingPath: codingPath
        )
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        guard let columnIndex = columns.columnIndex else {
            throw DecodingError.typeMismatch(String.self, .init(
                codingPath: codingPath,
                debugDescription: "\"\(pathDescription)\" is a group of columns, not a value"
            ))
        }
        return CSVSingleValueDecodingContainer(
            decoder: self,
            cell: row.cell(at: columnIndex)
        )
    }

    var pathDescription: String {
        codingPath.map(\.stringValue).joined(separator: ".")
    }
}

struct CSVKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let columns: CSVColumnTree
    let row: [String]
    let codingPath: [CodingKey]

    var allKeys: [Key] { columns.childNames.compactMap(Key.init(stringValue:)) }

    func contains(_ key: Key) -> Bool {
        columns.child(named: key.stringValue) != nil
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        guard let child = columns.child(named: key.stringValue) else { return true }
        return !child.hasValue(in: row)
    }

    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        try T(from: decoder(for: key))
    }

    func nestedContainer<NestedKey: CodingKey>(
        keyedBy type: NestedKey.Type,
        forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey> {
        try decoder(for: key).container(keyedBy: type)
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        try decoder(for: key).unkeyedContainer()
    }

    func superDecoder() throws -> Decoder {
        CSVRowDecoder(columns: columns, row: row, codingPath: codingPath)
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        try decoder(for: key)
    }

    private func decoder(for key: Key) throws -> CSVRowDecoder {
        guard let child = columns.child(named: key.stringValue) else {
            throw DecodingError.keyNotFound(key, .init(
                codingPath: codingPath,
                debugDescription: "No column named \"\(key.stringValue)\""
            ))
        }
        return CSVRowDecoder(columns: child, row: row, codingPath: codingPath + [key])
    }
}

struct CSVIndexedDecodingContainer: UnkeyedDecodingContainer {
    private let elements: [CSVColumnTree]
    private let row: [String]
    let codingPath: [CodingKey]
    var currentIndex: Int = 0

    init(columns: CSVColumnTree, row: [String], codingPath: [CodingKey]) throws {
        if let columnIndex = columns.columnIndex {
            guard row.cell(at: columnIndex).isEmpty else {
                throw DecodingError.typeMismatch([Any].self, .init(
                    codingPath: codingPath,
                    debugDescription: "Expected indexed sub-columns such as \"0\", \"1\"; "
                        + "found a single column holding \"\(row.cell(at: columnIndex))\""
                ))
            }
            self.elements = []
            self.row = row
            self.codingPath = codingPath
            return
        }

        var indexed: [(Int, CSVColumnTree)] = []
        for name in columns.childNames {
            guard let position = Int(name), let child = columns.child(named: name) else {
                throw DecodingError.typeMismatch([Any].self, .init(
                    codingPath: codingPath,
                    debugDescription: "Expected indexed sub-columns such as \"0\", \"1\"; "
                        + "found \"\(name)\""
                ))
            }
            indexed.append((position, child))
        }
        indexed.sort { $0.0 < $1.0 }

        var ordered = indexed.map(\.1)
        while let last = ordered.last, !last.hasValue(in: row) {
            ordered.removeLast()
        }

        self.elements = ordered
        self.row = row
        self.codingPath = codingPath
    }

    var count: Int? { elements.count }
    var isAtEnd: Bool { currentIndex >= elements.count }

    mutating func decodeNil() throws -> Bool {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Any.self, .init(
                codingPath: codingPath,
                debugDescription: "No element at index \(currentIndex)"
            ))
        }
        guard !elements[currentIndex].hasValue(in: row) else { return false }
        currentIndex += 1
        return true
    }

    mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try T(from: nextDecoder())
    }

    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy type: NestedKey.Type
    ) throws -> KeyedDecodingContainer<NestedKey> {
        try nextDecoder().container(keyedBy: type)
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        try nextDecoder().unkeyedContainer()
    }

    mutating func superDecoder() throws -> Decoder {
        try nextDecoder()
    }

    private mutating func nextDecoder() throws -> CSVRowDecoder {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Any.self, .init(
                codingPath: codingPath,
                debugDescription: "No element at index \(currentIndex)"
            ))
        }
        let element = elements[currentIndex]
        let key = CSVCodingKey(intValue: currentIndex)
        currentIndex += 1
        return CSVRowDecoder(columns: element, row: row, codingPath: codingPath + [key])
    }
}

struct CSVSingleValueDecodingContainer: SingleValueDecodingContainer {
    let decoder: CSVRowDecoder
    let cell: String

    var codingPath: [CodingKey] { decoder.codingPath }

    func decodeNil() -> Bool { cell.isEmpty }

    func decode(_ type: String.Type) throws -> String { cell }

    func decode(_ type: Bool.Type) throws -> Bool {
        switch CSVText.trimmed(cell).lowercased() {
        case "true", "yes", "1": return true
        case "false", "no", "0": return false
        default: throw mismatch(Bool.self)
        }
    }

    func decode(_ type: Double.Type) throws -> Double { try convert { Double($0) } }
    func decode(_ type: Float.Type) throws -> Float { try convert { Float($0) } }
    func decode(_ type: Int.Type) throws -> Int { try convert { Int($0) } }
    func decode(_ type: Int8.Type) throws -> Int8 { try convert { Int8($0) } }
    func decode(_ type: Int16.Type) throws -> Int16 { try convert { Int16($0) } }
    func decode(_ type: Int32.Type) throws -> Int32 { try convert { Int32($0) } }
    func decode(_ type: Int64.Type) throws -> Int64 { try convert { Int64($0) } }
    func decode(_ type: UInt.Type) throws -> UInt { try convert { UInt($0) } }
    func decode(_ type: UInt8.Type) throws -> UInt8 { try convert { UInt8($0) } }
    func decode(_ type: UInt16.Type) throws -> UInt16 { try convert { UInt16($0) } }
    func decode(_ type: UInt32.Type) throws -> UInt32 { try convert { UInt32($0) } }
    func decode(_ type: UInt64.Type) throws -> UInt64 { try convert { UInt64($0) } }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try T(from: decoder)
    }

    private func convert<T>(_ make: (String) -> T?) throws -> T {
        let text = CSVText.trimmed(cell)
        guard !text.isEmpty else {
            throw DecodingError.valueNotFound(T.self, .init(
                codingPath: codingPath,
                debugDescription: "Cell is empty"
            ))
        }
        guard let value = make(text) else { throw mismatch(T.self) }
        return value
    }

    private func mismatch<T>(_ type: T.Type) -> DecodingError {
        DecodingError.typeMismatch(type, .init(
            codingPath: codingPath,
            debugDescription: "\"\(cell)\" is not a valid \(type)"
        ))
    }
}
