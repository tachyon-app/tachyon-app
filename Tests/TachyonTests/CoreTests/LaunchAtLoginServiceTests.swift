import XCTest
import ServiceManagement
@testable import TachyonCore

/// Mock implementation of LoginItemServiceProtocol for testing
final class MockLoginItemService: LoginItemServiceProtocol {
    var mockStatus: SMAppService.Status = .notRegistered
    var registerCallCount = 0
    var unregisterCallCount = 0
    var shouldThrowOnRegister = false
    var shouldThrowOnUnregister = false
    var registerError: Error = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock register error"])
    var unregisterError: Error = NSError(domain: "TestError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Mock unregister error"])
    
    var status: SMAppService.Status {
        mockStatus
    }
    
    func register() throws {
        registerCallCount += 1
        if shouldThrowOnRegister {
            throw registerError
        }
        mockStatus = .enabled
    }
    
    func unregister() throws {
        unregisterCallCount += 1
        if shouldThrowOnUnregister {
            throw unregisterError
        }
        mockStatus = .notRegistered
    }
    
    func reset() {
        mockStatus = .notRegistered
        registerCallCount = 0
        unregisterCallCount = 0
        shouldThrowOnRegister = false
        shouldThrowOnUnregister = false
    }
}

/// Tests for LaunchAtLoginService
@MainActor
final class LaunchAtLoginServiceTests: XCTestCase {
    
    var mockService: MockLoginItemService!
    var sut: LaunchAtLoginService!
    
    override func setUp() {
        super.setUp()
        mockService = MockLoginItemService()
        sut = LaunchAtLoginService(loginItemService: mockService, initialStatus: false)
    }
    
    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitializationWithDisabledStatus() {
        let service = LaunchAtLoginService(loginItemService: mockService, initialStatus: false)
        XCTAssertFalse(service.isEnabled, "Service should initialize with disabled status")
    }
    
    func testInitializationWithEnabledStatus() {
        let service = LaunchAtLoginService(loginItemService: mockService, initialStatus: true)
        // Note: The didSet triggers when initialStatus is true, so register is called
        XCTAssertTrue(service.isEnabled, "Service should initialize with enabled status")
    }
    
    // MARK: - Enable/Disable Tests
    
    func testEnablingLaunchAtLogin() {
        sut.isEnabled = true
        
        XCTAssertEqual(mockService.registerCallCount, 1, "Register should be called once")
        XCTAssertEqual(mockService.unregisterCallCount, 0, "Unregister should not be called")
        XCTAssertEqual(mockService.mockStatus, .enabled, "Mock status should be enabled")
    }
    
    func testDisablingLaunchAtLogin() {
        // First enable
        sut.isEnabled = true
        mockService.registerCallCount = 0
        
        // Then disable
        sut.isEnabled = false
        
        XCTAssertEqual(mockService.unregisterCallCount, 1, "Unregister should be called once")
        XCTAssertEqual(mockService.mockStatus, .notRegistered, "Mock status should be notRegistered")
    }
    
    func testSettingSameValueDoesNotCallService() {
        // Value starts as false, setting to false should not trigger service call
        sut.isEnabled = false
        
        XCTAssertEqual(mockService.registerCallCount, 0, "Register should not be called for same value")
        XCTAssertEqual(mockService.unregisterCallCount, 0, "Unregister should not be called for same value")
    }
    
    func testMultipleToggles() {
        sut.isEnabled = true
        sut.isEnabled = false
        sut.isEnabled = true
        
        XCTAssertEqual(mockService.registerCallCount, 2, "Register should be called twice")
        XCTAssertEqual(mockService.unregisterCallCount, 1, "Unregister should be called once")
    }
    
    // MARK: - Error Handling Tests
    
    func testRegisterErrorSetsLastError() async {
        mockService.shouldThrowOnRegister = true
        
        sut.isEnabled = true
        
        XCTAssertNotNil(sut.lastError, "Last error should be set on registration failure")
    }
    
    func testUnregisterErrorSetsLastError() async {
        // First enable successfully
        sut.isEnabled = true
        XCTAssertNil(sut.lastError, "No error after successful registration")
        
        // Then try to disable with error
        mockService.shouldThrowOnUnregister = true
        sut.isEnabled = false
        
        XCTAssertNotNil(sut.lastError, "Last error should be set on unregistration failure")
    }
    
    func testSuccessfulOperationClearsLastError() async {
        // First cause an error
        mockService.shouldThrowOnRegister = true
        sut.isEnabled = true
        XCTAssertNotNil(sut.lastError, "Error should be set")
        
        // Reset mock and try again
        mockService.shouldThrowOnRegister = false
        mockService.mockStatus = .notRegistered
        sut.isEnabled = false
        sut.isEnabled = true
        
        XCTAssertNil(sut.lastError, "Error should be cleared on successful operation")
    }
    
    // MARK: - Refresh Status Tests
    
    func testRefreshStatusUpdatesIsEnabled() {
        mockService.mockStatus = .enabled
        
        sut.refreshStatus()
        
        XCTAssertTrue(sut.isEnabled, "isEnabled should reflect the service status after refresh")
    }
    
    func testRefreshStatusWithNotRegisteredStatus() {
        // Start enabled
        sut.isEnabled = true
        XCTAssertTrue(sut.isEnabled)
        
        // Externally change status
        mockService.mockStatus = .notRegistered
        
        sut.refreshStatus()
        
        XCTAssertFalse(sut.isEnabled, "isEnabled should be false when status is notRegistered")
    }
    
    // MARK: - Status Description Tests
    
    func testStatusDescriptionNotRegistered() {
        mockService.mockStatus = .notRegistered
        XCTAssertEqual(sut.statusDescription, "Not registered")
    }
    
    func testStatusDescriptionEnabled() {
        mockService.mockStatus = .enabled
        XCTAssertEqual(sut.statusDescription, "Enabled")
    }
    
    func testStatusDescriptionRequiresApproval() {
        mockService.mockStatus = .requiresApproval
        XCTAssertEqual(sut.statusDescription, "Requires approval in System Settings")
    }
    
    func testStatusDescriptionNotFound() {
        mockService.mockStatus = .notFound
        XCTAssertEqual(sut.statusDescription, "App not found")
    }
    
    // MARK: - Integration Tests
    
    func testFullEnableDisableCycle() async {
        // Enable
        sut.isEnabled = true
        XCTAssertTrue(sut.isEnabled)
        XCTAssertEqual(mockService.mockStatus, .enabled)
        XCTAssertNil(sut.lastError)
        
        // Disable
        sut.isEnabled = false
        XCTAssertFalse(sut.isEnabled)
        XCTAssertEqual(mockService.mockStatus, .notRegistered)
        XCTAssertNil(sut.lastError)
    }
}

// MARK: - SystemLoginItemService Tests

/// Tests to verify SystemLoginItemService initialization (actual SMAppService calls are not tested)
final class SystemLoginItemServiceTests: XCTestCase {
    
    func testSystemLoginItemServiceCanBeInitialized() {
        // This just verifies the type can be instantiated
        let service = SystemLoginItemService()
        XCTAssertNotNil(service, "SystemLoginItemService should be initializable")
    }
}
