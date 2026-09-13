public enum AccessLevel: String, CaseIterable, Sendable {
    case `internal`
    case `package`
    case `public`
}

public enum ResourceDefinitionsRenderer {
    public static func isValidTypeName(_ name: String) -> Bool {
        SwiftIdentifier.isValidTypeName(name)
    }

    public static func render(_ catalog: ResourceCatalog, typeName: String, accessLevel: AccessLevel) -> String {
        let access = accessLevel.rawValue
        let groups = ResourceGroup.allCases.map { group in
            renderGroup(group, entries: catalog.entries(in: group), access: access)
        }
        let preloadableGroups = ResourceGroup.allCases
            .filter(\.isPreloadable)
            .map { "        \($0.enumName).all," }
        return (
            [
                "import RedECS",
                "",
                "\(access) enum \(typeName) {",
                groups.joined(separator: "\n\n"),
                "",
                "    \(access) static let all: [LoadableResource] = [",
            ]
            + preloadableGroups
            + [
                "    ].flatMap { $0 }",
                "}",
                "",
            ]
        ).joined(separator: "\n")
    }

    private static func renderGroup(_ group: ResourceGroup, entries: [ResourceEntry], access: String) -> String {
        let header = "    \(access) enum \(group.enumName) {"
        guard !entries.isEmpty else {
            return [header, "        \(access) static let all: [LoadableResource] = []", "    }"].joined(separator: "\n")
        }
        let properties = entries.map { entry in
            "        \(access) static let \(SwiftIdentifier.escaped(entry.identifier)) = LoadableResource(name: \(literal(entry.name)), ext: \(literal(entry.ext)), type: .\(group.resourceTypeCase))"
        }
        let listItems = entries.map { "            \(SwiftIdentifier.escaped($0.identifier))," }
        return ([header] + properties + ["", "        \(access) static let all: [LoadableResource] = ["] + listItems + ["        ]", "    }"])
            .joined(separator: "\n")
    }

    private static func literal(_ value: String) -> String {
        let escaped = value.flatMap { character -> [Character] in
            character == "\\" || character == "\"" ? ["\\", character] : [character]
        }
        return "\"" + String(escaped) + "\""
    }
}
