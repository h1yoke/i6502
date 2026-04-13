
// Protocol for pluggable devices such as monitors, keyboards, randomizers etc.
public protocol PluggableDevice: Sendable {
    // Device memory section start and end addresses
    var addresses: ClosedRange<Int> { get }

    // Called at the start of CPU cycle and writes emitted values to assigned section
    func emit() -> [UInt8]

    // Called at the end of CPU cycle and recieves values from assigned section
    func recieve(section: [UInt8])

    // Checked at the start of CPU cycle and performs IRQ chores if I flag is set
    var irqRequired: Bool { get set }

    // Checked at the start of CPU cycle and performs NMI chores
    var nmiRequired: Bool { get set }
}

public enum EmulationMode {
    case instructionAccurate
    case cycleAccurate
}

public struct Emulator {
    public private(set) var emulationMode: EmulationMode
    public private(set) var state: StateImage = .init()
    public private(set) var devices: [PluggableDevice] = []
    private var remainingCycles: Int = 0

    public init(
        memory: [UInt8?] = [nil],
        emulationMode: EmulationMode = .instructionAccurate,
        devices: [PluggableDevice]
    ) {
        state.memory.assign(at: 0 ... memory.count - 1, memory)

        self.emulationMode = emulationMode
        self.devices = devices
    }

    public mutating func cycle() {
        switch emulationMode {
        case .instructionAccurate:
            cycleInstructionAccurate()
        case .cycleAccurate:
            break
        }
    }

    // Emulates RESET pin activation
    public mutating func reset() {
        remainingCycles = state.resetInstructionAccurate()
    }

    private mutating func cycleInstructionAccurate() {
        guard remainingCycles == 0 else {
            remainingCycles -= 1
            return
        }

        // handle devices emits
        /*
         for device in devices {
             try? state.memory.assign(at: device.addresses, device.emit())
         }
          */

        // handle interrupts and operation execution on cycle #1
        if devices.contains(where: \.nmiRequired) {
            remainingCycles = state.nmiInstructionAccurate()
        } else if !state.registerPS.interrupt, devices.contains(where: \.irqRequired) {
            remainingCycles = state.irqInstructionAccurate()
        } else {
            remainingCycles = state.cycleInstructionAccurate()
        }

        // handle devices recieves
        /*
          for device in devices {
             guard state.memory.indices.contains(device.addresses) else {
                 throw EmulatorError.deviceError(
                     "Device recieving addresses [\(device.addresses)] are not compatible with ram [0..65535]"
                 )
             }
             device.recieve(section: Array(state.memory[device.addresses]))
         }
          */
    }
}

public enum EmulatorError: Error {
    case unsupportedEmulationModeError(String)
    case deviceError(String)
    case stateCycleError(String)
}

extension UnsafeMutableBufferPointer {
    fileprivate func assign(at range: ClosedRange<Int>, _ value: [Element?]) {
        guard range.count == value.count else {
            return
        }
        for i in range {
            if let value = value[i - range.lowerBound] {
                self[i] = value
            }
        }
    }
}
