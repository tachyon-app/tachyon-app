import XCTest
@testable import TachyonCore
import GRDB

class WindowSnappingShortcutsTests: XCTestCase {
    
    var dbQueue: DatabaseQueue!
    var repository: WindowSnappingShortcutRepository!
    
    override func setUp() {
        super.setUp()
        // Create in-memory database for testing
        dbQueue = try! DatabaseQueue()
        
        // Create table
        try! dbQueue.write { db in
            try WindowSnappingShortcut.createTable(in: db)
        }
        
        repository = WindowSnappingShortcutRepository(dbQueue: dbQueue)
    }
    
    override func tearDown() {
        dbQueue = nil
        repository = nil
        super.tearDown()
    }
    
    // MARK: - Test 1: Schema & Migration
    
    func testTableCreationAndMigration() throws {
        // Verify table exists
        let tableExists = try dbQueue.read { db in
            try db.tableExists("window_snapping_shortcuts")
        }
        XCTAssertTrue(tableExists, "Table should exist after creation")
        
        // Verify columns
        let columns = try dbQueue.read { db -> [String] in
            try db.columns(in: "window_snapping_shortcuts").map { $0.name }
        }
        
        XCTAssertTrue(columns.contains("id"))
        XCTAssertTrue(columns.contains("action"))
        XCTAssertTrue(columns.contains("keyCode"))
        XCTAssertTrue(columns.contains("modifiers"))
        XCTAssertTrue(columns.contains("isEnabled"))
    }
    
    // MARK: - Test 2: Insert Default Shortcuts
    
    func testInsertDefaultShortcuts() throws {
        // Insert all defaults
        try repository.insertDefaults()
        
        // Verify count
        let shortcuts = try repository.fetchAll()
        XCTAssertEqual(shortcuts.count, 19, "Should have 19 default shortcuts")
        
        // Verify first shortcut
        let leftHalf = shortcuts.first { $0.action == "leftHalf" }
        XCTAssertNotNil(leftHalf)
        XCTAssertEqual(leftHalf?.keyCode, 123) // Left arrow
        XCTAssertEqual(leftHalf?.modifiers, 6144) // Ctrl+Opt
        XCTAssertTrue(leftHalf?.isEnabled ?? false)
    }
    
    // MARK: - Test 3: Query All Shortcuts
    
    func testFetchAllShortcuts() throws {
        // Insert shortcuts
        try repository.insertDefaults()
        
        // Fetch all
        let shortcuts = try repository.fetchAll()
        
        // Verify count
        XCTAssertEqual(shortcuts.count, 19)
        
        // Verify all have IDs assigned
        for shortcut in shortcuts {
            XCTAssertNotNil(shortcut.id)
        }
    }
    
    // MARK: - Test 4: Update Shortcut
    
    func testUpdateShortcutKeyCode() throws {
        // Insert defaults
        try repository.insertDefaults()
        
        // Fetch one shortcut
        var leftHalf = try repository.fetch(byAction: .leftHalf)!
        
        // Update keyCode and modifiers
        leftHalf.keyCode = 0 // A key
        leftHalf.modifiers = 256 // Cmd only
        
        try repository.update(leftHalf)
        
        // Fetch again and verify
        let updated = try repository.fetch(byAction: .leftHalf)
        XCTAssertEqual(updated?.keyCode, 0)
        XCTAssertEqual(updated?.modifiers, 256)
    }
    
    // MARK: - Test 5: Toggle Enabled/Disabled
    
    func testToggleShortcutEnabled() throws {
        // Insert defaults
        try repository.insertDefaults()
        
        // Fetch one shortcut
        var leftHalf = try repository.fetch(byAction: .leftHalf)!
        XCTAssertTrue(leftHalf.isEnabled)
        
        // Disable it
        leftHalf.isEnabled = false
        try repository.update(leftHalf)
        
        // Verify
        let updated = try repository.fetch(byAction: .leftHalf)
        XCTAssertFalse(updated?.isEnabled ?? true)
    }
    
    // MARK: - Test 6: Reset to Defaults
    
    func testResetToDefaults() throws {
        // Insert defaults
        try repository.insertDefaults()
        
        // Modify several shortcuts
        var leftHalf = try repository.fetch(byAction: .leftHalf)!
        leftHalf.keyCode = 999
        try repository.update(leftHalf)
        
        var rightHalf = try repository.fetch(byAction: .rightHalf)!
        rightHalf.isEnabled = false
        try repository.update(rightHalf)
        
        // Reset to defaults
        try repository.resetToDefaults()
        
        // Verify all shortcuts match defaults
        let shortcuts = try repository.fetchAll()
        XCTAssertEqual(shortcuts.count, 19)
        
        let leftHalfReset = try repository.fetch(byAction: .leftHalf)
        XCTAssertEqual(leftHalfReset?.keyCode, 123) // Back to default
        
        let rightHalfReset = try repository.fetch(byAction: .rightHalf)
        XCTAssertTrue(rightHalfReset?.isEnabled ?? false) // Back to enabled
    }
    
    // MARK: - Test 7: Migration from No Shortcuts
    
    func testAutoMigrationOnFirstLaunch() throws {
        // Start with empty table (already done in setUp)
        let initialCount = try repository.fetchAll().count
        XCTAssertEqual(initialCount, 0)
        
        // Trigger migration (insert defaults if empty)
        let count = try dbQueue.read { db in
            try WindowSnappingShortcut.fetchCount(db)
        }
        
        if count == 0 {
            try repository.insertDefaults()
        }
        
        // Verify 19 defaults inserted
        let shortcuts = try repository.fetchAll()
        XCTAssertEqual(shortcuts.count, 19)
    }
    
    // MARK: - Additional Tests
    
    func testFetchEnabledShortcutsOnly() throws {
        // Insert defaults
        try repository.insertDefaults()
        
        // Disable 2 shortcuts
        var leftHalf = try repository.fetch(byAction: .leftHalf)!
        leftHalf.isEnabled = false
        try repository.update(leftHalf)
        
        var rightHalf = try repository.fetch(byAction: .rightHalf)!
        rightHalf.isEnabled = false
        try repository.update(rightHalf)
        
        // Fetch enabled only
        let enabled = try repository.fetchEnabled()
        XCTAssertEqual(enabled.count, 17) // 19 - 2 = 17
    }
    
    func testFetchByAction() throws {
        // Insert defaults
        try repository.insertDefaults()
        
        // Fetch specific action
        let maximize = try repository.fetch(byAction: .maximize)
        XCTAssertNotNil(maximize)
        XCTAssertEqual(maximize?.action, "maximize")
        
        // Fetch non-existent action
        let fullscreen = try repository.fetch(byAction: .fullscreen)
        XCTAssertNil(fullscreen) // Not in defaults
    }
}
