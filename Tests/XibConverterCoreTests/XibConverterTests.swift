import Foundation
import Testing
@testable import XibConverterCore

@Test func generatesMarkdownSummary() throws {
    let file = try SampleXib.makeSampleConvertedFile()
    let report = ReportGenerator.generateMarkdownSummary(files: [file])
    
    #expect(report.contains("| LoginView.xib | 8 | LoginView.swift |"))
    #expect(report.contains("Total Nodes Across All Files: 8"))
}

@Test func parsesAndConvertsSampleLoginXibWithRichAttributes() throws {
    let converted = try SampleXib.makeSampleConvertedFile()
    #expect(converted.suggestedSwiftFileName == "LoginView.swift")
    #expect(converted.elementCount == 8)
    #expect(converted.swiftUICode.contains("struct LoginView: View"))
}