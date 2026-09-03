enum CSVText {
    static let whitespace: Set<Character> = [" ", "\t", "\n", "\r", "\r\n"]

    static func trimmed(_ value: String) -> String {
        var slice = value[...]
        while let first = slice.first, whitespace.contains(first) {
            slice = slice.dropFirst()
        }
        while let last = slice.last, whitespace.contains(last) {
            slice = slice.dropLast()
        }
        return String(slice)
    }
}

extension Character {
    var isCSVRowTerminator: Bool {
        self == "\n" || self == "\r\n" || self == "\r"
    }
}

extension [String] {
    func cell(at index: Int) -> String {
        indices.contains(index) ? self[index] : ""
    }
}
