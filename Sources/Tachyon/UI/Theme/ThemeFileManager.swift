import Foundation
import AppKit

/// Manages custom theme files in ~/.tachyon/themes/
class ThemeFileManager {
    static let shared = ThemeFileManager()
    
    enum ThemeFileError: Error {
        case directoryCreationFailed(Error)
        case readFailed(Error)
        case decodingFailed(Error)
    }
    
    /// Directory where themes are stored
    let themesDirectory: URL
    
    private init() {
        let homeUrl = FileManager.default.homeDirectoryForCurrentUser
        self.themesDirectory = homeUrl.appendingPathComponent(".tachyon/themes")
        
        // Create directory if it doesn't exist
        try? createThemesDirectory()
    }
    
    /// Create the themes directory if it doesn't exist
    private func createThemesDirectory() throws {
        do {
            try FileManager.default.createDirectory(
                at: themesDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            throw ThemeFileError.directoryCreationFailed(error)
        }
    }
    
    /// List all available theme files
    func listThemeFiles() -> [URL] {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: themesDirectory,
                includingPropertiesForKeys: nil
            )
            return fileURLs.filter { $0.pathExtension == "json" }
        } catch {
            print("❌ Failed to list themes: \(error)")
            return []
        }
    }
    
    /// Load a theme from a file
    func loadTheme(from url: URL) throws -> CodableTheme {
        do {
            let data = try Data(contentsOf: url)
            let theme = try JSONDecoder().decode(CodableTheme.self, from: data)
            return theme
        } catch let error as DecodingError {
            print("❌ Decoding error for \(url.lastPathComponent): \(error)")
            throw ThemeFileError.decodingFailed(error)
        } catch {
            print("❌ Read error for \(url.lastPathComponent): \(error)")
            throw ThemeFileError.readFailed(error)
        }
    }
    
    /// Open the themes folder in Finder
    func openThemesFolder() {
        NSWorkspace.shared.open(themesDirectory)
    }
}
