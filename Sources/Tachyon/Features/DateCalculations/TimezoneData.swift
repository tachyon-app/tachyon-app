import Foundation

/// Helper class containing city to timezone mappings
class TimezoneData {
    static let shared = TimezoneData()
    
    // City name (lowercase) -> TimeZone identifier
    let cities: [String: String] = [
        // North America
        "new york": "America/New_York",
        "nyc": "America/New_York",
        "los angeles": "America/Los_Angeles",
        "la": "America/Los_Angeles",
        "sf": "America/Los_Angeles",
        "san francisco": "America/Los_Angeles",
        "shicago": "America/Chicago",
        "toronto": "America/Toronto",
        "vancouver": "America/Vancouver",
        "mexico city": "America/Mexico_City",
        
        // Europe
        "london": "Europe/London",
        "uk": "Europe/London",
        "dublin": "Europe/Dublin",
        "paris": "Europe/Paris",
        "berlin": "Europe/Berlin",
        "rome": "Europe/Rome",
        "madrid": "Europe/Madrid",
        "amsterdam": "Europe/Amsterdam",
        "brussels": "Europe/Brussels",
        "zurich": "Europe/Zurich",
        "moscow": "Europe/Moscow",
        "kyiv": "Europe/Kyiv",
        
        // Asia
        "tokyo": "Asia/Tokyo",
        "seoul": "Asia/Seoul",
        "beijing": "Asia/Shanghai",
        "shanghai": "Asia/Shanghai",
        "hong kong": "Asia/Hong_Kong",
        "singapore": "Asia/Singapore",
        "bangkok": "Asia/Bangkok",
        "mumbai": "Asia/Kolkata",
        "delhi": "Asia/Kolkata",
        "dubai": "Asia/Dubai",
        
        // Oceania
        "sydney": "Australia/Sydney",
        "melbourne": "Australia/Melbourne",
        "auckland": "Pacific/Auckland",
        
        // South America
        "sao paulo": "America/Sao_Paulo",
        "buenos aires": "America/Argentina/Buenos_Aires",
        "rio": "America/Sao_Paulo",
        
        // Africa
        "cairo": "Africa/Cairo",
        "johannesburg": "Africa/Johannesburg",
        "lagos": "Africa/Lagos",
        
        // Standard UTCs
        "utc": "UTC",
        "gmt": "GMT",
        "z": "UTC"
    ]
    
    private init() {}
    
    func getTimeZone(for city: String) -> TimeZone? {
        if let identifier = cities[city.lowercased()] {
            return TimeZone(identifier: identifier)
        }
        return nil
    }
}
