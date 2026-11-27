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

    private static func renderNode(_ node: XibNode, indent: Int, state: StateCollector) -> String {
        let pad = String(repeating: "    ", count: indent)
        var lines: [String] = []

        switch node.kind {
        case .stackView:
            let container = node.axis == "horizontal" ? "HStack" : "VStack"
            let spacingArg = node.spacing.map { "spacing: \(Int($0.rounded()))" } ?? "spacing: 12"
            lines.append("\(pad)\(container)(\(spacingArg)) {")
            lines.append(contentsOf: renderChildren(node.children, indent: indent + 1, state: state))
            lines.append("\(pad)}")

        case .view, .unknown:
            if node.children.isEmpty {
                lines.append("\(pad)Color.clear")
            } else {
                let container = node.children.count > 1 ? "VStack(spacing: 12)" : "Group"
                lines.append("\(pad)\(container) {")
                lines.append(contentsOf: renderChildren(node.children, indent: indent + 1, state: state))
                lines.append("\(pad)}")
            }

        case .scrollView:
            lines.append("\(pad)ScrollView {")
            lines.append(contentsOf: renderChildren(node.children, indent: indent + 1, state: state, emptyFallback: "EmptyView()"))
            lines.append("\(pad)}")

        case .tableView:
            lines.append("\(pad)List {")
            lines.append(contentsOf: renderChildren(node.children, indent: indent + 1, state: state, emptyFallback: "Text(\"Row\")"))
            lines.append("\(pad)}")

        case .collectionView:
            lines.append("\(pad)LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))]) {")
            lines.append(contentsOf: renderChildren(node.children, indent: indent + 1, state: state, emptyFallback: "RoundedRectangle(cornerRadius: 12)"))
            lines.append("\(pad)}")

        case .visualEffectView:
            lines.append("\(pad)VStack(spacing: 12) {")
            lines.append(contentsOf: renderChildren(node.children, indent: indent + 1, state: state, emptyFallback: "EmptyView()"))
            lines.append("\(pad)}")
            lines.append("\(pad).padding()")
            lines.append("\(pad).glassEffect(in: .rect(cornerRadius: \(Int((node.cornerRadius ?? 16).rounded()))))")

        case .label:
            lines.append("\(pad)Text(\"\(escape(node.text ?? "Label"))\")")

        case .button:
            let escaped = escape(node.text ?? "Button")
            if let sym = node.imageName, node.isSystemSymbol {
                lines.append("\(pad)Button(\"\(escaped)\", systemImage: \"\(escape(sym))\") { }")
            } else {
                lines.append("\(pad)Button(\"\(escaped)\") { }")
            }
            lines.append("\(pad).buttonStyle(.borderedProminent)")

        case .textField:
            let varName = state.nextVar(prefix: "textField", type: "String", initialValue: "\"\(escape(node.text ?? ""))\"")
            lines.append("\(pad)TextField(\"\(escape(node.placeholder ?? "Enter text"))\", text: $\(varName))")
            lines.append("\(pad).textFieldStyle(.roundedBorder)")

        case .textView:
            let varName = state.nextVar(prefix: "textEditor", type: "String", initialValue: "\"\(escape(node.text ?? ""))\"")
            lines.append("\(pad)TextEditor(text: $\(varName))")

        case .imageView:
            let name = escape(node.imageName ?? "photo")
            lines.append(node.isSystemSymbol ? "\(pad)Image(systemName: \"\(name)\")" : "\(pad)Image(\"\(name)\")")
            lines.append("\(pad).resizable()")
            lines.append(node.contentMode == "scaleAspectFill" ? "\(pad).scaledToFill()" : "\(pad).scaledToFit()")

        case .switch:
            let varName = state.nextVar(prefix: "isOn", type: "Bool", initialValue: node.isOn ? "true" : "false")
            lines.append("\(pad)Toggle(\"\(escape(node.userLabel ?? "Toggle"))\", isOn: $\(varName))")

        case .slider:
            let varName = state.nextVar(prefix: "sliderValue", type: "Double", initialValue: String(format: "%.2f", node.sliderValue))
            lines.append("\(pad)Slider(value: $\(varName), in: \(node.minValue)...\(node.maxValue))")

        case .segmentedControl:
            let varName = state.nextVar(prefix: "selection", type: "Int", initialValue: "0")
            lines.append("\(pad)Picker(\"Options\", selection: $\(varName)) {")
            let labels = node.segments.isEmpty ? ["First", "Second"] : node.segments
            for (idx, title) in labels.enumerated() {
                lines.append("\(pad)    Text(\"\(escape(title))\").tag(\(idx))")
            }
            lines.append("\(pad)}")
            lines.append("\(pad).pickerStyle(.segmented)")

        case .progressView:
            lines.append("\(pad)ProgressView(value: \(String(format: "%.2f", node.sliderValue)))")

        case .activityIndicatorView:
            lines.append("\(pad)ProgressView()")
        }

        lines.append(contentsOf: modifiers(for: node, pad: pad))
        return lines.joined(separator: "\n")
    }

    private static func renderChildren(
        _ children: [XibNode],
        indent: Int,
        state: StateCollector,
        emptyFallback: String? = nil
    ) -> [String] {
        guard !children.isEmpty else {
            return emptyFallback.map { [String(repeating: "    ", count: indent) + $0] } ?? []
        }
        return children.map { renderNode($0, indent: indent, state: state) }
    }

    private static func modifiers(for node: XibNode, pad: String) -> [String] {
        var mods: [String] = []
        if let font = node.font { mods.append("\(pad)\(font.swiftUIModifier)") }
        if let lines = node.numberOfLines, lines > 0 { mods.append("\(pad).lineLimit(\(lines))") }
        if let align = node.textAlignment, let mapped = alignmentMap[align] {
            mods.append("\(pad).multilineTextAlignment(\(mapped))")
        }
        if let fg = node.textColor { mods.append("\(pad).foregroundStyle(\(fg.swiftUIExpression))") }
        if let tint = node.tintColor { mods.append("\(pad).tint(\(tint.swiftUIExpression))") }
        if let bg = node.backgroundColor, bg.systemName != "clearColor" {
            mods.append("\(pad).background(\(bg.swiftUIExpression))")
        }
        if let radius = node.cornerRadius, node.kind != .visualEffectView {
            mods.append("\(pad).clipShape(.rect(cornerRadius: \(Int(radius.rounded()))))")
        }
        if node.kind == .imageView, let w = node.width, let h = node.height, w > 0, h > 0 {
            mods.append("\(pad).frame(width: \(Int(w.rounded())), height: \(Int(h.rounded())))")
        }
        if node.isHidden {
            mods.append("\(pad).hidden()")
        } else if node.alpha < 0.99 {
            mods.append(String(format: "\(pad).opacity(%.2f)", node.alpha))
        }
        return mods
    }

    private static let alignmentMap: [String: String] = [
        "center": ".center",
        "right": ".trailing",
        "left": ".leading",
    ]

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}

// MARK: - SwiftUI Optimizer

public enum SwiftUIOptimizer {
    /// Simplifies generated SwiftUI code:
    /// - Collapses single-child `Group { … }` wrappers
    /// - Strips default `.foregroundStyle(.primary)` and `.opacity(1.00)` modifiers
    /// - Compacts consecutive blank lines to a single blank line
    public static func optimize(_ code: String) -> String {
        var lines = code.components(separatedBy: "\n")

        // 1. Collapse single-child Group wrappers
        lines = collapseSingleChildGroups(lines)

        // 2. Remove default / redundant modifiers
        lines = lines.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == ".foregroundStyle(.primary)" { return nil }
            if trimmed == ".opacity(1.00)" { return nil }
            // Also strip inline occurrences (rare, but be thorough)
            var cleaned = line.replacingOccurrences(of: ".foregroundStyle(.primary)", with: "")
            cleaned = cleaned.replacingOccurrences(of: ".opacity(1.00)", with: "")
            return cleaned.trimmingCharacters(in: .whitespaces).isEmpty && trimmed.isEmpty ? line : cleaned
        }

        // 3. Compact consecutive blank lines
        var result: [String] = []
        var prevBlank = false
        for line in lines {
            let blank = line.trimmingCharacters(in: .whitespaces).isEmpty
            if blank {
                if !prevBlank { result.append("") }
                prevBlank = true
            } else {
                result.append(line)
                prevBlank = false
            }
        }

        return result.joined(separator: "\n")
    }

    private static func collapseSingleChildGroups(_ lines: [String]) -> [String] {
        var out: [String] = []
        var i = 0
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Match "Group {"
            if trimmed == "Group {" {
                let indent = String(line.prefix(while: { $0 == " " }))
                // Scan for content lines and closing brace
                var j = i + 1
                var contentLines: [String] = []
                var foundClose = false
                while j < lines.count {
                    let inner = lines[j]
                    let innerTrimmed = inner.trimmingCharacters(in: .whitespaces)
                    if innerTrimmed == "}" && inner.prefix(while: { $0 == " " }) == indent[...] {
                        foundClose = true
                        break
                    }
                    if !innerTrimmed.isEmpty {
                        contentLines.append(inner)
                    }
                    j += 1
                }
                // If exactly one content line, collapse
                if foundClose && contentLines.count == 1 {
                    // Re-indent child to Group's indentation level
                    let childTrimmed = contentLines[0].trimmingCharacters(in: .whitespaces)
                    out.append(indent + childTrimmed)
                    i = j + 1
                    continue
                }
            }
            out.append(line)
            i += 1
        }
        return out
    }
}
