import Foundation

/// High-performance fuzzy string matching algorithm
/// Optimized for sub-5ms query times on typical datasets
public final class FuzzyMatcher {
    
    public init() {}
    
    /// Calculate fuzzy match score between query and target
    /// - Parameters:
    ///   - query: Search query string
    ///   - target: Target string to match against
    /// - Returns: Score from 0.0 (no match) to 1.0 (perfect match)
    public func score(query: String, target: String) -> Double {
        // Edge cases
        guard !query.isEmpty, !target.isEmpty else { return 0.0 }
        guard query.count <= target.count else { return 0.0 }
        
        let queryLower = query.lowercased()
        let targetLower = target.lowercased()
        
        // Check for exact match (highest score)
        if queryLower == targetLower {
            return 1.0
        }
        
        // Check for prefix match (very high score)
        if targetLower.hasPrefix(queryLower) {
            return 0.95
        }
        
        // Try acronym matching
        if let acronymScore = scoreAcronym(query: queryLower, target: targetLower) {
            return acronymScore
        }
        
        // Try substring matching with gap penalties
        if let substringScore = scoreSubstring(query: queryLower, target: targetLower) {
            return substringScore
        }
        
        return 0.0
    }
    
    // MARK: - Private Helpers
    
    /// Score acronym matches (e.g., "gc" matches "Google Chrome")
    private func scoreAcronym(query: String, target: String) -> Double? {
        let words = target.split(separator: " ")
        guard words.count > 1 else { return nil }
        
        let acronym = words.compactMap { $0.first }.map { String($0) }.joined()
        
        if acronym.lowercased().hasPrefix(query) {
            // High score for acronym match, slightly lower than prefix
            return 0.85
        }
        
        return nil
    }
    
    /// Score substring matches with gap penalties
    private func scoreSubstring(query: String, target: String) -> Double? {
        let queryChars = Array(query)
        let targetChars = Array(target)
        
        var queryIndex = 0
        var targetIndex = 0
        var gaps = 0
        var matchPositions: [Int] = []
        
        // Find all query characters in target
        while queryIndex < queryChars.count && targetIndex < targetChars.count {
            if queryChars[queryIndex] == targetChars[targetIndex] {
                matchPositions.append(targetIndex)
                queryIndex += 1
                targetIndex += 1
            } else {
                gaps += 1
                targetIndex += 1
            }
        }
        
        // If we didn't match all query characters, no match
        guard queryIndex == queryChars.count else { return nil }
        
        // Calculate score based on:
        // 1. Match ratio (matched chars / target length)
        // 2. Gap penalty
        // 3. Position bonus (earlier matches score higher)
        
        let matchRatio = Double(queryChars.count) / Double(targetChars.count)
        let gapPenalty = Double(gaps) / Double(targetChars.count)
        let positionBonus = matchPositions.isEmpty ? 0.0 : (1.0 - Double(matchPositions[0]) / Double(targetChars.count)) * 0.2
        
        let baseScore = matchRatio - (gapPenalty * 0.3) + positionBonus
        
        // Clamp between 0.1 and 0.9 (substring matches shouldn't score as high as prefix/acronym)
        return max(0.1, min(0.9, baseScore))
    }
}
