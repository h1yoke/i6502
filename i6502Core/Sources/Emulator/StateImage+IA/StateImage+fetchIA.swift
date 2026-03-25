import i6502Specification

extension Emulator.StateImage {
    func fetchAbsoluteJump() -> UInt16 {
        nextWord
    }

    func fetchIndirectJump() -> UInt16 {
        // 6502 wraps indirect addresses within a page
        // Example: JMP ($01FF) reads contents of 01FF and 0100 instead of 0200
        let lowAddress = nextWord
        let highAddress = nextWord & 0xFF == 0xFF ? (nextWord & 0xFF00) : nextWord + 1
        return UInt16(memory[lowAddress]) + (UInt16(memory[highAddress]) << 8)
    }

    func fetchRelativeBranch() -> (address: UInt16, pageCrossed: Bool) {
        let pcAfterBranch = nextPC + 2
        let pcTarget = UInt16(2 + Int(registerPC) + Int(Int8(bitPattern: nextByte)))
        return (pcTarget, pcTarget & 0xFF00 != pcAfterBranch & 0xFF00)
    }

    func fetchValue(_ op: i6502Specification.Operation) -> (value: UInt8, pageCrossed: Bool) {
        switch op.mode {
        case .immediate:
            (immediate(), false)
        case .zeroPage:
            (zeroPage(), false)
        case .zeroPageX:
            (zeroPageX(), false)
        case .zeroPageY:
            (zeroPageY(), false)
        case .absolute:
            (absolute(), false)
        case .absoluteX:
            absoluteX()
        case .absoluteY:
            absoluteY()
        case .indirectX:
            (indirectX(), false)
        case .indirectY:
            indirectY()
        case .accumulator:
            (registerA, false)
        case .implied, .indirect, .relative:
            preconditionFailure("Implied, indirect and relative addressing modes are handled separetly")
        }
    }

    func fetchAddress(_ op: i6502Specification.Operation) -> UInt16 {
        switch op.mode {
        case .zeroPage:
            return UInt16(nextByte)
        case .zeroPageX:
            return UInt16(nextByte &+ registerX)
        case .zeroPageY:
            return UInt16(nextByte &+ registerY)
        case .absolute:
            return nextWord
        case .absoluteX:
            return nextWord &+ UInt16(registerX)
        case .absoluteY:
            return nextWord &+ UInt16(registerY)
        case .indirectY:
            let lowAddress = nextByte
            let highAddress = lowAddress &+ 1
            let address = UInt16(memory[lowAddress]) + (UInt16(memory[highAddress]) << 8)
            return address &+ UInt16(registerY)
        case .indirectX:
            let lowAddress = nextByte &+ registerX
            let highAddress = lowAddress &+ 1
            return UInt16(memory[lowAddress]) + (UInt16(memory[highAddress]) << 8)
        default:
            preconditionFailure("No address fetching")
        }
    }

    private func immediate() -> UInt8 {
        nextByte
    }

    private func zeroPage() -> UInt8 {
        memory[nextByte]
    }

    private func zeroPageX() -> UInt8 {
        memory[nextByte &+ registerX]
    }

    private func zeroPageY() -> UInt8 {
        memory[nextByte &+ registerY]
    }

    private func absolute() -> UInt8 {
        memory[nextWord]
    }

    private func absoluteX() -> (value: UInt8, pageCrossed: Bool) {
        let addressX = nextWord &+ UInt16(registerX)
        return (memory[addressX], nextWord & 0xFF != addressX & 0xFF)
    }

    private func absoluteY() -> (value: UInt8, pageCrossed: Bool) {
        let addressY = nextWord &+ UInt16(registerY)
        return (memory[addressY], nextWord & 0xFF != addressY & 0xFF)
    }

    private func indirectX() -> UInt8 {
        let lowAddress = nextByte &+ registerX
        let highAddress = lowAddress &+ 1
        return memory[UInt16(memory[lowAddress]) + (UInt16(memory[highAddress]) << 8)]
    }

    private func indirectY() -> (value: UInt8, pageCrossed: Bool) {
        let lowAddress = nextByte
        let highAddress = lowAddress &+ 1
        let address = UInt16(memory[lowAddress]) + (UInt16(memory[highAddress]) << 8)
        let addressY = address &+ UInt16(registerY)
        return (memory[addressY], address & 0xFF != addressY & 0xFF)
    }

    // MARK: - Helping variables

    private var nextPC: UInt16 {
        registerPC + 1
    }

    private var nextByte: UInt8 {
        memory[nextPC]
    }

    private var nextWord: UInt16 {
        UInt16(nextByte) + (UInt16(memory[nextPC + 1]) << 8)
    }
}

extension Array {
    fileprivate subscript(_ index: UInt8) -> Element {
        self[Int(index)]
    }

    fileprivate subscript(_ index: Int8) -> Element {
        self[Int(UInt8(bitPattern: index))]
    }

    fileprivate subscript(_ index: UInt16) -> Element {
        self[Int(index)]
    }
}
