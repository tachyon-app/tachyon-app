import SwiftUI
import AppKit

/// Main view for Clipboard History feature
/// Displays search bar, item list, preview pane, and actions bar
struct ClipboardHistoryView: View {
    @ObservedObject var manager: ClipboardHistoryManager
    
    @State private var selectedItem: ClipboardItem?
    @State private var selectedIndex: Int = 0
    @State private var showDeleteConfirmation = false
    @State private var itemToDelete: ClipboardItem?
    
    @FocusState private var isSearchFocused: Bool
    
    @State private var eventMonitor: Any?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // ... content ...
                // Search bar with type filter
                searchBar
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Main content area
                HStack(spacing: 0) {
                    // Items list (left side)
                    itemsList
                        .frame(width: 340)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Preview pane (right side)
                    ClipboardPreviewPane(item: selectedItem)
                }
                .frame(maxHeight: .infinity)
                
                // Actions bar
                ClipboardActionsBar(
                    selectedItem: selectedItem,
                    onCopy: copySelected,
                    onPaste: pasteSelected,
                    onPin: pinSelected,
                    onDelete: deleteSelected
                )
            }
            .blur(radius: showDeleteConfirmation ? 2 : 0) // Blur background when overlay is active
            
            // Custom Confirmation Overlay
            if showDeleteConfirmation {
                Color.black.opacity(0.4)
                    .onTapGesture {
                        showDeleteConfirmation = false
                    }
                
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.red)
                        
                        Text("Delete Item?")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("This item will be permanently removed from history.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: { showDeleteConfirmation = false }) {
                            Text("Cancel")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(width: 80, height: 32)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            if let item = itemToDelete {
                                manager.deleteItem(item)
                                selectFirstItem()
                            }
                            showDeleteConfirmation = false
                        }) {
                            Text("Delete")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(width: 80, height: 32)
                                .background(Color.red)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(24)
                .background(Color(hex: "#252525"))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .frame(width: 300)
            }
        }
        .frame(width: 680, height: 480)
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .onAppear {
            // Force focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFocused = true
            }
            selectFirstItem()
            
            // Setup local monitor to intercept keys even when TextField has focus
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                // CRITICAL: Only handle events for the Clipboard History window
                guard let eventWindow = event.window,
                      let historyWindow = ClipboardHistoryWindowController.shared.window,
                      eventWindow == historyWindow else {
                    return event
                }
                
                if handleKeyEvent(event) {
                    return nil // Handled, suppress event
                }
                return event // Pass through
            }
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
        .onExitCommand {
            if showDeleteConfirmation {
                showDeleteConfirmation = false
            } else {
                closeWindow()
            }
        }
    }
    
    // MARK: - Keyboard Handling
    
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let keyCode = event.keyCode
        let hasCommand = event.modifierFlags.contains(.command)
        
        // If confirmation is showing, hijack keyboard for it
        if showDeleteConfirmation {
            switch keyCode {
            case KeyCode.returnKey.rawValue:
                // Delete confirmed
                if let item = itemToDelete {
                    manager.deleteItem(item)
                    selectFirstItem()
                }
                showDeleteConfirmation = false
                return true
                
            case KeyCode.escape.rawValue:
                // Cancel
                showDeleteConfirmation = false
                return true
                
            default:
                return true // Swallow other keys
            }
        }
        
        switch keyCode {
        case KeyCode.returnKey.rawValue:
            if hasCommand {
                pasteSelected()
            } else {
                copySelected()
            }
            return true
            
        case KeyCode.delete.rawValue:
            if hasCommand {
                deleteSelected()
                return true
            }
            return false
            
        case KeyCode.upArrow.rawValue:
            moveSelection(by: -1)
            return true
            
        case KeyCode.downArrow.rawValue:
            moveSelection(by: 1)
            return true
            
        case KeyCode.p.rawValue:
            if hasCommand {
                pinSelected()
                return true
            }
            return false
            
        case KeyCode.escape.rawValue:
            closeWindow()
            return true
            
        default:
            return false
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(Color.white.opacity(0.4))
            
            // Search input
            TextField("Search clipboard history...", text: $manager.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundColor(Color.white)
                .focused($isSearchFocused)
            
            // Type filter dropdown
            Menu {
                ForEach(ContentTypeFilter.allCases) { filter in
                    Button(action: {
                        manager.typeFilter = filter
                    }) {
                        HStack {
                            Image(systemName: filter.icon)
                            Text(filter.rawValue)
                            if manager.typeFilter == filter {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: manager.typeFilter.icon)
                        .font(.system(size: 12))
                    Text(manager.typeFilter.rawValue)
                        .font(.system(size: 12))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                }
                .foregroundColor(Color.white.opacity(0.7))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.1))
                .cornerRadius(6)
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: "#1C1C1E"))
    }
    
    // MARK: - Items List
    
    private var itemsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(Array(manager.filteredItems.enumerated()), id: \.element.id) { index, item in
                        ClipboardItemRow(
                            item: item,
                            isSelected: selectedItem?.id == item.id,
                            onCopy: { manager.copyItem(item) },
                            onPaste: { manager.pasteItem(item); closeWindow() },
                            onPin: { manager.togglePin(item) },
                            onDelete: {
                                itemToDelete = item
                                showDeleteConfirmation = true
                            }
                        )
                        .id(item.id)
                        .onTapGesture {
                            selectedItem = item
                            selectedIndex = index
                        }
                        .onTapGesture(count: 2) {
                            manager.pasteItem(item)
                            closeWindow()
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
            }
            .onChange(of: selectedItem) { newSelection in
                if let id = newSelection?.id {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        .background(Color(hex: "#2C2C2E"))
    }
    
    // MARK: - Actions
    
    private func copySelected() {
        guard let item = selectedItem else { return }
        manager.copyItem(item)
        closeWindow()
    }
    
    private func pasteSelected() {
        guard let item = selectedItem else { return }
        manager.pasteItem(item)
        closeWindow()
    }
    
    private func pinSelected() {
        guard let item = selectedItem else { return }
        manager.togglePin(item)
    }
    
    private func deleteSelected() {
        guard let item = selectedItem else { return }
        itemToDelete = item
        showDeleteConfirmation = true
    }
    
    private func selectFirstItem() {
        selectedItem = manager.filteredItems.first
        selectedIndex = 0
    }
    
    private func moveSelection(by offset: Int) {
        let items = manager.filteredItems
        guard !items.isEmpty else { return }
        
        let newIndex = max(0, min(items.count - 1, selectedIndex + offset))
        selectedIndex = newIndex
        selectedItem = items[newIndex]
    }
    
    private func closeWindow() {
        // Post notification to close the clipboard history window
        NotificationCenter.default.post(name: .closeClipboardHistoryWindow, object: nil)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let closeClipboardHistoryWindow = Notification.Name("closeClipboardHistoryWindow")
}

// MARK: - Preview

#Preview {
    ClipboardHistoryView(manager: ClipboardHistoryManager.shared)
}
