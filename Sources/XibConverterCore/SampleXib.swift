import Foundation

public enum SampleXib {
    public static let sampleLoginXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <document type="com.apple.InterfaceBuilder3.CocoaTouch.XIB" version="3.0" toolsVersion="27000" targetRuntime="iOS.CocoaTouch">
        <objects>
            <placeholder placeholderIdentifier="IBFilesOwner" id="-1" userLabel="File's Owner"/>
            <placeholder placeholderIdentifier="IBFirstResponder" id="-2" customClass="UIResponder"/>
            <view id="iN0-l3-epB" userLabel="LoginContainer">
                <color key="backgroundColor" systemColor="systemBackgroundColor"/>
                <subviews>
                    <stackView id="stk-1" axis="vertical" spacing="16">
                        <subviews>
                            <imageView id="img-1" image="flame.fill" catalog="system" contentMode="scaleAspectFit">
                                <rect key="frame" x="0" y="0" width="48" height="48"/>
                                <color key="tintColor" systemColor="systemOrangeColor"/>
                            </imageView>
                            <label id="lbl-1" text="Spreading Aroma" textAlignment="center" numberOfLines="1">
                                <fontDescription key="fontDescription" pointSize="28" weight="bold"/>
                                <color key="textColor" systemColor="labelColor"/>
                            </label>
                            <label id="lbl-2" text="Drop your XIB recipes and watch SwiftUI rise." textAlignment="center" alpha="0.85">
                                <fontDescription key="fontDescription" pointSize="14" weight="regular"/>
                                <color key="textColor" systemColor="secondaryLabelColor"/>
                            </label>
                            <textField id="tf-1" placeholder="Kitchen email address"/>
                            <switch id="sw-1" on="YES" userLabel="Auto-Simmer"/>
                            <button id="btn-1">
                                <state key="normal" title="Start Cooking"/>
                                <color key="tintColor" systemColor="systemOrangeColor"/>
                            </button>
                        </subviews>
                    </stackView>
                </subviews>
            </view>
        </objects>
    </document>
    """

    public static func makeSampleConvertedFile() throws -> ConvertedXibFile {
        let nodes = try XibParser.parse(data: Data(sampleLoginXML.utf8))
        let code = SwiftUIGenerator.generate(viewName: "LoginView", nodes: nodes)
        return ConvertedXibFile(
            fileName: "LoginView.xib",
            sourcePath: "Sample/LoginView.xib",
            rawXML: sampleLoginXML,
            rootNodes: nodes,
            swiftUICode: code
        )
    }

    public static func exportAll(_ files: [ConvertedXibFile], to directory: URL) throws -> [URL] {
        try files.map { file in
            let outURL = directory.appendingPathComponent(file.suggestedSwiftFileName)
            try file.swiftUICode.write(to: outURL, atomically: true, encoding: .utf8)
            return outURL
        }
    }

    public static func exportAsZip(_ files: [ConvertedXibFile], to zipURL: URL) throws {
        let stageDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("spreading-aroma-export-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: stageDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: stageDir) }

        _ = try exportAll(files, to: stageDir)
        if FileManager.default.fileExists(atPath: zipURL.path) {
            try FileManager.default.removeItem(at: zipURL)
        }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        proc.currentDirectoryURL = stageDir
        proc.arguments = ["-r", "-qq", zipURL.path, "."]
        try proc.run()
        proc.waitUntilExit()
        if proc.terminationStatus != 0 {
            throw ZipExtractorError.unzipFailed("Could not package SwiftUI files into zip (exit \(proc.terminationStatus))")
        }
    }
}
