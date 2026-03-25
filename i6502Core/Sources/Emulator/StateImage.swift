
extension Emulator {
    public struct StateImage {
        public var registerPC: UInt16
        public var registerSP: UInt8
        public var registerA: UInt8
        public var registerX: UInt8
        public var registerY: UInt8
        public var registerPS: ProcessorStatus
        public var memory: [UInt8] // 64 KiB

        public init(
            registerPC: UInt16,
            registerSP: UInt8,
            registerA: UInt8,
            registerX: UInt8,
            registerY: UInt8,
            registerPS: UInt8,
            memory: [UInt8]
        ) {
            self.registerPC = registerPC
            self.registerSP = registerSP
            self.registerA = registerA
            self.registerX = registerX
            self.registerY = registerY
            self.registerPS = registerPS
            self.memory = memory
        }

        public init() {
            self.init(
                registerPC: 0x0600,
                registerSP: 0xFF,
                registerA: 0,
                registerX: 0,
                registerY: 0,
                registerPS: 0b0011_0000,
                memory: Array(repeating: 0, count: 65_536)
            )
        }
    }

    public typealias ProcessorStatus = UInt8
}

extension Emulator.ProcessorStatus {
    public var negative: Bool {
        get { (self & 0b1000_0000) >> 7 == 1 }
        set {
            if newValue {
                self |= (1 << 7)
            } else {
                self &= ~(1 << 7)
            }
        }
    }

    public var overflow: Bool {
        get { (self & 0b1000000) >> 6 == 1 }
        set {
            if newValue {
                self |= (1 << 6)
            } else {
                self &= ~(1 << 6)
            }
        }
    }

    public var skip: Bool { true }

    public var `break`: Bool {
        get { (self & 0b10000) >> 4 == 1 }
        set {
            if newValue {
                self |= (1 << 4)
            } else {
                self &= ~(1 << 4)
            }
        }
    }

    public var decimal: Bool {
        get { (self & 0b1000) >> 3 == 1 }
        set {
            if newValue {
                self |= (1 << 3)
            } else {
                self &= ~(1 << 3)
            }
        }
    }

    public var interrupt: Bool {
        get { (self & 0b100) >> 2 == 1 }
        set {
            if newValue {
                self |= (1 << 2)
            } else {
                self &= ~(1 << 2)
            }
        }
    }

    public var zero: Bool {
        get { (self & 0b10) >> 1 == 1 }
        set {
            if newValue {
                self |= (1 << 1)
            } else {
                self &= ~(1 << 1)
            }
        }
    }

    public var carry: Bool {
        get { (self & 0b1) == 1 }
        set {
            if newValue {
                self |= (1 << 0)
            } else {
                self &= ~(1 << 0)
            }
        }
    }
}
