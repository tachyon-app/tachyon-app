import Foundation

/// Unit converter using Foundation's Measurement API
public class UnitConverter {
    
    public init() {}
    
    /// Convert units (e.g., "5 km to miles", "100 F to C")
    public func convert(_ input: String) -> CalculationResult? {
        // Pattern: number + unit + (to/in) + unit
        let pattern = #"([\d.eE+-]+)\s*([a-zA-Z]+)\s+(to|in)\s+([a-zA-Z]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)) else {
            return nil
        }
        
        guard let amountRange = Range(match.range(at: 1), in: input),
              let fromUnitRange = Range(match.range(at: 2), in: input),
              let toUnitRange = Range(match.range(at: 4), in: input),
              let amount = Double(input[amountRange]) else {
            return nil
        }
        
        let fromUnit = String(input[fromUnitRange]).lowercased()
        let toUnit = String(input[toUnitRange]).lowercased()
        
        // Try different unit categories
        if let result = convertLength(amount: amount, from: fromUnit, to: toUnit) {
            return result
        } else if let result = convertTemperature(amount: amount, from: fromUnit, to: toUnit) {
            return result
        } else if let result = convertMass(amount: amount, from: fromUnit, to: toUnit) {
            return result
        } else if let result = convertVolume(amount: amount, from: fromUnit, to: toUnit) {
            return result
        } else if let result = convertDuration(amount: amount, from: fromUnit, to: toUnit) {
            return result
        } else if let result = convertDataSize(amount: amount, from: fromUnit, to: toUnit) {
            return result
        }
        
        return nil
    }
    
    // MARK: - Length Conversion
    
    private func convertLength(amount: Double, from fromUnit: String, to toUnit: String) -> CalculationResult? {
        guard let from = lengthUnit(fromUnit),
              let to = lengthUnit(toUnit) else {
            return nil
        }
        
        let measurement = Measurement(value: amount, unit: from)
        let converted = measurement.converted(to: to)
        
        return CalculationResult(
            expression: "\(amount) \(fromUnit) to \(toUnit)",
            result: converted.value,
            inputLabel: lengthLabel(fromUnit),
            outputLabel: lengthLabel(toUnit),
            type: .unitConversion,
            inputUnit: lengthLabel(fromUnit),
            outputUnit: lengthLabel(toUnit)
        )
    }
    
    private func lengthUnit(_ unit: String) -> UnitLength? {
        switch unit {
        case "km", "kilometer", "kilometers": return .kilometers
        case "m", "meter", "meters": return .meters
        case "cm", "centimeter", "centimeters": return .centimeters
        case "mm", "millimeter", "millimeters": return .millimeters
        case "mile", "miles": return .miles
        case "yard", "yards": return .yards
        case "foot", "feet", "ft": return .feet
        case "inch", "inches": return .inches
        default: return nil
        }
    }
    
    private func lengthLabel(_ unit: String) -> String {
        switch unit {
        case "km", "kilometer", "kilometers": return "Kilometers"
        case "m", "meter", "meters": return "Meters"
        case "cm", "centimeter", "centimeters": return "Centimeters"
        case "mm", "millimeter", "millimeters": return "Millimeters"
        case "mile", "miles": return "Miles"
        case "yard", "yards": return "Yards"
        case "foot", "feet", "ft": return "Feet"
        case "inch", "inches": return "Inches"
        default: return unit.capitalized
        }
    }
    
    // MARK: - Temperature Conversion
    
    private func convertTemperature(amount: Double, from fromUnit: String, to toUnit: String) -> CalculationResult? {
        guard let from = temperatureUnit(fromUnit),
              let to = temperatureUnit(toUnit) else {
            return nil
        }
        
        let measurement = Measurement(value: amount, unit: from)
        let converted = measurement.converted(to: to)
        
        return CalculationResult(
            expression: "\(amount) \(fromUnit) to \(toUnit)",
            result: converted.value,
            inputLabel: temperatureLabel(fromUnit),
            outputLabel: temperatureLabel(toUnit),
            type: .unitConversion,
            inputUnit: temperatureLabel(fromUnit),
            outputUnit: temperatureLabel(toUnit)
        )
    }
    
    private func temperatureUnit(_ unit: String) -> UnitTemperature? {
        switch unit {
        case "c", "celsius": return .celsius
        case "f", "fahrenheit": return .fahrenheit
        case "k", "kelvin": return .kelvin
        default: return nil
        }
    }
    
    private func temperatureLabel(_ unit: String) -> String {
        switch unit {
        case "c", "celsius": return "Celsius"
        case "f", "fahrenheit": return "Fahrenheit"
        case "k", "kelvin": return "Kelvin"
        default: return unit.capitalized
        }
    }
    
    // MARK: - Mass Conversion
    
    private func convertMass(amount: Double, from fromUnit: String, to toUnit: String) -> CalculationResult? {
        guard let from = massUnit(fromUnit),
              let to = massUnit(toUnit) else {
            return nil
        }
        
        let measurement = Measurement(value: amount, unit: from)
        let converted = measurement.converted(to: to)
        
        return CalculationResult(
            expression: "\(amount) \(fromUnit) to \(toUnit)",
            result: converted.value,
            inputLabel: massLabel(fromUnit),
            outputLabel: massLabel(toUnit),
            type: .unitConversion,
            inputUnit: massLabel(fromUnit),
            outputUnit: massLabel(toUnit)
        )
    }
    
    private func massUnit(_ unit: String) -> UnitMass? {
        switch unit {
        case "kg", "kilogram", "kilograms": return .kilograms
        case "g", "gram", "grams": return .grams
        case "lb", "pound", "pounds": return .pounds
        case "oz", "ounce", "ounces": return .ounces
        default: return nil
        }
    }
    
    private func massLabel(_ unit: String) -> String {
        switch unit {
        case "kg", "kilogram", "kilograms": return "Kilograms"
        case "g", "gram", "grams": return "Grams"
        case "lb", "pound", "pounds": return "Pounds"
        case "oz", "ounce", "ounces": return "Ounces"
        default: return unit.capitalized
        }
    }
    
    // MARK: - Volume Conversion
    
    private func convertVolume(amount: Double, from fromUnit: String, to toUnit: String) -> CalculationResult? {
        guard let from = volumeUnit(fromUnit),
              let to = volumeUnit(toUnit) else {
            return nil
        }
        
        let measurement = Measurement(value: amount, unit: from)
        let converted = measurement.converted(to: to)
        
        return CalculationResult(
            expression: "\(amount) \(fromUnit) to \(toUnit)",
            result: converted.value,
            inputLabel: volumeLabel(fromUnit),
            outputLabel: volumeLabel(toUnit),
            type: .unitConversion,
            inputUnit: volumeLabel(fromUnit),
            outputUnit: volumeLabel(toUnit)
        )
    }
    
    private func volumeUnit(_ unit: String) -> UnitVolume? {
        switch unit {
        case "liter", "liters", "l": return .liters
        case "ml", "milliliter", "milliliters": return .milliliters
        case "gallon", "gallons": return .gallons
        case "cup", "cups": return .cups
        case "fl oz", "floz", "fluid oz": return .fluidOunces
        default: return nil
        }
    }
    
    private func volumeLabel(_ unit: String) -> String {
        switch unit {
        case "liter", "liters", "l": return "Liters"
        case "ml", "milliliter", "milliliters": return "Milliliters"
        case "gallon", "gallons": return "Gallons"
        case "cup", "cups": return "Cups"
        case "fl oz", "floz", "fluid oz": return "Fluid Ounces"
        default: return unit.capitalized
        }
    }
    
    // MARK: - Duration Conversion
    
    private func convertDuration(amount: Double, from fromUnit: String, to toUnit: String) -> CalculationResult? {
        guard let from = durationUnit(fromUnit),
              let to = durationUnit(toUnit) else {
            return nil
        }
        
        let measurement = Measurement(value: amount, unit: from)
        let converted = measurement.converted(to: to)
        
        return CalculationResult(
            expression: "\(amount) \(fromUnit) to \(toUnit)",
            result: converted.value,
            inputLabel: durationLabel(fromUnit),
            outputLabel: durationLabel(toUnit),
            type: .unitConversion,
            inputUnit: durationLabel(fromUnit),
            outputUnit: durationLabel(toUnit)
        )
    }
    
    private func durationUnit(_ unit: String) -> UnitDuration? {
        switch unit {
        case "second", "seconds", "s", "sec": return .seconds
        case "minute", "minutes", "min": return .minutes
        case "hour", "hours", "h", "hr": return .hours
        case "day", "days": return UnitDuration(symbol: "day", converter: UnitConverterLinear(coefficient: 86400))
        case "week", "weeks": return UnitDuration(symbol: "week", converter: UnitConverterLinear(coefficient: 604800))
        default: return nil
        }
    }
    
    private func durationLabel(_ unit: String) -> String {
        switch unit {
        case "second", "seconds", "s", "sec": return "Seconds"
        case "minute", "minutes", "min": return "Minutes"
        case "hour", "hours", "h", "hr": return "Hours"
        case "day", "days": return "Days"
        case "week", "weeks": return "Weeks"
        default: return unit.capitalized
        }
    }
    
    // MARK: - Data Size Conversion
    
    private func convertDataSize(amount: Double, from fromUnit: String, to toUnit: String) -> CalculationResult? {
        guard let from = dataSizeUnit(fromUnit),
              let to = dataSizeUnit(toUnit) else {
            return nil
        }
        
        let measurement = Measurement(value: amount, unit: from)
        let converted = measurement.converted(to: to)
        
        return CalculationResult(
            expression: "\(amount) \(fromUnit) to \(toUnit)",
            result: converted.value,
            inputLabel: dataSizeLabel(fromUnit),
            outputLabel: dataSizeLabel(toUnit),
            type: .unitConversion,
            inputUnit: dataSizeLabel(fromUnit),
            outputUnit: dataSizeLabel(toUnit)
        )
    }
    
    private func dataSizeUnit(_ unit: String) -> UnitInformationStorage? {
        switch unit {
        case "byte", "bytes": return .bytes
        case "kb", "kilobyte", "kilobytes": return .kilobytes
        case "mb", "megabyte", "megabytes": return .megabytes
        case "gb", "gigabyte", "gigabytes": return .gigabytes
        case "tb", "terabyte", "terabytes": return .terabytes
        default: return nil
        }
    }
    
    private func dataSizeLabel(_ unit: String) -> String {
        switch unit {
        case "byte", "bytes": return "Bytes"
        case "kb", "kilobyte", "kilobytes": return "Kilobytes"
        case "mb", "megabyte", "megabytes": return "Megabytes"
        case "gb", "gigabyte", "gigabytes": return "Gigabytes"
        case "tb", "terabyte", "terabytes": return "Terabytes"
        default: return unit.uppercased()
        }
    }
}
