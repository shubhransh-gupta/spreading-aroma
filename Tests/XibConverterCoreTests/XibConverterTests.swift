import Foundation
import Testing
@testable import XibConverterCore

@Test func generatesMarkdownSummary() throws {
    let file = try SampleXib.makeSampleConvertedFile()
    let report = ReportGenerator.generateMarkdownSummary(files: [file])
    
    #expect(report.contains("| LoginView.xib | 8 | LoginView.swift |"))
    #expect(report.contains("Total Nodes Across All Files: 8"))
}

@Test func formatCodeStripsWhitespaceAndIndents() {
    let input = """
    struct TestView: View {
        var body: some View {  
            VStack {   
                Text("Hi")    
            }
        }
    }
    """
    let formatted = SwiftUIGenerator.formatCode(input)
    #expect(!formatted.contains("  \n"))
    #expect(!formatted.contains(" {  "))
    #expect(formatted.contains("        Text(\"Hi\")"))
}

@Test func calculatesNodeStatisticsForSampleLogin() throws {
    let nodes = try XibParser.parse(data: Data(SampleXib.sampleLoginXML.utf8))
    let stats = SwiftUIGenerator.statistics(from: nodes)
    #expect(stats.views == 3)
    #expect(stats.controls == 3)
    #expect(stats.containers == 2)
}

@Test func parsesAndConvertsSampleLoginXibWithRichAttributes() throws {
    let converted = try SampleXib.makeSampleConvertedFile()
    #expect(converted.suggestedSwiftFileName == "LoginView.swift")
    #expect(converted.elementCount == 8)
    #expect(converted.lineCount > 10)
    #expect(converted.swiftUICode.contains("struct LoginView: View"))
    #expect(converted.swiftUICode.contains("@State private var textField1: String"))
    #expect(converted.swiftUICode.contains("@State private var isOn2: Bool = true"))
    #expect(converted.swiftUICode.contains("VStack(spacing: 16)"))
    #expect(converted.swiftUICode.contains("Image(systemName: \"flame.fill\")"))
    #expect(converted.swiftUICode.contains("Text(\"Spreading Aroma\")"))
    #expect(converted.swiftUICode.contains(".lineLimit(1)"))
    #expect(converted.swiftUICode.contains(".multilineTextAlignment(.center)"))
    #expect(converted.swiftUICode.contains(".opacity(0.85)"))
    #expect(converted.swiftUICode.contains("Button(\"Start Cooking\")"))
    #expect(converted.swiftUICode.contains("#Preview"))
}

@Test func extractsRealZipConvertsXibsAndExportsZipRoundTrip() throws {
    let tempRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent("aroma-zip-test-\(UUID().uuidString)", isDirectory: true)
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
                            <label id="hid-1" text="Secret" hidden="YES"/>
                            <imageView id="im-1" image="hero" contentMode="scaleAspectFill"/>
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
    #expect(profile.swiftUICode.contains(".hidden()"))
    #expect(profile.swiftUICode.contains(".scaledToFill()"))

    let exportZipURL = tempRoot.appendingPathComponent("SpreadingAroma-SwiftUI.zip")
    try SampleXib.exportAsZip(converted, to: exportZipURL)
    #expect(FileManager.default.fileExists(atPath: exportZipURL.path))
}

// MARK: - SwiftUI Optimizer Tests

@Test func optimizerCollapsesRedundantSingleChildGroup() {
    let input = """
        Group {
            Text("Hello")
        }
    """
    let optimized = SwiftUIOptimizer.optimize(input)
    #expect(!optimized.contains("Group {"))
    #expect(optimized.contains("Text(\"Hello\")"))
}

@Test func optimizerStripsDefaultForegroundStylePrimary() {
    let input = """
    Text("Hello")
    .foregroundStyle(.primary)
    .font(.body)
    """
    let optimized = SwiftUIOptimizer.optimize(input)
    #expect(!optimized.contains(".foregroundStyle(.primary)"))
    #expect(optimized.contains(".font(.body)"))
}

@Test func optimizerStripsDefaultOpacity() {
    let input = """
    Image(systemName: "star")
    .opacity(1.00)
    .resizable()
    """
    let optimized = SwiftUIOptimizer.optimize(input)
    #expect(!optimized.contains(".opacity(1.00)"))
    #expect(optimized.contains(".resizable()"))
}

@Test func optimizerCompactsConsecutiveBlankLines() {
    let input = "Text(\"A\")\n\n\n\n\nText(\"B\")"
    let optimized = SwiftUIOptimizer.optimize(input)
    #expect(!optimized.contains("\n\n\n"))
    #expect(optimized.contains("Text(\"A\")"))
    #expect(optimized.contains("Text(\"B\")"))
}

@Test func optimizerPreservesValidStructViewOutput() {
    let input = """
    import SwiftUI

    struct MyView: View {
        var body: some View {
            VStack(spacing: 16) {
                Text("Hello")
                Button("Go") { }
            }
        }
    }
    """
    let optimized = SwiftUIOptimizer.optimize(input)
    #expect(optimized.contains("struct MyView: View"))
    #expect(optimized.contains("VStack(spacing: 16)"))
    #expect(optimized.contains("Text(\"Hello\")"))
    #expect(optimized.contains("Button(\"Go\")"))
}

@Test func optimizerDoesNotCollapseMultiChildGroup() {
    let input = """
        Group {
            Text("A")
            Text("B")
        }
    """
    let optimized = SwiftUIOptimizer.optimize(input)
    #expect(optimized.contains("Group {"))
    #expect(optimized.contains("Text(\"A\")"))
    #expect(optimized.contains("Text(\"B\")"))
}
