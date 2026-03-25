import SwiftUI

struct CPUChipView: View {
    var factor: CGFloat = 1.0

    var body: some View {
        VStack(spacing: factor * 65) {
            Circle()
                .fill(.clear)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: factor * 15)

            Text("i6502")
                .foregroundStyle(Color(red: 0.5, green: 0.55, blue: 0.59))
                .font(.system(size: factor * 10, design: .monospaced)).bold()
                .rotationEffect(Angle(degrees: -90))

            Circle()
                .fill(.clear)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: factor * 15)
        }
        .frame(width: factor * 100, height: factor * 375)
        .backgroundiOSSpecific()
        .overlay(
            NotchedRoundedRect(notchRadius: 12)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .clipped()
        .shadow(radius: 10)
        .background {
            HStack(spacing: factor * 90) {
                VStack(spacing: factor * 15) {
                    ForEach(0 ..< 20) { _ in
                        Rectangle()
                            .fill(Color(red: 0.5, green: 0.55, blue: 0.59))
                            .frame(width: factor * 10, height: factor * 2)
                    }
                }
                VStack(spacing: factor * 15) {
                    ForEach(0 ..< 20) { _ in
                        Rectangle()
                            .fill(Color(red: 0.5, green: 0.55, blue: 0.59))
                            .frame(width: factor * 10, height: factor * 2)
                    }
                }
            }
        }
        .overlay {
            HStack(spacing: factor * 70) {
                VStack(spacing: factor * 11) {
                    ForEach(Array(leadingPins.enumerated()), id: \.offset) { _, pin in
                        Text(pin)
                            .frame(width: factor * 13, alignment: .leading)
                    }
                }
                VStack(spacing: factor * 11) {
                    ForEach(Array(trailingPins.enumerated()), id: \.offset) { _, pin in
                        Text(pin)
                            .frame(width: factor * 13, alignment: .trailing)
                    }
                }
            }
            .font(.system(size: factor * 5, design: .monospaced))
            .foregroundStyle(Color(red: 0.5, green: 0.55, blue: 0.59))
        }
    }

    private let leadingPins: [String] = [
        "GND", "RDY", "Φ1", "/IRQ", "NC", "/NMI", "Sync", "VCC",
        "A0", "A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8",
        "A9", "A10", "A11"
    ]

    private let trailingPins: [String] = [
        "/RES", "Φ2", "SO", "Φ0", "NC", "NC", "R/W",
        "D0", "D1", "D2", "D3", "D4", "D5", "D6", "D7",
        "A15", "A14", "A13", "A12", "GND"
    ]
}

#Preview {
    @Previewable @AppStorage("AppTheme") var appTheme: AppTheme = .defaultDark

    ZStack {
        appTheme.palette.backgroundPrimary.ignoresSafeArea()

        CPUChipView()
            .border(.red)
    }
}

extension View {
    fileprivate func backgroundiOSSpecific() -> some View {
        self
        #if !os(macOS)
        .background(
            VisualEffectView(effect: UIBlurEffect.withRadius(3))
                .clipShape(NotchedRoundedRect())
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

struct NotchedRoundedRect: InsettableShape {
    var cornerRadius: CGFloat = 12
    var notchRadius: CGFloat = 12
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> NotchedRoundedRect {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)

        let cr = max(cornerRadius - insetAmount, 0)
        let nr = max(notchRadius - insetAmount, 0)
        let midX = r.midX

        var path = Path()

        path.move(to: CGPoint(x: r.minX + cr, y: r.minY))

        path.addLine(to: CGPoint(x: midX - nr, y: r.minY))

        path.addArc(
            center: CGPoint(x: midX, y: r.minY),
            radius: nr,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: true
        )

        path.addLine(to: CGPoint(x: r.maxX - cr, y: r.minY))

        path.addArc(
            center: CGPoint(x: r.maxX - cr, y: r.minY + cr),
            radius: cr,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: r.maxX, y: r.maxY - cr))

        path.addArc(
            center: CGPoint(x: r.maxX - cr, y: r.maxY - cr),
            radius: cr,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: r.minX + cr, y: r.maxY))

        path.addArc(
            center: CGPoint(x: r.minX + cr, y: r.maxY - cr),
            radius: cr,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: r.minX, y: r.minY + cr))

        path.addArc(
            center: CGPoint(x: r.minX + cr, y: r.minY + cr),
            radius: cr,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        path.closeSubpath()
        return path
    }
}
