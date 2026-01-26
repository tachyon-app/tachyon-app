import Foundation
import GRDB

/// Proportional window geometry for a scene (stored in separate table, related to Scene)
public struct SceneWindow: Codable, Equatable, Identifiable, FetchableRecord, PersistableRecord {
    public var id: UUID
    public var sceneId: UUID               // Foreign key to Scene
    public var bundleId: String            // App identifier for launching
    public var appName: String             // Display name
    public var appPath: String?            // Path to app bundle (for launching)
    public var displayIndex: Int           // Which display this window is on (0-based)
    public var xPercent: Double            // X position as % of visibleFrame (0.0-1.0)
    public var yPercent: Double            // Y position as % of visibleFrame
    public var widthPercent: Double        // Width as % of visibleFrame
    public var heightPercent: Double       // Height as % of visibleFrame
    
    // GRDB table definition
    public static let databaseTableName = "scene_windows"
    
    // Define foreign key for relation
    public static let scene = belongsTo(WindowScene.self, using: ForeignKey(["sceneId"]))
    public var scene: QueryInterfaceRequest<WindowScene> {
        request(for: SceneWindow.scene)
    }
    
    // Initializer
    public init(
        id: UUID = UUID(),
        sceneId: UUID,
        bundleId: String,
        appName: String,
        appPath: String? = nil,
        displayIndex: Int,
        xPercent: Double,
        yPercent: Double,
        widthPercent: Double,
        heightPercent: Double
    ) {
        self.id = id
        self.sceneId = sceneId
        self.bundleId = bundleId
        self.appName = appName
        self.appPath = appPath
        self.displayIndex = displayIndex
        self.xPercent = xPercent
        self.yPercent = yPercent
        self.widthPercent = widthPercent
        self.heightPercent = heightPercent
    }
    
    // MARK: - Proportional Geometry Conversion
    
    /// Convert absolute frame to proportional coordinates relative to visibleFrame
    public static func fromAbsoluteFrame(
        _ frame: CGRect,
        visibleFrame: CGRect,
        bundleId: String,
        appName: String,
        appPath: String?,
        displayIndex: Int,
        sceneId: UUID
    ) -> SceneWindow {
        let xPercent = (frame.origin.x - visibleFrame.origin.x) / visibleFrame.width
        let yPercent = (frame.origin.y - visibleFrame.origin.y) / visibleFrame.height
        let widthPercent = frame.width / visibleFrame.width
        let heightPercent = frame.height / visibleFrame.height
        
        return SceneWindow(
            sceneId: sceneId,
            bundleId: bundleId,
            appName: appName,
            appPath: appPath,
            displayIndex: displayIndex,
            xPercent: max(0, min(1, xPercent)),
            yPercent: max(0, min(1, yPercent)),
            widthPercent: max(0, min(1, widthPercent)),
            heightPercent: max(0, min(1, heightPercent))
        )
    }
    
    /// Convert proportional coordinates back to absolute frame
    public func toAbsoluteFrame(visibleFrame: CGRect) -> CGRect {
        let x = visibleFrame.origin.x + (xPercent * visibleFrame.width)
        let y = visibleFrame.origin.y + (yPercent * visibleFrame.height)
        let width = widthPercent * visibleFrame.width
        let height = heightPercent * visibleFrame.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: - Table Creation

extension SceneWindow {
    public static func createTable(in db: Database) throws {
        try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("sceneId", .text).notNull()
                .references("scenes", onDelete: .cascade)
            t.column("bundleId", .text).notNull()
            t.column("appName", .text).notNull()
            t.column("appPath", .text)
            t.column("displayIndex", .integer).notNull()
            t.column("xPercent", .double).notNull()
            t.column("yPercent", .double).notNull()
            t.column("widthPercent", .double).notNull()
            t.column("heightPercent", .double).notNull()
        }
    }
}
