import SwiftUI

struct ResetChipView: View {
    var factor: CGFloat = 1.0
    let onTap: () -> Void

    var body: some View {
        ZStack {
            Button(action: onTap) {
                Text("RESET")
                    .font(.system(size: factor * 10, design: .monospaced)).bold()
                    .padding(factor * 16)
            }
            .buttonStyle(.plain)
            .contentShape(.circle)
            .glassEffect(.regular.tint(.red.opacity(0.2)).interactive(), in: Circle())
            .clipShape(Circle())
        }
        .font(.system(size: factor * 10, design: .monospaced)).bold()
        .foregroundStyle(Color(red: 0.5, green: 0.55, blue: 0.59))
        .frame(width: factor * 75, height: factor * 55)
        .backgroundiOSSpecific(cornerRadius: 12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .clipped()
        .shadow(radius: 10)
        .background {
            HStack(spacing: factor * 65) {
                Rectangle()
                    .fill(Color(red: 0.5, green: 0.55, blue: 0.59))
                    .frame(width: factor * 10, height: factor * 2)

                Rectangle()
                    .fill(Color(red: 0.5, green: 0.55, blue: 0.59))
                    .frame(width: factor * 10, height: factor * 2)
            }
        }
        .overlay {
            HStack(spacing: factor * 55) {
                Text("OUT")
                Text("IN")
            }
            .font(.system(size: factor * 5, design: .monospaced))
            .foregroundStyle(Color(red: 0.5, green: 0.55, blue: 0.59))
        }
    }
}

#Preview {
    @Previewable @AppStorage("AppTheme") var appTheme: AppTheme = .defaultDark

    ZStack {
        appTheme.palette.backgroundPrimary.ignoresSafeArea()

        ResetChipView {}
            .border(.red)
    }
}

extension View {
    fileprivate func backgroundiOSSpecific(cornerRadius: CGFloat) -> some View {
        self
        #if !os(macOS)
        .background(
            VisualEffectView(effect: UIBlurEffect.withRadius(3))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
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
