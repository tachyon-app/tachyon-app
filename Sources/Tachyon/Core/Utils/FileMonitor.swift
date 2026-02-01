import Foundation

/// Monitors directories for changes using DispatchSource
class FileMonitor {
    
    private var sources: [DispatchSourceFileSystemObject] = []
    private var debouncer: Task<Void, Never>?
    private let queue = DispatchQueue(label: "com.tachyon.filemonitor", attributes: .concurrent)
    
    /// Callback triggered when changes are detected (debounced)
    var onDidChange: (() -> Void)?
    
    init(paths: [String]) {
        for path in paths {
            startMonitoring(path: path)
        }
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring(path: String) {
        let url = URL(fileURLWithPath: path)
        
        // Ensure directory exists
        guard FileManager.default.fileExists(atPath: path) else { return }
        
        let descriptor = open(path, O_EVTONLY)
        guard descriptor != -1 else { return }
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .delete, .rename, .extend, .attrib, .link],
            queue: queue
        )
        
        source.setEventHandler { [weak self] in
            self?.handleEvent()
        }
        
        source.setCancelHandler {
            close(descriptor)
        }
        
        source.resume()
        sources.append(source)
    }
    
    func stopMonitoring() {
        for source in sources {
            source.cancel()
        }
        sources.removeAll()
    }
    
    private func handleEvent() {
        // Debounce events
        debouncer?.cancel()
        debouncer = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms debounce
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self.onDidChange?()
            }
        }
    }
}
