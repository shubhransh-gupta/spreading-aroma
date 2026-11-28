import AppKit
import Foundation
import Observation
import UniformTypeIdentifiers
import XibConverterCore

enum InspectorMode: String, CaseIterable, Identifiable {
    case preview = "Live Preview"
    case hierarchy = "Hierarchy"
    case xml = "XIB XML"

    var id: String { rawValue }
}

@MainActor
@Observable
final class ConverterStore {
    var files: [ConvertedXibFile] = []
    var selectedFileID: ConvertedXibFile.ID?
    var searchQuery: String = ""
    var inspectorMode: InspectorMode = .preview
    var statusMessage: String = "Drop a .zip of .xib files or upload directly."
    var errorMessage: String?

    var filteredFiles: [ConvertedXibFile] {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return files }
        return files.filter {
            $0.fileName.localizedCaseInsensitiveContains(searchQuery) ||
            $0.suggestedSwiftFileName.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    var selectedFile: ConvertedXibFile? {
        filteredFiles.first { $0.id == selectedFileID } ?? filteredFiles.first
    }

    var totalElementCount: Int {
        files.reduce(0) { $0 + $1.elementCount }
    }

    var totalLineCount: Int {
        files.reduce(0) { $0 + $1.lineCount }
    }

    func importURLs(_ urls: [URL]) {
        errorMessage = nil
        do {
            let xibURLs = try ZipExtractor.collectXibFiles(from: urls)
            let converted = try xibURLs.map(XibParser.convert(url:))
            files = converted
            selectedFileID = converted.first?.id
            statusMessage = "Infused \(converted.count) XIB file(s) (\(totalLineCount) lines) into SwiftUI."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadSample() {
        errorMessage = nil
        do {
            let sample = try SampleXib.makeSampleConvertedFile()
            files = [sample]
            selectedFileID = sample.id
            statusMessage = "Loaded sample LoginView.xib (\(sample.lineCount) lines)."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func copySelectedCode() {
        guard let code = selectedFile?.swiftUICode else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        statusMessage = "Copied \(selectedFile?.suggestedSwiftFileName ?? "SwiftUI") to clipboard."
    }

    func exportAllToFolder() {
        guard !files.isEmpty else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Export SwiftUI Files"
        guard panel.runModal() == .OK, let dir = panel.url else { return }
        do {
            let exported = try SampleXib.exportAll(files, to: dir)
            statusMessage = "Exported \(exported.count) SwiftUI file(s) to \(dir.lastPathComponent)."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exportAsZip() {
        guard !files.isEmpty else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.zip]
        panel.nameFieldStringValue = "SpreadingAroma-SwiftUI.zip"
        panel.prompt = "Export .zip"
        guard panel.runModal() == .OK, let destURL = panel.url else { return }
        do {
            try SampleXib.exportAsZip(files, to: destURL)
            statusMessage = "Packaged \(files.count) SwiftUI file(s) into \(destURL.lastPathComponent)."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
