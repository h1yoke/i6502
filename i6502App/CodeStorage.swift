import Observation

@Observable
class CodeStorage {
    var code: String

    init() {
        code = Self.entryPointProgram
    }
}

extension CodeStorage {
    // boiler-plate code that binds all interrupts and clears a screen
    private static let entryPointProgram: String = """
    ; Memory map
    .define SCREEN  $0200
    .define NMI     $0600
    .define IRQ     $0700
    .define ENTRY   $0800

    ; Bind interrupt handlers
    .org $FFFA
      .word NMI    ; $FFFA-$FFFB: NMI handler address
      .word ENTRY  ; $FFFC-$FFFD: RESET (program entry point) handler address
      .word IRQ    ; $FFFE-$FFFF: IRQ/brk handler address

    ; Non-maskable interrupt
    .org NMI
      rti

    ; IRQ/BRK interrupt
    .org IRQ
      rti

    ; Program entry point
    .org ENTRY
      cld
      clv
      jsr clean
    end:
      bvc end

    ; Clean screen subroutine
    clean:
      lda #$00
      ldx #$00
    _clear_loop:
      sta $0200,x
      sta $0300,x
      sta $0400,x
      sta $0500,x
      inx
      bne _clear_loop
      rts
    """
}
