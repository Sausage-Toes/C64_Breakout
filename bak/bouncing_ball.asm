; 10 SYS (49152)
*=$801
        byte $0E,$08,$0A,$00,$9E,$20,$28,$34,$39,$31,$35,$32,$29,$00,$00,$00

* = 16320
;incbin "ballsprite.bin"
        byte $00,$55,$00,$01,$aa,$40,$06,$aa,$90,$06,$af,$90,$1a,$ab,$a4,$1a
        byte $ab,$e4,$6a,$aa,$f9,$6a,$aa,$b9,$6a,$aa,$b9,$6a,$aa,$a9,$6a,$aa
        byte $a9,$6a,$aa,$a9,$6a,$aa,$a9,$6a,$aa,$a9,$6a,$aa,$a9,$1a,$aa,$a4
        byte $1a,$aa,$a4,$06,$aa,$90,$06,$aa,$90,$01,$aa,$40,$00,$55,$00,$87
 
* = 49152
ballx =  679 ;these are memory addresses for the variables starting ar 679
bally =  680
dirx =   681
diry =   682
 
leftx =   #12 ;constant left border
topy =    #50 ;const top
bottomy = #230 ;const bottom
rightx =  #161 ;const right NOTE: this is 1/2 the x-axis actual resolution
 
        lda #1
        sta dirx ;set x direction
        lda #1
        sta diry ;set y direction
 
        lda #20 ;left
        sta ballx
        lda #48 ;top
        sta bally
 
        lda #5
        sta $d027       ;sprite color

        lda #1
        sta $d01c       ;enable multi-color sprite

        lda #0          ;5 = green
        sta $d025       ;multi-color sprite color 1

        lda #1         ;13 = light green
        sta $d026       ;multi-color sprite color 2

        lda #1
        sta $d015       ;enable sprite

        ;set ball start location
        lda #32
        sta $d000
        lda #100
        sta $d001
        ;init_screen      
        lda #6          ;0 = black
        sta $d021       ;set background color
        lda #14         ;15 = light gray
        sta $d020       ;set border color  
        ;clear screen
        jsr $E544
 
raster
        ;inc $D020 ;flickering border color
        
;check for raster scan line 250
        lda 53266
        cmp #250
        bne raster
 
main
        jsr check_msb
        jsr moveball_horizontally
        lda ballx
        asl a   ;keep x-axis values < 255 (8bit max value)
        sta $d000

        jsr moveball_vertically
        lda bally
        sta $d001

        ;check floor collision
        lda bally
        cmp bottomy
        ;check cieling collision
        bcs reverseup_diry
        cmp topy
        bcc reversedown_diry  
        ;check wall collisions
        lda ballx
        cmp rightx 
        bcs reverseleft_dirx
        cmp leftx
        bcc reverseright_dirx

        jmp raster
        
moveball_horizontally
        lda dirx
        cmp #0
        beq moveball_left
        cmp #1
        beq moveball_right
        rts

moveball_vertically
        ;lda #2
        ;sta 53280
        lda diry
        cmp #0
        beq moveball_up
        cmp #1
        beq moveball_down
        rts
 
moveball_right
        inc ballx
        rts
moveball_left
        dec ballx
        rts
moveball_up
        dec bally
        rts
moveball_down
        inc bally
        rts
 
reverseup_diry
        lda #0
        sta diry
        ;lda #11
        ;sta 53280
        inc $d027
        jmp main
reversedown_diry
        lda #1
        sta diry
        jmp main
reverseright_dirx
        lda #1
        sta dirx
        jmp main
reverseleft_dirx
        lda #0
        sta dirx
        jmp main

set_msb
        lda #1
        sta $d010
        rts 
clear_msb
        lda #0
        sta $d010
        rts
check_msb
        lda ballx
        cmp #127
        bcs set_msb
        cmp #128
        bcc clear_msb

        ;rts
