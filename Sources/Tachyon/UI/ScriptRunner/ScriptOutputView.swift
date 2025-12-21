import SwiftUI

/// Terminal-like output view for fullOutput mode scripts
struct ScriptOutputView: View {
    let script: ScriptRecord
    let metadata: ScriptMetadata
    let onDismiss: () -> Void
    @StateObject private var viewModel: ScriptOutputViewModel
    
    init(script: ScriptRecord, metadata: ScriptMetadata, onDismiss: @escaping () -> Void = {}) {
        self.script = script
        self.metadata = metadata
        self.onDismiss = onDismiss
        self._viewModel = StateObject(wrappedValue: ScriptOutputViewModel(script: script, metadata: metadata))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Button(action: { onDismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                
                Text(script.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if viewModel.isRunning {
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(.circular)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(hex: "#1a1a1a"))
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
            
            // Output area
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.output)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("output")
                        
                        if let duration = viewModel.duration {
                            Text("Done in \(String(format: "%.2f", duration))s")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.green)
                                .padding(.top, 8)
                        }
                        
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                                .padding(.top, 8)
                        }
                    }
                    .padding(20)
                }
                .background(Color(hex: "#0d0d0d"))
                .onChange(of: viewModel.output) { _ in
                    withAnimation {
                        proxy.scrollTo("output", anchor: .bottom)
                    }
                }
            }
            
            // Footer
            HStack(spacing: 16) {
                Button(action: { viewModel.rerunScript() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                        Text("Rerun Script")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isRunning)
                
                Spacer()
                
                Text("⌘K")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(hex: "#3B86F7"))
                Text("Actions")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(hex: "#1a1a1a"))
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1),
                alignment: .top
            )
        }
        .frame(width: 680, height: 500)
        .background(Color(hex: "#0d0d0d"))
        .cornerRadius(12)
        .onAppear {
            viewModel.executeScript()
        }
    }
}

/// ViewModel for script output view
@MainActor
class ScriptOutputViewModel: ObservableObject {
    @Published var output: String = ""
    @Published var isRunning: Bool = false
    @Published var duration: TimeInterval?
    @Published var errorMessage: String?
    
    private let script: ScriptRecord
    private let metadata: ScriptMetadata
    private let executor = ScriptExecutor()
    
    init(script: ScriptRecord, metadata: ScriptMetadata) {
        self.script = script
        self.metadata = metadata
    }
    
    func executeScript(arguments: [Int: String] = [:]) {
        isRunning = true
        output = ""
        duration = nil
        errorMessage = nil
        
        let fileURL = ScriptFileManager.shared.scriptURL(for: script.fileName)
        
        Task {
            do {
                let result = try await executor.execute(
                    fileURL: fileURL,
                    metadata: metadata,
                    arguments: arguments,
                    onOutput: { [weak self] newOutput in
                        Task { @MainActor in
                            self?.output += newOutput
                        }
                    }
                )
                
                await MainActor.run {
                    self.isRunning = false
                    self.duration = result.duration
                    
                    if !result.isSuccess {
                        self.errorMessage = "Error: Script failed with code \(result.exitCode)"
                        if !result.stderr.isEmpty {
                            self.errorMessage! += "\n\(result.stderr)"
                        }
                    }
                    
                    // Update last executed
                    var updatedScript = self.script
                    updatedScript.lastExecuted = Date()
                    try? StorageManager.shared.saveScript(updatedScript)
                }
            } catch {
                await MainActor.run {
                    self.isRunning = false
                    self.errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func rerunScript() {
        executeScript()
    }
}
