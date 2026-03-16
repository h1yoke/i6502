import i6502Emulator
import SwiftUI

// emits a random byte value
class RandomizerDevice: PluggableDevice {
    var addresses: ClosedRange<Int> = 0xFE ... 0xFE
    var lastEmitted: UInt8 = 0

    func emit() -> [UInt8] {
        lastEmitted = UInt8.random(in: 0 ... 0xFF)
        return [lastEmitted]
    }

    func recieve(section: [UInt8]) {}
}

// emits an ASCII value of currently pressed key
class KeyboardDevice: PluggableDevice {
    var addresses: ClosedRange<Int> = 0xFF ... 0xFF
    var pressed: UInt8? = nil

    func emit() -> [UInt8] {
        [pressed ?? 0]
    }

    func recieve(section: [UInt8]) {}
}

struct EmulatorView: View {
    @State private var monitor: [UInt8]
    @State private var keyboard: KeyboardDevice
    @State private var randomizer: RandomizerDevice
    @State private var emulator: Emulator

    @State private var reset: Bool = false

    let pixelSize: CGFloat = 20
    let cyclesPerFrame = 16_667 // 1 MHz
    let program: [UInt8]

    init(program: [UInt8]) {
        self.program = program

        monitor = Array(repeating: 0, count: 1_024)
        keyboard = KeyboardDevice()
        randomizer = RandomizerDevice()
        emulator = Emulator(
            emulationMode: .instructionAccurate,
            devices: [_randomizer.wrappedValue, _keyboard.wrappedValue]
        )
    }

    var body: some View {
        ZStack {
            Color.gray.ignoresSafeArea()

            TimelineView(.animation) { timeline in
                Canvas { context, _ in
                    for i in 0 ..< 1_024 {
                        let x = CGFloat(i % 32) * pixelSize
                        let y = CGFloat(i / 32) * pixelSize
                        let rect = CGRect(x: x, y: y, width: pixelSize, height: pixelSize)
                        let color: Color = monitor[i] != 0 ? .white : .black
                        context.fill(Path(rect), with: .color(color))
                    }
                }
                .frame(width: 32 * pixelSize, height: 32 * pixelSize)
                .onChange(of: timeline.date) {
                    if reset {
                        emulator = Emulator(
                            program: program,
                            emulationMode: .instructionAccurate,
                            devices: [randomizer, keyboard]
                        )
                        reset = false
                    } else {
                        // unthrottling CPU from 60Hz to 1MHz clock rate
                        for _ in 0 ..< cyclesPerFrame / 80 {
                            try? emulator.cycle()
                        }
                        // updating monitor only in 60Hz
                        monitor = Array(emulator.state.memory[0x200 ... 0x5FF])
                    }
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            VStack {
                Button { keyboard.pressed = 0x77 } label: {
                    Text("W")
                        .frame(width: 75, height: 75)
                }
                HStack {
                    Button { keyboard.pressed = 0x61 } label: {
                        Text("A")
                            .frame(width: 75, height: 75)
                    }
                    Button { keyboard.pressed = 0x73 } label: {
                        Text("S")
                            .frame(width: 75, height: 75)
                    }
                    Button { keyboard.pressed = 0x64 } label: {
                        Text("D")
                            .frame(width: 75, height: 75)
                    }
                }
            }
            .buttonStyle(.glass)
            .padding()
        }
        .overlay(alignment: .bottomLeading) {
            Button { reset = true } label: {
                Text("RESET")
                    .frame(width: 75, height: 75)
            }
            .buttonStyle(.glass)
            .padding()
        }
    }
}
