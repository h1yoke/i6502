import SwiftUI

struct ClockChipView: View {
    @AppStorage("AppTheme") private var appTheme: AppTheme = .defaultDark

    var factor: CGFloat = 1.0
    @Binding var clockFrequency: Int

    var body: some View {
        HStack {
            Color.clear
                .backgroundiOSSpecific(cornerRadius: 12)
                .overlay(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)

                        Text("i555")
                            .rotationEffect(Angle(degrees: -90))
                            .font(.system(size: factor * 10, design: .monospaced)).bold()
                            .foregroundStyle(Color(red: 0.5, green: 0.55, blue: 0.59))
                    }
                )
                .clipped()
                .shadow(radius: 10)
                .frame(width: factor * 50, height: factor * 75)
                .padding()
                .background {
                    HStack(spacing: factor * 40) {
                        VStack(spacing: factor * 15) {
                            ForEach(0 ..< 4) { _ in
                                Rectangle()
                                    .fill(Color(red: 0.5, green: 0.55, blue: 0.59))
                                    .frame(width: factor * 10, height: factor * 2)
                            }
                        }
                        VStack(spacing: factor * 15) {
                            ForEach(0 ..< 4) { _ in
                                Rectangle()
                                    .fill(Color(red: 0.5, green: 0.55, blue: 0.59))
                                    .frame(width: factor * 10, height: factor * 2)
                            }
                        }
                    }
                }

            Slider(
                value: .init(
                    get: { Float(clockFrequency) },
                    set: { clockFrequency = Int($0) }
                ),
                in: 0.0 ... 10.0,
                step: 1.0
            )
            .frame(width: factor * 150)
            .rotationEffect(Angle(degrees: -90))
            .scaleEffect(0.5)
            .frame(width: factor * 15)
            .padding()
            .tint(Color(red: 0.5, green: 0.55, blue: 0.59))
        }
        .backgroundiOSSpecific()
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .clipped()
        .shadow(radius: 10)
        .frame(width: factor * 150, height: factor * 100)
        .overlay {
            HStack(spacing: factor * 6) {
                Text("GND")
                Text("OUT")
                Text("VCC")
            }
            .font(.system(size: factor * 5, design: .monospaced))
            .foregroundStyle(Color(red: 0.5, green: 0.55, blue: 0.59))
            .offset(y: factor * 45)
        }
        .background {
            HStack(spacing: 20) {
                ForEach(0 ..< 3) { _ in
                    Rectangle()
                        .fill(Color(red: 0.5, green: 0.55, blue: 0.59))
                        .frame(width: factor * 2, height: factor * 10)
                }
            }
            .offset(y: factor * 48)
        }
    }
}

#Preview {
    @Previewable @AppStorage("AppTheme") var appTheme: AppTheme = .defaultDark
    @Previewable @State var clockFrequency: Int = 2

    ZStack {
        appTheme.palette.backgroundPrimary.ignoresSafeArea()

        ClockChipView(factor: 1.5, clockFrequency: $clockFrequency)
            .border(.red)
    }
}

extension View {
    fileprivate func backgroundiOSSpecific(cornerRadius: CGFloat = 20) -> some View {
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
