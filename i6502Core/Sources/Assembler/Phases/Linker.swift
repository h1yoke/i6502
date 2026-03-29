import i6502Specification

enum Linker {
    static func process(_ tokens: inout [Token]) throws {
        try resolveLabelReferences(tokens: &tokens)
    }
}

extension Linker {
    fileprivate static func resolveLabelReferences(tokens: inout [Token]) throws {
        let labelKeysWithValues = tokens.compactMap {
            if case let .labelDeclaration(label) = $0 {
                return (label.name, label.address)
            }
            return nil
        }

        if let duplicates = Dictionary(grouping: labelKeysWithValues, by: \.0).first(where: { $1.count > 1 }) {
            throw AssemblerError.linkerError("multiple declarations of label \"\(duplicates.key)\"")
        }

        let labelAddresses: [String: UInt16] = Dictionary(
            uniqueKeysWithValues: labelKeysWithValues
        )

        for (index, token) in tokens.enumerated() {
            if case let .operation(operation) = token {
                switch operation.argument {
                case let .absolute(numberOrUsedLabel),
                     let .absoluteX(numberOrUsedLabel),
                     let .absoluteY(numberOrUsedLabel):

                    if case let .label(string) = numberOrUsedLabel {
                        guard let address = labelAddresses[string] else {
                            throw AssemblerError.linkerError("label \"\(string)\" was not resolved")
                        }

                        tokens[index] = .operation(.init(
                            code: operation.code,
                            argument: .absolute(.number(.word(address))),
                            address: operation.address
                        ))
                    }

                case let .indirect(numberOrUsedLabel):
                    if case let .label(string) = numberOrUsedLabel {
                        guard let address = labelAddresses[string] else {
                            throw AssemblerError.linkerError("label \"\(string)\" was not resolved")
                        }

                        tokens[index] = .operation(.init(
                            code: operation.code,
                            argument: .indirect(.number(.word(address))),
                            address: operation.address
                        ))
                    }

                case let .relative(.label(string)):
                    guard let address = labelAddresses[string] else {
                        throw AssemblerError.linkerError("label \"\(string)\" was not resolved")
                    }
                    let distance =
                        UInt8(bitPattern: Int8(Int(address) - Int(operation.address) - Int(operation.byteLength)))

                    tokens[index] = .operation(.init(
                        code: operation.code,
                        argument: .relative(.number(.byte(distance))),
                        address: operation.address
                    ))

                default:
                    break
                }
            }
        }
    }
}

extension Token.Operation.Argument {
    func toAddressingMode() -> AddressingMode {
        switch self {
        case .immediate: .immediate
        case .zeroPage: .zeroPage
        case .zeroPageX: .zeroPageX
        case .zeroPageY: .zeroPageY
        case .absolute: .absolute
        case .absoluteX: .absoluteX
        case .absoluteY: .absoluteY
        case .indirectX: .indirectX
        case .indirectY: .indirectY
        case .indirect: .indirect
        case .relative: .relative
        case .implied: .implied
        case .accumulator: .accumulator
        }
    }
}

extension Token.Operation.Argument {
    var value: [UInt8] {
        switch self {
        case let .immediate(value): [value]
        case let .zeroPage(value): [value]
        case let .zeroPageX(value): [value]
        case let .zeroPageY(value): [value]
        case let .absolute(.number(number)): number.toBytecode()
        case let .absoluteX(.number(number)): number.toBytecode()
        case let .absoluteY(.number(number)): number.toBytecode()
        case let .relative(.number(number)): number.toBytecode()
        case let .indirectX(value): [value]
        case let .indirectY(value): [value]
        case let .indirect(.number(number)): number.toBytecode()
        case .implied: []
        case .accumulator: []
        default: []
        }
    }
}

extension Token.Number {
    func toBytecode() -> [UInt8] {
        switch self {
        case let .byte(value): [value]
        case let .word(value): [UInt8(value & 0x00FF), UInt8((value & 0xFF00) >> 8)]
        }
    }
}
