import Foundation
import ServiceManagement

// MARK: - Login Item Service Protocol

/// Protocol abstracting login item management for testability
public protocol LoginItemServiceProtocol {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

/// Production implementation wrapping SMAppService
public struct SystemLoginItemService: LoginItemServiceProtocol {
    private let service = SMAppService.mainApp
    
    public init() {}
    
    public var status: SMAppService.Status {
        service.status
    }
    
    public func register() throws {
        try service.register()
    }
    
    public func unregister() throws {
        try service.unregister()
    }
}

// MARK: - Launch at Login Service

/// Service to manage the "Launch at Login" functionality using SMAppService (macOS 13+)
@MainActor
public final class LaunchAtLoginService: ObservableObject {
    
    public static let shared = LaunchAtLoginService()
    
    /// Published property to track whether launch at login is enabled
    @Published public var isEnabled: Bool {
        didSet {
            if oldValue != isEnabled {
                updateLaunchAtLoginStatus()
            }
        }
    }
    
    /// The last error that occurred during registration/unregistration
    @Published public private(set) var lastError: Error?
    
    private let loginItemService: LoginItemServiceProtocol
    
    /// Private initializer for the shared singleton
    private init() {
        self.loginItemService = SystemLoginItemService()
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }
    
    /// Initializer for dependency injection (used in tests)
    public init(loginItemService: LoginItemServiceProtocol, initialStatus: Bool = false) {
        self.loginItemService = loginItemService
        self.isEnabled = initialStatus
    }
    
    /// Updates the launch at login status based on the current `isEnabled` value
    private func updateLaunchAtLoginStatus() {
        lastError = nil
        do {
            if isEnabled {
                try loginItemService.register()
            } else {
                try loginItemService.unregister()
            }
        } catch {
            lastError = error
            print("Failed to \(isEnabled ? "enable" : "disable") launch at login: \(error.localizedDescription)")
            // Revert the published value if the operation failed
            Task { @MainActor in
                self.isEnabled = self.loginItemService.status == .enabled
            }
        }
    }
    
    /// Checks and returns the current launch at login status
    public func refreshStatus() {
        isEnabled = loginItemService.status == .enabled
    }
    
    /// Returns a human-readable status description
    public var statusDescription: String {
        switch loginItemService.status {
        case .notRegistered:
            return "Not registered"
        case .enabled:
            return "Enabled"
        case .requiresApproval:
            return "Requires approval in System Settings"
        case .notFound:
            return "App not found"
        @unknown default:
            return "Unknown"
        }
    }
}
