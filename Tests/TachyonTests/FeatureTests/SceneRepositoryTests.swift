import XCTest
import GRDB
@testable import TachyonCore

class SceneRepositoryTests: XCTestCase {
    
    var dbQueue: DatabaseQueue!
    var repository: SceneRepository!
    
    override func setUpWithError() throws {
        // Create in-memory database
        dbQueue = try DatabaseQueue()
        
        // Run migrations
        try dbQueue.write { db in
            try WindowScene.createTable(in: db)
            try SceneWindow.createTable(in: db)
        }
        
        repository = SceneRepository(dbQueue: dbQueue)
    }
    
    override func tearDownWithError() throws {
        dbQueue = nil
        repository = nil
    }
    
    // MARK: - Insert & Fetch Tests
    
    func testInsertAndFetchScene() throws {
        let scene = WindowScene(
            name: "Test Scene",
            displayCount: 2
        )
        
        try repository.insert(scene)
        
        let fetched = try repository.fetch(byId: scene.id)
        
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.name, "Test Scene")
        XCTAssertEqual(fetched?.displayCount, 2)
        XCTAssertNil(fetched?.targetDisplayIndex)
        XCTAssertTrue(fetched?.isEnabled ?? false)
    }
    
    func testInsertSceneWithWindows() throws {
        let scene = WindowScene(
            name: "Full Workspace",
            displayCount: 1
        )
        
        let windows = [
            SceneWindow(
                sceneId: scene.id,
                bundleId: "com.apple.Safari",
                appName: "Safari",
                displayIndex: 0,
                xPercent: 0.0,
                yPercent: 0.0,
                widthPercent: 0.5,
                heightPercent: 1.0
            ),
            SceneWindow(
                sceneId: scene.id,
                bundleId: "com.microsoft.VSCode",
                appName: "Visual Studio Code",
                displayIndex: 0,
                xPercent: 0.5,
                yPercent: 0.0,
                widthPercent: 0.5,
                heightPercent: 1.0
            )
        ]
        
        try repository.insert(scene, windows: windows)
        
        let fetchedWindows = try repository.fetchWindows(forSceneId: scene.id)
        XCTAssertEqual(fetchedWindows.count, 2)
        
        let safari = fetchedWindows.first { $0.bundleId == "com.apple.Safari" }
        XCTAssertNotNil(safari)
        XCTAssertEqual(safari?.widthPercent, 0.5)
    }
    
    func testFetchAll() throws {
        let scene1 = WindowScene(name: "Scene 1", displayCount: 1)
        let scene2 = WindowScene(name: "Scene 2", displayCount: 2)
        let scene3 = WindowScene(name: "Scene 3", displayCount: 1)
        
        try repository.insert(scene1)
        try repository.insert(scene2)
        try repository.insert(scene3)
        
        let allScenes = try repository.fetchAll()
        XCTAssertEqual(allScenes.count, 3)
    }
    
    func testFetchEnabled() throws {
        var enabledScene = WindowScene(name: "Enabled", displayCount: 1, isEnabled: true)
        var disabledScene = WindowScene(name: "Disabled", displayCount: 1, isEnabled: false)
        
        try repository.insert(enabledScene)
        try repository.insert(disabledScene)
        
        let enabledScenes = try repository.fetchEnabled()
        XCTAssertEqual(enabledScenes.count, 1)
        XCTAssertEqual(enabledScenes.first?.name, "Enabled")
    }
    
    // MARK: - Update Tests
    
    func testUpdateScene() throws {
        var scene = WindowScene(name: "Original", displayCount: 1)
        try repository.insert(scene)
        
        scene.name = "Updated"
        try repository.update(scene)
        
        let fetched = try repository.fetch(byId: scene.id)
        XCTAssertEqual(fetched?.name, "Updated")
    }
    
    func testUpdateShortcut() throws {
        let scene = WindowScene(name: "Test", displayCount: 1)
        try repository.insert(scene)
        
        try repository.updateShortcut(sceneId: scene.id, keyCode: 35, modifiers: 6144)
        
        let fetched = try repository.fetch(byId: scene.id)
        XCTAssertEqual(fetched?.shortcutKeyCode, 35)
        XCTAssertEqual(fetched?.shortcutModifiers, 6144)
    }
    
    func testClearShortcut() throws {
        var scene = WindowScene(
            name: "Test",
            displayCount: 1,
            shortcutKeyCode: 35,
            shortcutModifiers: 6144
        )
        try repository.insert(scene)
        
        try repository.updateShortcut(sceneId: scene.id, keyCode: nil, modifiers: nil)
        
        let fetched = try repository.fetch(byId: scene.id)
        XCTAssertNil(fetched?.shortcutKeyCode)
        XCTAssertNil(fetched?.shortcutModifiers)
    }
    
    // MARK: - Delete Tests
    
    func testDeleteScene() throws {
        let scene = WindowScene(name: "To Delete", displayCount: 1)
        try repository.insert(scene)
        
        try repository.delete(id: scene.id)
        
        let fetched = try repository.fetch(byId: scene.id)
        XCTAssertNil(fetched)
    }
    
    func testDeleteSceneCascadesWindows() throws {
        let scene = WindowScene(name: "With Windows", displayCount: 1)
        let window = SceneWindow(
            sceneId: scene.id,
            bundleId: "com.test.App",
            appName: "Test App",
            displayIndex: 0,
            xPercent: 0.0, yPercent: 0.0,
            widthPercent: 1.0, heightPercent: 1.0
        )
        
        try repository.insert(scene, windows: [window])
        
        // Verify window exists
        var windows = try repository.fetchWindows(forSceneId: scene.id)
        XCTAssertEqual(windows.count, 1)
        
        // Delete scene
        try repository.delete(id: scene.id)
        
        // Windows should be cascade deleted
        windows = try repository.fetchWindows(forSceneId: scene.id)
        XCTAssertEqual(windows.count, 0)
    }
    
    // MARK: - Validation Tests
    
    func testValidateShortcutNoConflict() throws {
        let scene1 = WindowScene(
            name: "Scene 1",
            displayCount: 1,
            shortcutKeyCode: 35,
            shortcutModifiers: 6144
        )
        try repository.insert(scene1)
        
        // Different shortcut, no conflict
        let conflict = try repository.validateShortcut(
            keyCode: 36,
            modifiers: 6144,
            excludingSceneId: nil
        )
        
        XCTAssertNil(conflict)
    }
    
    func testValidateShortcutWithConflict() throws {
        let scene1 = WindowScene(
            name: "Scene 1",
            displayCount: 1,
            shortcutKeyCode: 35,
            shortcutModifiers: 6144
        )
        try repository.insert(scene1)
        
        // Same shortcut, should conflict
        let conflict = try repository.validateShortcut(
            keyCode: 35,
            modifiers: 6144,
            excludingSceneId: nil
        )
        
        XCTAssertNotNil(conflict)
        XCTAssertEqual(conflict?.name, "Scene 1")
    }
    
    func testValidateShortcutExcludesSelf() throws {
        let scene = WindowScene(
            name: "Self",
            displayCount: 1,
            shortcutKeyCode: 35,
            shortcutModifiers: 6144
        )
        try repository.insert(scene)
        
        // Same shortcut but excluding self
        let conflict = try repository.validateShortcut(
            keyCode: 35,
            modifiers: 6144,
            excludingSceneId: scene.id
        )
        
        XCTAssertNil(conflict)
    }
    
    // MARK: - fetchWithShortcuts Tests
    
    func testFetchWithShortcuts() throws {
        let sceneWithShortcut = WindowScene(
            name: "Has Shortcut",
            displayCount: 1,
            shortcutKeyCode: 35,
            shortcutModifiers: 6144,
            isEnabled: true
        )
        let sceneWithoutShortcut = WindowScene(
            name: "No Shortcut",
            displayCount: 1,
            isEnabled: true
        )
        
        try repository.insert(sceneWithShortcut)
        try repository.insert(sceneWithoutShortcut)
        
        let scenesWithShortcuts = try repository.fetchWithShortcuts()
        XCTAssertEqual(scenesWithShortcuts.count, 1)
        XCTAssertEqual(scenesWithShortcuts.first?.name, "Has Shortcut")
    }
}
