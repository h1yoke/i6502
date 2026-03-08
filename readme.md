# i6502

## List of contents

* [i6502Core](#i6502Core) - 6502 Assembly & Emulator SPM package
* [i6502App](#i6502App) - iPhone, iPad and MacOS standalone app based on i6502Core

## i6502Core

### Assembler

Implements a tiny subset of [ca65](https://cc65.github.io/doc/ca65.html) assembler which is:
* All [60 opcodes](https://www.6502.org/tutorials/6502opcodes.html) with their addressing modes
* Label declaration and usage
* Decimal and hexidecimal literals
* `.define` and single byte `.byte` assembler directives
* Line comments that start on ';'

![Assembler example](Resources/assembler-example.png)

For debug purposes i6502Core package has "Main" i6502CLI target that spits compiled hexdump result for given file input

### Simulator

TBD!

## i6502App

i6502 app is featuring a live-reload 6502 assembly editor optimized for iPad and MacOS:

![Editor example](Resources/ipad-editor.png)

### Editor tab features:
* Dismissable hexdump inspector
* Syntax highlight
* Font size control
* Light and dark themes

### Emulator tab TBD features:
* Bytecode disassembler with debugger 
* RAM table monitor ($0000..$FFFF)
* Pixel display, corresponding for RAM section
* Keyboard and possibly other controls

*very self-confident*

## Useful links

* [Easy 6502](https://skilldrick.github.io/easy6502/) - smooth and short introduction to 6502 plus VERY useful playground
* [6502.org](https://www.6502.org/tutorials/6502opcodes.html) - table of official operation codes with comprehensive description
* [emulationonline.com](https://www.emulationonline.com/systems/nes/) - series of articles about NES emulation that based on 6502 architecture
* [nesdev.org](https://www.nesdev.org/wiki/NES_reference_guide) - NES-related wiki 
