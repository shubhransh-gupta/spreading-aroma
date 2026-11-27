import Foundation

public final class XibParser: NSObject, XMLParserDelegate {
    private var rootObjects: [XibNode] = []
    private var nodeStack: [XibNode] = []
    private var inObjects = false
    private var inSegments = false
    private var readingTextElement = false
    private var textBuffer = ""
    private var pendingUserAttributeKey: String?

    private static let viewTags: [String: XibElementKind] = [
        "view": .view,
        "label": .label,
        "button": .button,
        "textField": .textField,
        "textView": .textView,
        "imageView": .imageView,
        "stackView": .stackView,
        "scrollView": .scrollView,
        "tableView": .tableView,
        "collectionView": .collectionView,
        "switch": .switch,
        "slider": .slider,
        "segmentedControl": .segmentedControl,
        "progressView": .progressView,
        "activityIndicatorView": .activityIndicatorView,
        "visualEffectView": .visualEffectView,
    ]

    public static func parse(data: Data) throws -> [XibNode] {
        let delegate = XibParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse() else {
            throw parser.parserError ?? NSError(domain: "XibParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid XIB XML"])
        }
        return delegate.rootObjects
    }

    public static func convert(url: URL) throws -> ConvertedXibFile {
        let data = try Data(contentsOf: url)
        let rawXML = String(data: data, encoding: .utf8) ?? ""
        let nodes = try parse(data: data)
        let viewName = SwiftUIGenerator.sanitizedViewName(from: url.lastPathComponent)
        let code = SwiftUIGenerator.generate(viewName: viewName, nodes: nodes)
        return ConvertedXibFile(
            fileName: url.lastPathComponent,
            sourcePath: url.path,
            rawXML: rawXML,
            rootNodes: nodes,
            swiftUICode: code
        )
    }

    public func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        if elementName == "objects" {
            inObjects = true
            return
        }
        guard inObjects, elementName != "placeholder" else { return }

        if let kind = Self.viewTags[elementName] {
            var node = XibNode(id: attributeDict["id"] ?? UUID().uuidString, kind: kind)
            node.userLabel = attributeDict["userLabel"]
            node.text = attributeDict["text"] ?? attributeDict["title"]
            node.placeholder = attributeDict["placeholder"]
            node.axis = attributeDict["axis"]
            node.spacing = attributeDict["spacing"].flatMap(Double.init)
            node.imageName = attributeDict["image"]
            node.isSystemSymbol = attributeDict["catalog"] == "system"
            node.alpha = attributeDict["alpha"].flatMap(Double.init) ?? 1.0
            node.isHidden = attributeDict["hidden"] == "YES"
            node.numberOfLines = attributeDict["numberOfLines"].flatMap(Int.init)
            node.textAlignment = attributeDict["textAlignment"]
            node.contentMode = attributeDict["contentMode"]
            node.isOn = attributeDict["on"] == "YES"
            node.sliderValue = attributeDict["value"].flatMap(Double.init) ?? 0.5
            node.minValue = attributeDict["minValue"].flatMap(Double.init) ?? 0
            node.maxValue = attributeDict["maxValue"].flatMap(Double.init) ?? 1
            nodeStack.append(node)
            return
        }

        guard !nodeStack.isEmpty else { return }
        let idx = nodeStack.count - 1

        switch elementName {
        case "string" where attributeDict["key"] == "text":
            readingTextElement = true
            textBuffer = ""
        case "state" where attributeDict["key"] == "normal":
            if let title = attributeDict["title"], nodeStack[idx].text == nil {
                nodeStack[idx].text = title
            }
            if let image = attributeDict["image"], nodeStack[idx].imageName == nil {
                nodeStack[idx].imageName = image
                nodeStack[idx].isSystemSymbol = attributeDict["catalog"] == "system"
            }
        case "fontDescription":
            let size = attributeDict["pointSize"].flatMap(Double.init) ?? 17
            nodeStack[idx].font = XibFont(
                pointSize: size,
                weight: attributeDict["weight"],
                textStyle: attributeDict["style"]
            )
        case "color":
            let color = XibColor(
                systemName: attributeDict["systemColor"],
                red: attributeDict["red"].flatMap(Double.init),
                green: attributeDict["green"].flatMap(Double.init),
                blue: attributeDict["blue"].flatMap(Double.init),
                alpha: attributeDict["alpha"].flatMap(Double.init) ?? 1.0
            )
            switch attributeDict["key"] {
            case "textColor": nodeStack[idx].textColor = color
            case "backgroundColor": nodeStack[idx].backgroundColor = color
            case "tintColor": nodeStack[idx].tintColor = color
            default: break
            }
        case "rect" where attributeDict["key"] == "frame":
            nodeStack[idx].width = attributeDict["width"].flatMap(Double.init)
            nodeStack[idx].height = attributeDict["height"].flatMap(Double.init)
        case "segments":
            inSegments = true
        case "segment" where inSegments:
            if let title = attributeDict["title"] {
                nodeStack[idx].segments.append(title)
            }
        case "userDefinedRuntimeAttribute" where attributeDict["keyPath"] == "layer.cornerRadius":
            pendingUserAttributeKey = "cornerRadius"
        case "real" where pendingUserAttributeKey == "cornerRadius":
            nodeStack[idx].cornerRadius = attributeDict["value"].flatMap(Double.init)
            pendingUserAttributeKey = nil
        default:
            break
        }
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        if readingTextElement { textBuffer += string }
    }

    public func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "objects" {
            inObjects = false
            return
        }
        if elementName == "segments" {
            inSegments = false
            return
        }
        if elementName == "string" && readingTextElement {
            readingTextElement = false
            if !nodeStack.isEmpty {
                nodeStack[nodeStack.count - 1].text = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            textBuffer = ""
            return
        }
        if elementName == "userDefinedRuntimeAttribute" {
            pendingUserAttributeKey = nil
            return
        }
        guard inObjects, Self.viewTags[elementName] != nil, let finished = nodeStack.popLast() else { return }

        if nodeStack.isEmpty {
            rootObjects.append(finished)
        } else {
            nodeStack[nodeStack.count - 1].children.append(finished)
        }
    }
}
