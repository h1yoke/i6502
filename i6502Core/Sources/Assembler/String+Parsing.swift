import Foundation

extension String {
    @discardableResult
    mutating func take(_ token: Character) -> Character? {
        if first == token {
            return removeFirst()
        }
        return nil
    }

    @discardableResult
    mutating func take(_ set: CharacterSet) -> Character? {
        if let first = first?.unicodeScalars.first, set.contains(first) {
            return removeFirst()
        }
        return nil
    }

    @discardableResult
    mutating func take(_ token: String) -> String {
        if hasPrefix(token) {
            removeFirst(token.count)
            return token
        }
        return ""
    }

    @discardableResult
    mutating func takeAll(_ set: CharacterSet) -> String {
        var taken = ""
        while let ch = take(set) {
            taken.append(ch)
        }
        return taken
    }

    @discardableResult
    mutating func takeUntil(_ set: CharacterSet) -> String {
        var taken = ""
        while let ch = first,
              let scalar = ch.unicodeScalars.first,
              !set.contains(scalar)
        {
            taken.append(ch)
            removeFirst()
        }
        return taken
    }

    @discardableResult
    mutating func readUntil(_ set: CharacterSet) -> String {
        var copy = self
        return copy.takeUntil(set)
    }
}

extension CharacterSet {
    static let underscore: Self = .init(charactersIn: "_")
}

extension String {
    mutating func takeName() -> String {
        var copy = self

        guard let firstLetter = copy.take(.letters.union(.underscore)) else {
            return ""
        }
        self = copy
        return [firstLetter] + takeAll(.alphanumerics.union(.underscore))
    }

    mutating func takeNumber() -> String {
        let prefix = take("$")
        return prefix.isEmpty
            ? takeAll(.decimalDigits)
            : prefix + takeAll(.decimalDigits.union(.init(charactersIn: "acbdefABCDEF")))
    }
}
