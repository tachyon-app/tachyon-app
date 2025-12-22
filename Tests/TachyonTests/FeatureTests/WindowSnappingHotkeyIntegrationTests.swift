import XCTest
@testable import TachyonCore
import GRDB

class WindowSnappingHotkeyIntegrationTests: XCTestCase {
    
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
    
    // MARK: - Test 1: Register Custom Shortcut
    
    func testRegisterCustomShortcut() throws {
        // Create custom shortcut (Cmd+Shift+A for leftHalf)
        let customShortcut = WindowSnappingShortcut(
            action: "leftHalf",
            keyCode: 0,  // A key
            modifiers: 768,  // Cmd+Shift
            isEnabled: true
        )
        
        try repository.insert(customShortcut)
        
        // Verify it's stored
        let stored = try repository.fetch(byAction: .leftHalf)
        XCTAssertNotNil(stored)
        XCTAssertEqual(stored?.keyCode, 0)
        XCTAssertEqual(stored?.modifiers, 768)
        
        // In real implementation, this would register with HotkeyManager
        // For now, we just verify the data is correct
    }
    
    // MARK: - Test 2: Unregister All Shortcuts
    
    func testUnregisterAllShortcuts() throws {
        // Register 12 shortcuts
        try repository.insertDefaults()
        
        let before = try repository.fetchAll()
        XCTAssertEqual(before.count, 12)
        
        // Unregister all (delete all)
        try repository.deleteAll()
        
        let after = try repository.fetchAll()
        XCTAssertEqual(after.count, 0)
    }
    
    // MARK: - Test 3: Re-register After Change
    
    func testReregisterAfterShortcutChange() throws {
        // Register defaults
        try repository.insertDefaults()
        
        // Change one shortcut
        var leftHalf = try repository.fetch(byAction: .leftHalf)!
        let oldKeyCode = leftHalf.keyCode
        let oldModifiers = leftHalf.modifiers
        
        leftHalf.keyCode = 0  // A key
        leftHalf.modifiers = 256  // Cmd only
        try repository.update(leftHalf)
        
        // Verify change persisted
        let updated = try repository.fetch(byAction: .leftHalf)!
        XCTAssertNotEqual(updated.keyCode, oldKeyCode)
        XCTAssertNotEqual(updated.modifiers, oldModifiers)
        XCTAssertEqual(updated.keyCode, 0)
        XCTAssertEqual(updated.modifiers, 256)
        
        // In real implementation, this would:
        // 1. Unregister old hotkey (123, 6144)
        // 2. Register new hotkey (0, 256)
    }
    
    // MARK: - Test 4: Skip Disabled Shortcuts
    
    func testSkipDisabledShortcutsDuringRegistration() throws {
        // Setup: 2 disabled shortcuts
        try repository.insertDefaults()
        
        var leftHalf = try repository.fetch(byAction: .leftHalf)!
        leftHalf.isEnabled = false
        try repository.update(leftHalf)
        
        var rightHalf = try repository.fetch(byAction: .rightHalf)!
        rightHalf.isEnabled = false
        try repository.update(rightHalf)
        
        // Register all (fetch enabled only)
        let enabled = try repository.fetchEnabled()
        
        // Verify only 10 would be registered
        XCTAssertEqual(enabled.count, 10)
        XCTAssertFalse(enabled.contains { $0.action == "leftHalf" })
        XCTAssertFalse(enabled.contains { $0.action == "rightHalf" })
    }
    
    // MARK: - Additional Integration Tests
    
    func testModifierCombinations() throws {
        // Test various modifier combinations are stored correctly
        let shortcuts = [
            WindowSnappingShortcut(action: "test1", keyCode: 0, modifiers: 256, isEnabled: true),   // Cmd
            WindowSnappingShortcut(action: "test2", keyCode: 0, modifiers: 512, isEnabled: true),   // Shift
            WindowSnappingShortcut(action: "test3", keyCode: 0, modifiers: 2048, isEnabled: true),  // Option
            WindowSnappingShortcut(action: "test4", keyCode: 0, modifiers: 4096, isEnabled: true),  // Control
            WindowSnappingShortcut(action: "test5", keyCode: 0, modifiers: 6144, isEnabled: true),  // Ctrl+Opt
            WindowSnappingShortcut(action: "test6", keyCode: 0, modifiers: 768, isEnabled: true),   // Cmd+Shift
        ]
        
        for shortcut in shortcuts {
            try repository.insert(shortcut)
        }
        
        let all = try repository.fetchAll()
        XCTAssertEqual(all.count, 6)
        
        // Verify each has correct modifiers
        XCTAssertEqual(all.first { $0.action == "test1" }?.modifiers, 256)
        XCTAssertEqual(all.first { $0.action == "test5" }?.modifiers, 6144)
    }
    
    func testBulkEnableDisable() throws {
        // Insert defaults
        try repository.insertDefaults()
        
        // Disable all shortcuts
        var all = try repository.fetchAll()
        for var shortcut in all {
            shortcut.isEnabled = false
            try repository.update(shortcut)
        }
        
        // Verify all disabled
        let disabled = try repository.fetchEnabled()
        XCTAssertEqual(disabled.count, 0)
        
        // Re-enable all
        all = try repository.fetchAll()
        for var shortcut in all {
            shortcut.isEnabled = true
            try repository.update(shortcut)
        }
        
        // Verify all enabled
        let enabled = try repository.fetchEnabled()
        XCTAssertEqual(enabled.count, 12)
    }
    
    func testShortcutPersistenceAcrossReloads() throws {
        // Insert custom shortcut
        let custom = WindowSnappingShortcut(
            action: "leftHalf",
            keyCode: 99,
            modifiers: 999,
            isEnabled: false
        )
        try repository.insert(custom)
        
        // Simulate app restart by creating new repository instance
        let newRepository = WindowSnappingShortcutRepository(dbQueue: dbQueue)
        
        // Fetch and verify it persisted
        let loaded = try newRepository.fetch(byAction: .leftHalf)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.keyCode, 99)
        XCTAssertEqual(loaded?.modifiers, 999)
        XCTAssertFalse(loaded?.isEnabled ?? true)
    }
}
