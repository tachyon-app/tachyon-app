import XCTest
@testable import TachyonCore

/// Tests for the FuzzyMatcher algorithm
/// Requirements:
/// - Sub-5ms query time for typical app lists (~200 items)
/// - Acronym matching (e.g., "gc" → "Google Chrome")
/// - Substring matching with gap penalties
/// - Recency and frequency boosting
final class FuzzyMatcherTests: XCTestCase {
    
    var matcher: FuzzyMatcher!
    
    override func setUp() {
        super.setUp()
        matcher = FuzzyMatcher()
    }
    
    // MARK: - Acronym Matching
    
    func testAcronymMatching() {
        // "gc" should match "Google Chrome"
        let score = matcher.score(query: "gc", target: "Google Chrome")
        XCTAssertGreaterThan(score, 0.7, "Acronym matching should have high score")
    }
    
    func testAcronymMatchingCaseInsensitive() {
        let score1 = matcher.score(query: "gc", target: "Google Chrome")
        let score2 = matcher.score(query: "GC", target: "Google Chrome")
        XCTAssertEqual(score1, score2, accuracy: 0.01, "Matching should be case insensitive")
    }
    
    func testMultiWordAcronym() {
        // "vsc" should match "Visual Studio Code"
        let score = matcher.score(query: "vsc", target: "Visual Studio Code")
        XCTAssertGreaterThan(score, 0.7)
    }
    
    // MARK: - Substring Matching
    
    func testPrefixMatch() {
        // Prefix matches should score very high
        let score = matcher.score(query: "saf", target: "Safari")
        XCTAssertGreaterThan(score, 0.9, "Prefix matches should score highest")
    }
    
    func testSubstringMatch() {
        let score = matcher.score(query: "ari", target: "Safari")
        XCTAssertGreaterThan(score, 0.5, "Substring matches should score moderately")
    }
    
    func testNonMatch() {
        let score = matcher.score(query: "xyz", target: "Safari")
        XCTAssertEqual(score, 0.0, "Non-matching queries should score 0")
    }
    
    // MARK: - Gap Penalties
    
    func testGapPenalty() {
        // "sfi" matches "Safari" but with a gap, should score lower than "saf"
        let scoreWithGap = matcher.score(query: "sfi", target: "Safari")
        let scoreWithoutGap = matcher.score(query: "saf", target: "Safari")
        XCTAssertLessThan(scoreWithGap, scoreWithoutGap, "Gaps should reduce score")
    }
    
    // MARK: - Performance
    
    func testPerformance() {
        let targets = (0..<200).map { "Application \($0)" }
        
        measure {
            for target in targets {
                _ = matcher.score(query: "app", target: target)
            }
        }
        
        // Should complete 200 matches in well under 5ms total
    }
    
    // MARK: - Edge Cases
    
    func testEmptyQuery() {
        let score = matcher.score(query: "", target: "Safari")
        XCTAssertEqual(score, 0.0, "Empty query should score 0")
    }
    
    func testEmptyTarget() {
        let score = matcher.score(query: "test", target: "")
        XCTAssertEqual(score, 0.0, "Empty target should score 0")
    }
    
    func testQueryLongerThanTarget() {
        let score = matcher.score(query: "verylongquery", target: "short")
        XCTAssertEqual(score, 0.0, "Query longer than target should score 0")
    }
    
    func testSpecialCharacters() {
        let score = matcher.score(query: "1p", target: "1Password")
        XCTAssertGreaterThan(score, 0.7, "Should handle numbers and special chars")
    }
}
