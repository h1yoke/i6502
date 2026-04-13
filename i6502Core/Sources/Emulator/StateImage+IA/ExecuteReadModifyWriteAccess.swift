import i6502Specification

extension Emulator.StateImage {
    // Executes an operation that resolves operand both to a value and an address
    func executeReadModifyWriteAccessOperation(
        _ op: Specification.DecodedInstruction
    ) -> Int {
        let resolvedAddress = fetchAddress(op)
        let (resolvedValue, pageCrossed) = fetchValue(op)

        switch op.symbol {
        case .rol:
            executeRol(resolvedValue, resolvedAddress, length: op.length)

        case .ror:
            executeRor(resolvedValue, resolvedAddress, length: op.length)

        case .lsr:
            executeLsr(resolvedValue, resolvedAddress, length: op.length)

        case .asl:
            executeAsl(resolvedValue, resolvedAddress, length: op.length)

        case .inc, .dec:
            executeIncreaseDecrease(resolvedValue, resolvedAddress, op: op)

        default:
            preconditionFailure("Expected a read-modify-write access operation")
        }

        return pageCrossed ? 1 : 0
    }

    fileprivate func executeRol(_ value: UInt8, _ address: UInt16, length: UInt16) {
        // carry shifts into pos 0, pos 7 shift to carry
        memory[address] = (value << 1) | (registerPS.carry ? 0b1 : 0b0)

        registerPS.zero = registerA == 0
        registerPS.negative = Int8(bitPattern: memory[address]) < 0
        registerPS.carry = value & 0b1000_0000 == 1

        registerPC += length
    }

    fileprivate func executeRor(_ value: UInt8, _ address: UInt16, length: UInt16) {
        // carry shifts into pos 7, pos 0 shift to carry
        memory[address] = (value >> 1) | (registerPS.carry ? 0b1000_0000 : 0b0)

        registerPS.zero = memory[address] == 0
        registerPS.negative = Int8(bitPattern: memory[address]) < 0
        registerPS.carry = value & 0b1 == 1

        registerPC += length
    }

    fileprivate func executeLsr(_ value: UInt8, _ address: UInt16, length: UInt16) {
        memory[address] = value >> 1

        registerPS.zero = memory[address] == 0
        registerPS.negative = Int8(bitPattern: memory[address]) < 0
        registerPS.carry = value & 0b1 == 1

        registerPC += length
    }

    fileprivate func executeAsl(_ value: UInt8, _ address: UInt16, length: UInt16) {
        memory[address] = value << 1

        registerPS.zero = memory[address] == 0
        registerPS.negative = Int8(bitPattern: memory[address]) < 0
        registerPS.carry = value & 0b1000_0000 == 1

        registerPC += length
    }

    fileprivate func executeIncreaseDecrease(
        _ value: UInt8,
        _ address: UInt16,
        op: Specification.DecodedInstruction
    ) {
        switch op.symbol {
        case .inc:
            memory[address] = value &+ 1
        case .dec:
            memory[address] = value &- 1
        default:
            preconditionFailure("Expected to recieve an increase operation")
        }
        registerPC += op.length
    }
}

extension UnsafeMutableBufferPointer {
    fileprivate subscript(_ index: UInt8) -> Element {
        get { self[Int(index)] }
        nonmutating set { self[Int(index)] = newValue }
    }

    fileprivate subscript(_ index: UInt16) -> Element {
        get { self[Int(index)] }
        nonmutating set { self[Int(index)] = newValue }
    }
}
