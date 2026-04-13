import i6502Specification

extension Emulator.StateImage {
    // Executes an operation that moves program counter
    // may use operand as address if necessary
    func executeBranchesOperation(
        _ op: Specification.DecodedInstruction
    ) -> Int {
        let isBranching = switch op.symbol {
        case .bpl:
            !registerPS.negative
        case .bmi:
            registerPS.negative
        case .bvc:
            !registerPS.overflow
        case .bvs:
            registerPS.overflow
        case .bcc:
            !registerPS.carry
        case .bcs:
            registerPS.carry
        case .bne:
            !registerPS.zero
        case .beq:
            registerPS.zero
        default:
            preconditionFailure("Unexpected operation '\(op.symbol)' inside branch execution")
        }
        guard isBranching else {
            registerPC += 2
            return 0
        }

        let (address, pageCrossed) = fetchRelativeBranch()
        registerPC = address
        return pageCrossed ? 2 : 1
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
