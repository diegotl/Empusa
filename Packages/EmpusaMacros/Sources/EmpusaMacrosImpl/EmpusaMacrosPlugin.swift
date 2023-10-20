import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct EmpusaMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        URLMacro.self
    ]
}
