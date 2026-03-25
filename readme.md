# imaginary 6502

A very basic imaginary computer with imaginary [MOS 6502](https://en.wikipedia.org/wiki/MOS_Technology_6502) in it

![Simulator demo](Resources/snake.gif)

**List of contents:**
* [i6502Core](#i6502Core) - 6502 Assembly & Emulator SPM package
* [i6502App](#i6502App) - iPhone, iPad and MacOS standalone app based on i6502Core

## i6502Core

### Assembler

Implements a tiny subset of [ca65](https://cc65.github.io/doc/ca65.html) assembler which is:
* All [60 legal opcodes](https://www.6502.org/tutorials/6502opcodes.html) with their addressing modes
* Label declaration and usage
* Decimal and hexidecimal literals (with zero page and absolute addressing distinction `lda $0010` vs `lda $10`)
* `.define` and single byte `.byte` assembler directives
* Line comments that start on ';'

![Assembler example](Resources/assembler-example.png)

*For debug purposes i6502Core package has "Main" i6502CLI target that spits compiled hexdump result for given file input*

### Simulator

Implemented an emulator state machine that works with 60 opcodes (illegal are not supported yet):
```Swift
let program = try Assembler.compileBytes(input: "...")
let simulator = Simulator(
    program: program,
    devices: [...]    // devices conforming PluggableDevice protocol emit values to memory
)

while true {
    try simulator.cycle()
}
```

## i6502App

i6502 app is featuring a live-reload 6502 assembly editor optimized for iPad and MacOS:

![Editor example](Resources/ipad-editor.png)

### Editor tab features:
* Dismissable hexdump inspector
* Syntax highlight
* Font size control
* Light and dark themes

### Emulator tab features:
* Tiny monochrome CRT 32x32 monitor
* DPAD and RESET buttons

### TBD:
* Illegal opcode execution
* Clock speed control (1Hz ... 1GHz)

## Useful links

* [Easy 6502](https://skilldrick.github.io/easy6502/) - smooth and short introduction to 6502 plus VERY useful playground
* [6502.org](https://www.6502.org/tutorials/6502opcodes.html) - table of official operation codes with comprehensive description
* [obelisk.me.uk](https://web.archive.org/web/20210626024532/http://www.obelisk.me.uk/6502/registers.html) - brief description of 6502 CPU registers
* [emulationonline.com](https://www.emulationonline.com/systems/nes/) - series of articles about NES emulation that based on 6502 architecture
* [nesdev.org](https://www.nesdev.org/wiki/NES_reference_guide) - NES-related wiki 
