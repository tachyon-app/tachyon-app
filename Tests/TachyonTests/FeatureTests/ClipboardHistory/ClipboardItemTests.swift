import XCTest
@testable import TachyonCore

/// Tests for ClipboardItem model (TDD approach)
final class ClipboardItemTests: XCTestCase {
    
    // MARK: - Model Creation Tests
    
    func testTextItemCreation() {
        let item = ClipboardItem(
            id: UUID(),
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            type: .text,
            contentHash: "abc123",
            textContent: "Hello, world!"
        )
        
        XCTAssertEqual(item.type, .text)
        XCTAssertEqual(item.textContent, "Hello, world!")
        XCTAssertFalse(item.isPinned)
        XCTAssertNil(item.imagePath)
        XCTAssertNil(item.filePaths)
    }
    
    func testCodeItemCreation() {
        let item = ClipboardItem(
            id: UUID(),
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            type: .code,
            contentHash: "def456",
            textContent: "func hello() { print(\"Hello\") }",
            codeLanguage: "swift"
        )
        
        XCTAssertEqual(item.type, .code)
        XCTAssertEqual(item.codeLanguage, "swift")
        XCTAssertEqual(item.textContent, "func hello() { print(\"Hello\") }")
    }
    
    func testImageItemCreation() {
        let item = ClipboardItem(
            id: UUID(),
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            type: .image,
            contentHash: "img789",
            imagePath: "/path/to/image.png",
            imageOCRText: "Extracted text from image"
        )
        
        XCTAssertEqual(item.type, .image)
        XCTAssertEqual(item.imagePath, "/path/to/image.png")
        XCTAssertEqual(item.imageOCRText, "Extracted text from image")
        XCTAssertNil(item.textContent)
    }
    
    func testFileItemCreation() {
        let item = ClipboardItem(
            id: UUID(),
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            type: .file,
            contentHash: "file012",
            filePaths: ["/path/to/file1.txt", "/path/to/file2.pdf"]
        )
        
        XCTAssertEqual(item.type, .file)
        XCTAssertEqual(item.filePaths?.count, 2)
        XCTAssertEqual(item.filePaths?[0], "/path/to/file1.txt")
    }
    
    // MARK: - Pinning Tests
    
    func testPinnedItemCreation() {
        let item = ClipboardItem(
            id: UUID(),
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            type: .text,
            contentHash: "pinned123",
            textContent: "Pinned text",
            isPinned: true
        )
        
        XCTAssertTrue(item.isPinned)
    }
    
    func testDefaultUnpinned() {
        let item = ClipboardItem(
            id: UUID(),
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            type: .text,
            contentHash: "default123",
            textContent: "Default text"
        )
        
        XCTAssertFalse(item.isPinned)
    }
    
    // MARK: - Relative Timestamp Tests
    
    func testRelativeTimestampJustNow() {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let item = ClipboardItem(
            id: UUID(),
            timestamp: now,
            type: .text,
            contentHash: "now123",
            textContent: "Just now"
        )
        
        XCTAssertEqual(item.relativeTimestamp, "Just now")
    }
    
    func testRelativeTimestampMinutesAgo() {
        let fiveMinutesAgo = Int64((Date().timeIntervalSince1970 - 5 * 60) * 1000)
        let item = ClipboardItem(
            id: UUID(),
            timestamp: fiveMinutesAgo,
            type: .text,
            contentHash: "min123",
            textContent: "Minutes ago"
        )
        
        XCTAssertEqual(item.relativeTimestamp, "5m ago")
    }
    
    func testRelativeTimestampHoursAgo() {
        let threeHoursAgo = Int64((Date().timeIntervalSince1970 - 3 * 60 * 60) * 1000)
        let item = ClipboardItem(
            id: UUID(),
            timestamp: threeHoursAgo,
            type: .text,
            contentHash: "hour123",
            textContent: "Hours ago"
        )
        
        XCTAssertEqual(item.relativeTimestamp, "3h ago")
    }
    
    func testRelativeTimestampDaysAgo() {
        let twoDaysAgo = Int64((Date().timeIntervalSince1970 - 2 * 24 * 60 * 60) * 1000)
        let item = ClipboardItem(
            id: UUID(),
            timestamp: twoDaysAgo,
            type: .text,
            contentHash: "day123",
            textContent: "Days ago"
        )
        
        XCTAssertEqual(item.relativeTimestamp, "2d ago")
    }
    
    // MARK: - Content Hash Tests
    
    func testContentHashGeneration() {
        let text = "Hello, world!"
        let hash = ClipboardItem.generateHash(for: text)
        
        XCTAssertFalse(hash.isEmpty)
        XCTAssertEqual(hash.count, 64) // SHA-256 produces 64 hex characters
    }
    
    func testContentHashConsistency() {
        let text = "Consistent hash test"
        let hash1 = ClipboardItem.generateHash(for: text)
        let hash2 = ClipboardItem.generateHash(for: text)
        
        XCTAssertEqual(hash1, hash2, "Same content should produce same hash")
    }
    
    func testContentHashDifferentForDifferentContent() {
        let hash1 = ClipboardItem.generateHash(for: "Content A")
        let hash2 = ClipboardItem.generateHash(for: "Content B")
        
        XCTAssertNotEqual(hash1, hash2, "Different content should produce different hashes")
    }
    
    func testImageDataHashGeneration() {
        let imageData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG magic bytes
        let hash = ClipboardItem.generateHash(for: imageData)
        
        XCTAssertFalse(hash.isEmpty)
        XCTAssertEqual(hash.count, 64)
    }
    
    // MARK: - Preview Text Tests
    
    func testPreviewTextForTextItem() {
        let longText = String(repeating: "a", count: 200)
        let item = ClipboardItem(
            id: UUID(),
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            type: .text,
            contentHash: "preview123",
            textContent: longText
        )
        
        XCTAssertTrue(item.previewText.count <= 100, "Preview should be truncated")
        XCTAssertTrue(item.previewText.hasSuffix("…"), "Truncated preview should end with ellipsis")
    }
    
    func testPreviewTextForImageItem() {
        let item = ClipboardItem(
            id: UUID(),
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            type: .image,
            contentHash: "imgpreview123",
            imagePath: "/path/to/screenshot.png"
        )
        
        XCTAssertEqual(item.previewText, "Image")
    }
    
    func testPreviewTextForImageWithOCR() {
        let item = ClipboardItem(
            id: UUID(),
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            type: .image,
            contentHash: "imgocr123",
            imagePath: "/path/to/image.png",
            imageOCRText: "OCR extracted text"
        )
        
        XCTAssertEqual(item.previewText, "OCR extracted text")
    }
    
    func testPreviewTextForFileItem() {
        let item = ClipboardItem(
            id: UUID(),
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            type: .file,
            contentHash: "filepreview123",
            filePaths: ["/path/to/file1.txt", "/path/to/file2.pdf", "/path/to/file3.doc"]
        )
        
        XCTAssertEqual(item.previewText, "3 files")
    }
    
    func testPreviewTextForSingleFile() {
        let item = ClipboardItem(
            id: UUID(),
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            type: .file,
            contentHash: "singlefile123",
            filePaths: ["/path/to/document.pdf"]
        )
        
        XCTAssertEqual(item.previewText, "document.pdf")
    }
    
    // MARK: - Equatable Tests
    
    func testEquality() {
        let id = UUID()
        let item1 = ClipboardItem(
            id: id,
            timestamp: 1000,
            type: .text,
            contentHash: "eq123",
            textContent: "Equal"
        )
        let item2 = ClipboardItem(
            id: id,
            timestamp: 1000,
            type: .text,
            contentHash: "eq123",
            textContent: "Equal"
        )
        
        XCTAssertEqual(item1, item2)
    }
    
    func testInequalityDifferentId() {
        let item1 = ClipboardItem(
            id: UUID(),
            timestamp: 1000,
            type: .text,
            contentHash: "ineq123",
            textContent: "Same content"
        )
        let item2 = ClipboardItem(
            id: UUID(),
            timestamp: 1000,
            type: .text,
            contentHash: "ineq123",
            textContent: "Same content"
        )
        
        XCTAssertNotEqual(item1, item2)
    }
}
