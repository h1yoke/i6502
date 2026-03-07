import Foundation
import i6502Assembler

@main
struct Main {
    static func main() throws {
        guard CommandLine.arguments.count > 1,
              FileManager.default.isReadableFile(atPath: CommandLine.arguments[1]),
              let sourceData = try? Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])),
              let sourceCode = String(data: sourceData, encoding: .utf8)
        else {
            print(CommandLine.arguments)
            return
        }

        let bytecode = try Assembler.compileBytes(input: sourceCode)
        hexDump(bytecode)
    }

    private static func hexDump(_ bytes: [UInt8]) {
        print(
            bytes
                .enumerated()
                .map { index, byte in
                    var newLine = ""
                    if index % 16 == 0 {
                        if index != 0 {
                            newLine += "\n"
                        }
                        newLine += String(format: "%.4x: ", 0x0600 + index)
                    }
                    return newLine + String(format: "%.2x", byte)
                }
                .joined(separator: " ")
        )
    }
}
