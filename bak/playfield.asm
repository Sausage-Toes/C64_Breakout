; 10 SYS (49152)
*=$801
          byte $0E,$08,$0A,$00,$9E,$20,$28,$34,$39,$31,$35,$32,$29,$00,$00,$00

*= 49152
;these are memory addresses for the variables starting ar 679
scr_loc =  679 
brick_color =  680


        ;clear screen
        jsr $E544

        ;lda #26 ; "Z"
        ;sta 1184
        ;sta 1264
        ;sta 1304
        ;sta 1344

;set start location 
;max x = 40 columns max y = 25 rows
        lda #160
        sta scr_loc

        lda #2
        sta brick_color
        jsr draw_brick_row

        ;lda #80
        ;sta scr_loc
        ;lda #8
        ;sta brick_color
        ;jsr draw_brick_row

        rts

draw_brick_row

        ldy #0
draw_brick_row_top    
        jsr draw_brick_top
        iny
        cpy #10
        bne draw_brick_row_top

        ldy #0
draw_brick_row_bottom    
        jsr draw_brick_bottom
        iny
        cpy #10
        bne draw_brick_row_bottom 
        
        rts

draw_brick_top
        ldx scr_loc
        lda #108
        sta 1024,x
        lda brick_color
        sta 55296,x
        
        inx 
        lda #98
        sta 1024,x
        lda brick_color
        sta 55296,x

        inx
        lda #98
        sta 1024,x
        lda brick_color
        sta 55296,x
        
        inx
        lda #123
        sta 1024,x
        lda brick_color
        sta 55296,x

        inx
        stx scr_loc
        rts

draw_brick_bottom
        ldx scr_loc
        lda #124
        sta 1024,x
        lda brick_color
        sta 55296,x
        
        inx 
        lda #226
        sta 1024,x
        lda brick_color
        sta 55296,x

        inx
        lda #226
        sta 1024,x
        lda brick_color
        sta 55296,x
        
        inx
        lda #126
        sta 1024,x
        lda brick_color
        sta 55296,x

        inx
        stx scr_loc
        rts