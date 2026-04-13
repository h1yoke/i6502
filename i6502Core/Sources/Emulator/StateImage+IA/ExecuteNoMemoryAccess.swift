import i6502Specification

extension Emulator.StateImage {
    // Executes an operation that has no operand in program memory whatsoever
    func executeNoMemoryAccessOperation(
        _ op: Specification.DecodedInstruction
    ) -> Int {
        switch op.mode {
        case .implied:
            executeImplied(op)

        case .accumulator:
            executeAccumulator(op)

        default:
            preconditionFailure("Expected accumulator or implied mode for no memory access operation")
        }
        return 0
    }
}

extension Emulator.StateImage {
    fileprivate func executeImplied(_ op: Specification.DecodedInstruction) {
        switch op.symbol {
        case .tax, .txa, .tay, .tya, .txs, .tsx:
            executeTransfer(op)

        case .inx, .dex, .iny, .dey:
            executeIncreaseDecrease(op)

        case .pha, .pla, .php, .plp:
            executeStack(op)

        case .clc, .sec, .cli, .sei, .clv, .cld, .sed:
            executeFlag(op)

        case .nop:
            registerPC += 1

        default:
            preconditionFailure("Expected an implied mode operation")
        }
    }

    fileprivate func executeTransfer(_ op: Specification.DecodedInstruction) {
        switch op.symbol {
        case .tax:
            registerX = registerA
            registerPS.zero = registerA == 0
            registerPS.negative = Int8(bitPattern: registerA) < 0
            registerPC += op.length
        case .txa:
            registerA = registerX
            registerPS.zero = registerX == 0
            registerPS.negative = Int8(bitPattern: registerX) < 0
            registerPC += op.length
        case .tay:
            registerY = registerA
            registerPS.zero = registerA == 0
            registerPS.negative = Int8(bitPattern: registerA) < 0
            registerPC += op.length
        case .tya:
            registerA = registerY
            registerPS.zero = registerY == 0
            registerPS.negative = Int8(bitPattern: registerY) < 0
            registerPC += op.length
        case .txs:
            registerSP = registerX
            registerPS.zero = registerX == 0
            registerPS.negative = Int8(bitPattern: registerX) < 0
            registerPC += op.length
        case .tsx:
            registerX = registerSP
            registerPS.zero = registerSP == 0
            registerPS.negative = Int8(bitPattern: registerSP) < 0
            registerPC += op.length
        default:
            preconditionFailure("Expected to recieve a tranfer operation")
        }
    }

    fileprivate func executeIncreaseDecrease(_ op: Specification.DecodedInstruction) {
        switch op.symbol {
        case .inx:
            registerX &+= 1
            registerPS.zero = registerX == 0
            registerPS.negative = Int8(bitPattern: registerX) < 0
            registerPC += op.length
        case .dex:
            registerX &-= 1
            registerPS.zero = registerX == 0
            registerPS.negative = Int8(bitPattern: registerX) < 0
            registerPC += op.length
        case .iny:
            registerY &+= 1
            registerPS.zero = registerY == 0
            registerPS.negative = Int8(bitPattern: registerY) < 0
            registerPC += op.length
        case .dey:
            registerY &-= 1
            registerPS.zero = registerY == 0
            registerPS.negative = Int8(bitPattern: registerY) < 0
            registerPC += op.length
        default:
            preconditionFailure("Expected to recieve an increase operation")
        }
    }

    fileprivate func executeStack(_ op: Specification.DecodedInstruction) {
        switch op.symbol {
        case .pha:
            memory[UInt16(registerSP) + 0x100] = registerA
            registerSP &-= 1
        case .pla:
            registerSP &+= 1
            registerA = memory[UInt16(registerSP) + 0x100]
        case .php:
            memory[UInt16(registerSP) + 0x100] = registerPS
            registerSP &-= 1
        case .plp:
            registerSP &+= 1
            registerPS = memory[UInt16(registerSP) + 0x100]
        default:
            preconditionFailure("Expected to recieve a stack operation")
        }
        registerPC += op.length
    }

    fileprivate func executeFlag(_ op: Specification.DecodedInstruction) {
        switch op.symbol {
        case .clc:
            registerPS.carry = false
        case .sec:
            registerPS.carry = true
        case .cli:
            registerPS.interrupt = false
        case .sei:
            registerPS.interrupt = true
        case .clv:
            registerPS.overflow = false
        case .cld:
            registerPS.decimal = false
        case .sed:
            registerPS.decimal = true
        default:
            preconditionFailure("Expected to recieve a flag operation")
        }
        registerPC += 1
    }
}

extension Emulator.StateImage {
    fileprivate func executeAccumulator(_ op: Specification.DecodedInstruction) {
        switch op.symbol {
        case .rol:
            executeRol(length: op.length)
        case .ror:
            executeRor(length: op.length)
        case .lsr:
            executeLsr(length: op.length)
        case .asl:
            executeAsl(length: op.length)
        default:
            preconditionFailure("Expected to recieve an accumulator operation")
        }
    }

    fileprivate func executeRol(length: UInt16) {
        let value = registerA
        // carry shifts into pos 0, pos 7 shift to carry
        registerA = (value << 1) | (registerPS.carry ? 0b1 : 0b0)

        registerPS.zero = registerA == 0
        registerPS.negative = Int8(bitPattern: registerA) < 0
        registerPS.carry = value & 0b1000_0000 == 1

        registerPC += length
    }

    fileprivate func executeRor(length: UInt16) {
        let value = registerA
        // carry shifts into pos 7, pos 0 shift to carry
        registerA = (value >> 1) | (registerPS.carry ? 0b1000_0000 : 0b0)

        registerPS.zero = registerA == 0
        registerPS.negative = Int8(bitPattern: registerA) < 0
        registerPS.carry = value & 0b1 == 1

        registerPC += length
    }

    fileprivate func executeLsr(length: UInt16) {
        let value = registerA
        registerA = value >> 1

        registerPS.zero = registerA == 0
        registerPS.negative = Int8(bitPattern: registerA) < 0
        registerPS.carry = value & 0b1 == 1

        registerPC += length
    }

    fileprivate func executeAsl(length: UInt16) {
        let value = registerA
        registerA = value << 1

        registerPS.zero = registerA == 0
        registerPS.negative = Int8(bitPattern: registerA) < 0
        registerPS.carry = value & 0b1000_0000 == 1

        registerPC += length
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
