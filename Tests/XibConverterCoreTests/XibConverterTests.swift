import Foundation
import Testing
@testable import XibConverterCore

@Test func parsesAndConvertsSampleLoginXib() throws {
    let converted = try SampleXib.makeSampleConvertedFile()
    #expect(converted.suggestedSwiftFileName == "LoginView.swift")
    #expect(converted.elementCount >= 7)
    #expect(converted.swiftUICode.contains("struct LoginView: View"))
    #expect(converted.swiftUICode.contains("@State private var textField1: String"))
    #expect(converted.swiftUICode.contains("@State private var isOn2: Bool = true"))
    #expect(converted.swiftUICode.contains("VStack(spacing: 16)"))
    #expect(converted.swiftUICode.contains("Image(systemName: \"lock.shield.fill\")"))
    #expect(converted.swiftUICode.contains("Text(\"Welcome Back\")"))
    #expect(converted.swiftUICode.contains("Button(\"Sign In\")"))
    #expect(converted.swiftUICode.contains("#Preview"))
}

@Test func extractsRealZipArchiveSkippingMacOSXAndConvertsAllXibs() throws {
    let tempRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent("xib-zip-test-\(UUID().uuidString)", isDirectory: true)
    let inputDir = tempRoot.appendingPathComponent("input", isDirectory: true)
    let nestedDir = inputDir.appendingPathComponent("Screens", isDirectory: true)
    let macosJunk = inputDir.appendingPathComponent("__MACOSX", isDirectory: true)
    try FileManager.default.createDirectory(at: nestedDir, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: macosJunk, withIntermediateDirectories: true)

    let profileXib = """
    <?xml version="1.0" encoding="UTF-8"?>
    <document type="com.apple.InterfaceBuilder3.CocoaTouch.XIB" version="3.0">
        <objects>
            <visualEffectView id="ve-1">
                <userDefinedRuntimeAttributes>
                    <userDefinedRuntimeAttribute type="number" keyPath="layer.cornerRadius">
                        <real key="value" value="20"/>
                    </userDefinedRuntimeAttribute>
                </userDefinedRuntimeAttributes>
                <subviews>
                    <stackView id="st-1" axis="horizontal" spacing="8">
                        <subviews>
                            <segmentedControl id="seg-1">
                                <segments>
                                    <segment title="Day"/>
                                    <segment title="Week"/>
                                </segments>
                            </segmentedControl>
                            <slider id="sl-1" value="0.4" minValue="0" maxValue="10"/>
                        </subviews>
                    </stackView>
                </subviews>
            </visualEffectView>
        </objects>
    </document>
    """

    try SampleXib.sampleLoginXML.write(to: nestedDir.appendingPathComponent("Login.xib"), atomically: true, encoding: .utf8)
    try profileXib.write(to: nestedDir.appendingPathComponent("ProfileCard.xib"), atomically: true, encoding: .utf8)
    try profileXib.write(to: macosJunk.appendingPathComponent("._ProfileCard.xib"), atomically: true, encoding: .utf8)

    let zipURL = tempRoot.appendingPathComponent("xibs.zip")
    let zipProc = Process()
    zipProc.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
    zipProc.currentDirectoryURL = inputDir
    zipProc.arguments = ["-r", "-qq", zipURL.path, "."]
    try zipProc.run()
    zipProc.waitUntilExit()
    #expect(zipProc.terminationStatus == 0)

    let collected = try ZipExtractor.collectXibFiles(from: [zipURL])
    #expect(collected.count == 2)

    let converted = try collected.map(XibParser.convert(url:))
    let profile = try #require(converted.first { $0.fileName == "ProfileCard.xib" })
    #expect(profile.swiftUICode.contains(".glassEffect(in: .rect(cornerRadius: 20))"))
    #expect(profile.swiftUICode.contains("HStack(spacing: 8)"))
    #expect(profile.swiftUICode.contains(".pickerStyle(.segmented)"))
    #expect(profile.swiftUICode.contains("Slider(value: $sliderValue2, in: 0.0...10.0)"))

    let exportDir = tempRoot.appendingPathComponent("out", isDirectory: true)
    try FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)
    let exported = try SampleXib.exportAll(converted, to: exportDir)
    #expect(exported.count == 2)
    #expect(FileManager.default.fileExists(atPath: exportDir.appendingPathComponent("LoginView.swift").path))
    #expect(FileManager.default.fileExists(atPath: exportDir.appendingPathComponent("ProfileCardView.swift").path))
}
