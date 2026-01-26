import SwiftUI
import AppKit
import TachyonCore

/// Model for a window tile in the layout designer
struct LayoutTile: Identifiable {
    let id: UUID
    var appName: String
    var bundleId: String
    var appPath: String?
    var appIcon: NSImage?
    var url: String?
    var xPercent: Double
    var yPercent: Double
    var widthPercent: Double
    var heightPercent: Double
    var displayIndex: Int
    
    init(
        id: UUID = UUID(),
        appName: String = "Safari",
        bundleId: String = "com.apple.Safari",
        appPath: String? = nil,
        appIcon: NSImage? = nil,
        url: String? = nil,
        xPercent: Double = 0,
        yPercent: Double = 0,
        widthPercent: Double = 50,
        heightPercent: Double = 100,
        displayIndex: Int = 0
    ) {
        self.id = id
        self.appName = appName
        self.bundleId = bundleId
        self.appPath = appPath
        self.appIcon = appIcon
        self.url = url
        self.xPercent = xPercent
        self.yPercent = yPercent
        self.widthPercent = widthPercent
        self.heightPercent = heightPercent
        self.displayIndex = displayIndex
    }
}

/// Size preset for quick window sizing
enum SizePreset: String, CaseIterable {
    case full = "Full"
    case leftHalf = "Left Half"
    case rightHalf = "Right Half"
    case leftTwoThirds = "Left 2/3"
    case rightTwoThirds = "Right 2/3"
    case leftThird = "Left Third"
    case centerThird = "Center Third"
    case rightThird = "Right Third"
    case leftThreeQuarters = "Left 3/4"
    case rightThreeQuarters = "Right 3/4"
    case leftQuarter = "Left Quarter"
    case rightQuarter = "Right Quarter"
    
    var width: Double {
        switch self {
        case .full: return 100
        case .leftHalf, .rightHalf: return 50
        case .leftTwoThirds, .rightTwoThirds: return 66.67
        case .leftThird, .centerThird, .rightThird: return 33.33
        case .leftThreeQuarters, .rightThreeQuarters: return 75
        case .leftQuarter, .rightQuarter: return 25
        }
    }
    
    var height: Double { 100 }
    
    var xPosition: Double {
        switch self {
        case .full, .leftHalf, .leftTwoThirds, .leftThird, .leftThreeQuarters, .leftQuarter: return 0
        case .centerThird: return 33.33
        case .rightTwoThirds: return 33.33
        case .rightHalf: return 50
        case .rightThird: return 66.67
        case .rightThreeQuarters: return 25
        case .rightQuarter: return 75
        }
    }
    
    var yPosition: Double { 0 }
}

/// Position preset for 3x3 grid - each cell is 1/3 width x 1/3 height
enum PositionPreset: Int, CaseIterable {
    case topLeft = 0
    case topCenter = 1
    case topRight = 2
    case middleLeft = 3
    case middleCenter = 4
    case middleRight = 5
    case bottomLeft = 6
    case bottomCenter = 7
    case bottomRight = 8
    
    /// Width as percentage (1/3 of screen = 33.33%)
    var width: Double { 33.33 }
    
    /// Height as percentage (1/3 of screen = 33.33%)
    var height: Double { 33.33 }
    
    /// X position based on column (0, 33.33, or 66.67)
    var xPosition: Double {
        switch self {
        case .topLeft, .middleLeft, .bottomLeft: return 0
        case .topCenter, .middleCenter, .bottomCenter: return 33.33
        case .topRight, .middleRight, .bottomRight: return 66.67
        }
    }
    
    /// Y position based on row (0, 33.33, or 66.67)
    var yPosition: Double {
        switch self {
        case .topLeft, .topCenter, .topRight: return 0
        case .middleLeft, .middleCenter, .middleRight: return 33.33
        case .bottomLeft, .bottomCenter, .bottomRight: return 66.67
        }
    }
}


/// ViewModel for the layout designer
@MainActor
class LayoutDesignerViewModel: ObservableObject {
    @Published var sceneName: String = ""
    @Published var tiles: [LayoutTile] = []
    @Published var selectedTileId: UUID?
    @Published var selectedDisplayIndex: Int = 0
    @Published var isSaving = false
    @Published var errorMessage: String?
    
    /// Scene ID when editing an existing scene (nil for new scene)
    var editingSceneId: UUID?
    
    private var repository: SceneRepository?
    
    var selectedTile: LayoutTile? {
        tiles.first { $0.id == selectedTileId }
    }
    
    var displays: [(index: Int, name: String, size: CGSize)] {
        NSScreen.screens.enumerated().map { index, screen in
            (index, screen.localizedName, screen.frame.size)
        }
    }
    
    var currentDisplay: (index: Int, name: String, size: CGSize)? {
        displays.first { $0.index == selectedDisplayIndex }
    }
    
    var tilesForCurrentDisplay: [LayoutTile] {
        tiles.filter { $0.displayIndex == selectedDisplayIndex }
    }
    
    var isEditMode: Bool { editingSceneId != nil }
    
    init() {
        setupRepository()
    }
    
    private func setupRepository() {
        guard let dbQueue = StorageManager.shared.dbQueue else { return }
        repository = SceneRepository(dbQueue: dbQueue)
    }
    
    /// Load an existing scene for editing
    func loadScene(_ scene: WindowScene) {
        // Ensure repository is set up
        if repository == nil {
            setupRepository()
        }
        
        guard let repository = repository else {
            print("❌ Cannot load scene: repository not available")
            return
        }
        
        print("📂 Loading scene: \(scene.displayName) (id: \(scene.id))")
        
        editingSceneId = scene.id
        sceneName = scene.displayName
        
        do {
            let sceneWindows = try repository.fetchWindows(forSceneId: scene.id)
            print("📂 Found \(sceneWindows.count) windows for scene")
            
            tiles = sceneWindows.map { window in
                let icon: NSImage? = if let path = window.appPath {
                    NSWorkspace.shared.icon(forFile: path)
                } else if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: window.bundleId) {
                    NSWorkspace.shared.icon(forFile: appURL.path)
                } else {
                    nil
                }
                
                let tile = LayoutTile(
                    id: window.id,
                    appName: window.appName,
                    bundleId: window.bundleId,
                    appPath: window.appPath,
                    appIcon: icon,
                    url: nil,
                    xPercent: window.xPercent * 100,
                    yPercent: window.yPercent * 100,
                    widthPercent: window.widthPercent * 100,
                    heightPercent: window.heightPercent * 100,
                    displayIndex: window.displayIndex
                )
                print("  📦 Tile: \(window.appName) at \(tile.xPercent)%, \(tile.yPercent)% size \(tile.widthPercent)%x\(tile.heightPercent)% display:\(window.displayIndex)")
                return tile
            }
            selectedTileId = tiles.first?.id
            print("📂 Loaded \(tiles.count) tiles, selected: \(selectedTileId?.uuidString ?? "none")")
        } catch {
            print("❌ Failed to load scene windows: \(error)")
        }
    }
    
    func addTile() {
        let tile = LayoutTile(displayIndex: selectedDisplayIndex)
        tiles.append(tile)
        selectedTileId = tile.id
    }
    
    func deleteTile(_ id: UUID) {
        tiles.removeAll { $0.id == id }
        if selectedTileId == id {
            selectedTileId = tiles.first?.id
        }
    }
    
    func updateSelectedTile(_ update: (inout LayoutTile) -> Void) {
        guard let index = tiles.firstIndex(where: { $0.id == selectedTileId }) else { return }
        update(&tiles[index])
    }
    
    func applySizePreset(_ preset: SizePreset) {
        updateSelectedTile { tile in
            tile.widthPercent = preset.width
            tile.heightPercent = preset.height
            tile.xPercent = preset.xPosition
            tile.yPercent = preset.yPosition
        }
    }
    
    func applyPositionPreset(_ preset: PositionPreset) {
        updateSelectedTile { tile in
            tile.widthPercent = preset.width
            tile.heightPercent = preset.height
            tile.xPercent = preset.xPosition
            tile.yPercent = preset.yPosition
        }
    }
    
    func updateTilePosition(_ id: UUID, x: Double, y: Double) {
        guard let index = tiles.firstIndex(where: { $0.id == id }) else { return }
        tiles[index].xPercent = x
        tiles[index].yPercent = y
    }
    
    func save(onComplete: @escaping (Bool) -> Void) {
        guard let repository = repository else {
            errorMessage = "Database not available"
            onComplete(false)
            return
        }
        
        guard !sceneName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a scene name"
            onComplete(false)
            return
        }
        
        guard !tiles.isEmpty else {
            errorMessage = "Add at least one window tile"
            onComplete(false)
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                // Use existing scene ID if editing, otherwise create new
                let sceneId = editingSceneId ?? UUID()
                let scene = WindowScene(
                    id: sceneId,
                    name: sceneName.trimmingCharacters(in: .whitespaces),
                    displayCount: NSScreen.screens.count
                )
                
                let sceneWindows = tiles.map { tile in
                    SceneWindow(
                        sceneId: sceneId,
                        bundleId: tile.bundleId,
                        appName: tile.appName,
                        appPath: tile.appPath,
                        displayIndex: tile.displayIndex,
                        xPercent: tile.xPercent / 100,
                        yPercent: tile.yPercent / 100,
                        widthPercent: tile.widthPercent / 100,
                        heightPercent: tile.heightPercent / 100
                    )
                }
                
                if isEditMode {
                    // Update existing scene
                    try repository.update(scene, windows: sceneWindows)
                } else {
                    // Insert new scene
                    try repository.insert(scene, windows: sceneWindows)
                }
                
                NotificationCenter.default.post(name: .scenesDidChange, object: nil)
                
                isSaving = false
                onComplete(true)
            } catch {
                errorMessage = error.localizedDescription
                isSaving = false
                onComplete(false)
            }
        }
    }
}

/// Main layout designer view
struct LayoutDesignerView: View {
    @StateObject private var viewModel = LayoutDesignerViewModel()
    @Binding var isPresented: Bool
    var sceneToEdit: WindowScene?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            DesignerHeader(
                sceneName: $viewModel.sceneName,
                isEditMode: viewModel.isEditMode,
                onCancel: { isPresented = false },
                onSave: save
            )
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack(spacing: 0) {
                // Canvas (left)
                LayoutCanvasView(viewModel: viewModel)
                    .frame(minWidth: 400)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Config panel (right)
                if viewModel.selectedTile != nil {
                    LayoutConfigPanel(viewModel: viewModel)
                        .frame(width: 280)
                } else {
                    EmptyConfigPanel(onAddTile: viewModel.addTile)
                        .frame(width: 280)
                }
            }
            
            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
            }
        }
        .frame(width: 750, height: 550)
        .background(Color(hex: "#1a1a1a"))
        .onAppear {
            if let scene = sceneToEdit {
                viewModel.loadScene(scene)
            }
        }
    }
    
    private func save() {
        viewModel.save { success in
            if success {
                isPresented = false
            }
        }
    }
}

/// Header with scene name and actions
struct DesignerHeader: View {
    @Binding var sceneName: String
    var isEditMode: Bool = false
    let onCancel: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "rectangle.3.group")
                        .foregroundColor(.white.opacity(0.5))
                )
            
            // Scene name
            TextField(isEditMode ? "Edit scene..." : "Scene name...", text: $sceneName)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Actions
            Button("Cancel", action: onCancel)
                .buttonStyle(.plain)
                .foregroundColor(.white.opacity(0.6))
            
            Button(isEditMode ? "Update" : "Save", action: onSave)
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

/// Canvas showing the screen with tiles
struct LayoutCanvasView: View {
    @ObservedObject var viewModel: LayoutDesignerViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Display tabs
            HStack(spacing: 8) {
                ForEach(viewModel.displays, id: \.index) { display in
                    Button(action: { viewModel.selectedDisplayIndex = display.index }) {
                        Text(display.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(viewModel.selectedDisplayIndex == display.index ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(viewModel.selectedDisplayIndex == display.index ? Color.blue : Color.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // Add tile button
                Button(action: viewModel.addTile) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            
            // Screen canvas
            GeometryReader { geometry in
                let displaySize = viewModel.currentDisplay?.size ?? CGSize(width: 1920, height: 1080)
                let aspectRatio = displaySize.width / displaySize.height
                let canvasWidth = min(geometry.size.width - 40, (geometry.size.height - 60) * aspectRatio)
                let canvasHeight = canvasWidth / aspectRatio
                
                ZStack {
                    // Screen background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black)
                        .frame(width: canvasWidth, height: canvasHeight)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    
                    // Window tiles
                    ForEach(viewModel.tilesForCurrentDisplay) { tile in
                        WindowTileView(
                            tile: tile,
                            isSelected: tile.id == viewModel.selectedTileId,
                            canvasSize: CGSize(width: canvasWidth, height: canvasHeight),
                            onSelect: { viewModel.selectedTileId = tile.id },
                            onDrag: { newX, newY in
                                viewModel.updateTilePosition(tile.id, x: newX, y: newY)
                            }
                        )
                    }
                }
                .frame(width: canvasWidth, height: canvasHeight)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            
            // Display info
            if let display = viewModel.currentDisplay {
                Text("\(display.name) · \(Int(display.size.width)) × \(Int(display.size.height))")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, 16)
            }
        }
        .padding(.top, 16)
    }
}

/// Individual window tile on the canvas
struct WindowTileView: View {
    let tile: LayoutTile
    let isSelected: Bool
    let canvasSize: CGSize
    let onSelect: () -> Void
    let onDrag: (Double, Double) -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        let baseX = canvasSize.width * tile.xPercent / 100
        let baseY = canvasSize.height * tile.yPercent / 100
        let width = canvasSize.width * tile.widthPercent / 100
        let height = canvasSize.height * tile.heightPercent / 100
        
        let x = baseX + dragOffset.width
        let y = baseY + dragOffset.height
        
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "#2a2a2a"))
            
            RoundedRectangle(cornerRadius: 4)
                .stroke(isSelected ? Color.blue : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            
            // App icon
            if let icon = tile.appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: min(width * 0.4, 32), height: min(height * 0.4, 32))
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: min(width * 0.3, 24)))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(width: width, height: height)
        .position(x: x + width / 2, y: y + height / 2)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isDragging {
                        onSelect()
                        isDragging = true
                    }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    isDragging = false
                    // Calculate new percentage position
                    let newX = baseX + value.translation.width
                    let newY = baseY + value.translation.height
                    
                    // Clamp to canvas bounds
                    let clampedX = max(0, min(canvasSize.width - width, newX))
                    let clampedY = max(0, min(canvasSize.height - height, newY))
                    
                    // Convert back to percentages
                    let newXPercent = (clampedX / canvasSize.width) * 100
                    let newYPercent = (clampedY / canvasSize.height) * 100
                    
                    onDrag(newXPercent, newYPercent)
                    dragOffset = .zero
                }
        )
        .onTapGesture {
            onSelect()
        }
    }
}

/// Config panel for selected tile
struct LayoutConfigPanel: View {
    @ObservedObject var viewModel: LayoutDesignerViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // App picker section
                ConfigSection(title: "Application") {
                    AppPickerView(viewModel: viewModel)
                }
                
                // URL field (for browsers)
                if viewModel.selectedTile?.bundleId.contains("Safari") == true ||
                   viewModel.selectedTile?.bundleId.contains("Chrome") == true ||
                   viewModel.selectedTile?.bundleId.contains("Firefox") == true {
                    ConfigSection(title: "URL") {
                        TextField("https://...", text: Binding(
                            get: { viewModel.selectedTile?.url ?? "" },
                            set: { newValue in viewModel.updateSelectedTile { $0.url = newValue.isEmpty ? nil : newValue } }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                    }
                }
                
                // Size presets
                ConfigSection(title: "Size") {
                    SizePresetsView(viewModel: viewModel)
                }
                
                // Manual size inputs
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("W")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        HStack(spacing: 4) {
                            TextField("", value: Binding(
                                get: { viewModel.selectedTile?.widthPercent ?? 50 },
                                set: { newValue in viewModel.updateSelectedTile { $0.widthPercent = newValue } }
                            ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            Text("%")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("H")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        HStack(spacing: 4) {
                            TextField("", value: Binding(
                                get: { viewModel.selectedTile?.heightPercent ?? 100 },
                                set: { newValue in viewModel.updateSelectedTile { $0.heightPercent = newValue } }
                            ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            Text("%")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                
                // Position grid
                ConfigSection(title: "Position") {
                    PositionGridView(viewModel: viewModel)
                }
                
                Spacer()
                
                // Delete button
                Button(role: .destructive) {
                    if let id = viewModel.selectedTileId {
                        viewModel.deleteTile(id)
                    }
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Remove Window")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .background(Color(hex: "#1e1e1e"))
    }
}

/// Section wrapper for config panel
struct ConfigSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
            
            content
        }
    }
}

/// App picker with installed apps
struct AppPickerView: View {
    @ObservedObject var viewModel: LayoutDesignerViewModel
    @State private var showAppPicker = false
    
    var body: some View {
        Button(action: { showAppPicker = true }) {
            HStack {
                if let icon = viewModel.selectedTile?.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "app.fill")
                        .frame(width: 20, height: 20)
                }
                
                Text(viewModel.selectedTile?.appName ?? "Select App")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.08))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showAppPicker) {
            InstalledAppsListView(viewModel: viewModel, isPresented: $showAppPicker)
        }
    }
}

/// List of installed apps
struct InstalledAppsListView: View {
    @ObservedObject var viewModel: LayoutDesignerViewModel
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var installedApps: [(name: String, bundleId: String, path: String, icon: NSImage)] = []
    
    var filteredApps: [(name: String, bundleId: String, path: String, icon: NSImage)] {
        if searchText.isEmpty {
            return installedApps
        }
        return installedApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            TextField("Search apps...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(12)
            
            Divider()
            
            // App list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredApps, id: \.bundleId) { app in
                        Button {
                            viewModel.updateSelectedTile { tile in
                                tile.appName = app.name
                                tile.bundleId = app.bundleId
                                tile.appPath = app.path
                                tile.appIcon = app.icon
                            }
                            isPresented = false
                        } label: {
                            HStack(spacing: 12) {
                                Image(nsImage: app.icon)
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                
                                Text(app.name)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Divider().padding(.leading, 48)
                    }
                    
                    // Browse button
                    Button {
                        browseForApp()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "folder")
                                .frame(width: 24, height: 24)
                            
                            Text("Browse...")
                                .font(.system(size: 13))
                                .foregroundColor(.blue)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 280, height: 350)
        .background(Color(hex: "#252525"))
        .onAppear {
            loadInstalledApps()
        }
    }
    
    private func loadInstalledApps() {
        var apps: [(name: String, bundleId: String, path: String, icon: NSImage)] = []
        
        let appDirectories = [
            "/Applications",
            "/System/Applications",
            NSHomeDirectory() + "/Applications"
        ]
        
        for dir in appDirectories {
            guard let contents = try? FileManager.default.contentsOfDirectory(atPath: dir) else { continue }
            
            for item in contents where item.hasSuffix(".app") {
                let path = (dir as NSString).appendingPathComponent(item)
                if let bundle = Bundle(path: path),
                   let bundleId = bundle.bundleIdentifier,
                   let name = bundle.infoDictionary?["CFBundleName"] as? String ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String {
                    let icon = NSWorkspace.shared.icon(forFile: path)
                    apps.append((name: name, bundleId: bundleId, path: path, icon: icon))
                }
            }
        }
        
        installedApps = apps.sorted { $0.name < $1.name }
    }
    
    private func browseForApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            if let bundle = Bundle(url: url),
               let bundleId = bundle.bundleIdentifier,
               let name = bundle.infoDictionary?["CFBundleName"] as? String ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String {
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                viewModel.updateSelectedTile { tile in
                    tile.appName = name
                    tile.bundleId = bundleId
                    tile.appPath = url.path
                    tile.appIcon = icon
                }
                isPresented = false
            }
        }
    }
}

/// Size presets grid
struct SizePresetsView: View {
    @ObservedObject var viewModel: LayoutDesignerViewModel
    
    private let presets: [[SizePreset]] = [
        [.full],
        [.leftHalf, .rightHalf],
        [.leftTwoThirds, .rightTwoThirds],
        [.leftThreeQuarters, .rightThreeQuarters],
        [.leftThird, .centerThird, .rightThird],
        [.leftQuarter, .rightQuarter]
    ]
    
    var body: some View {
        VStack(spacing: 6) {
            ForEach(presets, id: \.first?.rawValue) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.rawValue) { preset in
                        Button(action: { viewModel.applySizePreset(preset) }) {
                            Text(preset.rawValue)
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

/// 3x3 Position grid
struct PositionGridView: View {
    @ObservedObject var viewModel: LayoutDesignerViewModel
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<3) { row in
                HStack(spacing: 4) {
                    ForEach(0..<3) { col in
                        let preset = PositionPreset(rawValue: row * 3 + col)!
                        Button(action: { viewModel.applyPositionPreset(preset) }) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

/// Empty state for config panel
struct EmptyConfigPanel: View {
    let onAddTile: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.dashed")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.2))
            
            Text("No window selected")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Add a window to configure its position")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
            
            Button(action: onAddTile) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Window")
                }
                .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
        .frame(maxHeight: .infinity)
        .background(Color(hex: "#1e1e1e"))
    }
}
