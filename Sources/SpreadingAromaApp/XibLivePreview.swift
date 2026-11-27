import SwiftUI
import XibConverterCore

struct XibLivePreview: View {
    let nodes: [XibNode]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(nodes) { node in
                    XibNodePreview(node: node)
                }
            }
            .padding(24)
            .frame(maxWidth: 380)
            .background(.background, in: .rect(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(.quaternary, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct XibNodePreview: View {
    let node: XibNode
    @State private var toggleState: Bool
    @State private var textState: String
    @State private var sliderState: Double
    @State private var segmentState: Int = 0

    init(node: XibNode) {
        self.node = node
        self._toggleState = State(initialValue: node.isOn)
        self._textState = State(initialValue: node.text ?? "")
        self._sliderState = State(initialValue: node.sliderValue)
    }

    var body: some View {
        coreView
            .modifier(NodeStyleModifier(node: node))
    }

    @ViewBuilder
    private var coreView: some View {
        switch node.kind {
        case .stackView:
            if node.axis == "horizontal" {
                HStack(spacing: node.spacing ?? 12) {
                    ForEach(node.children) { XibNodePreview(node: $0) }
                }
            } else {
                VStack(spacing: node.spacing ?? 12) {
                    ForEach(node.children) { XibNodePreview(node: $0) }
                }
            }
        case .view, .unknown:
            VStack(spacing: 12) {
                ForEach(node.children) { XibNodePreview(node: $0) }
            }
        case .scrollView:
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(node.children) { XibNodePreview(node: $0) }
                }
            }
        case .tableView:
            VStack(alignment: .leading, spacing: 8) {
                if node.children.isEmpty {
                    Text("Table Row").foregroundStyle(.secondary)
                } else {
                    ForEach(node.children) { XibNodePreview(node: $0) }
                }
            }
        case .collectionView:
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))]) {
                ForEach(node.children) { XibNodePreview(node: $0) }
            }
        case .visualEffectView:
            VStack(spacing: 12) {
                ForEach(node.children) { XibNodePreview(node: $0) }
            }
            .padding()
            .background(.ultraThinMaterial, in: .rect(cornerRadius: node.cornerRadius ?? 16))
        case .label:
            Text(node.text ?? "Label")
        case .button:
            if let sym = node.imageName, node.isSystemSymbol {
                Button(node.text ?? "Button", systemImage: sym) {}
                    .buttonStyle(.borderedProminent)
            } else {
                Button(node.text ?? "Button") {}
                    .buttonStyle(.borderedProminent)
            }
        case .textField:
            TextField(node.placeholder ?? "Enter text", text: $textState)
                .textFieldStyle(.roundedBorder)
        case .textView:
            TextEditor(text: $textState)
                .frame(minHeight: 72)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
        case .imageView:
            Image(systemName: node.isSystemSymbol ? (node.imageName ?? "photo") : "photo")
                .resizable()
                .scaledToFit()
                .frame(width: min(node.width ?? 48, 160), height: min(node.height ?? 48, 160))
        case .switch:
            Toggle(node.userLabel ?? "Toggle", isOn: $toggleState)
        case .slider:
            Slider(value: $sliderState, in: node.minValue...max(node.minValue + 0.01, node.maxValue))
        case .segmentedControl:
            Picker("Options", selection: $segmentState) {
                let labels = node.segments.isEmpty ? ["First", "Second"] : node.segments
                ForEach(Array(labels.enumerated()), id: \.offset) { idx, title in
                    Text(title).tag(idx)
                }
            }
            .pickerStyle(.segmented)
        case .progressView:
            ProgressView(value: min(max(node.sliderValue, 0), 1))
        case .activityIndicatorView:
            ProgressView()
        }
    }
}

private struct NodeStyleModifier: ViewModifier {
    let node: XibNode

    func body(content: Content) -> some View {
        content
            .font(node.font?.swiftUIFont)
            .lineLimit(node.numberOfLines.flatMap { $0 > 0 ? $0 : nil })
            .multilineTextAlignment(alignment)
            .foregroundStyle(node.textColor?.swiftUIColor ?? .primary)
            .tint(node.tintColor?.swiftUIColor)
            .opacity(node.isHidden ? 0 : node.alpha)
    }

    private var alignment: TextAlignment {
        switch node.textAlignment {
        case "center": .center
        case "right": .trailing
        default: .leading
        }
    }
}
