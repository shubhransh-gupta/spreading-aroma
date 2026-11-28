import Foundation
import SwiftUI

public enum XibElementKind: String, Sendable, Hashable {
    case view, label, button, textField, textView, imageView, stackView
    case scrollView, tableView, collectionView, `switch`, slider
    case segmentedControl, progressView, activityIndicatorView, visualEffectView
    case unknown
}

public struct XibColor: Sendable, Hashable {
    public let systemName: String?
    public let red: Double?
    public let green: Double?
    public let blue: Double?
    public let alpha: Double

    public init(systemName: String? = nil, red: Double? = nil, green: Double? = nil, blue: Double? = nil, alpha: Double = 1.0) {
        self.systemName = systemName
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public var swiftUIExpression: String {
        if let systemName, let direct = Self.systemExprMap[systemName] {
            return direct
        }
        if let r = red, let g = green, let b = blue {
            let base = String(format: "Color(red: %.3f, green: %.3f, blue: %.3f)", r, g, b)
            return alpha < 0.99 ? String(format: "%@.opacity(%.2f)", base, alpha) : base
        }
        return ".primary"
    }

    public var swiftUIColor: Color {
        if let systemName, let direct = Self.systemColorMap[systemName] {
            return direct
        }
        if let r = red, let g = green, let b = blue {
            return Color(red: r, green: g, blue: b).opacity(alpha)
        }
        return .primary
    }

    private static let systemExprMap: [String: String] = [
        "labelColor": ".primary",
        "secondaryLabelColor": ".secondary",
        "systemBackgroundColor": "Color(.windowBackgroundColor)",
        "secondarySystemBackgroundColor": "Color(.controlBackgroundColor)",
        "systemBlueColor": ".blue",
        "systemRedColor": ".red",
        "systemGreenColor": ".green",
        "systemOrangeColor": ".orange",
        "systemIndigoColor": ".indigo",
        "systemPurpleColor": ".purple",
        "systemGrayColor": ".gray",
        "clearColor": ".clear",
    ]

    private static let systemColorMap: [String: Color] = [
        "labelColor": .primary,
        "secondaryLabelColor": .secondary,
        "systemBackgroundColor": Color(.windowBackgroundColor),
        "secondarySystemBackgroundColor": Color(.controlBackgroundColor),
        "systemBlueColor": .blue,
        "systemRedColor": .red,
        "systemGreenColor": .green,
        "systemOrangeColor": .orange,
        "systemIndigoColor": .indigo,
        "systemPurpleColor": .purple,
        "systemGrayColor": .gray,
        "clearColor": .clear,
    ]
}

public struct XibFont: Sendable, Hashable {
    public let pointSize: Double
    public let weight: String?
    public let textStyle: String?

    public init(pointSize: Double = 17, weight: String? = nil, textStyle: String? = nil) {
        self.pointSize = pointSize
        self.weight = weight
        self.textStyle = textStyle
    }

    public var swiftUIModifier: String {
        if let textStyle, let mapped = Self.styleMap[textStyle] {
            return ".font(\(mapped))"
        }
        let weightExpr = weight.flatMap { Self.weightMap[$0] }.map { ", weight: \($0)" } ?? ""
        return ".font(.system(size: \(Int(pointSize.rounded()))\(weightExpr)))"
    }

    public var swiftUIFont: Font {
        if let textStyle, let mapped = Self.fontValueMap[textStyle] {
            return mapped
        }
        let w = weight.flatMap { Self.fontWeightMap[$0] } ?? .regular
        return .system(size: pointSize, weight: w)
    }

    private static let weightMap: [String: String] = [
        "ultraLight": ".ultraLight", "thin": ".thin", "light": ".light",
        "regular": ".regular", "medium": ".medium", "semibold": ".semibold",
        "bold": ".bold", "heavy": ".heavy", "black": ".black",
    ]

    private static let fontWeightMap: [String: Font.Weight] = [
        "ultraLight": .ultraLight, "thin": .thin, "light": .light,
        "regular": .regular, "medium": .medium, "semibold": .semibold,
        "bold": .bold, "heavy": .heavy, "black": .black,
    ]

    private static let styleMap: [String: String] = [
        "UICTFontTextStyleLargeTitle": ".largeTitle",
        "UICTFontTextStyleTitle1": ".title",
        "UICTFontTextStyleTitle2": ".title2",
        "UICTFontTextStyleTitle3": ".title3",
        "UICTFontTextStyleHeadline": ".headline",
        "UICTFontTextStyleSubhead": ".subheadline",
        "UICTFontTextStyleBody": ".body",
        "UICTFontTextStyleCallout": ".callout",
        "UICTFontTextStyleFootnote": ".footnote",
        "UICTFontTextStyleCaption1": ".caption",
        "UICTFontTextStyleCaption2": ".caption2",
    ]

    private static let fontValueMap: [String: Font] = [
        "UICTFontTextStyleLargeTitle": .largeTitle,
        "UICTFontTextStyleTitle1": .title,
        "UICTFontTextStyleTitle2": .title2,
        "UICTFontTextStyleTitle3": .title3,
        "UICTFontTextStyleHeadline": .headline,
        "UICTFontTextStyleSubhead": .subheadline,
        "UICTFontTextStyleBody": .body,
        "UICTFontTextStyleCallout": .callout,
        "UICTFontTextStyleFootnote": .footnote,
        "UICTFontTextStyleCaption1": .caption,
        "UICTFontTextStyleCaption2": .caption2,
    ]
}

public struct XibNode: Identifiable, Sendable, Hashable {
    public let id: String
    public var kind: XibElementKind
    public var userLabel: String?
    public var text: String?
    public var placeholder: String?
    public var imageName: String?
    public var isSystemSymbol: Bool = false
    public var axis: String?
    public var spacing: Double?
    public var cornerRadius: Double?
    public var width: Double?
    public var height: Double?
    public var alpha: Double = 1.0
    public var isHidden: Bool = false
    public var numberOfLines: Int?
    public var textAlignment: String?
    public var contentMode: String?
    public var isOn: Bool = false
    public var sliderValue: Double = 0.5
    public var minValue: Double = 0
    public var maxValue: Double = 1
    public var font: XibFont?
    public var textColor: XibColor?
    public var backgroundColor: XibColor?
    public var tintColor: XibColor?
    public var segments: [String] = []
    public var children: [XibNode] = []

    public init(id: String = UUID().uuidString, kind: XibElementKind) {
        self.id = id
        self.kind = kind
    }

    public var totalNodeCount: Int {
        1 + children.reduce(0) { $0 + $1.totalNodeCount }
    }
}

public struct ConvertedXibFile: Identifiable, Sendable, Hashable {
    public let id: UUID
    public let fileName: String
    public let sourcePath: String
    public let rawXML: String
    public let rootNodes: [XibNode]
    public var swiftUICode: String

    public init(
        id: UUID = UUID(),
        fileName: String,
        sourcePath: String,
        rawXML: String,
        rootNodes: [XibNode],
        swiftUICode: String
    ) {
        self.id = id
        self.fileName = fileName
        self.sourcePath = sourcePath
        self.rawXML = rawXML
        self.rootNodes = rootNodes
        self.swiftUICode = swiftUICode
    }

    public var elementCount: Int {
        rootNodes.reduce(0) { $0 + $1.totalNodeCount }
    }

    public var lineCount: Int {
        swiftUICode.components(separatedBy: .newlines).count
    }

    public var suggestedSwiftFileName: String {
        SwiftUIGenerator.sanitizedViewName(from: fileName) + ".swift"
    }
}
