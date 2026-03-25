import Foundation
import i6502Specification

extension Emulator.StateImage {
    // Executes a "leading" cycle of operation and returns cycle length to skip
    public mutating func cycleInstructionAccurate() throws -> Int {
        guard let operation = Specification.translate(byte: memory[registerPC]) else {
            throw EmulatorError.stateCycleError(
                "Byte \(String(format: "%.2x", Int(memory[registerPC]))) is illegal opcode!"
            )
        }
        guard let baseTiming = operation.baseTiming else {
            throw EmulatorError.stateCycleError("No base timing for operation '\(operation)'")
        }

        let additionalTiming = switch (operation.symbol, operation.mode) {
        case (.brk, _), (.rti, _), (.rts, _), (.jsr, _), (.jmp, _):
            executeConrolFlowOperation(operation)

        case (_, .implied), (_, .accumulator):
            executeNoMemoryAccessOperation(operation)

        case (_, .relative):
            executeBranchesOperation(operation)

        case (.adc, _), (.sbc, _),
             (.and, _), (.ora, _), (.eor, _),
             (.cmp, _), (.cpx, _), (.cpy, _),
             (.lda, _), (.ldx, _), (.ldy, _),
             (.bit, _):
            executeReadAccessOperation(operation)

        case (.sta, _), (.stx, _), (.sty, _):
            executeWriteAccessOperation(operation)

        case (.rol, _), (.ror, _), (.lsr, _), (.asl, _),
             (.inc, _), (.dec, _):
            executeReadModifyWriteAccessOperation(operation)
        default:
            throw EmulatorError.stateCycleError("Unknown operation '\(operation)'")
        }
        return baseTiming + additionalTiming
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
