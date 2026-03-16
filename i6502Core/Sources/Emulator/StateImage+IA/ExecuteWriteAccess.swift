import i6502Specification

extension Emulator.StateImage {
    // Executes an operation that resolves operand to an address
    mutating func executeWriteAccessOperation(
        _ op: i6502Specification.Operation
    ) -> Int {
        let resolvedAddress = fetchAddress(op)

        switch op.symbol {
        case .sta:
            memory[resolvedAddress] = registerA
        case .stx:
            memory[resolvedAddress] = registerX
        case .sty:
            memory[resolvedAddress] = registerY
        default:
            preconditionFailure("Expected a write access operation")
        }
        registerPC += op.length
        return 0
    }
}

extension Array {
    fileprivate subscript(_ index: UInt8) -> Element {
        get { self[Int(index)] }
        set { self[Int(index)] = newValue }
    }

    fileprivate subscript(_ index: UInt16) -> Element {
        get { self[Int(index)] }
        set { self[Int(index)] = newValue }
    }
}

extension Emulator.StateImage {
    fileprivate mutating func assign(
        _ value: UInt8,
        to keyPath: WritableKeyPath<Emulator.StateImage, UInt8>,
        length: UInt16
    ) {
        self[keyPath: keyPath] = value

        registerPS.zero = value == 0
        registerPS.negative = Int8(bitPattern: value) < 0

        registerPC += length
    }
}
