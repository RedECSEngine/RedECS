import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosTestSupport
import RedECSMacros

final class CasePathableMacroTests: XCTestCase {
    let specs: [String: MacroSpec] = ["CasePathable": MacroSpec(type: CasePathableMacro.self, conformances: ["CasePathable"])]

    func testBasicEnum() {
        assertMacroExpansion(
            """
            @CasePathable
            enum GameAction: Equatable, Codable {
                case start
                case levelUp(Int)
            }
            """,
            expandedSource: """
            enum GameAction: Equatable, Codable {
                case start
                case levelUp(Int)

                struct AllCasePaths {
                    var start: CasePath<GameAction, Void> {
                        CasePath(
                            extract: {
                                if case .start = $0 {
                                    ()
                                } else {
                                    nil
                                }
                            },
                            embed: { _ in
                                .start
                            }
                        )
                    }
                    var levelUp: CasePath<GameAction, Int> {
                        CasePath(
                            extract: {
                                if case .levelUp(let v0) = $0 {
                                    v0
                                } else {
                                    nil
                                }
                            },
                            embed: {
                                .levelUp($0)
                            }
                        )
                    }
                }

                static var allCasePaths: AllCasePaths {
                    AllCasePaths()
                }
            }

            extension GameAction: CasePathable {
            }
            """,
            macroSpecs: specs
        )
    }

    func testLabeledAndMultiPayloads() {
        assertMacroExpansion(
            """
            @CasePathable
            enum Action: Equatable, Codable {
                case spawn(id: String)
                case move(x: Double, y: Double)
                case pair(Int, String)
            }
            """,
            expandedSource: """
            enum Action: Equatable, Codable {
                case spawn(id: String)
                case move(x: Double, y: Double)
                case pair(Int, String)

                struct AllCasePaths {
                    var spawn: CasePath<Action, String> {
                        CasePath(
                            extract: {
                                if case .spawn(let v0) = $0 {
                                    v0
                                } else {
                                    nil
                                }
                            },
                            embed: {
                                .spawn(id: $0)
                            }
                        )
                    }
                    var move: CasePath<Action, (x: Double, y: Double)> {
                        CasePath(
                            extract: {
                                if case .move(let v0, let v1) = $0 {
                                    (x: v0, y: v1)
                                } else {
                                    nil
                                }
                            },
                            embed: {
                                .move(x: $0.x, y: $0.y)
                            }
                        )
                    }
                    var pair: CasePath<Action, (Int, String)> {
                        CasePath(
                            extract: {
                                if case .pair(let v0, let v1) = $0 {
                                    (v0, v1)
                                } else {
                                    nil
                                }
                            },
                            embed: {
                                .pair($0.0, $0.1)
                            }
                        )
                    }
                }

                static var allCasePaths: AllCasePaths {
                    AllCasePaths()
                }
            }

            extension Action: CasePathable {
            }
            """,
            macroSpecs: specs
        )
    }

    func testGenericEnumWithSelfPayload() {
        assertMacroExpansion(
            """
            @CasePathable
            enum Wrapper<T: Equatable & Codable>: Equatable, Codable {
                case value(T)
                case recursive(Box<Self>)
            }
            """,
            expandedSource: """
            enum Wrapper<T: Equatable & Codable>: Equatable, Codable {
                case value(T)
                case recursive(Box<Self>)

                struct AllCasePaths {
                    var value: CasePath<Wrapper<T>, T> {
                        CasePath(
                            extract: {
                                if case .value(let v0) = $0 {
                                    v0
                                } else {
                                    nil
                                }
                            },
                            embed: {
                                .value($0)
                            }
                        )
                    }
                    var recursive: CasePath<Wrapper<T>, Box<Wrapper<T>>> {
                        CasePath(
                            extract: {
                                if case .recursive(let v0) = $0 {
                                    v0
                                } else {
                                    nil
                                }
                            },
                            embed: {
                                .recursive($0)
                            }
                        )
                    }
                }

                static var allCasePaths: AllCasePaths {
                    AllCasePaths()
                }
            }

            extension Wrapper: CasePathable {
            }
            """,
            macroSpecs: specs
        )
    }

    func testPublicEnum() {
        assertMacroExpansion(
            """
            @CasePathable
            public enum Action: Equatable, Codable {
                case ping
            }
            """,
            expandedSource: """
            public enum Action: Equatable, Codable {
                case ping

                public struct AllCasePaths {
                    public var ping: CasePath<Action, Void> {
                        CasePath(
                            extract: {
                                if case .ping = $0 {
                                    ()
                                } else {
                                    nil
                                }
                            },
                            embed: { _ in
                                .ping
                            }
                        )
                    }
                }

                public static var allCasePaths: AllCasePaths {
                    AllCasePaths()
                }
            }

            extension Action: CasePathable {
            }
            """,
            macroSpecs: specs
        )
    }

    func testNestedEnum() {
        assertMacroExpansion(
            """
            struct Outer {
                @CasePathable
                enum Inner: Equatable, Codable {
                    case ping
                }
            }
            """,
            expandedSource: """
            struct Outer {
                enum Inner: Equatable, Codable {
                    case ping

                    struct AllCasePaths {
                        var ping: CasePath<Inner, Void> {
                            CasePath(
                                extract: {
                                    if case .ping = $0 {
                                        ()
                                    } else {
                                        nil
                                    }
                                },
                                embed: { _ in
                                    .ping
                                }
                            )
                        }
                    }

                    static var allCasePaths: AllCasePaths {
                        AllCasePaths()
                    }
                }
            }

            extension Outer.Inner: CasePathable {
            }
            """,
            macroSpecs: specs
        )
    }

    func testNonEnumFails() {
        assertMacroExpansion(
            """
            @CasePathable
            struct NotAnEnum {
            }
            """,
            expandedSource: """
            struct NotAnEnum {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@CasePathable can only be attached to an enum", line: 1, column: 1),
                DiagnosticSpec(message: "@CasePathable can only be attached to an enum", line: 1, column: 1),
            ],
            macroSpecs: specs
        )
    }
}
