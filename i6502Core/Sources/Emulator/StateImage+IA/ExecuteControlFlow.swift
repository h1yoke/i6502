import i6502Specification

extension Emulator.StateImage {
    // Executes an operation that moves program counter
    // may use operand as address if necessary
    mutating func executeConrolFlowOperation(
        _ op: i6502Specification.Operation
    ) -> Int {
        switch op.symbol {
        case .brk:
            executeBrk()

        case .rti:
            executeRti()

        case .rts:
            executeRts()

        case .jsr:
            executeJsr()

        case .jmp:
            executeJmp(op.mode)

        default:
            preconditionFailure("Expected control flow operation")
        }
        return 0
    }

    fileprivate mutating func executeBrk() {
        // increase program counter by 2
        registerPC += 2
        // push PC to stack
        memory[UInt16(registerSP) + 0x100] = UInt8((registerPC & 0xFF00) >> 8)
        registerSP &-= 1
        memory[UInt16(registerSP) + 0x100] = UInt8(registerPC & 0xFF)
        registerSP &-= 1
        // push P to stack with injected B flag
        memory[UInt16(registerSP) + 0x100] = registerPS | 0b0001_0000
        registerSP &-= 1
        // set I flag
        registerPS.interrupt = true
        // set PC to value of $FFFE-FFFF
        registerPC = UInt16(memory[0xFFFE]) + (UInt16(memory[0xFFFF]) << 8)
    }

    fileprivate mutating func executeRti() {
        // pop P from stack
        registerSP &+= 1
        registerPS = memory[UInt16(registerSP) + 0x100]
        // pop PC from stack
        registerSP &+= 1
        let low = UInt16(memory[UInt16(registerSP) + 0x100])
        registerSP &+= 1
        let high = UInt16(memory[UInt16(registerSP) + 0x100]) << 8
        registerPC = low + high
    }

    fileprivate mutating func executeRts() {
        // pop PC from stack
        registerSP &+= 1
        let low = UInt16(memory[UInt16(registerSP) + 0x100])
        registerSP &+= 1
        let high = UInt16(memory[UInt16(registerSP) + 0x100]) << 8
        registerPC = low + high + 1
    }

    fileprivate mutating func executeJsr() {
        let origin = registerPC + 2

        // proccess absolute jump
        executeJmp(.absolute)

        // push PC to stack
        memory[UInt16(registerSP) + 0x100] = UInt8((origin & 0xFF00) >> 8)
        registerSP &-= 1
        memory[UInt16(registerSP) + 0x100] = UInt8(origin & 0xFF)
        registerSP &-= 1
    }

    fileprivate mutating func executeJmp(_ mode: AddressingMode) {
        switch mode {
        case .absolute:
            registerPC = fetchAbsoluteJump()
        case .indirect:
            registerPC = fetchIndirectJump()
        default:
            break
        }
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
