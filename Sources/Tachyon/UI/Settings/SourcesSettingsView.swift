import SwiftUI

/// Unified view for managing all sources (Custom Links, Search Engines, Apps)
struct SourcesSettingsView: View {
    @StateObject private var customLinksViewModel = CustomLinksSettingsViewModel()
    @StateObject private var searchEnginesViewModel = SearchEnginesSettingsViewModel()
    
    @State private var searchText = ""
    @State private var selectedFilter: SourceFilter = .all
    @State private var showAddPopover = false
    @State private var showAddCustomLink = false
    @State private var showAddSearchEngine = false
    @State private var isAddButtonHovered = false
    @State private var editingCustomLink: CustomLinkRecord? = nil
    @State private var editingSearchEngine: SearchEngineRecord? = nil
    
    enum SourceFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case customLinks = "Custom Links"
        case searchEngines = "Search Engines"
        case apps = "Applications"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .customLinks: return "link"
            case .searchEngines: return "magnifyingglass"
            case .apps: return "app.badge"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and filter bar
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    // Search field
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.white.opacity(0.35))
                            .font(.system(size: 13, weight: .medium))
                        
                        TextField("Search sources...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(7)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                    .frame(maxWidth: 320)
                    
                    Spacer()
                    
                    // Add button with popover (Raycast style)
                    Button(action: {
                        showAddPopover.toggle()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .semibold))
                            
                            if isAddButtonHovered {
                                Text("Add")
                                    .font(.system(size: 13, weight: .medium))
                                    .transition(.opacity)
                                
                                Text("⌘N")
                                    .font(.system(size: 11, weight: .medium))
                                    .opacity(0.65)
                                    .transition(.opacity)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, isAddButtonHovered ? 13 : 9)
                        .padding(.vertical, 7)
                        .background(Color(hex: "#3B86F7"))
                        .cornerRadius(6)
                        .animation(.easeOut(duration: 0.15), value: isAddButtonHovered)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        isAddButtonHovered = hovering
                    }
                    .popover(isPresented: $showAddPopover, arrowEdge: .bottom) {
                        AddSourcePopover(
                            onAddCustomLink: {
                                showAddPopover = false
                                showAddCustomLink = true
                            },
                            onAddSearchEngine: {
                                showAddPopover = false
                                showAddSearchEngine = true
                            }
                        )
                    }
                }
                
                // Filter pills
                HStack(spacing: 7) {
                    ForEach(SourceFilter.allCases) { filter in
                        FilterPill(
                            title: filter.rawValue,
                            icon: filter.icon,
                            isSelected: selectedFilter == filter
                        ) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)
            
            Divider()
                .background(Color.white.opacity(0.06))
            
            // Sources list
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Custom Links
                    if shouldShowCustomLinks {
                        ForEach(filteredCustomLinks) { link in
                            SourceListItem(
                                icon: "link",
                                iconColor: Color(hex: "#3B86F7"),
                                title: link.name,
                                subtitle: link.urlTemplate,
                                type: "Custom Link"
                            ) {
                                editingCustomLink = link
                            } onDelete: {
                                customLinksViewModel.deleteLink(id: link.id)
                            }
                        }
                    }
                    
                    // Search Engines
                    if shouldShowSearchEngines {
                        ForEach(filteredSearchEngines) { engine in
                            SourceListItem(
                                icon: "magnifyingglass",
                                iconColor: Color(hex: "#FF6B35"),
                                title: engine.name,
                                subtitle: engine.urlTemplate,
                                type: "Search Engine"
                            ) {
                                editingSearchEngine = engine
                            } onDelete: {
                                searchEnginesViewModel.deleteEngine(id: engine.id)
                            }
                        }
                    }
                    
                    // Apps (placeholder for now)
                    if shouldShowApps {
                        SourceListItem(
                            icon: "app.badge",
                            iconColor: Color(hex: "#4CAF50"),
                            title: "Applications",
                            subtitle: "Automatically indexed from /Applications",
                            type: "Application Group"
                        ) {
                            // No edit action for apps
                        } onDelete: {
                            // No delete action for apps
                        }
                    }
                }
                .padding(.top, 8)
            }
            .scrollContentBackground(.hidden)
        }
        .onAppear {
            customLinksViewModel.loadLinks()
            searchEnginesViewModel.loadEngines()
        }
        .background(
            // Invisible button for keyboard shortcut
            Button("") {
                showAddPopover.toggle()
            }
            .keyboardShortcut("n", modifiers: .command)
            .hidden()
        )
        .sheet(isPresented: $showAddCustomLink) {
            AddEditCustomLinkSheet(
                viewModel: customLinksViewModel,
                isPresented: $showAddCustomLink,
                linkToEdit: nil
            )
        }
        .sheet(item: $editingCustomLink) { link in
            AddEditCustomLinkSheet(
                viewModel: customLinksViewModel,
                isPresented: Binding(
                    get: { editingCustomLink != nil },
                    set: { if !$0 { editingCustomLink = nil } }
                ),
                linkToEdit: link
            )
        }
        .sheet(isPresented: $showAddSearchEngine) {
            AddEditSearchEngineSheet(
                viewModel: searchEnginesViewModel,
                isPresented: $showAddSearchEngine,
                engineToEdit: nil
            )
        }
        .sheet(item: $editingSearchEngine) { engine in
            AddEditSearchEngineSheet(
                viewModel: searchEnginesViewModel,
                isPresented: Binding(
                    get: { editingSearchEngine != nil },
                    set: { if !$0 { editingSearchEngine = nil } }
                ),
                engineToEdit: engine
            )
        }
    }
    
    // MARK: - Filtering Logic
    
    private var shouldShowCustomLinks: Bool {
        selectedFilter == .all || selectedFilter == .customLinks
    }
    
    private var shouldShowSearchEngines: Bool {
        selectedFilter == .all || selectedFilter == .searchEngines
    }
    
    private var shouldShowApps: Bool {
        selectedFilter == .all || selectedFilter == .apps
    }
    
    private var filteredCustomLinks: [CustomLinkRecord] {
        let links = customLinksViewModel.links
        if searchText.isEmpty {
            return links
        }
        return links.filter { link in
            link.name.localizedCaseInsensitiveContains(searchText) ||
            link.urlTemplate.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredSearchEngines: [SearchEngineRecord] {
        let engines = searchEnginesViewModel.engines
        if searchText.isEmpty {
            return engines
        }
        return engines.filter { engine in
            engine.name.localizedCaseInsensitiveContains(searchText) ||
            engine.urlTemplate.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Filter Pill (Raycast style)

struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Color.white.opacity(0.6))
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: "#3B86F7") : (isHovered ? Color.white.opacity(0.06) : Color.white.opacity(0.03)))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Source List Item (Raycast style)

struct SourceListItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let type: String
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon in rounded square (36x36 for better proportion)
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.5))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Type badge
            Text(type)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.white.opacity(0.45))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.05))
                .cornerRadius(5)
            
            // Actions (show on hover)
            if isHovered && type != "Application Group" {
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.6))
                            .frame(width: 26, height: 26)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red.opacity(0.8))
                            .frame(width: 26, height: 26)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(isHovered ? Color.white.opacity(0.04) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Add Source Popover (Raycast style)

struct AddSourcePopover: View {
    let onAddCustomLink: () -> Void
    let onAddSearchEngine: () -> Void
    
    @State private var hoveredOption: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Link option
            Button(action: onAddCustomLink) {
                HStack(spacing: 11) {
                    Image(systemName: "link")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "#3B86F7"))
                        .frame(width: 26, height: 26)
                    
                    Text("Custom Link")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(hoveredOption == "link" ? Color.white.opacity(0.06) : Color.clear)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                hoveredOption = hovering ? "link" : nil
            }
            
            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.horizontal, 12)
            
            // Search Engine option
            Button(action: onAddSearchEngine) {
                HStack(spacing: 11) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "#FF6B35"))
                        .frame(width: 26, height: 26)
                    
                    Text("Search Engine")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(hoveredOption == "search" ? Color.white.opacity(0.06) : Color.clear)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                hoveredOption = hovering ? "search" : nil
            }
        }
        .frame(width: 200)
        .background(Color(hex: "#252525"))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
    }
}
