import i6502Specification

enum Translator {
    static func process(_ tokens: inout [Token]) throws -> [UInt8] {
        try translateBytecode(tokens: tokens)
    }
}

extension Translator {
    fileprivate static func translateBytecode(tokens: [Token]) throws -> [UInt8] {
        var currentAddress: UInt16 = 0x0000
        var memory = [UInt8](repeating: 0, count: 65_536)

        for token in tokens {
            switch token {
            case .labelDeclaration:
                break

            case let .byte(byteValue):
                memory[currentAddress] = byteValue
                currentAddress += 1

            case let .org(address):
                currentAddress = address

            case let .operation(operation):
                let specOperation = i6502Specification.Operation(operation.code, operation.argument.toAddressingMode())
                guard let translatedOp = Specification.translate(op: specOperation) else {
                    throw AssemblerError.translatorError(
                        "\(specOperation.symbol) in \(specOperation.mode) mode is illegal"
                    )
                }

                memory[currentAddress] = translatedOp
                currentAddress += 1
                for item in operation.argument.value {
                    memory[currentAddress] = item
                    currentAddress += 1
                }
            }
        }
        return memory
    }
}

extension Array {
    fileprivate subscript(_ index: UInt16) -> Element {
        get {
            self[Int(index)]
        }
        set(newValue) {
            self[Int(index)] = newValue
        }
    }
}
