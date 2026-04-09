import i6502Specification
import Testing
@testable import i6502Assembler

@Suite
struct AssemblerTests {
    @Test("basic")
    func basic() {
        #expect(throws: Never.self, "compiled without errors") {
            let resultBytes = try Assembler.compileBytes(
                input: """
                lda #$01
                sta $0200
                lda #$05
                sta $0201
                lda #$08
                sta $0202
                """
            )
            let expectedBytes = memory { bytes in
                bytes.assign([
                    0xA9, 0x01,
                    0x8D, 0x00, 0x02,
                    0xA9, 0x05,
                    0x8D, 0x01, 0x02,
                    0xA9, 0x08,
                    0x8D, 0x02, 0x02
                ])
            }
            #expect(resultBytes == expectedBytes, "assembler compiled input as expected")
        }
    }

    @Test("empty")
    func empty() {
        #expect(throws: Never.self, "compiled empty input without errors") {
            let resultBytes = try Assembler.compileBytes(input: "")
            let expectedBytes = memory()
            #expect(resultBytes == expectedBytes, "assembler compiled input as expected")
        }
    }

    @Test("64KiB")
    func filled64Kib() {
        #expect(throws: Never.self, "compiled 64KiB input without errors") {
            let resultBytes = try Assembler.compileBytes(
                input: Array(repeating: "nop", count: 65_536).joined(separator: " ")
            )
            let expectedBytes = [UInt8?](repeating: 0xEA, count: 65_536)
            #expect(resultBytes == expectedBytes, "assembler compiled input as expected")
        }
    }

    @Test("interrupt handling")
    func interruptHandling() {
        #expect(throws: Never.self, "compiled without errors") {
            let resultBytes = try Assembler.compileBytes(input: withInterruptHandling)
            let expectedBytes = memory { bytes in
                // NMI, RESET and IRQ handler references
                bytes.assign(at: 0xFFFA, [0x00, 0x10, 0x00, 0x20, 0x00, 0x30])

                // NMI handler
                bytes.assign(at: 0x1000, [0x6C, 0xFE, 0xFF])

                // RESET handler
                bytes.assign(at: 0x2000, [
                    0xB8, // clv
                    0xA5, 0x00, // lda $00
                    0xC9, 0xAD, // cmp #$AD
                    0xD0, 0x04, // bne +4
                    0xE6, 0x01, // inc $01
                    0x50, 0x08, // bvc +8
                    0xA9, 0xAD, // lda #$AD
                    0x85, 0x00, // sta $00
                    0xA9, 0, // lda #0
                    0x85, 0x01, // sta $01
                    0xA9, 0xFF, // lda #$FF
                    0xA4, 0x01, // ldy $01
                    0x99, 0x00, 0x02, // sta SCREEN,y
                    0x50, 0xF7 // bvc -8
                ])

                // IRQ handler
                bytes.assign(at: 0x3000, [
                    0xA9, 0xFF, // lda #$FF
                    0xA2, 0x00, // ldx #0
                    0x9D, 0x00, 0x02, // sta SCREEN,x
                    0xE8, // inx
                    0xE0, 32, // cpx #32
                    0xD0, 0xF8, // bne -7
                    0x40 // rti
                ])
            }

            #expect(resultBytes == expectedBytes, "assembler compiled input as expected")
        }
    }

    @Test("easy6502 snake game")
    func assemblerSnake() {
        #expect(throws: Never.self, "compiled easy6502 snake without errors") {
            let resultBytes = try Assembler.compileBytes(input: skillDrickSnakeGame)
            // expected bytes from easy6502 hexdump
            let expectedBytes = memory { bytes in
                bytes.assign(
                    at: 0x0600, [
                        0x20, 0x06, 0x06, 0x20, 0x38, 0x06, 0x20, 0x0D, 0x06, 0x20, 0x2A, 0x06, 0x60, 0xA9, 0x02, 0x85,
                        0x02, 0xA9, 0x04, 0x85, 0x03, 0xA9, 0x11, 0x85, 0x10, 0xA9, 0x10, 0x85, 0x12, 0xA9, 0x0F, 0x85,
                        0x14, 0xA9, 0x04, 0x85, 0x11, 0x85, 0x13, 0x85, 0x15, 0x60, 0xA5, 0xFE, 0x85, 0x00, 0xA5, 0xFE,
                        0x29, 0x03, 0x18, 0x69, 0x02, 0x85, 0x01, 0x60, 0x20, 0x4D, 0x06, 0x20, 0x8D, 0x06, 0x20, 0xC3,
                        0x06, 0x20, 0x19, 0x07, 0x20, 0x20, 0x07, 0x20, 0x2D, 0x07, 0x4C, 0x38, 0x06, 0xA5, 0xFF, 0xC9,
                        0x77, 0xF0, 0x0D, 0xC9, 0x64, 0xF0, 0x14, 0xC9, 0x73, 0xF0, 0x1B, 0xC9, 0x61, 0xF0, 0x22, 0x60,
                        0xA9, 0x04, 0x24, 0x02, 0xD0, 0x26, 0xA9, 0x01, 0x85, 0x02, 0x60, 0xA9, 0x08, 0x24, 0x02, 0xD0,
                        0x1B, 0xA9, 0x02, 0x85, 0x02, 0x60, 0xA9, 0x01, 0x24, 0x02, 0xD0, 0x10, 0xA9, 0x04, 0x85, 0x02,
                        0x60, 0xA9, 0x02, 0x24, 0x02, 0xD0, 0x05, 0xA9, 0x08, 0x85, 0x02, 0x60, 0x60, 0x20, 0x94, 0x06,
                        0x20, 0xA8, 0x06, 0x60, 0xA5, 0x00, 0xC5, 0x10, 0xD0, 0x0D, 0xA5, 0x01, 0xC5, 0x11, 0xD0, 0x07,
                        0xE6, 0x03, 0xE6, 0x03, 0x20, 0x2A, 0x06, 0x60, 0xA2, 0x02, 0xB5, 0x10, 0xC5, 0x10, 0xD0, 0x06,
                        0xB5, 0x11, 0xC5, 0x11, 0xF0, 0x09, 0xE8, 0xE8, 0xE4, 0x03, 0xF0, 0x06, 0x4C, 0xAA, 0x06, 0x4C,
                        0x35, 0x07, 0x60, 0xA6, 0x03, 0xCA, 0x8A, 0xB5, 0x10, 0x95, 0x12, 0xCA, 0x10, 0xF9, 0xA5, 0x02,
                        0x4A, 0xB0, 0x09, 0x4A, 0xB0, 0x19, 0x4A, 0xB0, 0x1F, 0x4A, 0xB0, 0x2F, 0xA5, 0x10, 0x38, 0xE9,
                        0x20, 0x85, 0x10, 0x90, 0x01, 0x60, 0xC6, 0x11, 0xA9, 0x01, 0xC5, 0x11, 0xF0, 0x28, 0x60, 0xE6,
                        0x10, 0xA9, 0x1F, 0x24, 0x10, 0xF0, 0x1F, 0x60, 0xA5, 0x10, 0x18, 0x69, 0x20, 0x85, 0x10, 0xB0,
                        0x01, 0x60, 0xE6, 0x11, 0xA9, 0x06, 0xC5, 0x11, 0xF0, 0x0C, 0x60, 0xC6, 0x10, 0xA5, 0x10, 0x29,
                        0x1F, 0xC9, 0x1F, 0xF0, 0x01, 0x60, 0x4C, 0x35, 0x07, 0xA0, 0x00, 0xA5, 0xFE, 0x91, 0x00, 0x60,
                        0xA6, 0x03, 0xA9, 0x00, 0x81, 0x10, 0xA2, 0x00, 0xA9, 0x01, 0x81, 0x10, 0x60, 0xA2, 0x00, 0xEA,
                        0xEA, 0xCA, 0xD0, 0xFB, 0x60
                    ]
                )
            }
            #expect(resultBytes == expectedBytes, "assembler compiled input as expected")
        }
    }

    private func memory(modifing: ((inout [UInt8?]) -> Void) = { _ in }) -> [UInt8?] {
        var memory = [UInt8?](repeating: nil, count: 65_536)
        modifing(&memory)
        return memory
    }
}

extension AssemblerTests {
    // written by https://skilldrick.github.io/easy6502/#snake
    private var skillDrickSnakeGame: String { """
        .define appleL         $00 ; screen location of apple, low byte
        .define appleH         $01 ; screen location of apple, high byte
        .define snakeHeadL     $10 ; screen location of snake head, low byte
        .define snakeHeadH     $11 ; screen location of snake head, high byte
        .define snakeBodyStart $12 ; start of snake body byte pairs
        .define snakeDirection $02 ; direction (possible values are below)
        .define snakeLength    $03 ; snake length, in bytes

        ; Directions (each using a separate bit)
        .define movingUp      1
        .define movingRight   2
        .define movingDown    4
        .define movingLeft    8

        ; ASCII values of keys controlling the snake
        .define ASCII_w      $77
        .define ASCII_a      $61
        .define ASCII_s      $73
        .define ASCII_d      $64

        ; System variables
        .define sysRandom    $fe
        .define sysLastKey   $ff
        .define rom        $0600
        .define screen     $0200

        .org rom
          jsr init
          jsr loop

        init:
          jsr initSnake
          jsr generateApplePosition
          rts


        initSnake:
          lda #movingRight  ;start direction
          sta snakeDirection

          lda #4  ;start length (2 segments)
          sta snakeLength

          lda #$11
          sta snakeHeadL

          lda #$10
          sta snakeBodyStart

          lda #$0f
          sta $14 ; body segment 1

          lda #$04
          sta snakeHeadH
          sta $13 ; body segment 1
          sta $15 ; body segment 2
          rts


        generateApplePosition:
          ;load a new random byte into $00
          lda sysRandom
          sta appleL

          ;load a new random number from 2 to 5 into $01
          lda sysRandom
          and #$03 ;mask out lowest 2 bits
          clc
          adc #2
          sta appleH

          rts


        loop:
          jsr readKeys
          jsr checkCollision
          jsr updateSnake
          jsr drawApple
          jsr drawSnake
          jsr spinWheels
          jmp loop


        readKeys:
          lda sysLastKey
          cmp #ASCII_w
          beq upKey
          cmp #ASCII_d
          beq rightKey
          cmp #ASCII_s
          beq downKey
          cmp #ASCII_a
          beq leftKey
          rts
        upKey:
          lda #movingDown
          bit snakeDirection
          bne illegalMove

          lda #movingUp
          sta snakeDirection
          rts
        rightKey:
          lda #movingLeft
          bit snakeDirection
          bne illegalMove

          lda #movingRight
          sta snakeDirection
          rts
        downKey:
          lda #movingUp
          bit snakeDirection
          bne illegalMove

          lda #movingDown
          sta snakeDirection
          rts
        leftKey:
          lda #movingRight
          bit snakeDirection
          bne illegalMove

          lda #movingLeft
          sta snakeDirection
          rts
        illegalMove:
          rts


        checkCollision:
          jsr checkAppleCollision
          jsr checkSnakeCollision
          rts


        checkAppleCollision:
          lda appleL
          cmp snakeHeadL
          bne doneCheckingAppleCollision
          lda appleH
          cmp snakeHeadH
          bne doneCheckingAppleCollision

          ;eat apple
          inc snakeLength
          inc snakeLength ;increase length
          jsr generateApplePosition
        doneCheckingAppleCollision:
          rts


        checkSnakeCollision:
          ldx #2 ;start with second segment
        snakeCollisionLoop:
          lda snakeHeadL,x
          cmp snakeHeadL
          bne continueCollisionLoop

        maybeCollided:
          lda snakeHeadH,x
          cmp snakeHeadH
          beq didCollide

        continueCollisionLoop:
          inx
          inx
          cpx snakeLength          ;got to last section with no collision
          beq didntCollide
          jmp snakeCollisionLoop

        didCollide:
          jmp gameOver
        didntCollide:
          rts


        updateSnake:
          ldx snakeLength
          dex
          txa
        updateloop:
          lda snakeHeadL,x
          sta snakeBodyStart,x
          dex
          bpl updateloop

          lda snakeDirection
          lsr
          bcs up
          lsr
          bcs right
          lsr
          bcs down
          lsr
          bcs left
        up:
          lda snakeHeadL
          sec
          sbc #$20
          sta snakeHeadL
          bcc upup
          rts
        upup:
          dec snakeHeadH
          lda #$1
          cmp snakeHeadH
          beq collision
          rts
        right:
          inc snakeHeadL
          lda #$1f
          bit snakeHeadL
          beq collision
          rts
        down:
          lda snakeHeadL
          clc
          adc #$20
          sta snakeHeadL
          bcs downdown
          rts
        downdown:
          inc snakeHeadH
          lda #$6
          cmp snakeHeadH
          beq collision
          rts
        left:
          dec snakeHeadL
          lda snakeHeadL
          and #$1f
          cmp #$1f
          beq collision
          rts
        collision:
          jmp gameOver


        drawApple:
          ldy #0
          lda sysRandom
          sta (appleL),y
          rts


        drawSnake:
          ldx snakeLength
          lda #0
          sta (snakeHeadL,x) ; erase end of tail

          ldx #0
          lda #1
          sta (snakeHeadL,x) ; paint head
          rts


        spinWheels:
          ldx #0
        spinloop:
          nop
          nop
          dex
          bne spinloop
          rts


        gameOver:
    """ }

    // written by me 😎
    private var withInterruptHandling: String { """
        ; Memory map
        .define SCREEN $0200
        .define NMI    $1000
        .define RESET  $2000
        .define IRQ    $3000

        ; Bind interrupt handlers
        .org $FFFA
          .word NMI    ; $FFFA-$FFFB: NMI handler address
          .word RESET  ; $FFFC-$FFFD: RESET (program entry point) handler address
          .word IRQ    ; $FFFE-$FFFF: IRQ/brk handler address

        ; Non-maskable interrupt
        .org NMI
          jmp ($FFFE) ; jump to IRQ handler

        ; IRQ/BRK interrupt
        .org IRQ
          lda #$FF
          ldx #0
        irq_loop:
          sta SCREEN,x ; M[SCREEN+X] = $FF
          inx          ; x++
          cpx #32
          bne irq_loop ; jump if (x != 32)
          rti          ; return back from interrupt

        ; Program entry point
        .define MAGIC_NUMBER $AD
        .org RESET
          clv               ; V flag = 0 (used for unconditional branching later)
          lda $00           ; load M[0] and compare to magic number
          cmp #MAGIC_NUMBER
          bne cold_boot     ; cold boot if number isn't set
        warm_reset:
          inc $01           ; M[1]++
          bvc main_loop
        cold_boot:
          lda #MAGIC_NUMBER ; store magic number in M[0]
          sta $00
          lda #0            ; store $00 in M[1]
          sta $01
        main_loop:
          lda #$FF          ; M[SCREEN+M[1]]=$FF
          ldy $01
          sta SCREEN,y
          bvc main_loop
    """ }
}

extension Array {
    fileprivate mutating func assign(at: Int = 0, _ value: Self) {
        for i in at ..< at + value.count {
            self[i] = value[i - at]
        }
    }
}
