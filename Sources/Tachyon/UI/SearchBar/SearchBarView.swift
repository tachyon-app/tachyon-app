import SwiftUI

/// Main search bar view with results
struct SearchBarView: View {
    @ObservedObject var viewModel: SearchBarViewModel
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        if let (script, metadata) = viewModel.showingScriptOutput {
            // Show script output view
            ScriptOutputView(script: script, metadata: metadata) {
                viewModel.showingScriptOutput = nil
            }
        } else if let (script, metadata) = viewModel.showingScriptArgumentForm {
            // Show script argument input form
            ScriptArgumentInputView(
                script: script,
                metadata: metadata,
                onExecute: { arguments in
                    viewModel.showingScriptArgumentForm = nil
                    viewModel.executeScript(script: script, metadata: metadata, arguments: arguments)
                },
                onCancel: {
                    viewModel.showingScriptArgumentForm = nil
                }
            )
        } else if let link = viewModel.showingLinkForm {
        } else {
            // Show normal search interface with premium dark design
            VStack(spacing: 0) {
                // Search input area
                HStack(spacing: 12) {
                    // Purple search icon
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(hex: "#3B86F7"))
                    
                    TextField("Search for apps and commands...", text: $viewModel.query)
                        .textFieldStyle(.plain)
                        .font(.system(size: 20, weight: .regular, design: .default))
                        .foregroundColor(.white)
                        .focused($isSearchFocused)
                        .onSubmit {
                            viewModel.executeSelectedResult()
                        }
                        .onExitCommand {
                            viewModel.onHideWindow?()
                        }
                    
                    if !viewModel.query.isEmpty {
                        Button(action: { viewModel.query = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(
                    Color.black.opacity(0.15)
                )
                
                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
                
                // Results list
                if !viewModel.results.isEmpty {
                    ResultsListView(
                        results: viewModel.results,
                        selectedIndex: viewModel.selectedIndex,
                        onSelect: { index in
                            viewModel.selectedIndex = index
                        },
                        onExecute: { result in
                            viewModel.execute(result: result)
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeOut(duration: 0.2), value: viewModel.results.count)
                    
                    // Footer with keyboard hints
                    HStack(spacing: 20) {
                        HStack(spacing: 6) {
                            Text("↵")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(hex: "#3B86F7"))
                            Text("Open")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                        
                        HStack(spacing: 6) {
                            Text("⌘,")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(hex: "#3B86F7"))
                            Text("Settings")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                        
                        HStack(spacing: 6) {
                            Text("⎋")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(hex: "#3B86F7"))
                            Text("Close")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.2))
                    .overlay(
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 1),
                        alignment: .top
                    )
                }
                
                // Persistent status bar at bottom (Raycast-style)
                StatusBarComponent(
                    state: viewModel.statusBarState,
                    showActionButtons: !viewModel.results.isEmpty
                )            }
            .frame(width: 680)
            .background(
                // Dark gradient background with proper corner radius
                ZStack {
                    // Main dark gradient background
                    LinearGradient(
                        colors: [
                            Color(hex: "#1a1a1a"),
                            Color(hex: "#1f1f1f")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Subtle blue glow at top
                    RadialGradient(
                        colors: [
                            Color(hex: "#3B86F7").opacity(0.05),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 0,
                        endRadius: 300
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                // Subtle border with gradient
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
            // Layered shadows for depth (Raycast-style)
            .shadow(color: Color.black.opacity(0.6), radius: 50, x: 0, y: 20)
            .shadow(color: Color.black.opacity(0.4), radius: 25, x: 0, y: 10)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            .onAppear {
                isSearchFocused = true
            }
            .onExitCommand {
                viewModel.onHideWindow?()
            }
            .onHeightChange { height in
                viewModel.onHeightChanged?(height)
            }
        }
    }
    
    func focusSearchField() {
        isSearchFocused = true
    }
    
    func clearSearch() {
        viewModel.query = ""
        viewModel.results = []
    }
}

/// Preference key for tracking view size
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

extension View {
    func onHeightChange(perform action: @escaping (CGFloat) -> Void) -> some View {
        self.background(
            GeometryReader { geo in
                Color.clear.preference(key: ViewHeightKey.self, value: geo.size.height)
            }
        )
        .onPreferenceChange(ViewHeightKey.self, perform: action)
    }
}

/// ViewModel for search bar
@MainActor
class SearchBarViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [QueryResult] = []
    @Published var selectedIndex: Int = 0
    @Published var showingLinkForm: CustomLinkRecord? = nil
    @Published var showingScriptOutput: (ScriptRecord, ScriptMetadata)? = nil
    @Published var showingScriptArgumentForm: (ScriptRecord, ScriptMetadata)? = nil
    @Published private var scriptMessage: String? = nil
    @Published private var scriptMessageType: ScriptMessageType = .success
    
    enum ScriptMessageType {
        case running, success, error
    }
    
    var statusBarState: StatusBarComponent.State {
        if let message = scriptMessage {
            switch scriptMessageType {
            case .running:
                return .scriptRunning(message)
            case .success:
                return .scriptSuccess(message)
            case .error:
                return .scriptError(message)
            }
        } else {
            return .hint("Type to search apps and commands...")
        }
    }    
    private let queryEngine = QueryEngine()
    
    /// Callback to hide the window
    var onHideWindow: (() -> Void)?
    
    /// Callback when content height changes
    var onHeightChanged: ((CGFloat) -> Void)?
    
    init() {
        // Listen for link input form requests
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShowLinkInputForm"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let link = notification.object as? CustomLinkRecord {
                self?.showingLinkForm = link
            }
        }
        
        // Register plugins
        print("🔌 Registering AppLauncherPlugin...")
        let appLauncher = AppLauncherPlugin()
        queryEngine.register(plugin: appLauncher)
        print("✅ AppLauncherPlugin registered")
        
        print("🔌 Registering CustomLinksPlugin...")
        let customLinks = CustomLinksPlugin()
        queryEngine.register(plugin: customLinks)
        print("✅ CustomLinksPlugin registered")
        
        
        let searchEngines = SearchEnginePlugin()
        queryEngine.register(plugin: searchEngines)
        print("✅ SearchEnginePlugin registered")
        
        print("🔌 Registering WindowSnapperPlugin...")
        let windowSnapper = WindowSnapperPlugin()
        queryEngine.register(plugin: windowSnapper)
        print("✅ WindowSnapperPlugin registered")
        
        print("🔌 Registering ScriptRunnerPlugin...")
        let scriptRunner = ScriptRunnerPlugin()
        queryEngine.register(plugin: scriptRunner)
        print("✅ ScriptRunnerPlugin registered")        
        
        // Listen for status bar updates
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UpdateStatusBar"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let (indicatorEmoji, message) = notification.object as? (String, String) {
                self?.updateStatusBar(indicatorEmoji: indicatorEmoji, message: message)
            }
        }
        
        // Listen for script output view requests
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShowScriptOutputView"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let (script, metadata) = notification.object as? (ScriptRecord, ScriptMetadata) {
                self?.showingScriptOutput = (script, metadata)
            }
        }
        
        // Listen for script argument form requests
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShowScriptArgumentForm"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let (script, metadata) = notification.object as? (ScriptRecord, ScriptMetadata) {
                self?.showingScriptArgumentForm = (script, metadata)
            }
        }
        
        // Listen for search results refresh requests (e.g., when inline script updates)
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RefreshSearchResults"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                let currentQuery = self.query
                if !currentQuery.isEmpty {
                    self.performSearch(query: currentQuery)
                }
            }
        }
        
        // Listen for clear search query requests (e.g., after compact/inline/silent script execution)
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ClearSearchQuery"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.query = ""
            }
        }
        // Setup debounced search
        queryEngine.onSearchComplete = { [weak self] results in
            self?.results = results
            self?.selectedIndex = 0
        }
        
        // Observe query changes
        $query
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func performSearch(query: String) {
        print("🔍 performSearch called with query: '\(query)'")
        if query.isEmpty {
            results = []
            selectedIndex = 0
        } else {
            let searchResults = queryEngine.search(query: query)
            print("📊 Got \(searchResults.count) results")
            
            // Ensure UI update happens on main thread
            Task { @MainActor in
                self.results = searchResults
                self.selectedIndex = 0 // Always reset to first item
                print("🎨 UI updated with \(self.results.count) results")
                if !self.results.isEmpty {
                    print("✅ First result: \(self.results[0].title)")
                }
            }
        }
    }
    
    func selectNext() {
        guard !results.isEmpty else { return }
        selectedIndex = min(selectedIndex + 1, results.count - 1)
    }
    
    func selectPrevious() {
        guard !results.isEmpty else { return }
        selectedIndex = max(selectedIndex - 1, 0)
    }
    
    func executeSelectedResult() {
        guard selectedIndex < results.count else { return }
        let result = results[selectedIndex]
        execute(result: result)
    }
    
    func execute(result: QueryResult) {
        result.action()
        // Hide window after execution only if requested
        if result.hideWindowAfterExecution {
            onHideWindow?()
        }
    }
    
    /// Update status bar with indicator and message
    private func updateStatusBar(indicatorEmoji: String, message: String) {
        // Map emoji to message type
        switch indicatorEmoji {
        case "✅":
            scriptMessageType = .success
        case "⏳", "⏰":
            scriptMessageType = .running
        case "❌":
            scriptMessageType = .error
        default:
            scriptMessageType = .success
        }
        
        scriptMessage = message
        
        // Auto-clear after 5 seconds for success/error messages
        if indicatorEmoji == "✅" || indicatorEmoji == "❌" {
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                await MainActor.run {
                    if self.scriptMessage == message {
                        self.scriptMessage = nil
                    }
                }
            }
        }
    }
    
    /// Execute a script with arguments
    func executeScript(script: ScriptRecord, metadata: ScriptMetadata, arguments: [Int: String]) {
        Task {
            let fileURL = ScriptFileManager.shared.scriptURL(for: script.fileName)
            let executor = ScriptExecutor()
            
            do {
                let result = try await executor.execute(
                    fileURL: fileURL,
                    metadata: metadata,
                    arguments: arguments
                )
                
                await MainActor.run {
                    if result.isSuccess {
                        showingScriptOutput = (script, metadata)
                    } else {
                        // Show error
                        updateStatusBar(indicatorEmoji: "❌", message: "Script failed")
                    }
                }
            } catch {
                await MainActor.run {
                    updateStatusBar(indicatorEmoji: "❌", message: "Error: \(error.localizedDescription)")
                }
            }
        }
    }
}

// Need to import Combine for debounce
import Combine
