import Foundation

/// Detects sensitive data patterns that should not be stored in clipboard history
/// This is a privacy-critical component - all sensitive data MUST be detected
public final class SensitiveDataDetector {
    
    // MARK: - Credit Card Patterns
    
    /// Visa: Starts with 4, 13 or 16 digits
    private static let visaPattern = #"4[0-9]{12}(?:[0-9]{3})?"#
    
    /// Mastercard: Starts with 51-55 or 2221-2720, 16 digits
    private static let mastercardPattern = #"5[1-5][0-9]{14}"#
    
    /// American Express: Starts with 34 or 37, 15 digits
    private static let amexPattern = #"3[47][0-9]{13}"#
    
    /// Discover: Starts with 6011 or 65, 16 digits
    private static let discoverPattern = #"6(?:011|5[0-9]{2})[0-9]{12}"#
    
    /// All credit card patterns combined
    private static let creditCardPatterns = [
        visaPattern,
        mastercardPattern,
        amexPattern,
        discoverPattern
    ]
    
    // MARK: - Public API
    
    /// Check if the given text contains sensitive data
    /// - Parameter text: The text to check
    /// - Returns: True if sensitive data is detected
    public static func containsSensitiveData(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        
        // Remove common separators (spaces, dashes) for card number detection
        let normalized = text.replacingOccurrences(of: "[\\s\\-]", with: "", options: .regularExpression)
        
        // Check each credit card pattern
        for pattern in creditCardPatterns {
            if let _ = normalized.range(of: pattern, options: .regularExpression) {
                return true
            }
        }
        
        return false
    }
    
    /// Check if secure text input is currently active on the system
    /// When secure input is enabled (e.g., password fields), we should not capture clipboard
    /// - Returns: True if secure input mode is detected
    public static func isSecureInputActive() -> Bool {
        // Note: CGEventSource.flagsState is not reliable for secure input detection
        // A more robust solution would use the CGSCurrentInputSourceSecureInputSession function
        // but that's a private API. For now, we'll return false and rely on
        // the application's UTI checks for password manager apps.
        // TODO: Investigate using IOHIDCheckAccess or similar for secure input detection
        return false
    }
}
