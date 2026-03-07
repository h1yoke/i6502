
import Foundation
import i6502Specification

// *** Literals:
// <number> := <hex_number> | <dec_number>
//     <hex_number> := $<dec_number>
//     <dec_number> := [0-9]+
//
// ** Root:
// <label> := <label_name>:
//     <label_name> := (_ | a-z | A-Z)[_ | a-z | A-Z | 0-9]*
// <operation> := <op_code> <op_argument>
//     <op_code> := case-insesitive 6502 opcode
//     <op_argument> := <number_or_label> | A | #<number> | <number_or_label>,X
//         | <number_or_label>,Y | (<number_or_label>,X) | (<number>),Y | (<number>) | none
//     <number_or_label> := <number> | <label_name>
//

enum Tokenizer {
    static func process(input: inout String) throws -> [Token] {
        try processTokens(input: &input)
    }
}

extension Tokenizer {
    private static func processTokens(input: inout String) throws -> [Token] {
        var currentAddress: UInt16 = 0x0600
        var tokens: [Token] = []

        while !input.isEmpty {
            input.takeAll(.whitespacesAndNewlines)

            if let byteDirective = try input.takeByteDirective() {
                tokens.append(.byte(byteDirective))
                currentAddress += 1
            } else if let (_, opCode) = input.takeOperation() {
                let operation = try processOperation(in: &input, code: opCode, address: currentAddress)
                tokens.append(.operation(operation))
                currentAddress += operation.byteLength
            } else {
                let labelDeclaration = try processLabelDeclaration(in: &input, address: currentAddress)
                tokens.append(.labelDeclaration(labelDeclaration))
            }
        }
        return tokens
    }

    private static func processOperation(
        in input: inout String,
        code: OperationCode,
        address: UInt16
    ) throws -> Token.Operation {
        input.takeAll(.whitespacesAndNewlines)

        var probeNextToken = input
        let nextToken = probeNextToken.takeUntil(.whitespacesAndNewlines.union(.init(charactersIn: ":")))
        if OperationCode(rawValue: nextToken) != nil || probeNextToken.take(":") == ":" {
            if Specification.allowedModes[code]?.contains(.implied) == true {
                return .init(code: code, argument: .implied, address: address)
            }
            return .init(code: code, argument: .accumulator, address: address)
        }

        if input.take("#") == "#" {
            let tryNumber = input.takeNumber()
            guard !tryNumber.isEmpty,
                  let number = tryNumber.parseNumber(),
                  case let .byte(value) = number
            else {
                throw AssemblerError.tokenizerError("'\(tryNumber)' is not a valid number!")
            }
            return .init(code: code, argument: .immediate(value), address: address)
        }

        if input.take("(") == "(" {
            input.takeAll(.whitespacesAndNewlines)

            let tryNumber = input.takeNumber()
            input.takeAll(.whitespacesAndNewlines)
            if !tryNumber.isEmpty, let number = tryNumber.parseNumber() {
                switch number {
                case let .byte(value):
                    if input.take(")") == ")" {
                        input.takeAll(.whitespacesAndNewlines)
                        input.take(",")
                        input.takeAll(.whitespacesAndNewlines)
                        input.take("y")

                        return .init(code: code, argument: .indirectY(value), address: address)
                    } else if input.take(",") == "," {
                        input.takeAll(.whitespacesAndNewlines)
                        if input.take("x") == "x" {
                            input.takeAll(.whitespacesAndNewlines)
                            input.take(")")
                            return .init(code: code, argument: .indirectX(value), address: address)
                        } else {
                            throw AssemblerError.tokenizerError("Expected 'X' for Indirect,X addressing mode")
                        }
                    } else {
                        throw AssemblerError.tokenizerError("Expected ')', ','")
                    }
                case let .word(value):
                    guard input.take(")") == ")" else {
                        throw AssemblerError.tokenizerError("Expected Indirect adressing mode for value '\(tryNumber)'")
                    }
                    return .init(code: code, argument: .indirect(value), address: address)
                }
            } else {
                throw AssemblerError.tokenizerError("Expected number after '('")
            }
        } else {
            let numberOrLabel = try processNumberOrLabel(in: &input)
            if input.take(",") == "," {
                input.takeAll(.whitespacesAndNewlines)

                if input.take("x") == "x" {
                    return switch numberOrLabel {
                    case .label, .number(.word):
                        .init(code: code, argument: .absoluteX(numberOrLabel), address: address)
                    case let .number(.byte(value)):
                        .init(code: code, argument: .zeroPageX(value), address: address)
                    }
                } else if input.take("y") == "y" {
                    return switch numberOrLabel {
                    case .label, .number(.word):
                        .init(code: code, argument: .absoluteY(numberOrLabel), address: address)
                    case let .number(.byte(value)):
                        .init(code: code, argument: .zeroPageY(value), address: address)
                    }
                } else {
                    throw AssemblerError.tokenizerError("Expected 'X' or 'Y' after '('")
                }
            } else if case .label("A") = numberOrLabel {
                return .init(code: code, argument: .accumulator, address: address)
            } else {
                return switch numberOrLabel {
                case let .label(value):
                    if Specification.branchingOperations.contains(code) {
                        .init(code: code, argument: .relative(.label(value)), address: address)
                    } else {
                        .init(code: code, argument: .absolute(numberOrLabel), address: address)
                    }
                case .number(.word):
                    .init(code: code, argument: .absolute(numberOrLabel), address: address)
                case let .number(.byte(value)):
                    .init(code: code, argument: .zeroPage(value), address: address)
                }
            }
        }
    }

    private static func processNumberOrLabel(in input: inout String) throws -> Token.Operation.NumberOrUsedLabel {
        let tryNumber = input.takeNumber()
        if !tryNumber.isEmpty, let value = tryNumber.parseNumber() {
            return .number(value)
        }
        let tryName = input.takeName()
        if !tryName.isEmpty {
            return .label(tryName)
        }
        throw AssemblerError.compilerError("Expected number or label")
    }

    private static func processLabelDeclaration(
        in input: inout String,
        address: UInt16
    ) throws -> Token.DeclaredLabel {
        let name = input.takeName()
        guard !name.isEmpty, input.take(":") == ":" else {
            if !name.isEmpty {
                throw AssemblerError.compilerError("Unrecognized token '\(name)'")
            } else {
                throw AssemblerError.compilerError("Unrecognized token '\(input.takeUntil(.whitespacesAndNewlines))'")
            }
        }
        return Token.DeclaredLabel(name: name, address: address)
    }
}

enum Token {
    enum Number {
        case byte(UInt8)
        case word(UInt16)
    }

    struct DeclaredLabel {
        let name: String
        let address: UInt16
    }

    struct Operation {
        enum NumberOrUsedLabel {
            case number(Token.Number)
            case label(String)
        }

        enum Argument {
            case immediate(UInt8)
            case zeroPage(UInt8)
            case zeroPageX(UInt8)
            case zeroPageY(UInt8)
            case absolute(NumberOrUsedLabel)
            case absoluteX(NumberOrUsedLabel)
            case absoluteY(NumberOrUsedLabel)
            case indirectX(UInt8)
            case indirectY(UInt8)
            case indirect(UInt16)
            case relative(NumberOrUsedLabel)
            case implied
            case accumulator
        }

        let code: OperationCode
        let argument: Argument
        let address: UInt16

        var byteLength: UInt16 {
            // all op codes take exactly one byte
            // lenght depends only on addressing mode
            switch argument {
            case .immediate: 2
            case .zeroPage, .zeroPageX, .zeroPageY: 2
            case .indirectX, .indirectY: 2
            case .absolute, .absoluteX, .absoluteY: 3
            case .indirect: 3
            case .relative: 2
            case .implied, .accumulator: 1
            }
        }
    }

    case labelDeclaration(Token.DeclaredLabel)
    case operation(Token.Operation)
    case byte(UInt8)
}

extension String {
    mutating func takeOperation() -> (String, OperationCode)? {
        var copy = self

        let token = copy.takeUntil(.whitespacesAndNewlines)
        guard let code = OperationCode(rawValue: token.lowercased()) else {
            return nil
        }
        self = copy
        return (token, code)
    }
}

extension String {
    mutating func takeByteDirective() throws -> UInt8? {
        var copy = self

        let token = copy.takeUntil(.whitespacesAndNewlines)
        if token == ".byte" {
            copy.takeAll(.whitespacesAndNewlines)
            let argument = copy.takeUntil(.whitespacesAndNewlines)

            guard case let .byte(value) = argument.parseNumber() else {
                throw AssemblerError.tokenizerError("Expected a byte argument")
            }
            self = copy
            return value
        }
        return nil
    }
}

extension String {
    func parseNumber() -> Token.Number? {
        let isHexidecimal = first == "$"
        guard let value = Int(isHexidecimal ? String(dropFirst()) : self, radix: isHexidecimal ? 16 : 10) else {
            return nil
        }

        if isHexidecimal && count <= 3 || !isHexidecimal && value <= 0xFF {
            return .byte(UInt8(value))
        }
        return .word(UInt16(value))
    }
}
