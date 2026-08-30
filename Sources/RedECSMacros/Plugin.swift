import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct RedECSMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CasePathableMacro.self
    ]
}
