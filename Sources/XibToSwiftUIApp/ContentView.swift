import SwiftUI
import UniformTypeIdentifiers
import XibConverterCore

private extension UTType {
    static let xibDocument = UTType(filenameExtension: "xib") ?? .xml
}

private struct AdaptiveGlassCard: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(in: .rect(cornerRadius: 16))
        } else {
            content.background(.ultraThinMaterial, in: .rect(cornerRadius: 16))
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
        } detail: {
            detailPane
        }
        .navigationTitle("XibToSwiftUI")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Upload .zip / .xib", systemImage: "square.and.arrow.down") {
                    showingImporter = true
                }
                Button("Sample", systemImage: "wand.and.stars") {
                    store.loadSample()
                }
                Button("Copy SwiftUI", systemImage: "doc.on.doc") {
                    store.copySelectedCode()
                }
                .disabled(store.selectedFile == nil)
                Button("Export All", systemImage: "folder.badge.plus") {
                    store.exportAllToFolder()
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
            Section("Converted XIBs (\(store.files.count))") {
                ForEach(store.files) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.fileName)
                            .font(.headline)
                        Text("\(item.suggestedSwiftFileName) • \(item.elementCount) nodes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(item.id)
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 220, ideal: 260)
    }

    @ViewBuilder
    private var detailPane: some View {
        if let selected = store.selectedFile {
            HSplitView {
                sourceInspector(for: selected)
                    .frame(minWidth: 280)
                swiftUIPreviewPane(for: selected)
                    .frame(minWidth: 360)
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Text(store.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Toggle("Raw XIB XML", isOn: $store.showRawXML)
                        .toggleStyle(.switch)
                        .controlSize(.small)
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
            Image(systemName: "archivebox.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Drop a .zip of XIB files here")
                .font(.title2.bold())
            Text("Converts Interface Builder .xib views head-to-head into clean SwiftUI.")
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button("Choose .zip or .xib") { showingImporter = true }
                    .buttonStyle(.borderedProminent)
                Button("Load Sample XIB") { store.loadSample() }
                    .buttonStyle(.bordered)
            }
        }
        .padding(36)
        .modifier(AdaptiveGlassCard())
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isDropTargeted ? Color.accentColor : Color.clear, lineWidth: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func sourceInspector(for file: ConvertedXibFile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(store.showRawXML ? "XIB XML — \(file.fileName)" : "Parsed XIB Hierarchy — \(file.fileName)")
                .font(.subheadline.weight(.semibold))
                .padding(10)
            Divider()
            if store.showRawXML {
                ScrollView([.vertical, .horizontal]) {
                    Text(file.rawXML)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(12)
                }
            } else {
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
                Text(file.swiftUICode)
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
