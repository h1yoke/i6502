import i6502Assembler
import SwiftUI

#if !os(macOS)
import UIKit
#endif

struct HexdumpOverlayView: View {
    let originalText: String

    var body: some View {
        HexdumpView(originalText: originalText)
            .frame(maxWidth: 500, alignment: .topLeading)
            .backgroundiOSSpecific()
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .clipped()
            .shadow(radius: 10)
    }
}

struct HexdumpTabView: View {
    let originalText: String

    var body: some View {
        HexdumpView(originalText: originalText)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(red: 41 / 255.0, green: 42 / 255.0, blue: 47 / 255.0).ignoresSafeArea())
    }
}

private struct HexdumpView: View {
    let originalText: String

    private var hexdumpRepresentation: String {
        do {
            return try hexDump(Assembler.compileBytes(input: originalText))
        } catch let AssemblerError.preprocessorError(description) {
            return "Preprocessor error: \(description)"
        } catch let AssemblerError.tokenizerError(description) {
            return "Tokenizer error: \(description)"
        } catch let AssemblerError.compilerError(description) {
            return "Complier error: \(description)"
        } catch {
            return "Unknown error!"
        }
    }

    var body: some View {
        ScrollView {
            Text(hexdumpRepresentation)
                .padding()
                .font(.system(size: 14, design: .monospaced))
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func hexDump(_ bytes: [UInt8]) -> String {
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
    }
}

extension View {
    fileprivate func backgroundiOSSpecific() -> some View {
        self
        #if !os(macOS)
        .background(
            VisualEffectView(effect: UIBlurEffect.withRadius(3))
                .clipShape(RoundedRectangle(cornerRadius: 20))
        )
        #endif
    }
}

#if !os(macOS)
private struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?

    init(effect: UIVisualEffect?) {
        self.effect = effect
    }

    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) { uiView.effect = effect }
}

@objc private protocol UIBlurEffectWithRadius {
    func effect(withBlurRadius: Double) -> Self?
}

extension UIBlurEffect {
    fileprivate static func withRadius(_ radius: Double) -> UIBlurEffect? {
        if UIBlurEffect.responds(to: #selector(UIBlurEffectWithRadius.effect(withBlurRadius:))) {
            return UIBlurEffect.perform(#selector(UIBlurEffectWithRadius.effect(withBlurRadius:)))
                .takeUnretainedValue() as? UIBlurEffect
        }

        return nil
    }
}
#endif
