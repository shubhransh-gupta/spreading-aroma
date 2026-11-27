import Foundation

public enum ReportGenerator {
    public static func generateMarkdownSummary(files: [ConvertedXibFile]) -> String {
        let header = "# Conversion Summary\n\n| File Name | Elements | Swift File |\n| :--- | :--- | :--- |"
        let rows = files.map { "| \($0.fileName) | \($0.elementCount) | \($0.suggestedSwiftFileName) |" }.joined(separator: "\n")
        let totalNodes = files.reduce(0) { $0 + $1.elementCount }
        return "\(header)\n\(rows)\n\nTotal Nodes Across All Files: \(totalNodes)"
    }
}

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

        return """
        import SwiftUI

        struct \(viewName): View {
        \(stateSection)    var body: some View {
        \(bodyContent)
            }
        }

        #Preview {
            \(viewName)()
        }
        """
    }

    private static func renderNode(_ node: XibNode, indent: Int, state: StateCollector) -> String { "" }
}