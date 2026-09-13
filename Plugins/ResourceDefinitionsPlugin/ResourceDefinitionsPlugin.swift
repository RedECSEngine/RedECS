import Foundation
import PackagePlugin

@main
struct ResourceDefinitionsPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        try ResourceDefinitionsCommand(
            baseDirectory: target.directoryURL,
            workDirectory: context.pluginWorkDirectoryURL,
            generator: try context.tool(named: "ResourceDefinitionsGenerator").url,
            targetName: target.name
        ).commands()
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension ResourceDefinitionsPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        try ResourceDefinitionsCommand(
            baseDirectory: context.xcodeProject.directoryURL,
            workDirectory: context.pluginWorkDirectoryURL,
            generator: try context.tool(named: "ResourceDefinitionsGenerator").url,
            targetName: target.displayName
        ).commands()
    }
}
#endif

struct ResourceDefinitionsConfiguration: Decodable {
    static let fileName = "resource-definitions.json"

    var path: String?
    var typeName: String?
    var accessLevel: String?
}

struct ResourceDefinitionsCommand {
    let baseDirectory: URL
    let workDirectory: URL
    let generator: URL
    let targetName: String

    func commands() throws -> [Command] {
        let configurationURL = baseDirectory.appending(path: ResourceDefinitionsConfiguration.fileName)
        let configuration = try loadConfiguration(at: configurationURL)
        let resourceDirectory = baseDirectory.appending(path: configuration.path ?? "Resources")
        let resourceFiles = try listFiles(in: resourceDirectory)
        let outputFile = workDirectory.appending(path: "ResourceDefinitions.swift")
        let configurationInputs = FileManager.default.fileExists(atPath: configurationURL.path) ? [configurationURL] : []

        return [
            .buildCommand(
                displayName: "Generating resource definitions for \(targetName)",
                executable: generator,
                arguments: [
                    outputFile.path,
                    configuration.typeName ?? "Resources",
                    configuration.accessLevel ?? "internal",
                ] + resourceFiles.map(\.relativePath),
                inputFiles: resourceFiles.map(\.url) + configurationInputs,
                outputFiles: [outputFile]
            )
        ]
    }

    private func loadConfiguration(at url: URL) throws -> ResourceDefinitionsConfiguration {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return ResourceDefinitionsConfiguration()
        }
        return try JSONDecoder().decode(ResourceDefinitionsConfiguration.self, from: Data(contentsOf: url))
    }

    private func listFiles(in directory: URL) throws -> [(url: URL, relativePath: String)] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        let directoryPath = directory.standardizedFileURL.path + "/"
        var files: [(url: URL, relativePath: String)] = []
        for case let url as URL in enumerator {
            guard try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else { continue }
            let path = url.standardizedFileURL.path
            guard path.hasPrefix(directoryPath) else { continue }
            files.append((url, String(path.dropFirst(directoryPath.count))))
        }
        return files.sorted { $0.relativePath < $1.relativePath }
    }
}
