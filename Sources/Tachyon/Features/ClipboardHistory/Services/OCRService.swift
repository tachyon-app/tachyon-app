import Cocoa
import Vision

/// Service for extracting text from images using Vision framework
public final class OCRService {
    
    /// Extract text from an NSImage using Vision framework
    /// - Parameter image: The source image
    /// - Returns: Recognized text as a single string, or nil if recognition fails/empty
    public static func extractText(from image: NSImage) async -> String? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil else {
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: text.isEmpty ? nil : text)
            }
            
            // Configure for accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("OCR Error: \(error)")
                continuation.resume(returning: nil)
            }
        }
    }
}
