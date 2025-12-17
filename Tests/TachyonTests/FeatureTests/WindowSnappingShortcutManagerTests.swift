import XCTest
@testable import TachyonCore
import GRDB

class WindowSnappingShortcutManagerTests: XCTestCase {
    
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
    
    // MARK: - Test 1: Load Shortcuts from Database
    
    func testLoadShortcutsFromDatabase() throws {
        // Setup: Insert shortcuts in DB
        try repository.insertDefaults()
        
        // Call loadShortcuts()
        let shortcuts = try repository.fetchAll()
        
        // Verify returned array matches DB
        XCTAssertEqual(shortcuts.count, 19)
        
        // Verify specific shortcuts
        let leftHalf = shortcuts.first { $0.action == "leftHalf" }
        XCTAssertNotNil(leftHalf)
        XCTAssertEqual(leftHalf?.keyCode, 123)
        XCTAssertEqual(leftHalf?.modifiers, 6144)
    }
    
    // MARK: - Test 2: Save Shortcuts to Database
    
    func testSaveShortcutsToDatabase() throws {
        // Create shortcuts array
        let shortcut = WindowSnappingShortcut(
            action: "leftHalf",
            keyCode: 123,
            modifiers: 6144,
            isEnabled: true
        )
        
        // Call saveShortcuts()
        try repository.insert(shortcut)
        
        // Query DB, verify saved correctly
        let saved = try repository.fetch(byAction: .leftHalf)
        XCTAssertNotNil(saved)
        XCTAssertEqual(saved?.keyCode, 123)
        XCTAssertEqual(saved?.modifiers, 6144)
    }
    
    // MARK: - Test 3: Validate Unique Shortcut
    
    func testValidateUniqueShortcut() throws {
        // Insert defaults
        try repository.insertDefaults()
        
        // Create shortcut not used by others (Cmd+Shift+A)
        let uniqueShortcut = WindowSnappingShortcut(
            action: "testAction",
            keyCode: 0,  // A key
            modifiers: 768,  // Cmd+Shift
            isEnabled: true
        )
        
        // Call validate()
        let result = try repository.validateShortcut(uniqueShortcut)
        
        // Verify returns .valid
        XCTAssertEqual(result, .valid)
    }
    
    // MARK: - Test 4: Validate Duplicate Shortcut
    
    func testValidateDuplicateShortcut() throws {
        // Insert defaults
        try repository.insertDefaults()
        
        // Create shortcut already in use (Ctrl+Opt+← is used by leftHalf)
        let duplicateShortcut = WindowSnappingShortcut(
            action: "testAction",
            keyCode: 123,  // Left arrow
            modifiers: 6144,  // Ctrl+Opt
            isEnabled: true
        )
        
        // Call validate()
        let result = try repository.validateShortcut(duplicateShortcut)
        
        // Verify returns .conflict
        if case .conflict(let conflictingAction) = result {
            XCTAssertEqual(conflictingAction, "leftHalf")
        } else {
            XCTFail("Expected conflict result")
        }
    }
    
    // MARK: - Test 5: Validate Invalid Key Code
    
    func testValidateInvalidKeyCode() throws {
        // Create shortcut with invalid keyCode (0 is invalid in our mapper)
        let invalidShortcut = WindowSnappingShortcut(
            action: "testAction",
            keyCode: 0,  // Invalid
            modifiers: 6144,
            isEnabled: true
        )
        
        // Call validate()
        let result = try repository.validateShortcut(invalidShortcut)
        
        // Verify returns .invalid
        // Note: keyCode 0 is actually valid (A key), so let's use 999
        let reallyInvalidShortcut = WindowSnappingShortcut(
            action: "testAction",
            keyCode: 999,  // Definitely invalid
            modifiers: 6144,
            isEnabled: true
        )
        
        let invalidResult = try repository.validateShortcut(reallyInvalidShortcut)
        
        if case .invalid = invalidResult {
            // Success
        } else {
            XCTFail("Expected invalid result")
        }
    }
    
    // MARK: - Test 6: Get Shortcut by Action
    
    func testGetShortcutByAction() throws {
        // Load shortcuts
        try repository.insertDefaults()
        
        // Query for .leftHalf
        let leftHalf = try repository.fetch(byAction: .leftHalf)
        
        // Verify correct shortcut returned
        XCTAssertNotNil(leftHalf)
        XCTAssertEqual(leftHalf?.action, "leftHalf")
        XCTAssertEqual(leftHalf?.keyCode, 123)
    }
    
    // MARK: - Test 7: Get Enabled Shortcuts Only
    
    func testGetEnabledShortcutsOnly() throws {
        // Setup: 3 enabled, 2 disabled
        try repository.insertDefaults()
        
        // Disable 2 shortcuts
        var leftHalf = try repository.fetch(byAction: .leftHalf)!
        leftHalf.isEnabled = false
        try repository.update(leftHalf)
        
        var rightHalf = try repository.fetch(byAction: .rightHalf)!
        rightHalf.isEnabled = false
        try repository.update(rightHalf)
        
        // Call getEnabledShortcuts()
        let enabled = try repository.fetchEnabled()
        
        // Verify returns only enabled (17 out of 19)
        XCTAssertEqual(enabled.count, 17)
        
        // Verify disabled ones are not in the list
        XCTAssertFalse(enabled.contains { $0.action == "leftHalf" })
        XCTAssertFalse(enabled.contains { $0.action == "rightHalf" })
    }
    
    // MARK: - Additional Tests
    
    func testValidateSelfIsNotConflict() throws {
        // Insert defaults
        try repository.insertDefaults()
        
        // Fetch existing shortcut
        let existing = try repository.fetch(byAction: .leftHalf)!
        
        // Validate it (should not conflict with itself)
        let result = try repository.validateShortcut(existing)
        
        // Should be valid (not conflicting with itself)
        XCTAssertEqual(result, .valid)
    }
    
    func testUpdateShortcutValidation() throws {
        // Insert defaults
        try repository.insertDefaults()
        
        // Try to update leftHalf to use rightHalf's shortcut
        var leftHalf = try repository.fetch(byAction: .leftHalf)!
        let rightHalf = try repository.fetch(byAction: .rightHalf)!
        
        leftHalf.keyCode = rightHalf.keyCode
        leftHalf.modifiers = rightHalf.modifiers
        
        // Validate should fail
        let result = try repository.validateShortcut(leftHalf)
        
        if case .conflict(let conflictingAction) = result {
            XCTAssertEqual(conflictingAction, "rightHalf")
        } else {
            XCTFail("Expected conflict")
        }
    }
    
    func testShortcutStringFormatting() throws {
        // Insert defaults
        try repository.insertDefaults()
        
        let leftHalf = try repository.fetch(byAction: .leftHalf)!
        
        // Verify shortcut string is formatted correctly
        let formatted = leftHalf.shortcutString
        
        // Should contain control and option symbols
        XCTAssertTrue(formatted.contains("⌃"))  // Control
        XCTAssertTrue(formatted.contains("⌥"))  // Option
        XCTAssertTrue(formatted.contains("←"))  // Left arrow
    }
    
    func testDisplayName() throws {
        // Insert defaults
        try repository.insertDefaults()
        
        let leftHalf = try repository.fetch(byAction: .leftHalf)!
        
        // Verify display name
        XCTAssertEqual(leftHalf.displayName, "Left Half")
    }
}
