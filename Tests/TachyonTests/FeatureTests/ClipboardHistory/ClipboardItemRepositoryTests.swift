import XCTest
@testable import TachyonCore
import GRDB

/// Tests for ClipboardItemRepository (TDD approach)
final class ClipboardItemRepositoryTests: XCTestCase {
    
    var dbQueue: DatabaseQueue!
    var repository: ClipboardItemRepository!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory database for testing
        dbQueue = try! DatabaseQueue()
        try! dbQueue.write { db in
            try ClipboardItem.createTable(in: db)
        }
        
        repository = ClipboardItemRepository(dbQueue: dbQueue)
    }
    
    override func tearDown() {
        repository = nil
        dbQueue = nil
        super.tearDown()
    }
    
    // MARK: - Insert Tests
    
    func testInsertTextItem() throws {
        let item = ClipboardItem(
            type: .text,
            contentHash: "hash123",
            textContent: "Test content"
        )
        
        try repository.insert(item)
        
        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].textContent, "Test content")
    }
    
    func testInsertCodeItem() throws {
        let item = ClipboardItem(
            type: .code,
            contentHash: "codehash123",
            textContent: "func test() {}",
            codeLanguage: "swift"
        )
        
        try repository.insert(item)
        
        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].type, .code)
        XCTAssertEqual(fetched[0].codeLanguage, "swift")
    }
    
    func testInsertImageItem() throws {
        let item = ClipboardItem(
            type: .image,
            contentHash: "imghash123",
            imagePath: "/path/to/image.png",
            imageOCRText: "Extracted text"
        )
        
        try repository.insert(item)
        
        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].imagePath, "/path/to/image.png")
        XCTAssertEqual(fetched[0].imageOCRText, "Extracted text")
    }
    
    func testInsertFileItem() throws {
        let item = ClipboardItem(
            type: .file,
            contentHash: "filehash123",
            filePaths: ["/path/file1.txt", "/path/file2.pdf"]
        )
        
        try repository.insert(item)
        
        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].filePaths?.count, 2)
    }
    
    // MARK: - Deduplication Tests
    
    func testDuplicateHashRejected() throws {
        let item1 = ClipboardItem(
            type: .text,
            contentHash: "samehash",
            textContent: "First content"
        )
        
        let item2 = ClipboardItem(
            type: .text,
            contentHash: "samehash",
            textContent: "Different content"
        )
        
        try repository.insert(item1)
        
        // Second insert with same hash should fail
        XCTAssertThrowsError(try repository.insert(item2))
        
        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].textContent, "First content")
    }
    
    func testFindByHash() throws {
        let item = ClipboardItem(
            type: .text,
            contentHash: "uniquehash",
            textContent: "Find me"
        )
        
        try repository.insert(item)
        
        let found = try repository.findByHash("uniquehash")
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.textContent, "Find me")
        
        let notFound = try repository.findByHash("nonexistent")
        XCTAssertNil(notFound)
    }
    
    // MARK: - Ordering Tests
    
    func testFetchAllOrderedByTimestamp() throws {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        
        let older = ClipboardItem(
            timestamp: now - 10000,
            type: .text,
            contentHash: "older",
            textContent: "Older"
        )
        
        let newer = ClipboardItem(
            timestamp: now,
            type: .text,
            contentHash: "newer",
            textContent: "Newer"
        )
        
        try repository.insert(older)
        try repository.insert(newer)
        
        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 2)
        XCTAssertEqual(fetched[0].textContent, "Newer") // Most recent first
        XCTAssertEqual(fetched[1].textContent, "Older")
    }
    
    func testPinnedItemsFirst() throws {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        
        let unpinned = ClipboardItem(
            timestamp: now,
            type: .text,
            contentHash: "unpinned",
            textContent: "Unpinned recent",
            isPinned: false
        )
        
        let pinned = ClipboardItem(
            timestamp: now - 10000,
            type: .text,
            contentHash: "pinned",
            textContent: "Pinned older",
            isPinned: true
        )
        
        try repository.insert(unpinned)
        try repository.insert(pinned)
        
        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 2)
        XCTAssertTrue(fetched[0].isPinned) // Pinned first even if older
        XCTAssertFalse(fetched[1].isPinned)
    }
    
    // MARK: - Pinning Tests
    
    func testTogglePin() throws {
        let item = ClipboardItem(
            type: .text,
            contentHash: "togglepin",
            textContent: "Toggle me",
            isPinned: false
        )
        
        try repository.insert(item)
        
        // Pin the item
        try repository.togglePin(id: item.id)
        var fetched = try repository.fetch(byId: item.id)
        XCTAssertTrue(fetched?.isPinned ?? false)
        
        // Unpin the item
        try repository.togglePin(id: item.id)
        fetched = try repository.fetch(byId: item.id)
        XCTAssertFalse(fetched?.isPinned ?? true)
    }
    
    // MARK: - Delete Tests
    
    func testDeleteItem() throws {
        let item = ClipboardItem(
            type: .text,
            contentHash: "deleteme",
            textContent: "Delete me"
        )
        
        try repository.insert(item)
        XCTAssertEqual(try repository.count(), 1)
        
        try repository.delete(id: item.id)
        XCTAssertEqual(try repository.count(), 0)
    }
    
    func testDeleteAllExceptPinned() throws {
        let pinned = ClipboardItem(
            type: .text,
            contentHash: "pinned1",
            textContent: "Pinned",
            isPinned: true
        )
        
        let unpinned1 = ClipboardItem(
            type: .text,
            contentHash: "unpinned1",
            textContent: "Unpinned 1"
        )
        
        let unpinned2 = ClipboardItem(
            type: .text,
            contentHash: "unpinned2",
            textContent: "Unpinned 2"
        )
        
        try repository.insert(pinned)
        try repository.insert(unpinned1)
        try repository.insert(unpinned2)
        XCTAssertEqual(try repository.count(), 3)
        
        try repository.deleteAll(exceptPinned: true)
        
        let remaining = try repository.fetchAll()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertTrue(remaining[0].isPinned)
    }
    
    func testDeleteAllIncludingPinned() throws {
        let pinned = ClipboardItem(
            type: .text,
            contentHash: "pinned2",
            textContent: "Pinned",
            isPinned: true
        )
        
        let unpinned = ClipboardItem(
            type: .text,
            contentHash: "unpinned3",
            textContent: "Unpinned"
        )
        
        try repository.insert(pinned)
        try repository.insert(unpinned)
        
        try repository.deleteAll(exceptPinned: false)
        
        XCTAssertEqual(try repository.count(), 0)
    }
    
    // MARK: - FIFO Eviction Tests
    
    func testFetchOldestUnpinned() throws {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        
        let oldest = ClipboardItem(
            timestamp: now - 30000,
            type: .text,
            contentHash: "oldest",
            textContent: "Oldest"
        )
        
        let middle = ClipboardItem(
            timestamp: now - 20000,
            type: .text,
            contentHash: "middle",
            textContent: "Middle"
        )
        
        let newest = ClipboardItem(
            timestamp: now - 10000,
            type: .text,
            contentHash: "newest",
            textContent: "Newest"
        )
        
        let pinnedOld = ClipboardItem(
            timestamp: now - 40000,
            type: .text,
            contentHash: "pinnedold",
            textContent: "Pinned old",
            isPinned: true
        )
        
        try repository.insert(oldest)
        try repository.insert(middle)
        try repository.insert(newest)
        try repository.insert(pinnedOld)
        
        let oldestTwo = try repository.fetchOldestUnpinned(limit: 2)
        XCTAssertEqual(oldestTwo.count, 2)
        XCTAssertEqual(oldestTwo[0].textContent, "Oldest")
        XCTAssertEqual(oldestTwo[1].textContent, "Middle")
        
        // Pinned item should not be included
        XCTAssertFalse(oldestTwo.contains { $0.isPinned })
    }
    
    // MARK: - Search Tests
    
    func testSearchTextContent() throws {
        let item1 = ClipboardItem(
            type: .text,
            contentHash: "search1",
            textContent: "Hello world"
        )
        
        let item2 = ClipboardItem(
            type: .text,
            contentHash: "search2",
            textContent: "Goodbye world"
        )
        
        let item3 = ClipboardItem(
            type: .text,
            contentHash: "search3",
            textContent: "Something else"
        )
        
        try repository.insert(item1)
        try repository.insert(item2)
        try repository.insert(item3)
        
        let results = try repository.search(query: "world")
        XCTAssertEqual(results.count, 2)
    }
    
    func testSearchImageOCRText() throws {
        let item = ClipboardItem(
            type: .image,
            contentHash: "searchimg",
            imagePath: "/path/image.png",
            imageOCRText: "Screenshot of error message"
        )
        
        try repository.insert(item)
        
        let results = try repository.search(query: "error")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].type, .image)
    }
    
    func testSearchCaseInsensitive() throws {
        let item = ClipboardItem(
            type: .text,
            contentHash: "searchcase",
            textContent: "UPPERCASE TEXT"
        )
        
        try repository.insert(item)
        
        let results = try repository.search(query: "uppercase")
        XCTAssertEqual(results.count, 1)
    }
    
    // MARK: - Type Filter Tests
    
    func testFetchByType() throws {
        let textItem = ClipboardItem(
            type: .text,
            contentHash: "type1",
            textContent: "Text"
        )
        
        let codeItem = ClipboardItem(
            type: .code,
            contentHash: "type2",
            textContent: "Code",
            codeLanguage: "swift"
        )
        
        let imageItem = ClipboardItem(
            type: .image,
            contentHash: "type3",
            imagePath: "/path/img.png"
        )
        
        try repository.insert(textItem)
        try repository.insert(codeItem)
        try repository.insert(imageItem)
        
        let textOnly = try repository.fetchByType(.text)
        XCTAssertEqual(textOnly.count, 1)
        XCTAssertEqual(textOnly[0].type, .text)
        
        let codeOnly = try repository.fetchByType(.code)
        XCTAssertEqual(codeOnly.count, 1)
        XCTAssertEqual(codeOnly[0].type, .code)
        
        let imageOnly = try repository.fetchByType(.image)
        XCTAssertEqual(imageOnly.count, 1)
        XCTAssertEqual(imageOnly[0].type, .image)
    }
    
    // MARK: - Count Tests
    
    func testCount() throws {
        XCTAssertEqual(try repository.count(), 0)
        
        for i in 1...5 {
            let item = ClipboardItem(
                type: .text,
                contentHash: "count\(i)",
                textContent: "Item \(i)"
            )
            try repository.insert(item)
        }
        
        XCTAssertEqual(try repository.count(), 5)
    }
    
    func testCountUnpinned() throws {
        let pinned = ClipboardItem(
            type: .text,
            contentHash: "countpinned",
            textContent: "Pinned",
            isPinned: true
        )
        
        let unpinned = ClipboardItem(
            type: .text,
            contentHash: "countunpinned",
            textContent: "Unpinned"
        )
        
        try repository.insert(pinned)
        try repository.insert(unpinned)
        
        XCTAssertEqual(try repository.count(), 2)
        XCTAssertEqual(try repository.countUnpinned(), 1)
    }
    
    // MARK: - Pagination Tests
    
    func testFetchRecent() throws {
        for i in 1...10 {
            let item = ClipboardItem(
                timestamp: Int64(i * 1000),
                type: .text,
                contentHash: "page\(i)",
                textContent: "Item \(i)"
            )
            try repository.insert(item)
        }
        
        let firstPage = try repository.fetchRecent(limit: 5, offset: 0)
        XCTAssertEqual(firstPage.count, 5)
        XCTAssertEqual(firstPage[0].textContent, "Item 10") // Most recent
        
        let secondPage = try repository.fetchRecent(limit: 5, offset: 5)
        XCTAssertEqual(secondPage.count, 5)
        XCTAssertEqual(secondPage[0].textContent, "Item 5")
    }
}
