import i6502Specification
import Testing
@testable import i6502Assembler

@Suite
struct TranslatorTests {
    @Test("empty input")
    func empty() {
        #expect(throws: Never.self, "transaltion went successfully") {
            let resultBytes = try Translator.process([])
            let expectedBytes = memory()
            #expect(resultBytes == expectedBytes, "full memory is unallocated")
        }
    }

    @Test("empty directives")
    func emptyDirecties() {
        #expect(throws: Never.self, "transaltion went successfully") {
            let resultBytes = try Translator.process([
                .org(0xDEAD),
                .labelDeclaration(.init(name: "label", address: 0xDEAD))
            ])
            let expectedBytes = memory()
            #expect(resultBytes == expectedBytes, "full memory is unallocated")
        }
    }

    @Test(".org + .byte")
    func orgByte() {
        #expect(throws: Never.self, "transaltion went successfully") {
            let resultBytes = try Translator.process([
                .org(0xDEAD),
                .byte(0xFF)
            ])
            let expectedBytes = memory { bytes in
                bytes[0xDEAD] = 0xFF
            }
            #expect(resultBytes == expectedBytes, "memory is allocated with $FF at $DEAD")
        }
    }

    @Test(".org + .org + .byte")
    func orgOrgByte() {
        #expect(throws: Never.self, "transaltion went successfully") {
            let resultBytes = try Translator.process([
                .org(0xDEAD),
                .org(0x0123),
                .byte(0xFF)
            ])
            let expectedBytes = memory { bytes in
                bytes[0x123] = 0xFF
            }
            #expect(resultBytes == expectedBytes, "memory is allocated with $FF at $0123")
        }
    }

    @Test(".org + operation")
    func orgOperation() {
        #expect(throws: Never.self, "transaltion went successfully") {
            let resultBytes = try Translator.process([
                .org(0xDEAD),
                .operation(.init(code: .adc, argument: .immediate(0xAA), address: 0xDEAD))
            ])
            let expectedBytes = memory { bytes in
                bytes[0xDEAD] = 0x69
                bytes[0xDEAE] = 0xAA
            }
            #expect(resultBytes == expectedBytes, "memory is allocated with $69,$AA at $DEAD")
        }
    }

    @Test("failing unresolved reference")
    func failingUnresolvedReference() {
        #expect(throws: AssemblerError.translatorError("unresolved label \"unknown\" reference in absolute mode")) {
            try Translator.process([
                .operation(.init(code: .adc, argument: .absolute(.label("unknown")), address: 0xDEAD))
            ])
        }
    }

    @Test("failing illegal operation")
    func failingIllegalOperation() {
        #expect(
            throws: AssemblerError
                .translatorError("nop in immediate mode is illegal, use \".byte **\" if you are absolutely sure")
        ) {
            try Translator.process([
                .operation(.init(code: .nop, argument: .immediate(0xBB), address: 0xDEAD))
            ])
        }
    }

    // MARK: - bounds tests

    @Test("bounds byte")
    func boundsByte() {
        #expect(throws: Never.self, "translated \".byte\" on last memory cell") {
            let resultBytes = try Translator.process([
                .org(0xFFFF),
                .byte(0x10)
            ])
            let expectedBytes = memory { bytes in
                bytes[0xFFFF] = 0x10
            }
            #expect(resultBytes == expectedBytes, "memory is allocated with $10 at $FFFF")
        }
    }

    @Test("bounds implied operation")
    func boundsImplied() {
        #expect(throws: Never.self, "translated implied operation on last memory cell") {
            let resultBytes = try Translator.process([
                .org(0xFFFF),
                .operation(.init(code: .inx, argument: .implied, address: 0xFFFF))
            ])
            let expectedBytes = memory { bytes in
                bytes[0xFFFF] = 0xE8
            }
            #expect(resultBytes == expectedBytes, "memory is allocated with \"inx\" at $FFFF")
        }
    }

    @Test("bounds accumulator operation")
    func boundsAccumulator() {
        #expect(throws: Never.self, "translated implied operation on last memory cell") {
            let resultBytes = try Translator.process([
                .org(0xFFFF),
                .operation(.init(code: .asl, argument: .accumulator, address: 0xFFFF))
            ])
            let expectedBytes = memory { bytes in
                bytes[0xFFFF] = 0x0A
            }
            #expect(resultBytes == expectedBytes, "memory is allocated with \"asl a\" at $FFFF")
        }
    }

    @Test("bounds immediate operation")
    func boundsImmediate() {
        #expect(throws: Never.self, "translated implied operation on last memory cell") {
            let resultBytes = try Translator.process([
                .org(0xFFFE),
                .operation(.init(code: .adc, argument: .immediate(0x30), address: 0xFFFE))
            ])
            let expectedBytes = memory { bytes in
                bytes[0xFFFE] = 0x69
                bytes[0xFFFF] = 0x30
            }
            #expect(resultBytes == expectedBytes, "memory is allocated with \"adc #$30\" at $FFFF")
        }
    }

    @Test("bounds zero page operation")
    func boundsZeroPage() {
        #expect(throws: Never.self, "translated implied operation on last memory cell") {
            let resultBytes = try Translator.process([
                .org(0xFFFE),
                .operation(.init(code: .inc, argument: .zeroPage(0xFF), address: 0xFFFE))
            ])
            let expectedBytes = memory { bytes in
                bytes[0xFFFE] = 0xE6
                bytes[0xFFFF] = 0xFF
            }
            #expect(resultBytes == expectedBytes, "memory is allocated with \"inc $FF\" at $FFFF")
        }
    }

    @Test("bounds absolute operation")
    func boundsAbsolute() {
        #expect(throws: Never.self, "translated implied operation on last memory cell") {
            let resultBytes = try Translator.process([
                .org(0xFFFD),
                .operation(.init(code: .jmp, argument: .absolute(.number(.word(0xFFFD))), address: 0xFFFD))
            ])
            let expectedBytes = memory { bytes in
                bytes[0xFFFD] = 0x4C
                bytes[0xFFFE] = 0xFD
                bytes[0xFFFF] = 0xFF
            }
            #expect(resultBytes == expectedBytes, "memory is allocated with \"jmp $FFFD\" at $FFFD")
        }
    }

    @Test("bounds brk operation")
    func boundsBreak() {
        #expect(throws: Never.self, "translated implied operation on last memory cell") {
            let resultBytes = try Translator.process([
                .org(0xFFFE),
                .operation(.init(code: .brk, argument: .implied, address: 0xFFFE))
            ])
            let expectedBytes = memory { bytes in
                bytes[0xFFFE] = 0x00
            }
            #expect(resultBytes == expectedBytes, "memory is allocated with \"brk\" at $FFFE")
        }
    }

    @Test("bounds failing byte")
    func boundsFailingByte() {
        #expect(throws: AssemblerError.translatorError("\".byte\" on address $10000 is out of bounds")) {
            try Translator.process([
                .org(0xFFFF),
                .byte(0x10),
                .byte(0x11)
            ])
        }
    }

    @Test("failing failing word")
    func boundsFailingWord() {
        #expect(throws: AssemblerError.translatorError("\".word\" on address $ffff is out of bounds")) {
            try Translator.process([
                .org(0xFFFF),
                .word(0x1234)
            ])
        }
    }

    @Test("bounds failing implied operation")
    func boundsFailingImplied() {
        #expect(throws: AssemblerError.translatorError("\"iny\" in implied mode on address $10000 is out of bounds")) {
            try Translator.process([
                .org(0xFFFF),
                .operation(.init(code: .nop, argument: .implied, address: 0xFFFF)),
                .operation(.init(code: .iny, argument: .implied, address: 0xFFFF))
            ])
        }
    }

    @Test("bounds failing accumulator operation")
    func boundsFailingAccumulator() {
        #expect(
            throws: AssemblerError
                .translatorError("\"ror\" in accumulator mode on address $10000 is out of bounds")
        ) {
            try Translator.process([
                .org(0xFFFF),
                .operation(.init(code: .nop, argument: .implied, address: 0xFFFF)),
                .operation(.init(code: .ror, argument: .accumulator, address: 0xFFFF))
            ])
        }
    }

    @Test("bounds failing immediate operation")
    func boundsFailingImmediate() {
        #expect(throws: AssemblerError.translatorError("\"cmp\" in immediate mode on address $ffff is out of bounds")) {
            try Translator.process([
                .org(0xFFFF),
                .operation(.init(code: .cmp, argument: .immediate(0xFF), address: 0xFFFF))
            ])
        }
    }

    @Test("bounds failing zero page operation")
    func boundsFailingZeroPage() {
        #expect(throws: AssemblerError.translatorError("\"cpx\" in zeroPage mode on address $ffff is out of bounds")) {
            try Translator.process([
                .org(0xFFFF),
                .operation(.init(code: .cpx, argument: .zeroPage(0x67), address: 0xFFFF))
            ])
        }
    }

    @Test("bounds failing absolute operation")
    func boundsFailingAbsolute() {
        #expect(throws: AssemblerError.translatorError("\"dec\" in absolute mode on address $fffe is out of bounds")) {
            try Translator.process([
                .org(0xFFFE),
                .operation(.init(code: .dec, argument: .absolute(.number(.word(0x1000))), address: 0xFFFE))
            ])
        }
        #expect(throws: AssemblerError.translatorError("\"eor\" in absolute mode on address $ffff is out of bounds")) {
            try Translator.process([
                .org(0xFFFF),
                .operation(.init(code: .eor, argument: .absolute(.number(.word(0x1001))), address: 0xFFFF))
            ])
        }
    }

    @Test("bounds failing brk operation")
    func boundsFailingBreak() {
        #expect(throws: AssemblerError.translatorError("\"brk\" in implied mode on address $ffff is out of bounds")) {
            try Translator.process([
                .org(0xFFFF),
                .operation(.init(code: .brk, argument: .implied, address: 0xFFFF))
            ])
        }
    }

    private func memory(modifing: ((inout [UInt8?]) -> Void) = { _ in }) -> [UInt8?] {
        var memory = [UInt8?](repeating: nil, count: 65_536)
        modifing(&memory)
        return memory
    }
}

extension Array {
    private mutating func assign(at: Int = 0, _ value: Self) {
        for i in at ..< at + value.count {
            self[i] = value[i - at]
        }
    }
}
