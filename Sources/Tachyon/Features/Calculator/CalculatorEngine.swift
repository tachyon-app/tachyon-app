import Foundation

/// Calculator engine for evaluating math expressions
public class CalculatorEngine {
    
    public init() {}
    
    /// Evaluate a mathematical expression
    public func evaluate(_ expression: String) -> CalculationResult? {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        
        // Detect percentage expressions
        if trimmed.contains("%") {
            return evaluatePercentage(trimmed)
        }
        
        // Parse and evaluate expression
        do {
            let parser = ExpressionParser(expression: trimmed)
            let result = try parser.parse()
            
            return CalculationResult(
                expression: expression,
                result: result,
                type: .math
            )
        } catch {
            return nil
        }
    }
    
    /// Evaluate percentage expressions like "100*30%" or "50+10%"
    private func evaluatePercentage(_ expression: String) -> CalculationResult? {
        // Pattern: number operator percentage
        let pattern = #"(\d+(?:\.\d+)?)\s*([\+\-\*])\s*(\d+(?:\.\d+)?)%"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: expression, range: NSRange(expression.startIndex..., in: expression)) else {
            return nil
        }
        
        guard let baseRange = Range(match.range(at: 1), in: expression),
              let opRange = Range(match.range(at: 2), in: expression),
              let percentRange = Range(match.range(at: 3), in: expression),
              let base = Double(expression[baseRange]),
              let percent = Double(expression[percentRange]) else {
            return nil
        }
        
        let op = String(expression[opRange])
        let result: Double
        
        switch op {
        case "*":
            // 100*30% = 30
            result = base * (percent / 100)
        case "+":
            // 50+10% = 55 (50 + 5)
            result = base + (base * percent / 100)
        case "-":
            // 100-20% = 80 (100 - 20)
            result = base - (base * percent / 100)
        default:
            return nil
        }
        
        return CalculationResult(
            expression: expression,
            result: result,
            inputLabel: "Percentage",
            type: .percentage
        )
    }
}

/// Recursive descent parser for math expressions
private class ExpressionParser {
    private let expression: String
    private var position = 0
    private var currentChar: Character?
    
    init(expression: String) {
        self.expression = expression.replacingOccurrences(of: " ", with: "")
        self.currentChar = self.expression.first
    }
    
    func parse() throws -> Double {
        let result = try parseExpression()
        if position < expression.count {
            throw CalculatorError.invalidExpression
        }
        return result
    }
    
    // Expression → Term (('+' | '-') Term)*
    private func parseExpression() throws -> Double {
        var result = try parseTerm()
        
        while let char = currentChar, char == "+" || char == "-" {
            let op = char
            advance()
            let term = try parseTerm()
            
            if op == "+" {
                result += term
            } else {
                result -= term
            }
        }
        
        return result
    }
    
    // Term → Factor (('*' | '/') Factor)*
    private func parseTerm() throws -> Double {
        var result = try parseFactor()
        
        while let char = currentChar, char == "*" || char == "/" {
            let op = char
            advance()
            let factor = try parseFactor()
            
            if op == "*" {
                result *= factor
            } else {
                if factor == 0 {
                    throw CalculatorError.divisionByZero
                }
                result /= factor
            }
        }
        
        return result
    }
    
    // Factor → Number | '(' Expression ')' | Function '(' Expression ')' | Constant
    private func parseFactor() throws -> Double {
        // Handle unary minus
        if currentChar == "-" {
            advance()
            return -(try parseFactor())
        }
        
        // Handle parentheses
        if currentChar == "(" {
            advance()
            let result = try parseExpression()
            if currentChar != ")" {
                throw CalculatorError.unmatchedParentheses
            }
            advance()
            return result
        }
        
        // Try to parse as function or constant
        let startPos = position
        var identifier = ""
        
        while let char = currentChar, char.isLetter {
            identifier.append(char)
            advance()
        }
        
        if !identifier.isEmpty {
            // Check if it's a constant
            if let constant = parseConstant(identifier) {
                return constant
            }
            
            // Otherwise it's a function
            return try parseFunction(identifier)
        }
        
        // Parse number
        return try parseNumber()
    }
    
    private func parseNumber() throws -> Double {
        var numStr = ""
        var hasDecimal = false
        var hasExponent = false
        
        while let char = currentChar {
            if char.isNumber {
                numStr.append(char)
                advance()
            } else if char == "." && !hasDecimal {
                hasDecimal = true
                numStr.append(char)
                advance()
            } else if (char == "e" || char == "E") && !hasExponent {
                hasExponent = true
                numStr.append(char)
                advance()
                // Handle sign after exponent
                if currentChar == "+" || currentChar == "-" {
                    numStr.append(currentChar!)
                    advance()
                }
            } else {
                break
            }
        }
        
        guard let number = Double(numStr) else {
            throw CalculatorError.invalidNumber
        }
        
        return number
    }
    
    private func parseConstant(_ name: String) -> Double? {
        switch name.lowercased() {
        case "pi":
            return Double.pi
        case "e":
            return M_E
        default:
            return nil
        }
    }
    
    private func parseFunction(_ name: String) throws -> Double {
        if currentChar != "(" {
            throw CalculatorError.invalidFunction
        }
        advance()
        
        let arg = try parseExpression()
        
        if currentChar != ")" {
            throw CalculatorError.unmatchedParentheses
        }
        advance()
        
        switch name.lowercased() {
        case "sqrt":
            return sqrt(arg)
        case "sin":
            return sin(arg)
        case "cos":
            return cos(arg)
        case "tan":
            return tan(arg)
        case "log":
            return log10(arg)
        case "ln":
            return log(arg)
        case "abs":
            return abs(arg)
        case "floor":
            return floor(arg)
        case "ceil":
            return ceil(arg)
        default:
            throw CalculatorError.unknownFunction(name)
        }
    }
    
    private func advance() {
        position += 1
        if position < expression.count {
            let index = expression.index(expression.startIndex, offsetBy: position)
            currentChar = expression[index]
        } else {
            currentChar = nil
        }
    }
}

enum CalculatorError: Error {
    case invalidExpression
    case invalidNumber
    case divisionByZero
    case unmatchedParentheses
    case invalidFunction
    case unknownFunction(String)
}
