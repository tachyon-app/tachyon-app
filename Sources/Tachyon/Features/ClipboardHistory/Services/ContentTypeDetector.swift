import Foundation

/// Detects content types for clipboard items
/// Used to determine if text should be stored as plain text, code, URL, or markdown
public final class ContentTypeDetector {
    
    // MARK: - Code Language Patterns
    
    /// Patterns for detecting programming languages
    /// Order matters - more specific patterns should come first
    private static let languagePatterns: [(language: String, pattern: String)] = [
        // Swift - check for Swift-specific keywords
        ("swift", #"(import\s+(Foundation|SwiftUI|UIKit|AppKit)|func\s+\w+\(|guard\s+let|if\s+let|\.self|@State|@Published|@ObservedObject)"#),
        
        // TypeScript - check before JavaScript since TypeScript is more specific
        ("typescript", #"(interface\s+\w+\s*\{|type\s+\w+\s*=|:\s*(string|number|boolean|any)\b)"#),
        
        // Python - Python-specific patterns
        ("python", #"(def\s+\w+\s*\(|import\s+\w+|from\s+\w+\s+import|if\s+__name__\s*==|print\s*\()"#),
        
        // JavaScript - JavaScript-specific patterns
        ("javascript", #"(const\s+\w+\s*=|let\s+\w+\s*=|function\s+\w*\s*\(|=>\s*\{|console\.(log|error|warn)\(|require\s*\()"#),
        
        // SQL - SQL keywords (case insensitive)
        ("sql", #"(?i)(SELECT\s+.+\s+FROM|INSERT\s+INTO|UPDATE\s+\w+\s+SET|DELETE\s+FROM|CREATE\s+TABLE|DROP\s+TABLE)"#),
        
        // Bash/Shell
        ("bash", #"(#!/bin/(ba)?sh|echo\s+|export\s+\w+=|\$\{?\w+\}?)"#),
        
        // HTML
        ("html", #"(<html|<head|<body|<div|<span|<p>|</\w+>)"#),
        
        // CSS
        ("css", #"(\.\w+\s*\{|#\w+\s*\{|\w+:\s*[\w#]+;|@media\s)"#),
        
        // JSON (basic detection)
        ("json", #"^\s*[\{\[][\s\S]*[\}\]]\s*$"#),
    ]
    
    // MARK: - Public API
    
    /// Detect the programming language of a code snippet
    /// - Parameter text: The text to analyze
    /// - Returns: The detected language name, or nil if not code
    public static func detectCodeLanguage(_ text: String) -> String? {
        guard !text.isEmpty else { return nil }
        
        for (language, pattern) in languagePatterns {
            if let _ = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                return language
            }
        }
        
        return nil
    }
    
    /// Check if text is a URL
    /// - Parameter text: The text to check
    /// - Returns: True if the text is a valid URL
    public static func isURL(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Must start with http:// or https://
        let urlPattern = #"^https?://[^\s]+"#
        return trimmed.range(of: urlPattern, options: .regularExpression) != nil
    }
    
    /// Check if text contains markdown formatting
    /// - Parameter text: The text to check
    /// - Returns: True if markdown patterns are detected
    public static func isMarkdown(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        
        let markdownPatterns = [
            #"^#{1,6}\s+"#,           // Headers (# Heading)
            #"\*\*[^*]+\*\*"#,        // Bold (**text**)
            #"(?<!\*)\*[^*]+\*(?!\*)"#, // Italic (*text*) - not bold
            #"\[.+\]\(.+\)"#,          // Links [text](url)
            #"```"#,                   // Code blocks
            #"^[\-\*]\s+"#,           // Unordered list (- item, * item)
            #"^\d+\.\s+"#,            // Ordered list (1. item)
        ]
        
        for pattern in markdownPatterns {
            if let _ = text.range(of: pattern, options: .regularExpression) {
                return true
            }
        }
        
        return false
    }
    
    /// Infer the content type for a given text
    /// - Parameter text: The text to analyze
    /// - Returns: A tuple containing the inferred type and optional code language
    public static func inferType(for text: String) -> (type: ClipboardItem.ContentType, codeLanguage: String?) {
        // Check for URL (high priority, but simple URLs can also be text. Let's prioritize URL)
        // If it looks like a URL, it's a URL.
        if isURL(text) {
            return (.link, nil)
        }
        
        // Check for code
        if let language = detectCodeLanguage(text) {
            return (.code, language)
        }
        
        // Default to text
        return (.text, nil)
    }
}
