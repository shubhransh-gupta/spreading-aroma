import Foundation
import Testing
@testable import XibConverterCore

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

// ... (existing tests preserved)