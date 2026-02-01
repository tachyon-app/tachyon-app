import SwiftUI
import Cocoa
import Combine

struct WindowSwitcherView: View {
    @ObservedObject var viewModel: WindowSwitcherViewModel
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(Array(viewModel.windows.enumerated()), id: \.element) { index, window in
                        WindowItemView(window: window, isSelected: index == viewModel.selectedIndex)
                            .id(index)
                    }
                }
                .padding(30)
            }
            .onChange(of: viewModel.selectedIndex) { newIndex in
                withAnimation {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
        .frame(height: 250)
        .background(VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(20)
        .padding(20) // Outer padding for shadow/glow
    }
}

struct WindowItemView: View {
    let window: WindowInfo
    let isSelected: Bool
    @State private var snapshot: NSImage?
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                // Snapshot
                if let snapshot = snapshot {
                    Image(nsImage: snapshot)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 150)
                        .cornerRadius(8)
                } else {
                    // Placeholder / Fallback
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 200, height: 150)
                            .cornerRadius(8)
                        
                        // If no snapshot, show generic icon or app icon centered
                        if let appIcon = window.appIcon {
                            Image(nsImage: appIcon)
                                .resizable()
                                .frame(width: 64, height: 64)
                                .opacity(0.5)
                        } else {
                            ProgressView()
                        }
                    }
                }
                
                // App Icon Badge
                if let appIcon = window.appIcon {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .offset(x: 8, y: 8)
                        .shadow(radius: 2)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 4)
                    .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            
            Text(window.appName)
                .font(.headline)
                .foregroundColor(.white)
            Text(window.title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: 200)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(), value: isSelected)
        .onAppear {
            loadSnapshot()
        }
    }
    
    func loadSnapshot() {
        WindowDiscoveryService.shared.generateSnapshot(for: window) { image in
            self.snapshot = image
        }
    }
}

// MARK: - Visual Effect Blur (NSVisualEffectView Wrapper)
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - WindowSwitcherPanel

public class WindowSwitcherPanel: NSPanel {
    private var cancellables = Set<AnyCancellable>()
    let viewModel: WindowSwitcherViewModel
    
    public init() {
        self.viewModel = WindowSwitcherViewModel()
        
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel], 
            backing: .buffered, 
            defer: false
        )
        
        self.level = .floating
        self.isFloatingPanel = true
        self.backgroundColor = .clear
        self.hasShadow = false // SwiftUI view will handle shadow/background
        self.isOpaque = false // Allow transparency
        
        let hostingView = NSHostingView(rootView: WindowSwitcherView(viewModel: viewModel))
        self.contentView = hostingView
        
        // Auto-center and size logic
        // For simplicity, fixed large size centered on screen
        self.setFrame(NSRect(x: 0, y: 0, width: 800, height: 400), display: true)
        self.center()
        
        bindViewModel()
    }
    
    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                print("🔍 WindowSwitcherPanel: State changed to \(state)")
                switch state {
                case .active, .navigating:
                    if !self.isVisible {
                        self.center() // Re-center just in case
                        self.orderFront(nil)
                    }
                case .idle, .committing:
                    if self.isVisible {
                        self.orderOut(nil)
                    }
                }
            }
            .store(in: &cancellables)
            
        // Also observe Window count to adjust frame? 
        // Optional polish.
    }
}
