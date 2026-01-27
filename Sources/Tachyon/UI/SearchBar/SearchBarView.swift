import SwiftUI
import AppKit
import AVFoundation

/// Main search bar view with results
struct SearchBarView: View {
    @ObservedObject var viewModel: SearchBarViewModel
    @ObservedObject var themeManager = ThemeManager.shared
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        // Camera view takes over the entire window when active
        if viewModel.showingCameraView {
            CameraView(
                cameraService: viewModel.cameraService,
                onClose: {
                    viewModel.showingCameraView = false
                }
            )
        } else if let (script, metadata, arguments) = viewModel.showingScriptOutput {
            // Show script output view
            ScriptOutputView(script: script, metadata: metadata, arguments: arguments) {
                viewModel.showingScriptOutput = nil
            }
            .onExitCommand {
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
            .onExitCommand {
                viewModel.showingScriptArgumentForm = nil
            }
        } else if let link = viewModel.showingLinkForm {
        } else {
            // Show normal search interface with premium dark design
            // Use fixed height container with top alignment to avoid window resize jitter
            VStack(spacing: 0) {
                // Content container with background and rounded corners
                VStack(spacing: 0) {
                    // Search input area
                    HStack(spacing: 12) {
                        if viewModel.isCollectingArguments {
                            // Inline argument collection mode (Raycast-style)
                            if let context = viewModel.inlineArgumentContext {
                                LockedItemChip(
                                    title: context.title,
                                    icon: context.icon,
                                    iconData: context.iconData
                                )
                            }
                            
                            ForEach(Array(viewModel.inlineArguments.enumerated()), id: \.element.id) { index, argument in
                                InlineArgumentChip(
                                    argument: argument,
                                    value: Binding(
                                        get: { viewModel.inlineArgumentValues[argument.id] ?? "" },
                                        set: { viewModel.inlineArgumentValues[argument.id] = $0 }
                                    ),
                                    isFocused: viewModel.focusedArgumentIndex == index,
                                    onTab: { viewModel.focusNextArgument() },
                                    onSubmit: {
                                        if viewModel.canExecuteWithArguments {
                                            viewModel.executeWithInlineArguments()
                                        } else {
                                            viewModel.focusNextArgument()
                                        }
                                    }
                                )
                            }
                            
                            Spacer()
                        } else {
                            // Normal search mode
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.searchIconColor)
                            
                            ZStack(alignment: .leading) {
                                if viewModel.query.isEmpty {
                                    Text("Search for apps and commands...")
                                        .font(.system(size: 20, weight: .regular, design: .default))
                                        .foregroundColor(themeManager.currentTheme.searchFieldPlaceholderColor)
                                        .allowsHitTesting(false) // Let touches pass through to TextField
                                }
                                
                                TextField("", text: $viewModel.query)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 20, weight: .regular, design: .default))
                                    .foregroundColor(themeManager.currentTheme.searchFieldTextColor)
                                    .focused($isSearchFocused)
                                    .onSubmit {
                                        viewModel.executeSelectedResult()
                                    }
                            }
                            if !viewModel.query.isEmpty {
                                Button(action: { viewModel.query = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(themeManager.currentTheme.searchFieldTextColor.opacity(0.4))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .background(themeManager.currentTheme.searchFieldBackgroundColor)
                    
                    // Divider
                    Rectangle()
                        .fill(themeManager.currentTheme.separatorColor)
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
                    }
                    
                    // Persistent status bar at bottom (Raycast-style)
                    StatusBarComponent(
                        state: viewModel.statusBarState,
                        showActionButtons: !viewModel.results.isEmpty
                    )
                }
                .background(
                    themeManager.currentTheme.windowBackgroundGradient ?? AnyView(themeManager.currentTheme.windowBackgroundColor)
                )
                .clipShape(RoundedRectangle(cornerRadius: themeManager.currentTheme.windowCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.currentTheme.windowCornerRadius, style: .continuous)
                        .stroke(themeManager.currentTheme.windowBorderColor, lineWidth: 1)
                )
                
                // Push content to top
                Spacer(minLength: 0)
            }
            .frame(width: themeManager.currentTheme.windowWidth, height: 560) // Fixed height window - content aligns to top
            .onAppear {
                isSearchFocused = true
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FocusSearchBar"))) { _ in
                // Use async to ensure the view is fully visible before focusing
                DispatchQueue.main.async {
                    isSearchFocused = true
                }
            }
            .onExitCommand {
                // Escape acts as "go back" - exit current mode or close window
                if viewModel.isCollectingArguments {
                    viewModel.exitInlineArgumentMode()
                } else if viewModel.showingScriptOutput != nil {
                    viewModel.showingScriptOutput = nil
                } else if viewModel.showingScriptArgumentForm != nil {
                    viewModel.showingScriptArgumentForm = nil
                } else if viewModel.showingLinkForm != nil {
                    viewModel.showingLinkForm = nil
                } else {
                    // Only close window when at main search screen
                    viewModel.onHideWindow?()
                }
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
    @Published var showingScriptOutput: (ScriptRecord, ScriptMetadata, [Int: String])? = nil
    @Published var showingScriptArgumentForm: (ScriptRecord, ScriptMetadata)? = nil
    
    // Camera state
    @Published var showingCameraView: Bool = false
    let cameraService = CameraService()
    
    // Inline argument state (Raycast-style)
    @Published var inlineArgumentContext: InlineArgumentContext? = nil
    @Published var inlineArguments: [InlineArgument] = []
    @Published var inlineArgumentValues: [Int: String] = [:]
    @Published var focusedArgumentIndex: Int = 0
    
    /// Whether we're in inline argument collection mode
    var isCollectingArguments: Bool {
        inlineArgumentContext != nil && !inlineArguments.isEmpty
    }
    
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
        
        print("🔌 Registering CalculatorPlugin...")
        let calculatorPlugin = CalculatorPlugin()
        queryEngine.register(plugin: calculatorPlugin)
        print("✅ CalculatorPlugin registered")
        
        print("🔌 Registering SystemCommandsPlugin...")
        let systemCommands = SystemCommandsPlugin()
        queryEngine.register(plugin: systemCommands)
        print("✅ SystemCommandsPlugin registered")
        
        print("🔌 Registering DateCalculationsPlugin...")
        let datePlugin = DateCalculationsPlugin()
        queryEngine.register(plugin: datePlugin)
        print("✅ DateCalculationsPlugin registered")
        
        print("🔌 Registering FocusModePlugin...")
        let focusPlugin = FocusModePlugin()
        queryEngine.register(plugin: focusPlugin)
        print("✅ FocusModePlugin registered")
        
        print("🔌 Registering ClipboardHistoryPlugin...")
        let clipboardPlugin = ClipboardHistoryPlugin()
        queryEngine.register(plugin: clipboardPlugin)
        print("✅ ClipboardHistoryPlugin registered")
        
        print("🔌 Registering CameraPlugin...")
        let cameraPlugin = CameraPlugin()
        queryEngine.register(plugin: cameraPlugin)
        print("✅ CameraPlugin registered")
        
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
                self?.showingScriptOutput = (script, metadata, [:])
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
        
        // Listen for inline argument mode requests (Raycast-style)
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("EnterInlineArgumentMode"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let (script, metadata) = notification.object as? (ScriptRecord, ScriptMetadata) {
                self?.enterInlineArgumentMode(script: script, metadata: metadata)
            }
        }
        
        // Listen for inline argument mode for custom links
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("EnterInlineLinkArgumentMode"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let link = notification.object as? CustomLinkRecord {
                self?.enterInlineArgumentMode(link: link)
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
        
        // Listen for OpenCameraView notification (from CameraPlugin)
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenCameraView"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.showingCameraView = true
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
        print("📦 executeScript called with arguments: \(arguments)")
        Task {
            let fileURL = ScriptFileManager.shared.scriptURL(for: script.fileName)
            let executor = ScriptExecutor()
            print("⚙️ About to execute script at \(fileURL.path) with args: \(arguments)")
            
            do {
                let result = try await executor.execute(
                    fileURL: fileURL,
                    metadata: metadata,
                    arguments: arguments
                )
                print("✅ Script execution result: exitCode=\(result.exitCode), stdout=\(result.stdout.prefix(100))")
                
                await MainActor.run {
                    if result.isSuccess {
                        showingScriptOutput = (script, metadata, arguments)
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
    
    // MARK: - Inline Argument Collection
    
    /// Enter inline argument collection mode for a script
    func enterInlineArgumentMode(script: ScriptRecord, metadata: ScriptMetadata) {
        let args = metadata.arguments.map { InlineArgument(from: $0) }
        inlineArgumentContext = .script(script, metadata)
        inlineArguments = args
        inlineArgumentValues = [:]
        focusedArgumentIndex = 0
        
        // Initialize empty values for all arguments
        for arg in args {
            inlineArgumentValues[arg.id] = ""
        }
        print("📝 Entered inline argument mode for '\(script.title)' with \(args.count) arguments")
        
        // Reset focus after a brief delay to ensure view is rendered
        focusedArgumentIndex = -1  // Temporarily set to invalid
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            focusedArgumentIndex = 0  // Now trigger focus on first argument
        }
    }
    
    /// Enter inline argument collection mode for a custom link
    func enterInlineArgumentMode(link: CustomLinkRecord) {
        let args = link.parameters.enumerated().map { index, param in
            InlineArgument(position: index + 1, placeholder: param, isRequired: true, isPassword: false)
        }
        inlineArgumentContext = .customLink(link)
        inlineArguments = args
        inlineArgumentValues = [:]
        focusedArgumentIndex = 0
        
        // Initialize empty values for all arguments
        for arg in args {
            inlineArgumentValues[arg.id] = ""
        }
        print("📝 Entered inline argument mode for link '\(link.name)' with \(args.count) parameters")
        
        // Reset focus after a brief delay to ensure view is rendered
        focusedArgumentIndex = -1  // Temporarily set to invalid
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            focusedArgumentIndex = 0  // Now trigger focus on first argument
        }
    }
    
    /// Exit inline argument collection mode (cancel)
    func exitInlineArgumentMode() {
        inlineArgumentContext = nil
        inlineArguments = []
        inlineArgumentValues = [:]
        focusedArgumentIndex = 0
        
        // Focus back on the search bar after a brief delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            NotificationCenter.default.post(name: NSNotification.Name("FocusSearchBar"), object: nil)
        }
    }
    
    /// Move to next argument (Tab key)
    func focusNextArgument() {
        guard !inlineArguments.isEmpty else { return }
        if focusedArgumentIndex < inlineArguments.count - 1 {
            focusedArgumentIndex += 1
        } else {
            // Loop back to first
            focusedArgumentIndex = 0
        }
    }
    
    /// Move to previous argument (Shift+Tab)
    func focusPreviousArgument() {
        guard !inlineArguments.isEmpty else { return }
        if focusedArgumentIndex > 0 {
            focusedArgumentIndex -= 1
        } else {
            // Loop to last
            focusedArgumentIndex = inlineArguments.count - 1
        }
    }
    
    /// Check if all required arguments are filled
    var canExecuteWithArguments: Bool {
        for arg in inlineArguments where arg.isRequired {
            if inlineArgumentValues[arg.id]?.isEmpty ?? true {
                return false
            }
        }
        return true
    }
    
    /// Execute with collected arguments (Enter key when all required args filled)
    func executeWithInlineArguments() {
        guard let context = inlineArgumentContext, canExecuteWithArguments else { return }
        
        // Capture arguments before clearing inline state
        let capturedArguments = inlineArgumentValues
        print("🚀 executeWithInlineArguments: capturedArguments = \(capturedArguments)")
        
        switch context {
        case .script(let script, let metadata):
            print("🎯 Executing script '\(script.title)' with arguments: \(capturedArguments)")
            // Exit inline mode first (clears state)
            exitInlineArgumentMode()
            // Execute script with captured arguments
            executeScript(script: script, metadata: metadata, arguments: capturedArguments)
            
        case .customLink(let link):
            // Construct URL with captured arguments
            var values: [String: String] = [:]
            for (index, param) in link.parameters.enumerated() {
                values[param] = capturedArguments[index + 1] ?? ""
            }
            // Exit inline mode first
            exitInlineArgumentMode()
            if let url = link.constructURL(values: values) {
                NSWorkspace.shared.open(url)
            }
            onHideWindow?()
        }
    }
}
// Need to import Combine for debounce
import Combine

