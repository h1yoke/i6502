import i6502Specification

extension Emulator.StateImage {
    // Executes an operation that resolves operand to a value
    mutating func executeReadAccessOperation(
        _ op: i6502Specification.Operation
    ) -> Int {
        let (resolvedValue, pageCrossed) = fetchValue(op)

        switch op.symbol {
        case .adc:
            executeAdc(resolvedValue, length: op.length)

        case .sbc:
            executeSbc(resolvedValue, length: op.length)

        case .and, .ora, .eor:
            executeLogic(resolvedValue, op: op)

        case .cmp, .cpx, .cpy:
            executeCompare(resolvedValue, op: op)

        case .lda, .ldx, .ldy:
            executeLoad(resolvedValue, op: op)

        case .bit:
            executeBit(resolvedValue, length: op.length)

        default:
            preconditionFailure("Expected a read access operation")
        }

        return pageCrossed ? 1 : 0
    }

    private mutating func executeAdc(_ value: UInt8, length: UInt16) {
        guard !registerPS.decimal else {
            fatalError("Decimal mode is not supported yet") // TODO: decimal mode
        }

        let carryIn: UInt8 = registerPS.carry ? 1 : 0
        let (partial, carry1) = registerA.addingReportingOverflow(value)
        let (result, carry2) = partial.addingReportingOverflow(carryIn)
        let carry = carry1 || carry2
        let negative = Int8(bitPattern: result) < 0

        registerA = result
        registerPS.zero = result == 0
        registerPS.carry = carry
        registerPS.overflow = ((registerA ^ result) & (value ^ result) & 0x80) != 0
        registerPS.negative = negative

        registerPC += length
    }

    private mutating func executeSbc(_ value: UInt8, length: UInt16) {
        guard !registerPS.decimal else {
            fatalError("Decimal mode is not supported yet") // TODO: decimal mode
        }

        let borrowIn: UInt8 = registerPS.carry ? 0 : 1
        let (partial, borrow1) = registerA.subtractingReportingOverflow(value)
        let (result, borrow2) = partial.subtractingReportingOverflow(borrowIn)
        let borrow = borrow1 || borrow2
        let negative = Int8(bitPattern: result) < 0

        registerA = result
        registerPS.zero = result == 0
        registerPS.carry = !borrow
        registerPS.overflow = ((registerA ^ result) & (registerA ^ value) & 0x80) != 0
        registerPS.negative = negative

        registerPC += length
    }

    private mutating func executeLogic(_ value: UInt8, op: i6502Specification.Operation) {
        switch op.symbol {
        case .and:
            assign(value & registerA, to: \.registerA, length: op.length)
        case .ora:
            assign(value | registerA, to: \.registerA, length: op.length)
        case .eor:
            assign(value ^ registerA, to: \.registerA, length: op.length)
        default:
            preconditionFailure("Expected a logic operation")
        }
    }

    private mutating func executeCompare(_ value: UInt8, op: i6502Specification.Operation) {
        let keyPath: WritableKeyPath<Self, UInt8> = switch op.symbol {
        case .cmp:
            \.registerA
        case .cpx:
            \.registerX
        case .cpy:
            \.registerY
        default:
            preconditionFailure("Expected a compare operation")
        }

        let result = self[keyPath: keyPath] &- value

        registerPS.carry = self[keyPath: keyPath] >= value
        registerPS.zero = self[keyPath: keyPath] == value
        registerPS.negative = Int8(bitPattern: result) < 0

        registerPC += op.length
    }

    private mutating func executeLoad(_ value: UInt8, op: i6502Specification.Operation) {
        switch op.symbol {
        case .lda:
            assign(value, to: \.registerA, length: op.length)
        case .ldx:
            assign(value, to: \.registerX, length: op.length)
        case .ldy:
            assign(value, to: \.registerY, length: op.length)
        default:
            preconditionFailure("Expected a load operation")
        }
    }

    private mutating func executeBit(_ value: UInt8, length: UInt16) {
        registerPS.zero = registerA & value == 0
        registerPS.negative = value & 0b1000_0000 != 0
        registerPS.overflow = value & 0b0100_0000 != 0

        registerPC += length
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
