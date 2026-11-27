import AppKit
import Foundation
import Observation
import XibConverterCore

@MainActor
@Observable
final class ConverterStore {
    var files: [ConvertedXibFile] = []
    var selectedFileID: ConvertedXibFile.ID?
    var statusMessage: String = "Drop a .zip of .xib files or upload directly."
    var errorMessage: String?
    var showRawXML: Bool = false

    var selectedFile: ConvertedXibFile? {
        files.first { $0.id == selectedFileID } ?? files.first
    }

    func importURLs(_ urls: [URL]) {
        errorMessage = nil
        do {
            let xibURLs = try ZipExtractor.collectXibFiles(from: urls)
            let converted = try xibURLs.map(XibParser.convert(url:))
            files = converted
            selectedFileID = converted.first?.id
            statusMessage = "Converted \(converted.count) XIB file(s) head-to-head into SwiftUI."
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
            statusMessage = "Loaded sample LoginView.xib."
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
}
