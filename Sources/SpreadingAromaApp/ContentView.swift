import SwiftUI
import UniformTypeIdentifiers
import XibConverterCore

private extension UTType {
    static let xibDocument = UTType(filenameExtension: "xib") ?? .xml
}

private struct AdaptiveGlassCard: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(in: .rect(cornerRadius: 18))
        } else {
            content.background(.ultraThinMaterial, in: .rect(cornerRadius: 18))
        }
    }
}

struct ContentView: View {
    @State private var store = ConverterStore()
    @State private var showingImporter = false
    @State private var isDropTargeted = false

    var body: some View {
        NavigationSplitView {
            sidebar
                .searchable(text: $store.searchQuery, prompt: "Filter XIB screens")
        } detail: {
            detailPane
        }
        .navigationTitle("Spreading Aroma")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Upload .zip / .xib", systemImage: "square.and.arrow.down") {
                    showingImporter = true
                }
                Button("Sample", systemImage: "flame") {
                    store.loadSample()
                }
                Button("Optimize", systemImage: "sparkles") {
                    store.optimizeSwiftUI.toggle()
                }
                .symbolVariant(store.optimizeSwiftUI ? .fill : .none)
                .help("Simplify SwiftUI code")
                Button("Copy SwiftUI", systemImage: "doc.on.doc") {
                    store.copySelectedCode()
                }
                .disabled(store.selectedFile == nil)
                Button("Export Folder", systemImage: "folder.badge.plus") {
                    store.exportAllToFolder()
                }
                .disabled(store.files.isEmpty)
                Button("Export .zip", systemImage: "archivebox") {
                    store.exportAsZip()
                }
                .disabled(store.files.isEmpty)
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.zip, .xibDocument],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                store.importURLs(urls)
            } else if case .failure(let err) = result {
                store.errorMessage = err.localizedDescription
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            store.importURLs(urls)
            return true
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
        .alert("Conversion Error", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private var sidebar: some View {
        List(selection: $store.selectedFileID) {
            Section("Recipes (\(store.filteredFiles.count) XIBs • \(store.totalLineCount) lines)") {
                ForEach(store.filteredFiles) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.fileName)
                            .font(.headline)
                        Text("\(item.suggestedSwiftFileName) • \(item.elementCount) nodes • \(item.lineCount) lines")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(item.id)
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 230, ideal: 270)
    }

    @ViewBuilder
    private var detailPane: some View {
        if let selected = store.selectedFile {
            HSplitView {
                leftInspector(for: selected)
                    .frame(minWidth: 320)
                swiftUIPreviewPane(for: selected)
                    .frame(minWidth: 380)
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Text(store.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("View", selection: $store.inspectorMode) {
                        ForEach(InspectorMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 280)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.bar)
            }
        } else {
            emptyDropZone
        }
    }

    private var emptyDropZone: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Spreading Aroma")
                .font(.largeTitle.bold())
            Text("Drop a .zip of Interface Builder .xib files to infuse them head-to-head into SwiftUI.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            HStack(spacing: 12) {
                Button("Choose .zip or .xib") { showingImporter = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                Button("Load Sample Recipe") { store.loadSample() }
                    .buttonStyle(.bordered)
            }
        }
        .padding(36)
        .modifier(AdaptiveGlassCard())
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(isDropTargeted ? Color.orange : Color.clear, lineWidth: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func leftInspector(for file: ConvertedXibFile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(store.inspectorMode.rawValue) — \(file.fileName)")
                .font(.subheadline.weight(.semibold))
                .padding(10)
            Divider()
            switch store.inspectorMode {
            case .preview:
                XibLivePreview(nodes: file.rootNodes)
            case .hierarchy:
                List(file.rootNodes, children: \.optionalChildren) { node in
                    HStack {
                        Text(node.kind.rawValue)
                            .font(.system(.body, design: .monospaced).weight(.semibold))
                        if let label = node.text ?? node.userLabel ?? node.imageName {
                            Text("“\(label)”")
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            case .xml:
                ScrollView([.vertical, .horizontal]) {
                    Text(file.rawXML)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(12)
                }
            }
        }
    }

    private func swiftUIPreviewPane(for file: ConvertedXibFile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Generated SwiftUI — \(file.suggestedSwiftFileName)")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button("Copy", systemImage: "doc.on.doc") { store.copySelectedCode() }
                    .buttonStyle(.borderless)
            }
            .padding(10)
            Divider()
            ScrollView([.vertical, .horizontal]) {
                let code = store.optimizeSwiftUI ? SwiftUIOptimizer.optimize(file.swiftUICode) : file.swiftUICode
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }
        }
    }
}

private extension XibNode {
    var optionalChildren: [XibNode]? {
        children.isEmpty ? nil : children
    }
}
