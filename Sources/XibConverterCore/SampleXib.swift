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
                            <imageView id="img-1" image="lock.shield.fill" catalog="system">
                                <rect key="frame" x="0" y="0" width="48" height="48"/>
                                <color key="tintColor" systemColor="systemBlueColor"/>
                            </imageView>
                            <label id="lbl-1" text="Welcome Back">
                                <fontDescription key="fontDescription" pointSize="28" weight="bold"/>
                                <color key="textColor" systemColor="labelColor"/>
                            </label>
                            <textField id="tf-1" placeholder="Email address"/>
                            <switch id="sw-1" on="YES" userLabel="Remember Me"/>
                            <button id="btn-1">
                                <state key="normal" title="Sign In"/>
                                <color key="tintColor" systemColor="systemBlueColor"/>
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
}
