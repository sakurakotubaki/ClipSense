//
//  ClipboardSecurityFilter.swift
//  ClipSense
//

import Foundation

struct ClipboardSecurityFilter {
    nonisolated init() {}

    func shouldStore(_ content: String) -> Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return false
        }

        guard !isOneTimePasscode(trimmed) else {
            return false
        }

        guard !containsCreditCardNumber(trimmed) else {
            return false
        }

        guard !looksLikeLongRandomString(trimmed) else {
            return false
        }

        return true
    }

    private func isOneTimePasscode(_ content: String) -> Bool {
        content.range(of: #"^\d{6,8}$"#, options: .regularExpression) != nil
    }

    private func containsCreditCardNumber(_ content: String) -> Bool {
        let pattern = #"(?:\d[ -]?){13,19}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }

        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        let matches = regex.matches(in: content, range: range)

        return matches.contains { match in
            guard let matchRange = Range(match.range, in: content) else {
                return false
            }

            let digits = content[matchRange].filter(\.isNumber)
            return (13...19).contains(digits.count) && passesLuhnCheck(String(digits))
        }
    }

    private func passesLuhnCheck(_ digits: String) -> Bool {
        let numbers = digits.compactMap(\.wholeNumberValue)
        guard numbers.count == digits.count, numbers.count >= 13 else {
            return false
        }

        let checksum = numbers.reversed().enumerated().reduce(0) { partial, element in
            let (offset, value) = element
            guard offset.isMultiple(of: 2) == false else {
                return partial + value
            }

            let doubled = value * 2
            return partial + (doubled > 9 ? doubled - 9 : doubled)
        }

        return checksum.isMultiple(of: 10)
    }

    private func looksLikeLongRandomString(_ content: String) -> Bool {
        guard content.count >= 32 else {
            return false
        }

        let scalars = content.unicodeScalars
        let whitespaceRatio = Double(scalars.filter(CharacterSet.whitespacesAndNewlines.contains).count) / Double(scalars.count)
        guard whitespaceRatio < 0.05 else {
            return false
        }

        let hasLowercase = content.range(of: #"[a-z]"#, options: .regularExpression) != nil
        let hasUppercase = content.range(of: #"[A-Z]"#, options: .regularExpression) != nil
        let hasDigit = content.range(of: #"\d"#, options: .regularExpression) != nil
        let hasSymbol = content.range(of: #"[^A-Za-z0-9]"#, options: .regularExpression) != nil
        let classCount = [hasLowercase, hasUppercase, hasDigit, hasSymbol].filter { $0 }.count

        guard classCount >= 3 else {
            return false
        }

        return shannonEntropy(of: content) >= 4.0
    }

    private func shannonEntropy(of content: String) -> Double {
        let counts = Dictionary(grouping: content) { $0 }.mapValues(\.count)
        let length = Double(content.count)

        return counts.values.reduce(0) { entropy, count in
            let probability = Double(count) / length
            return entropy - probability * log2(probability)
        }
    }
}
