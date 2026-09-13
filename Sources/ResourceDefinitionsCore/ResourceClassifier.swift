public enum ResourceClassifier {
    static let imageExtensions: Set<String> = ["png", "jpg", "jpeg"]
    static let audioExtensions: Set<String> = ["m4a", "mp3", "ogg", "wav"]
    static let reservedIdentifiers: Set<String> = ["all"]

    public static func classify(paths: [String]) -> ResourceClassification {
        var diagnostics: [ResourceDiagnostic] = []
        let files = topLevelFiles(in: paths, diagnostics: &diagnostics)
            .map(ResourceFileName.init)
            .sorted { $0.fileName < $1.fileName }
        let extensionsByBase = Dictionary(grouping: files, by: \.base)
            .mapValues { Set($0.map(\.lowercasedExt)) }

        var filesByGroup: [ResourceGroup: [ResourceFileName]] = [:]
        for file in files {
            if let group = group(for: file, siblingExtensions: extensionsByBase[file.base] ?? []) {
                filesByGroup[group, default: []].append(file)
            }
        }

        var catalog = ResourceCatalog()
        for group in ResourceGroup.allCases {
            catalog.groups[group] = entries(for: filesByGroup[group] ?? [], in: group, diagnostics: &diagnostics)
        }
        return ResourceClassification(catalog: catalog, diagnostics: diagnostics)
    }

    static func group(for file: ResourceFileName, siblingExtensions: Set<String>) -> ResourceGroup? {
        let ext = file.lowercasedExt
        switch ext {
        case "tmj":
            return .tileMaps
        case "tsj":
            return .tileSets
        case "fnt":
            return .fonts
        case "csv":
            return .csv
        case "json":
            if !siblingExtensions.isDisjoint(with: imageExtensions) {
                return nil
            }
            if !siblingExtensions.isDisjoint(with: audioExtensions) {
                return .sounds
            }
            return .json
        case _ where imageExtensions.contains(ext):
            return siblingExtensions.contains("json") ? .images : nil
        default:
            return nil
        }
    }

    private static func topLevelFiles(in paths: [String], diagnostics: inout [ResourceDiagnostic]) -> [String] {
        var skippedDirectories: Set<String> = []
        var files: [String] = []
        for path in paths {
            let components = path.split(separator: "/").map(String.init)
            guard let first = components.first else { continue }
            if components.count > 1 {
                if !first.lowercased().hasSuffix(".xcassets") {
                    skippedDirectories.insert(first)
                }
            } else if !first.hasPrefix(".") {
                files.append(first)
            }
        }
        for directory in skippedDirectories.sorted() {
            diagnostics.append(.warning("resources in subdirectory '\(directory)' are not included in resource definitions; move them to the top level of the resource folder"))
        }
        return files
    }

    private static func entries(
        for files: [ResourceFileName],
        in group: ResourceGroup,
        diagnostics: inout [ResourceDiagnostic]
    ) -> [ResourceEntry] {
        var fileNameByIdentifier: [String: String] = [:]
        var entries: [ResourceEntry] = []
        for file in files {
            guard let identifier = SwiftIdentifier.make(from: file.base) else {
                diagnostics.append(.error("'\(file.fileName)' has no characters usable in a Swift identifier"))
                continue
            }
            if reservedIdentifiers.contains(identifier) {
                diagnostics.append(.error("'\(file.fileName)' would generate '\(group.enumName).\(identifier)', which is reserved; rename the file"))
                continue
            }
            if let existing = fileNameByIdentifier[identifier] {
                diagnostics.append(.error("'\(existing)' and '\(file.fileName)' both generate '\(group.enumName).\(identifier)'; rename one of them"))
                continue
            }
            fileNameByIdentifier[identifier] = file.fileName
            entries.append(ResourceEntry(identifier: identifier, name: file.base, ext: file.ext))
        }
        return entries
    }
}

struct ResourceFileName {
    let fileName: String
    let base: String
    let ext: String

    var lowercasedExt: String {
        ext.lowercased()
    }

    init(_ fileName: String) {
        self.fileName = fileName
        if let dot = fileName.lastIndex(of: "."), dot != fileName.startIndex {
            base = String(fileName[..<dot])
            ext = String(fileName[fileName.index(after: dot)...])
        } else {
            base = fileName
            ext = ""
        }
    }
}
