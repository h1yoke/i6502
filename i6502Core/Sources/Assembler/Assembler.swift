import Foundation

public enum Assembler {
    public static func compileBytes(input: String) throws -> [UInt8] {
        var input = input

        try Preprocessor.process(input: &input)
        var tokens = try Tokenizer.process(input: &input)
        return try Complier.process(&tokens)
    }

    public static func compileData(input: String) throws -> Data {
        try Data(compileBytes(input: input))
    }
}

public enum AssemblerError: Error {
    case preprocessorError(String)
    case tokenizerError(String)
    case compilerError(String)
}
