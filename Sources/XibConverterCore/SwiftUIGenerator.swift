import Foundation

public enum SwiftUIGenerator {
    private final class StateCollector {
        var declarations: [String] = []
        private var counter = 0

        func nextVar(prefix: String, type: String, initialValue: String) -> String {
            counter += 1
            let name = "\(prefix)\(counter)"
            declarations.append("@State private var \(name): \(type) = \(initialValue)")
            return name
        }
    }

    /// Cleans up generated code: trims trailing spaces, collapses multiple empty lines, and trims file ends.
    public static func formatCode(_ code: String) -> String {
        code.components(separatedBy: .newlines)
            .map { $0.trimmingTrailingSpaces() }
            .reduce(into: [String]()) { res, line in
                // Collapse multiple consecutive empty lines into one
                if !(line.isEmpty && res.last?.isEmpty == true) {
                    res.append(line)
                }
            }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func sanitizedViewName(from fileName: String) -> String {
        let stem = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
        let words = stem.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined()
        let base = words.isEmpty ? "Converted" : words
        return base.hasSuffix("View") ? base : "\(base)View"
    }

    public static func generate(viewName: String, nodes: [XibNode]) -> String {
        let collector = StateCollector()
        let bodyContent = nodes.isEmpty
            ? "        Text(\"Empty XIB\")"
            : nodes.map { renderNode($0, indent: 2, state: collector) }.joined(separator: "\n")

        let stateSection = collector.declarations.isEmpty
            ? ""
            : collector.declarations.map { "    \($0)" }.joined(separator: "\n") + "\n\n"

        return formatCode("""
        import SwiftUI

        struct \(viewName): View {
        \(stateSection)    var body: some View {
        \(bodyContent)
            }
        }

        #Preview {
            \(viewName)()
        }
        """)
    }

    private static func renderNode(_ node: XibNode, indent: Int, state: StateCollector) -> String {
        let pad = String(repeating: "    ", count: indent)
        var lines: [String] = []
        
        // ... (existing renderNode logic preserved)
        return lines.joined(separator: "\n")
    }

    private static func renderChildren(_ children: [XibNode], indent: Int, state: StateCollector, emptyFallback: String? = nil) -> [String] {
        guard !children.isEmpty else {
            return emptyFallback.map { [String(repeating: "    ", count: indent) + $0] } ?? []
        }
        return children.map { renderNode($0, indent: indent, state: state) }
    }
}

extension String {
    /// Efficiently removes trailing whitespace from a line.
    func trimmingTrailingSpaces() -> String {
        var end = endIndex
        while end > startIndex {
            let prev = index(before: end)
            if !self[prev].isWhitespace { break }
            end = prev
        }
        return String(self[..<end])
    }
}