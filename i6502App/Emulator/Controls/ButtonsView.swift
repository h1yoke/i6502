import SwiftUI

struct ButtonsView: View {
    let reset: () -> Void
    let action: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            Color(red: 157 / 255.0, green: 35 / 255.0, blue: 45 / 255.0)
                .opacity(0.8)
                .backgroundiOSSpecific()
                .frame(width: 120, height: 120)
                .contentShape(.circle)
                .clipShape(Circle())
                .onTapGesture(perform: reset)
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.2))
                )

            Color(red: 157 / 255.0, green: 35 / 255.0, blue: 45 / 255.0)
                .opacity(0.8)
                .backgroundiOSSpecific()
                .frame(width: 120, height: 120)
                .contentShape(.circle)
                .clipShape(Circle())
                .onTapGesture(perform: action)
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.2))
                )
        }
    }
}

#Preview {
    @Previewable @AppStorage("AppTheme") var appTheme: AppTheme = .defaultDark

    ZStack {
        appTheme.palette.backgroundPrimary.ignoresSafeArea()

        ButtonsView(reset: {}, action: {})
            .border(.red)
    }
}

extension View {
    fileprivate func backgroundiOSSpecific() -> some View {
        self
        #if !os(macOS)
        .background(
            VisualEffectView(effect: UIBlurEffect.withRadius(3))
                .clipShape(Circle())
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
