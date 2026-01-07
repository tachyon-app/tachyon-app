import XCTest
import Vision
@testable import TachyonCore

final class OCRServiceTests: XCTestCase {
    
    func testExtractTextFromImage() async throws {
        // Create a simple image with text "Hello World"
        let size = CGSize(width: 200, height: 100)
        let image = createTestImage(text: "Hello World", size: size)
        
        let text = await OCRService.extractText(from: image)
        
        XCTAssertNotNil(text)
        XCTAssertTrue(text!.contains("Hello"))
        XCTAssertTrue(text!.contains("World"))
    }
    
    func testExtractTextFromEmptyImage() async throws {
        let size = CGSize(width: 100, height: 100)
        // Image with no text
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath.fill(NSRect(origin: .zero, size: size))
        image.unlockFocus()
        
        // Vision might return nil or empty string depending on noise
        let text = await OCRService.extractText(from: image)
        
        // Either nil or empty or very confident it has no "Hello World"
        if let text = text {
            XCTAssertFalse(text.contains("Hello World"))
        }
    }
    
    // Helper to create an image with text
    private func createTestImage(text: String, size: CGSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        
        // White background
        NSColor.white.setFill()
        NSBezierPath.fill(NSRect(origin: .zero, size: size))
        
        // Draw text
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24),
            .foregroundColor: NSColor.black
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(at: NSPoint(x: 20, y: 40))
        
        image.unlockFocus()
        return image
    }
}
