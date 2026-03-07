
// *** Preprocessor:
// <definition> := .define <def_name> <def_value>
//     <def_name> := (_ | a-z | A-Z)[_ | a-z | A-Z | 0-9]*
//     <def_value> := <number>
// <comment> := ;.*
enum Preprocessor {
    static func process(input: inout String) throws {
        processComments(in: &input)
        try processDefinitions(in: &input)
        input = input.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Preprocessor {
    private static func processComments(in input: inout String) {
        let occurrences = input.indices(of: ";")

        var comments: [String] = []

        for occurrence in occurrences {
            var scope = String(input[occurrence...])
            var comment = ""

            comment += scope.take(";")
            comment += scope.takeUntil(.newlines)

            comments.append(comment)
        }

        comments.forEach { input = input.replacingOccurrences(of: $0, with: "") }
    }

    private static func processDefinitions(in input: inout String) throws {
        let definitionTable = try grabDefinitionTable(in: &input)
        for (name, value) in definitionTable {
            input = input.replacingOccurrences(of: name, with: value)
        }
    }

    // removes all definition statements from input and stores them in table
    private static func grabDefinitionTable(in input: inout String) throws -> [String: String] {
        let occurrences = input.indices(of: ".define")

        var definitionTable: [String: String] = [:]
        var definitions: [String] = []

        for occurrence in occurrences {
            var scope = String(input[occurrence...])
            var definition = ""
            let start = occurrence.utf16Offset(in: input)

            definition += scope.take(".define")
            definition += scope.takeAll(.whitespacesAndNewlines)
            let name = scope.takeName()
            guard !name.isEmpty else {
                throw AssemblerError.preprocessorError("Expected a definition name")
            }
            guard !illegalNames.contains(name) else {
                throw AssemblerError.preprocessorError("Illegal name '\(name)'")
            }
            definition += name
            definition += scope.takeAll(.whitespacesAndNewlines)
            let value = scope.takeNumber()
            guard !value.isEmpty else {
                throw AssemblerError.preprocessorError("Expected a definition value for '\(name)'")
            }
            guard definitionTable[name] == nil else {
                throw AssemblerError.preprocessorError("Illegal redefinition of '\(name)'")
            }
            definition += value

            definitionTable[name] = value
            definitions.append(definition)
        }
        definitions.forEach { input = input.replacingOccurrences(of: $0, with: "") }
        return definitionTable
    }

    private static let illegalNames: Set = ["define", "a"]
}

extension String {
    fileprivate func indices(of substring: String) -> [String.Index] {
        guard !substring.isEmpty else {
            return []
        }

        var indices: [String.Index] = []
        var searchRange = startIndex ..< endIndex

        while let range = range(of: substring, range: searchRange) {
            indices.append(range.lowerBound)
            searchRange = index(after: range.lowerBound) ..< endIndex
        }

        return indices
    }
}
