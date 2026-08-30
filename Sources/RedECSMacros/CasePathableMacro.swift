import SwiftSyntax
import SwiftSyntaxMacros

public struct CasePathableMacro {}

struct CasePathableMacroError: Error, CustomStringConvertible {
    let description: String
}

private final class SelfTypeRewriter: SyntaxRewriter {
    let selfTypeName: String

    init(selfTypeName: String) {
        self.selfTypeName = selfTypeName
        super.init()
    }

    override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
        guard node.name.text == "Self" else { return super.visit(node) }
        var replacement = node
        replacement.name = .identifier(selfTypeName, leadingTrivia: node.name.leadingTrivia, trailingTrivia: node.name.trailingTrivia)
        return TypeSyntax(replacement)
    }
}

private struct CaseInfo {
    let name: String
    let valueType: String
    let extractClosure: String
    let embedClosure: String
}

private func selfTypeName(of enumDecl: EnumDeclSyntax) -> String {
    let base = enumDecl.name.text
    guard let genericParameters = enumDecl.genericParameterClause?.parameters, !genericParameters.isEmpty else {
        return base
    }
    let arguments = genericParameters.map { $0.name.text }.joined(separator: ", ")
    return "\(base)<\(arguments)>"
}

private func accessPrefix(of enumDecl: EnumDeclSyntax) -> String {
    for modifier in enumDecl.modifiers {
        let name = modifier.name.text
        if name == "public" || name == "package" {
            return "\(name) "
        }
    }
    return ""
}

private func caseInfo(for element: EnumCaseElementSyntax, selfName: String) -> CaseInfo {
    let name = element.name.text
    let rewriter = SelfTypeRewriter(selfTypeName: selfName)
    let parameters = element.parameterClause?.parameters.map { parameter -> (label: String?, type: String) in
        let label = parameter.firstName.flatMap { $0.text == "_" ? nil : $0.text }
        let type = rewriter.rewrite(parameter.type).trimmedDescription
        return (label, type)
    } ?? []

    if parameters.isEmpty {
        return CaseInfo(
            name: name,
            valueType: "Void",
            extractClosure: "{ if case .\(name) = $0 { () } else { nil } }",
            embedClosure: "{ _ in .\(name) }"
        )
    }

    if parameters.count == 1 {
        let parameter = parameters[0]
        let embedArgument = parameter.label.map { "\($0): $0" } ?? "$0"
        return CaseInfo(
            name: name,
            valueType: parameter.type,
            extractClosure: "{ if case .\(name)(let v0) = $0 { v0 } else { nil } }",
            embedClosure: "{ .\(name)(\(embedArgument)) }"
        )
    }

    let valueType = "(" + parameters.map { parameter in
        parameter.label.map { "\($0): \(parameter.type)" } ?? parameter.type
    }.joined(separator: ", ") + ")"
    let bindings = parameters.indices.map { "let v\($0)" }.joined(separator: ", ")
    let tupleElements = parameters.enumerated().map { index, parameter in
        parameter.label.map { "\($0): v\(index)" } ?? "v\(index)"
    }.joined(separator: ", ")
    let embedArguments = parameters.enumerated().map { index, parameter in
        let accessor = parameter.label ?? "\(index)"
        return parameter.label.map { "\($0): $0.\(accessor)" } ?? "$0.\(accessor)"
    }.joined(separator: ", ")
    return CaseInfo(
        name: name,
        valueType: valueType,
        extractClosure: "{ if case .\(name)(\(bindings)) = $0 { (\(tupleElements)) } else { nil } }",
        embedClosure: "{ .\(name)(\(embedArguments)) }"
    )
}

extension CasePathableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw CasePathableMacroError(description: "@CasePathable can only be attached to an enum")
        }
        let selfName = selfTypeName(of: enumDecl)
        let access = accessPrefix(of: enumDecl)

        var cases: [CaseInfo] = []
        for member in enumDecl.memberBlock.members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
            for element in caseDecl.elements {
                cases.append(caseInfo(for: element, selfName: selfName))
            }
        }

        let properties = cases.map { info in
            """
                \(access)var \(info.name): CasePath<\(selfName), \(info.valueType)> {
                    CasePath(
                        extract: \(info.extractClosure),
                        embed: \(info.embedClosure)
                    )
                }
            """
        }.joined(separator: "\n")

        let allCasePathsStruct = """
        \(access)struct AllCasePaths {
        \(properties)
        }
        """

        let allCasePathsProperty = """
        \(access)static var allCasePaths: AllCasePaths {
            AllCasePaths()
        }
        """

        return [
            DeclSyntax(stringLiteral: allCasePathsStruct),
            DeclSyntax(stringLiteral: allCasePathsProperty),
        ]
    }
}

extension CasePathableMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(EnumDeclSyntax.self) else {
            throw CasePathableMacroError(description: "@CasePathable can only be attached to an enum")
        }
        guard !protocols.isEmpty else { return [] }
        return [try ExtensionDeclSyntax("extension \(type.trimmed): CasePathable {}")]
    }
}
