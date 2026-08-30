public struct CasePath<Root, Value> {
    public let extract: (Root) -> Value?
    public let embed: (Value) -> Root

    public init(
        extract: @escaping (Root) -> Value?,
        embed: @escaping (Value) -> Root
    ) {
        self.extract = extract
        self.embed = embed
    }
}

public protocol CasePathable {
    associatedtype AllCasePaths
    static var allCasePaths: AllCasePaths { get }
}

@attached(member, names: named(AllCasePaths), named(allCasePaths))
@attached(extension, conformances: CasePathable)
public macro CasePathable() = #externalMacro(module: "RedECSMacros", type: "CasePathableMacro")
