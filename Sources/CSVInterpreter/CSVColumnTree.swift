struct CSVColumnTree: Equatable, Sendable {
    var columnIndex: Int?
    var childNames: [String] = []
    var children: [String: CSVColumnTree] = [:]

    func child(named name: String) -> CSVColumnTree? { children[name] }

    func hasValue(in row: [String]) -> Bool {
        if let columnIndex {
            return !row.cell(at: columnIndex).isEmpty
        }
        for name in childNames where children[name]?.hasValue(in: row) == true {
            return true
        }
        return false
    }

    static func build(headers: [String]) throws -> CSVColumnTree {
        var root = CSVColumnTree()
        var seen: Set<String> = []
        for (index, header) in headers.enumerated() {
            let path = header.split(separator: ".").map(String.init)
            guard !header.isEmpty, !path.isEmpty else {
                throw CSVError.emptyColumnName(index: index)
            }
            guard seen.insert(header).inserted else {
                throw CSVError.duplicateColumn(header)
            }
            try root.insert(path: path[...], columnIndex: index, header: header)
        }
        return root
    }

    private mutating func insert(
        path: ArraySlice<String>,
        columnIndex index: Int,
        header: String
    ) throws {
        guard let name = path.first else {
            guard columnIndex == nil, children.isEmpty else {
                throw CSVError.conflictingColumn(header)
            }
            columnIndex = index
            return
        }
        guard columnIndex == nil else { throw CSVError.conflictingColumn(header) }
        if children[name] == nil {
            children[name] = CSVColumnTree()
            childNames.append(name)
        }
        try children[name]!.insert(
            path: path.dropFirst(),
            columnIndex: index,
            header: header
        )
    }
}
