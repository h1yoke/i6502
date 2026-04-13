import i6502Specification

extension Emulator.StateImage {
    // Executes an operation that resolves operand to a value
    func executeReadAccessOperation(
        _ op: Specification.DecodedInstruction
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

    private func executeAdc(_ value: UInt8, length: UInt16) {
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

    private func executeSbc(_ value: UInt8, length: UInt16) {
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

    private func executeLogic(_ value: UInt8, op: Specification.DecodedInstruction) {
        switch op.symbol {
        case .and:
            registerA = value & registerA
            registerPS.zero = registerA == 0
            registerPS.negative = Int8(bitPattern: registerA) < 0
            registerPC += op.length
        case .ora:
            registerA = value | registerA
            registerPS.zero = registerA == 0
            registerPS.negative = Int8(bitPattern: registerA) < 0
            registerPC += op.length
        case .eor:
            registerA = value ^ registerA
            registerPS.zero = registerA == 0
            registerPS.negative = Int8(bitPattern: registerA) < 0
            registerPC += op.length
        default:
            preconditionFailure("Expected a logic operation")
        }
    }

    private func executeCompare(_ value: UInt8, op: Specification.DecodedInstruction) {
        let register: UInt8 = switch op.symbol {
        case .cmp:
            registerA
        case .cpx:
            registerX
        case .cpy:
            registerY
        default:
            preconditionFailure("Expected a compare operation")
        }

        let result = register &- value

        registerPS.carry = register >= value
        registerPS.zero = register == value
        registerPS.negative = Int8(bitPattern: result) < 0

        registerPC += op.length
    }

    private func executeLoad(_ value: UInt8, op: Specification.DecodedInstruction) {
        switch op.symbol {
        case .lda:
            registerA = value
            registerPS.zero = registerA == 0
            registerPS.negative = Int8(bitPattern: registerA) < 0
            registerPC += op.length
        case .ldx:
            registerX = value
            registerPS.zero = registerX == 0
            registerPS.negative = Int8(bitPattern: registerX) < 0
            registerPC += op.length
        case .ldy:
            registerY = value
            registerPS.zero = registerY == 0
            registerPS.negative = Int8(bitPattern: registerY) < 0
            registerPC += op.length
        default:
            preconditionFailure("Expected a load operation")
        }
    }

    private func executeBit(_ value: UInt8, length: UInt16) {
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
