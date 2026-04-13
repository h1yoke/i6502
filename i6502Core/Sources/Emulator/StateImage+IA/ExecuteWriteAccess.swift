import i6502Specification

extension Emulator.StateImage {
    // Executes an operation that resolves operand to an address
    func executeWriteAccessOperation(
        _ op: Specification.DecodedInstruction
    ) -> Int {
        let resolvedAddress = fetchAddress(op)

        switch op.symbol {
        case .sta:
            memory[Int(resolvedAddress)] = registerA
        case .stx:
            memory[Int(resolvedAddress)] = registerX
        case .sty:
            memory[Int(resolvedAddress)] = registerY
        default:
            preconditionFailure("Expected a write access operation")
        }
        registerPC += op.length
        return 0
    }
}
