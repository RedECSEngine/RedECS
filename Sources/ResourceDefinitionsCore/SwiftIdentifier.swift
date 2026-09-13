enum SwiftIdentifier {
    static let keywords: Set<String> = [
        "Any", "Protocol", "Self", "Type", "as", "associatedtype", "break", "case", "catch", "class",
        "continue", "default", "defer", "deinit", "do", "else", "enum", "extension", "fallthrough",
        "false", "fileprivate", "for", "func", "guard", "if", "import", "in", "init", "inout",
        "internal", "is", "let", "nil", "open", "operator", "package", "private", "protocol",
        "public", "repeat", "rethrows", "return", "self", "static", "struct", "subscript", "super",
        "switch", "throw", "throws", "true", "try", "typealias", "var", "where", "while",
    ]

    static func make(from base: String) -> String? {
        let words = base
            .split(whereSeparator: { !($0.isLetter || $0.isNumber) })
            .map(String.init)
        guard let first = words.first else { return nil }
        let camelCased = lowercasedLeadingWord(first) + words.dropFirst().map(capitalized).joined()
        return camelCased.first?.isNumber == true ? "_" + camelCased : camelCased
    }

    static func escaped(_ identifier: String) -> String {
        keywords.contains(identifier) ? "`\(identifier)`" : identifier
    }

    static func isValidTypeName(_ name: String) -> Bool {
        guard let first = name.first, first.isLetter || first == "_" else { return false }
        return name.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" } && !keywords.contains(name)
    }

    private static func lowercasedLeadingWord(_ word: String) -> String {
        let uppercasePrefixLength = word.prefix(while: \.isUppercase).count
        if uppercasePrefixLength == word.count {
            return word.lowercased()
        }
        if uppercasePrefixLength <= 1 {
            return word.prefix(1).lowercased() + word.dropFirst()
        }
        return word.prefix(uppercasePrefixLength - 1).lowercased() + word.dropFirst(uppercasePrefixLength - 1)
    }

    private static func capitalized(_ word: String) -> String {
        word.prefix(1).uppercased() + word.dropFirst()
    }
}
