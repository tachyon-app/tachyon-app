import SwiftUI

/// Main search bar view with results
struct SearchBarView: View {
    @ObservedObject var viewModel: SearchBarViewModel
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Search input
            HStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Search...", text: $viewModel.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 26, weight: .light))
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
                            .font(.title3)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
            .background(Color.white.opacity(0.05)) // Subtle input background
            
            Divider()
                .opacity(0.2)
            
            // Results list
            if !viewModel.results.isEmpty {
                VStack(spacing: 0) {
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
                    // Dynamic height handled by swiftUI, no fixed frame needed
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(width: 650) // Slightly wider for a grander feel
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 30, y: 15)
                // Add a subtle border for contrast
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
        .onAppear {
            isSearchFocused = true
        }
        .onExitCommand {
            viewModel.onHideWindow?()
        }
        .onHeightChange { height in
            // Notify window to resize
            // We need a way to pass this back to the window
            // For now, we'll use a callback in the ViewModel or a closure passed to the view
            viewModel.onHeightChanged?(height)
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
    
    private let queryEngine = QueryEngine()
    
    /// Callback to hide the window
    var onHideWindow: (() -> Void)?
    
    /// Callback when content height changes
    var onHeightChanged: ((CGFloat) -> Void)?
    
    init() {
        // Register plugins
        print("🔌 Registering AppLauncherPlugin...")
        let appLauncher = AppLauncherPlugin()
        queryEngine.register(plugin: appLauncher)
        print("✅ AppLauncherPlugin registered")
        
        let customLinks = CustomLinksPlugin()
        queryEngine.register(plugin: customLinks)
        print("✅ CustomLinksPlugin registered")
        
        let searchEngines = SearchEnginePlugin()
        queryEngine.register(plugin: searchEngines)
        print("✅ SearchEnginePlugin registered")
        
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
        } else {
            let searchResults = queryEngine.search(query: query)
            print("📊 Got \(searchResults.count) results")
            
            // Ensure UI update happens on main thread
            Task { @MainActor in
                self.results = searchResults
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
        // Hide window after execution
        onHideWindow?()
    }
}

// Need to import Combine for debounce
import Combine
