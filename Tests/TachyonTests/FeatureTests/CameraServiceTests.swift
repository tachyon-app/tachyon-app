import XCTest
@testable import TachyonCore

/// Tests for CameraService
/// Note: Camera hardware tests require physical camera access and will be skipped on CI
@MainActor
final class CameraServiceTests: XCTestCase {
    
    var service: CameraService!
    
    override func setUp() async throws {
        try await super.setUp()
        service = CameraService()
    }
    
    override func tearDown() async throws {
        service.stopSession()
        service = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialStateNotRunning() {
        XCTAssertFalse(service.isRunning)
    }
    
    func testInitialStateMirroredByDefault() {
        XCTAssertTrue(service.isMirrored, "Camera should be mirrored by default")
    }
    
    func testInitialPermissionStatusNotDetermined() {
        XCTAssertEqual(service.permissionStatus, .notDetermined)
    }
    
    func testInitialNoCapturedPhoto() {
        XCTAssertNil(service.lastCapturedPhoto)
    }
    
    func testInitialCaptureSessionNil() {
        XCTAssertNil(service.captureSession)
    }
    
    // MARK: - Default Save Location Tests
    
    func testDefaultSaveLocationIsDesktop() {
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        XCTAssertEqual(service.defaultSaveLocation, desktopURL)
    }
    
    func testCanChangeDefaultSaveLocation() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        service.defaultSaveLocation = documentsURL
        XCTAssertEqual(service.defaultSaveLocation, documentsURL)
    }
    
    // MARK: - Mirror Toggle Tests
    
    func testToggleMirrorFromTrue() {
        XCTAssertTrue(service.isMirrored)
        service.toggleMirror()
        XCTAssertFalse(service.isMirrored)
    }
    
    func testToggleMirrorFromFalse() {
        service.isMirrored = false
        service.toggleMirror()
        XCTAssertTrue(service.isMirrored)
    }
    
    func testDoubleToggleMirrorRestoresOriginal() {
        let original = service.isMirrored
        service.toggleMirror()
        service.toggleMirror()
        XCTAssertEqual(service.isMirrored, original)
    }
    
    // MARK: - Stop Session Tests
    
    func testStopSessionWhenNotRunning() {
        // Should not crash when stopping non-running session
        XCTAssertFalse(service.isRunning)
        service.stopSession()
        XCTAssertFalse(service.isRunning)
    }
    
    // MARK: - Error Type Tests
    
    func testCameraErrorPermissionDeniedDescription() {
        let error = CameraError.permissionDenied
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("denied") ?? false)
    }
    
    func testCameraErrorNoCameraDescription() {
        let error = CameraError.noCameraAvailable
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("No camera") ?? false)
    }
    
    func testCameraErrorSessionNotRunningDescription() {
        let error = CameraError.sessionNotRunning
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("not running") ?? false)
    }
    
    func testCameraErrorPhotoConversionDescription() {
        let error = CameraError.photoConversionFailed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("convert") ?? false)
    }
}
