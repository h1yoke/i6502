import SwiftUI

struct BoardView: View {
    var factor: CGFloat = 1.0
    var onClockWireTap: () -> Void = {}

    @State private var clockFrequncy: Int = 1
    // 1 - 1Hz
    // 2 - 1000Hz
    // 3 - 5000Hz
    // 4 - 10000Hz
    // 5 - 25000Hz
    // 6 - 50000Hz
    // 7 - 100000Hz
    // 8 - 250000Hz
    // 9 - 500000Hz
    // 10 - 1MHz

    private let redColor = Color(red: 0.8, green: 0.25, blue: 0.29)
    private let wireColor = Color(red: 0.5, green: 0.55, blue: 0.59)

    var body: some View {
        TimelineView(.animation) { _ in
            HStack(alignment: .top) {
                Rectangle()
                    .fill(redColor)
                    .frame(width: factor * 2, height: factor * 500)
                    .padding(.trailing, 30)
                    .shadow(color: redColor, radius: 8)
                    .shadow(color: redColor, radius: 16)
                    .shadow(color: redColor.opacity(0.5), radius: 32)

                CPUChipView(factor: factor)
                    .overlay(alignment: .topTrailing) {
                        Rectangle()
                            .fill(wireColor)
                            .frame(width: factor * 75, height: factor * 2)
                            .offset(x: factor * 80, y: factor * 42)
                            .modifier(ClockGlowModifier(frequency: clockFrequncy))
                    }
                    .overlay(alignment: .topLeading) {
                        Rectangle()
                            .fill(redColor)
                            .frame(width: factor * 20, height: factor * 2)
                            .offset(x: factor * -25, y: factor * 144)
                            .shadow(color: redColor, radius: 8)
                            .shadow(color: redColor, radius: 16)
                            .shadow(color: redColor.opacity(0.5), radius: 32)
                    }
                    .padding(.top, factor * 100)
                    .zIndex(1)

                ClockChipView(factor: factor, clockFrequency: $clockFrequncy)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(redColor)
                            .frame(width: factor * 2, height: factor * 12)
                            .offset(x: factor * 15.35, y: factor * 15)
                            .shadow(color: redColor, radius: 8)
                            .shadow(color: redColor, radius: 16)
                            .shadow(color: redColor.opacity(0.5), radius: 32)
                            .zIndex(-1)

                        Rectangle()
                            .fill(redColor)
                            .frame(width: factor * 222.5, height: factor * 2)
                            .offset(x: factor * -95, y: factor * 20)
                            .shadow(color: redColor, radius: 8)
                            .shadow(color: redColor, radius: 16)
                            .shadow(color: redColor.opacity(0.5), radius: 32)
                            .zIndex(-1)
                    }
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(wireColor)
                            .frame(width: factor * 2, height: factor * 42)
                            .offset(y: factor * 44)
                            .modifier(ClockGlowModifier(frequency: clockFrequncy))
                    }
            }
            .padding()
        }
    }
}

private struct ClockGlowModifier: ViewModifier {
    let frequency: Int
    @State private var lastPulseDate: Date = .now

    func body(content: Content) -> some View {
        if frequency == 1 {
            TimelineView(.animation) { timeline in
                content
                    .shadow(color: shouldPulse(timeline.date) ? wireColor : .clear, radius: 8)
                    .shadow(color: shouldPulse(timeline.date) ? wireColor : .clear, radius: 16)
                    .shadow(color: shouldPulse(timeline.date) ? wireColor.opacity(0.5) : .clear, radius: 32)
                    .animation(.default, value: shouldPulse(timeline.date))
            }
        } else if frequency > 1 {
            content
                .shadow(color: wireColor, radius: 8)
                .shadow(color: wireColor, radius: 16)
                .shadow(color: wireColor, radius: 32)
        } else {
            content
        }
    }

    private let wireColor = Color(red: 0.5, green: 0.55, blue: 0.59)

    private func shouldPulse(_ date: Date) -> Bool {
        Int(date.timeIntervalSince1970 * 2) % 2 == 0
    }

}

#Preview {
    @Previewable @AppStorage("AppTheme") var appTheme: AppTheme = .defaultDark

    ZStack {
        appTheme.palette.backgroundPrimary.ignoresSafeArea()

        BoardView(factor: 1.5)
        // .border(.black)
    }
}
