import Foundation

struct Cursor: CustomStringConvertible {
    var line: Int
    var position: Int

    private(set) var globalPosition: String.Index

    init(input: String) {
        line = 0
        position = 0
        globalPosition = .init(utf16Offset: 0, in: input)
    }

    fileprivate mutating func advance(_ input: String, for character: Character?) {
        guard let character else {
            return
        }
        if character.isNewline {
            line += 1
            position = 0
        } else {
            position += 1
        }
        globalPosition = input.index(globalPosition, offsetBy: 1)
    }

    fileprivate mutating func advance(_ input: String, for characters: String) {
        characters.forEach { advance(input, for: $0) }
    }

    var description: String {
        "(\(line):\(position))"
    }
}

extension String {
    @discardableResult
    func take(_ symbolSet: CharacterSet, cursor: inout Cursor) -> Character? {
        guard indices.contains(cursor.globalPosition) else {
            return nil
        }

        if let unicodeScalar = self[cursor.globalPosition].unicodeScalars.first,
           symbolSet.contains(unicodeScalar)
        {
            let symbol = Character(unicodeScalar)
            cursor.advance(self, for: symbol)
            return symbol
        }
        return nil
    }

    @discardableResult
    func take(_ symbols: String, cursor: inout Cursor) -> String {
        guard indices.contains(cursor.globalPosition) else {
            return ""
        }

        if self[cursor.globalPosition...].hasPrefix(symbols) {
            cursor.advance(self, for: symbols)
            return symbols
        }
        return ""
    }

    @discardableResult
    func takeAll(_ set: CharacterSet, cursor: inout Cursor) -> String {
        var taken = ""
        while let ch = take(set, cursor: &cursor) {
            taken.append(ch)
        }
        return taken
    }

    @discardableResult
    func takeUntil(_ set: CharacterSet, cursor: inout Cursor) -> String {
        var taken = ""
        while indices.contains(cursor.globalPosition),
              let unicodeScalar = self[cursor.globalPosition].unicodeScalars.first,
              !set.contains(unicodeScalar)
        {
            let symbol = Character(unicodeScalar)
            taken.append(symbol)
            cursor.advance(self, for: symbol)
        }
        return taken
    }

    @discardableResult
    func takeUntil(_ symbol: Character, cursor: inout Cursor) -> String {
        takeUntil(.init(charactersIn: String(symbol)), cursor: &cursor)
    }
}

extension CharacterSet {
    static let underscore: Self = .init(charactersIn: "_")
    static let lettersUnderscore: Self = .letters.union(.underscore)
    static let word: Self = .alphanumerics.union(.underscore)
    static let decimalMinus: Self = .decimalDigits.union(.init(charactersIn: "-"))
    static let hexadecimalDigits: Self = .decimalDigits.union(.init(charactersIn: "acbdefABCDEF"))
}

extension String {
    func takeName(cursor: inout Cursor) throws -> String {
        var cursorCopy = cursor

        guard let firstLetter = take(.lettersUnderscore, cursor: &cursorCopy) else {
            if let found = first.map(String.init) {
                throw AssemblerError.tokenizerError("\(cursorCopy): expected letter or underscore, found \"\(found)\"")
            }
            throw AssemblerError.tokenizerError("\(cursorCopy): expected a name")
        }
        cursor = cursorCopy
        return [firstLetter] + takeAll(.word, cursor: &cursor)
    }

    func takeNumber(cursor: inout Cursor) throws -> String {
        let prefix = take("$", cursor: &cursor)
        if prefix.isEmpty {
            let digits = takeAll(.decimalMinus, cursor: &cursor)
            guard !digits.isEmpty else {
                throw AssemblerError.tokenizerError("\(cursor): expected a decimal digits or '$'")
            }
            return digits
        }

        let digits = takeAll(.hexadecimalDigits, cursor: &cursor)
        guard !digits.isEmpty else {
            throw AssemblerError.tokenizerError("\(cursor): expected a hexadecimal digits")
        }
        return prefix + digits
    }
}
