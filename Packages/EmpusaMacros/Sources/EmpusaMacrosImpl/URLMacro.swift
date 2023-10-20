import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum URLMacroError: Error, CustomStringConvertible {
    case requiresStaticStringLiteral
    case malformedURL(urlString: String)

    var description: String {
        switch self {
        case .requiresStaticStringLiteral:
            return "#URL requires a static string literal"
        case .malformedURL(let urlString):
            return "The input URL is malformed: \(urlString)"
        }
    }
}

public struct URLMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard
            let argument = node.argumentList.first?.expression,
            let segments = argument.as(StringLiteralExprSyntax.self)?.segments,
            segments.count == 1,
            case .stringSegment(let literalSegment)? = segments.first
        else {
            throw URLMacroError.requiresStaticStringLiteral
        }

        guard let _ = URL(string: literalSegment.content.text) else {
            throw URLMacroError.malformedURL(urlString: "\(argument)")
        }

        return "URL(string: \(argument))!"
    }
}
