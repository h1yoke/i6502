import i6502Assembler
import SwiftUI

struct EditorView: View {
    @AppStorage("AppTheme") private var appTheme: AppTheme = .defaultDark
    @AppStorage("FontSize") private var fontSize: Double = 14
    @State private var onSettings: Bool = false

    @State private var _text: AttributedString = ""
    @State private var showInspector: Bool = true

    var body: some View {
        ZStack(alignment: .trailing) {
            TextEditor(text: .init(
                get: { _text },
                set: { _text = applyHighlighting($0) }
            ))
            .autocorrectionDisabled()
            .keyboardIOSSpecific()

            if showInspector, UIDevice.current.userInterfaceIdiom != .phone {
                HexdumpOverlayView(originalText: String(_text.characters))
                    .transition(.move(edge: .trailing))
                    .padding([.trailing, .bottom], 12)
                    .ignoresSafeArea(.all, edges: [.trailing, .bottom])
                    .simultaneousGesture(DragGesture().onEnded {
                        if $0.predictedEndTranslation.width > 250 {
                            withAnimation {
                                showInspector = false
                            }
                        }
                    })
            }
        }
        .onAppear { _text = applyHighlighting(Self.snakeGame) }
        .background(appTheme.palette.backgroundPrimary.ignoresSafeArea())
        .font(.system(size: fontSize, design: .monospaced))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Hexdump", systemImage: "sidebar.squares.trailing") {
                    withAnimation {
                        showInspector.toggle()
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu("", systemImage: "ellipsis") {
                    Button("Settings", systemImage: "gear") { onSettings = true }
                    Divider()
                    Button("Import as..", systemImage: "square.and.arrow.down") {}
                    Button("Export as..", systemImage: "square.and.arrow.up") {}
                    Divider()
                    Button("About", systemImage: "info.circle") {}
                }
            }
        }
        .settingsSheet(isPresented: $onSettings)
        .onChange(of: appTheme) {
            _text = applyHighlighting(_text)
        }
    }

    private func applyHighlighting(_ string: AttributedString) -> AttributedString {
        var newText = string
        newText.foregroundColor = appTheme.palette.foregroundPrimary
        return newText
            .highlightingMatches(
                of: "\\.\\w*",
                color: appTheme.palette.directives
            )
            .highlightingMatches(
                of: "\\S*:",
                color: appTheme.palette.labels
            )
            .highlightingMatches(
                of: "\\$[0-9A-Fa-f]+",
                color: appTheme.palette.literals
            )
            .highlightingMatches(
                of: "\\b\\d+\\b",
                color: appTheme.palette.literals
            )
            .highlightingMatches(
                of: ";.*",
                color: appTheme.palette.comments
            )
    }

    private static let snakeGame: AttributedString = """
        ; Change direction: W A S D

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
    """
}

extension View {
    fileprivate func keyboardIOSSpecific() -> some View {
        self
        #if !os(macOS)
        .keyboardType(.asciiCapable)
        .textInputAutocapitalization(.never)
        .scrollContentBackground(.hidden)
        #endif
    }
}

extension AttributedString {
    fileprivate func highlightingMatches(
        of pattern: String,
        color: Color = .blue,
        font: Font? = nil,
        backgroundColor: Color? = nil
    ) -> AttributedString {
        var result = self
        let text = String(result.characters)

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return result
        }

        let nsRange = NSRange(text.startIndex ..< text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)

        for match in matches.reversed() { // Reverse to maintain indices
            if let range = Range(match.range, in: text),
               let attributedRange = Range(range, in: result)
            {
                result[attributedRange].foregroundColor = color
                if let font {
                    result[attributedRange].font = font
                }
                if let bgColor = backgroundColor {
                    result[attributedRange].backgroundColor = bgColor
                }
            }
        }

        return result
    }
}
