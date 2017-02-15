;===============================================================================
; DIRECTIVES
;===============================================================================
Operator Calc        ; IMPORTANT - calculations are made BEFORE hi/lo bytes
                     ;             in precidence (for expressions and tables)

;===============================================================================
; CONSTANTS
;===============================================================================
SCREEN_MEM = $0400                   ; $0400-$07FF, 1024-2047 Default screen memory
COLOR_MEM  = $D800                   ; Color mem never changes
COLOR_DIFF = COLOR_MEM - SCREEN_MEM  ; difference between color and screen ram
                                     ; a workaround for CBM PRG STUDIOs poor
                                     ; expression handling

VIC_RASTER_LINE      =  $D012        ; Read: Current raster line (bits #0-#7)
                                     ; Write: Raster line to generate interrupt at (bits #0-#7).


;---------------------------------------------------------------------------------------------
; COLORS
;-----------------------------------------------------------------------------------------------
COLOR_BLACK     = 0
COLOR_WHITE     = 1
COLOR_RED       = 2
COLOR_CYAN      = 3
COLOR_VIOLET    = 4
COLOR_GREEN     = 5
COLOR_BLUE      = 6
COLOR_YELLOW    = 7
COLOR_ORANGE    = 8
COLOR_BROWN     = 9
COLOR_LTRED     = 10
COLOR_GREY1     = 11
COLOR_GREY2     = 12
COLOR_LTGREEN   = 13
COLOR_LTBLUE    = 14
COLOR_GREY3     = 15

;===============================================================================
; ZERO PAGE VARIABLES
;===============================================================================
PARAM1 = $03   ; These will be used to pass parameters to routines
PARAM2 = $04   ; when you can't use registers or other reasons
PARAM3 = $05                            
PARAM4 = $06   ; essentially, think of these as extra data registers
PARAM5 = $07

ZEROPAGE_POINTER_1 = $17  ; Similar only for pointers that hold a word long address
ZEROPAGE_POINTER_2 = $19
ZEROPAGE_POINTER_3 = $21
ZEROPAGE_POINTER_4 = $23

;==================================================
; PROGRAM START
;
; 10 SYS2064
;==================================================
*=$0801
        byte $0B,$08,$0A,$00,$9E,$32,$30,$36,$34,$00,$00,$00
*=$0810 ;2064

setup
        lda #$20 ;space
        ldy #COLOR_BLACK
        jsr ClearScreen
        jsr display_text_test

main
        jsr WaitFrame

        jsr main



display_text_test
                                        ; Display a little message to test our 
                                        ; custom character set and text display routines

                                        ; Setup for the DisplayText routine
        lda #<TEST_TEXT                 ; Loading a pointer to TEST_TEXT - load the low byte 
        sta ZEROPAGE_POINTER_1          ; or the address into the pointer variable
        lda #>TEST_TEXT                 ; Then the high byte to complete the one word address
        sta ZEROPAGE_POINTER_1 + 1      ; (just in case someone didn't know what that was)
                                        ; I'll add a macro for this later. I do it a lot
        lda #1                          
        sta PARAM1                      ; PARAM1 and PARAM2 hold X and Y screen character coords
        sta PARAM2                      ; To write the text at
        lda #COLOR_WHITE                ; PARAM3 hold the color 
        sta PARAM3

        jsr DisplayText
        rts


TEST_TEXT
        byte 'hello world!@'


;-------------------------------------------------------------------------------------------
; CLEAR SCREEN
;-------------------------------------------------------------------------------------------
; Clears the screen using a chosen character.
; A = Character to clear the screen with
; Y = Color to fill with
; ------------------------------------------------------------------------------------------
ClearScreen
        ldx #$00                        ; Clear X register
ClearLoop
        sta SCREEN_MEM,x                ; Write the character (in A) at SCREEN_MEM + x
        sta SCREEN_MEM + 250,x          ; at SCREEN_MEM + 250 + x
        sta SCREEN_MEM + 500,x          ; at SCREEN_MEM + 500 + x
        sta SCREEN_MEM + 750,x          ; st SCREEN_MEM + 750 + x
        inx
        cpx #250                        ; is X > 250?
        bne ClearLoop                   ; if not - continue clearing

        tya                             ; transfer Y (color) to A
        ldx #$00                        ; reset x to 0
ColorLoop
        sta COLOR_MEM,x                 ; Do the same for color ram
        sta COLOR_MEM + 250,x
        sta COLOR_MEM + 500,x
        sta COLOR_MEM + 750,x
        inx
        cpx #250
        bne ColorLoop

        rts

;-------------------------------------------------------------------------------------------
; VBL WAIT
;-------------------------------------------------------------------------------------------
; Wait for the raster to reach line $f8 - if it's aleady there, wait for
; the next screen blank. This prevents mistimings if the code runs too fast

WaitFrame
        lda VIC_RASTER_LINE  ; fetch the current raster line
        cmp #$F8             ; wait here till line #$f8
        beq WaitFrame           
        
@WaitStep2
        lda VIC_RASTER_LINE
        cmp #$F8
        bne @WaitStep2
        rts

;-------------------------------------------------------------------------------------------
; DISPLAY TEXT
;-------------------------------------------------------------------------------------------
; Displays a line of text.      '@' ($00) is the end of text character
;                               '/' ($2f) is the line break character
; ZEROPAGE_POINTER_1 = pointer to text data
; PARAM1 = X
; PARAM2 = Y
; PARAM3 = Color
; Modifies ZEROPAGE_POINTER_2 and ZEROPAGE_POINTER_3
;
; NOTE : all text should be in lower case :  byte 'hello world@' or byte 'hello world',$00
;-------------------------------------------------------------------------------------------

DisplayText

        ldx PARAM2

        lda SCREEN_LINE_OFFSET_TABLE_LO,x

        sta ZEROPAGE_POINTER_2
        sta ZEROPAGE_POINTER_3
        lda SCREEN_LINE_OFFSET_TABLE_HI,x
        sta ZEROPAGE_POINTER_2 + 1

        clc
        adc #>COLOR_DIFF
        sta ZEROPAGE_POINTER_3 + 1

        lda ZEROPAGE_POINTER_2
        clc
        adc PARAM1
        sta ZEROPAGE_POINTER_2
        lda ZEROPAGE_POINTER_2 + 1
        adc #0
        sta ZEROPAGE_POINTER_2 + 1
        lda ZEROPAGE_POINTER_3
        clc
        adc PARAM1
        sta ZEROPAGE_POINTER_3
        lda ZEROPAGE_POINTER_3 + 1
        adc #0
        sta ZEROPAGE_POINTER_3 + 1

        ldy #0
@inlineLoop
        lda (ZEROPAGE_POINTER_1),y              ; test for end of line
        cmp #$00
        beq @endMarkerReached                 
        cmp #$2F                                ; test for line break
        beq @lineBreak
        sta (ZEROPAGE_POINTER_2),y
        lda PARAM3
        sta (ZEROPAGE_POINTER_3),y
        iny
        jmp @inLineLoop

@lineBreak
        iny
        tya
        clc
        adc ZEROPAGE_POINTER_1
        sta ZEROPAGE_POINTER_1
        lda #0
        adc ZEROPAGE_POINTER_1 + 1
        sta ZEROPAGE_POINTER_1 + 1

        inc PARAM2
        
        jmp DisplayText

@endMarkerReached
        rts

;---------------------------------------------------------------------------------------------------
; Screen Line Offset Tables
; Query a line with lda (POINTER TO TABLE),x (where x holds the line number)
; and it will return the screen address for that line

; C64 PRG STUDIO has a lack of expression support that makes creating some tables very problematic
; Be aware that you can only use ONE expression after a defined constant, no braces, and be sure to
; account for order of precedence.

; For these tables you MUST have the Operator Calc directive set at the top of your main file
; or have it checked in options or BAD THINGS WILL HAPPEN!! It basically means that calculations
; will be performed BEFORE giving back the hi/lo byte with '>' rather than the default of
; hi/lo byte THEN the calculation
                                                  
SCREEN_LINE_OFFSET_TABLE_LO        
          byte <SCREEN_MEM + 0
          byte <SCREEN_MEM + 40
          byte <SCREEN_MEM + 80
          byte <SCREEN_MEM + 120
          byte <SCREEN_MEM + 160
          byte <SCREEN_MEM + 200
          byte <SCREEN_MEM + 240
          byte <SCREEN_MEM + 280
          byte <SCREEN_MEM + 320
          byte <SCREEN_MEM + 360
          byte <SCREEN_MEM + 400
          byte <SCREEN_MEM + 440
          byte <SCREEN_MEM + 480
          byte <SCREEN_MEM + 520
          byte <SCREEN_MEM + 560
          byte <SCREEN_MEM + 600
          byte <SCREEN_MEM + 640
          byte <SCREEN_MEM + 680
          byte <SCREEN_MEM + 720
          byte <SCREEN_MEM + 760
          byte <SCREEN_MEM + 800
          byte <SCREEN_MEM + 840
          byte <SCREEN_MEM + 880
          byte <SCREEN_MEM + 920
          byte <SCREEN_MEM + 960

SCREEN_LINE_OFFSET_TABLE_HI
          byte >SCREEN_MEM + 0
          byte >SCREEN_MEM + 40
          byte >SCREEN_MEM + 80
          byte >SCREEN_MEM + 120
          byte >SCREEN_MEM + 160
          byte >SCREEN_MEM + 200
          byte >SCREEN_MEM + 240
          byte >SCREEN_MEM + 280
          byte >SCREEN_MEM + 320
          byte >SCREEN_MEM + 360
          byte >SCREEN_MEM + 400
          byte >SCREEN_MEM + 440
          byte >SCREEN_MEM + 480
          byte >SCREEN_MEM + 520
          byte >SCREEN_MEM + 560
          byte >SCREEN_MEM + 600
          byte >SCREEN_MEM + 640
          byte >SCREEN_MEM + 680
          byte >SCREEN_MEM + 720
          byte >SCREEN_MEM + 760
          byte >SCREEN_MEM + 800
          byte >SCREEN_MEM + 840
          byte >SCREEN_MEM + 880
          byte >SCREEN_MEM + 920
          byte >SCREEN_MEM + 960
