import Foundation

public enum ZipExtractorError: LocalizedError, Sendable {
    case unsupportedInput(String)
    case unzipFailed(String)
    case noXibFilesFound

    public var errorDescription: String? {
        switch self {
        case .unsupportedInput(let name): "Unsupported file '\(name)'. Drop a .zip archive or .xib file."
        case .unzipFailed(let msg): "Failed to extract zip archive: \(msg)"
        case .noXibFilesFound: "No .xib files were found inside the uploaded archive."
        }
    }
}

public enum ZipExtractor {
    /// Collects `.xib` URLs from a `.zip` archive, `.xib` file, or folder.
    public static func collectXibFiles(from urls: [URL]) throws -> [URL] {
        let collected = try urls.flatMap { try extractSingleURL($0) }
        guard !collected.isEmpty else { throw ZipExtractorError.noXibFilesFound }
        return collected.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    private static func extractSingleURL(_ url: URL) throws -> [URL] {
        let ext = url.pathExtension.lowercased()
        if ext == "xib" { return [url] }

        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            return findXibs(in: url)
        }

        guard ext == "zip" else {
            throw ZipExtractorError.unsupportedInput(url.lastPathComponent)
        }

        let destDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("xib-to-swiftui-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-qq", "-o", url.path, "-d", destDir.path]
        let stderrPipe = Pipe()
        process.standardError = stderrPipe
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let msg = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "exit \(process.terminationStatus)"
            throw ZipExtractorError.unzipFailed(msg.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return findXibs(in: destDir)
    }

    private static func findXibs(in root: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return enumerator.compactMap { $0 as? URL }
            .filter { $0.pathExtension.lowercased() == "xib" && !$0.pathComponents.contains("__MACOSX") }
    }
}
