import i6502Specification

extension Emulator.StateImage {
    // Executes an operation that has no operand in program memory whatsoever
    mutating func executeNoMemoryAccessOperation(
        _ op: i6502Specification.Operation
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
    fileprivate mutating func executeImplied(_ op: i6502Specification.Operation) {
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

    fileprivate mutating func executeTransfer(_ op: i6502Specification.Operation) {
        switch op.symbol {
        case .tax:
            assign(registerA, to: \.registerX, length: op.length)
        case .txa:
            assign(registerX, to: \.registerA, length: op.length)
        case .tay:
            assign(registerA, to: \.registerY, length: op.length)
        case .tya:
            assign(registerY, to: \.registerA, length: op.length)
        case .txs:
            assign(registerX, to: \.registerSP, length: op.length)
        case .tsx:
            assign(registerSP, to: \.registerX, length: op.length)
        default:
            preconditionFailure("Expected to recieve a tranfer operation")
        }
    }

    fileprivate mutating func executeIncreaseDecrease(_ op: i6502Specification.Operation) {
        switch op.symbol {
        case .inx:
            assign(registerX &+ 1, to: \.registerX, length: op.length)
        case .dex:
            assign(registerX &- 1, to: \.registerX, length: op.length)
        case .iny:
            assign(registerY &+ 1, to: \.registerY, length: op.length)
        case .dey:
            assign(registerY &- 1, to: \.registerY, length: op.length)
        default:
            preconditionFailure("Expected to recieve an increase operation")
        }
    }

    fileprivate mutating func executeStack(_ op: i6502Specification.Operation) {
        switch op.symbol {
        case .pha:
            memory[UInt16(registerSP) + 0x100] = registerA
            registerSP &-= 1
        case .pla:
            registerA = memory[UInt16(registerSP) + 0x100]
            registerSP &+= 1
        case .php:
            memory[UInt16(registerSP) + 0x100] = registerPS
            registerSP &-= 1
        case .plp:
            registerPS = memory[UInt16(registerSP) + 0x100]
            registerSP &+= 1
        default:
            preconditionFailure("Expected to recieve a stack operation")
        }
        registerPC += op.length
    }

    fileprivate mutating func executeFlag(_ op: i6502Specification.Operation) {
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
    fileprivate mutating func executeAccumulator(_ op: i6502Specification.Operation) {
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

    fileprivate mutating func executeRol(length: UInt16) {
        let value = registerA
        // carry shifts into pos 0, pos 7 shift to carry
        registerA = (value << 1) | (registerPS.carry ? 0b1 : 0b0)

        registerPS.zero = registerA == 0
        registerPS.negative = Int8(bitPattern: registerA) < 0
        registerPS.carry = value & 0b1000_0000 == 1

        registerPC += length
    }

    fileprivate mutating func executeRor(length: UInt16) {
        let value = registerA
        // carry shifts into pos 7, pos 0 shift to carry
        registerA = (value >> 1) | (registerPS.carry ? 0b1000_0000 : 0b0)

        registerPS.zero = registerA == 0
        registerPS.negative = Int8(bitPattern: registerA) < 0
        registerPS.carry = value & 0b1 == 1

        registerPC += length
    }

    fileprivate mutating func executeLsr(length: UInt16) {
        let value = registerA
        registerA = value >> 1

        registerPS.zero = registerA == 0
        registerPS.negative = Int8(bitPattern: registerA) < 0
        registerPS.carry = value & 0b1 == 1

        registerPC += length
    }

    fileprivate mutating func executeAsl(length: UInt16) {
        let value = registerA
        registerA = value << 1

        registerPS.zero = registerA == 0
        registerPS.negative = Int8(bitPattern: registerA) < 0
        registerPS.carry = value & 0b1000_0000 == 1

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
