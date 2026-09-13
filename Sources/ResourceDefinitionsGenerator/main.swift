import Foundation
import ResourceDefinitionsCore

func fail(_ message: String) -> Never {
    print("error: \(message)")
    exit(1)
}

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count >= 3 else {
    fail("usage: ResourceDefinitionsGenerator <output-file> <type-name> <access-level> [resource-path ...]")
}

let outputPath = arguments[0]
let typeName = arguments[1]

guard let accessLevel = AccessLevel(rawValue: arguments[2]) else {
    fail("access level '\(arguments[2])' must be one of \(AccessLevel.allCases.map(\.rawValue).joined(separator: ", "))")
}
guard ResourceDefinitionsRenderer.isValidTypeName(typeName) else {
    fail("type name '\(typeName)' is not a valid Swift type name")
}

let classification = ResourceClassifier.classify(paths: Array(arguments.dropFirst(3)))
for diagnostic in classification.diagnostics {
    switch diagnostic.severity {
    case .warning:
        print("warning: \(diagnostic.message)")
    case .error:
        print("error: \(diagnostic.message)")
    }
}
if classification.hasErrors {
    exit(1)
}

let source = ResourceDefinitionsRenderer.render(classification.catalog, typeName: typeName, accessLevel: accessLevel)
do {
    try source.write(toFile: outputPath, atomically: true, encoding: .utf8)
} catch {
    fail("could not write \(outputPath): \(error)")
}
