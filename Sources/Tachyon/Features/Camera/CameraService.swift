import Foundation
import AVFoundation
import AppKit

/// Service managing camera capture session and providing camera functionality
/// Designed with future video recording support in mind
@MainActor
public class CameraService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var isRunning: Bool = false
    @Published public var isMirrored: Bool = true
    @Published public private(set) var availableCameras: [AVCaptureDevice] = []
    @Published public private(set) var currentCamera: AVCaptureDevice?
    @Published public private(set) var permissionStatus: PermissionStatus = .notDetermined
    @Published public private(set) var lastCapturedPhoto: NSImage?
    
    /// Default save location for photos (user-configurable, persisted)
    @Published public var defaultSaveLocation: URL {
        didSet {
            // Save to UserDefaults when changed
            UserDefaults.standard.set(defaultSaveLocation.path, forKey: "CameraDefaultSaveLocation")
        }
    }
    
    // MARK: - Permission Status
    
    public enum PermissionStatus {
        case notDetermined
        case authorized
        case denied
        case restricted
    }
    
    // MARK: - Session Properties (accessible for preview)
    
    public private(set) var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var photoOutput: AVCapturePhotoOutput?
    private var currentInput: AVCaptureDeviceInput?
    
    /// The preview layer for displaying camera feed
    public private(set) var previewLayer: AVCaptureVideoPreviewLayer?
    
    // Photo capture continuation for async/await
    private var photoCaptureCompletion: CheckedContinuation<NSImage, Error>?
    
    // MARK: - Initialization
    
    public override init() {
        // Load saved location or default to Desktop
        if let savedPath = UserDefaults.standard.string(forKey: "CameraDefaultSaveLocation") {
            self.defaultSaveLocation = URL(fileURLWithPath: savedPath)
        } else {
            self.defaultSaveLocation = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        }
        super.init()
        updateAvailableCameras()
        
        // Listen for save location changes from settings
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CameraSaveLocationChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let url = notification.object as? URL {
                self?.defaultSaveLocation = url
            }
        }
    }
    
    // MARK: - Permission Handling
    
    /// Check and request camera permission
    public func requestPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            permissionStatus = .authorized
            return true
            
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            permissionStatus = granted ? .authorized : .denied
            return granted
            
        case .denied:
            permissionStatus = .denied
            return false
            
        case .restricted:
            permissionStatus = .restricted
            return false
            
        @unknown default:
            permissionStatus = .denied
            return false
        }
    }
    
    // MARK: - Session Management
    
    /// Start the camera capture session
    public func startSession() async throws {
        guard !isRunning else { return }
        
        // Request permission first
        guard await requestPermission() else {
            throw CameraError.permissionDenied
        }
        
        // Update available cameras
        updateAvailableCameras()
        
        guard let camera = availableCameras.first else {
            throw CameraError.noCameraAvailable
        }
        
        // Create session
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        // Add input
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
                currentInput = input
                currentCamera = camera
            } else {
                throw CameraError.cannotAddInput
            }
        } catch {
            throw CameraError.inputCreationFailed(error)
        }
        
        // Add photo output
        let photoOutput = AVCapturePhotoOutput()
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            self.photoOutput = photoOutput
        } else {
            throw CameraError.cannotAddOutput
        }
        
        // Create preview layer
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        self.previewLayer = preview
        
        // Apply mirroring
        updateMirrorState()
        
        // Start session on background thread
        self.captureSession = session
        
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
                DispatchQueue.main.async {
                    self.isRunning = true
                    continuation.resume()
                }
            }
        }
    }
    
    /// Stop the camera capture session - MUST be called when closing camera view
    public func stopSession() {
        guard isRunning, let session = captureSession else { return }
        
        // Stop on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            session.stopRunning()
            
            DispatchQueue.main.async {
                // Clean up
                self.captureSession = nil
                self.previewLayer = nil
                self.currentInput = nil
                self.photoOutput = nil
                self.isRunning = false
                self.lastCapturedPhoto = nil
            }
        }
    }
    
    // MARK: - Camera Switching
    
    /// Switch to a different camera
    public func switchCamera(to device: AVCaptureDevice) {
        guard let session = captureSession, isRunning else { return }
        
        session.beginConfiguration()
        
        // Remove current input
        if let currentInput = currentInput {
            session.removeInput(currentInput)
        }
        
        // Add new input
        do {
            let newInput = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                currentInput = newInput
                currentCamera = device
            }
        } catch {
            // Restore previous input if available
            if let currentInput = currentInput, session.canAddInput(currentInput) {
                session.addInput(currentInput)
            }
        }
        
        session.commitConfiguration()
        updateMirrorState()
    }
    
    /// Cycle to the next available camera
    public func cycleCamera() {
        guard availableCameras.count > 1, let current = currentCamera else { return }
        
        if let index = availableCameras.firstIndex(where: { $0.uniqueID == current.uniqueID }) {
            let nextIndex = (index + 1) % availableCameras.count
            switchCamera(to: availableCameras[nextIndex])
        } else if let first = availableCameras.first {
            switchCamera(to: first)
        }
    }
    
    // MARK: - Mirroring
    
    /// Toggle video mirroring
    public func toggleMirror() {
        isMirrored.toggle()
        updateMirrorState()
    }
    
    private func updateMirrorState() {
        guard let connection = previewLayer?.connection, connection.isVideoMirroringSupported else { return }
        connection.automaticallyAdjustsVideoMirroring = false
        connection.isVideoMirrored = isMirrored
    }
    
    // MARK: - Photo Capture
    
    /// Capture a photo from the current camera feed
    public func capturePhoto() async throws -> NSImage {
        guard isRunning, let photoOutput = photoOutput else {
            throw CameraError.sessionNotRunning
        }
        
        let settings = AVCapturePhotoSettings()
        
        return try await withCheckedThrowingContinuation { continuation in
            self.photoCaptureCompletion = continuation
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    /// Save photo to the specified location (or default location)
    public func savePhoto(_ image: NSImage, to url: URL? = nil) throws -> URL {
        let saveURL = url ?? defaultSaveLocation.appendingPathComponent(generatePhotoFilename())
        
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw CameraError.photoConversionFailed
        }
        
        try pngData.write(to: saveURL)
        return saveURL
    }
    
    /// Copy photo to clipboard
    public func copyPhotoToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
    
    private func generatePhotoFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return "Tachyon_Photo_\(formatter.string(from: Date())).png"
    }
    
    // MARK: - Camera Enumeration
    
    private func updateAvailableCameras() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        )
        availableCameras = discoverySession.devices
    }
    
    // MARK: - Future Video Recording Support (Stubs)
    
    // public func startRecording() async throws {
    //     // TODO: Implement video recording
    // }
    
    // public func stopRecording() async throws -> URL {
    //     // TODO: Implement video recording
    // }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    
    nonisolated public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        Task { @MainActor in
            if let error = error {
                photoCaptureCompletion?.resume(throwing: error)
                photoCaptureCompletion = nil
                return
            }
            
            guard let data = photo.fileDataRepresentation(),
                  let image = NSImage(data: data) else {
                photoCaptureCompletion?.resume(throwing: CameraError.photoCaptureFailed)
                photoCaptureCompletion = nil
                return
            }
            
            // Apply mirroring to captured photo if enabled
            let finalImage: NSImage
            if isMirrored {
                finalImage = image.mirrored() ?? image
            } else {
                finalImage = image
            }
            
            lastCapturedPhoto = finalImage
            photoCaptureCompletion?.resume(returning: finalImage)
            photoCaptureCompletion = nil
        }
    }
}

// MARK: - Camera Errors

public enum CameraError: LocalizedError {
    case permissionDenied
    case noCameraAvailable
    case cannotAddInput
    case cannotAddOutput
    case inputCreationFailed(Error)
    case sessionNotRunning
    case photoCaptureFailed
    case photoConversionFailed
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera access was denied. Please enable camera access in System Settings."
        case .noCameraAvailable:
            return "No camera found on this device."
        case .cannotAddInput:
            return "Could not add camera input to session."
        case .cannotAddOutput:
            return "Could not add photo output to session."
        case .inputCreationFailed(let error):
            return "Failed to create camera input: \(error.localizedDescription)"
        case .sessionNotRunning:
            return "Camera session is not running."
        case .photoCaptureFailed:
            return "Failed to capture photo."
        case .photoConversionFailed:
            return "Failed to convert photo for saving."
        }
    }
}

// MARK: - NSImage Extension for Mirroring

extension NSImage {
    func mirrored() -> NSImage? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let flipped = NSImage(size: self.size)
        flipped.lockFocus()
        
        let transform = NSAffineTransform()
        transform.translateX(by: self.size.width, yBy: 0)
        transform.scaleX(by: -1, yBy: 1)
        transform.concat()
        
        let rect = NSRect(origin: .zero, size: self.size)
        let nsImage = NSImage(cgImage: cgImage, size: self.size)
        nsImage.draw(in: rect)
        
        flipped.unlockFocus()
        return flipped
    }
}
