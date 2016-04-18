; 10 SYS (49152)

*=$801

        BYTE $0E,$08,$0A,$00,$9E,$20,$28,$34,$39,$31,$35,$32,$29,$00,$00,$00

* = 49152

SCR_ADDR_LO = 251
SCR_ADDR_HI = 252

        ;init_screen      
        lda #0          ;0 = black
        sta $d021       ;set background color
        lda #15         ;15 = light gray
        sta $d020       ;set border color 
        ;clear screen
        jsr $E544

        jsr draw_brick_chars
        jsr color_bricks
        rts

color_bricks
        ldx #0
read_color_addr_loop
        lda row_color_adrress,x
        sta SCR_ADDR_LO
        inx
        lda row_color_adrress,x
        sta SCR_ADDR_HI
        inx 
        lda brick_color_values,x-2
        jsr color_row
        cpx #8 ; 4 rows - incr by 2 each interation for hi/lo
        bne read_color_addr_loop
        rts

color_row
        ldy #0    
color_row_loop
        sta (SCR_ADDR_LO),y
        iny
        cpy #80
        bne color_row_loop
        rts

draw_brick_chars        
        ldx #0 ;
read_scr_addr_loop
        lda row_screen_address,x
        sta SCR_ADDR_LO
        inx
        lda row_screen_address,x
        sta SCR_ADDR_HI
        inx
        jsr draw_row
        cpx #8 ; 4 rows - incr by 2 each interation for hi/lo
        bne read_scr_addr_loop
        rts

draw_row        
        ldy #0 ;
read_brick_row_char_loop
        lda brick_row_char_data,y
        sta (SCR_ADDR_LO),y
        iny
        cpy #80
        bne read_brick_row_char_loop
        rts

row_screen_address
        ;screen memory addresses for start of each of the 4 rows of bricks
        ; row 1 $04A0 = 1184 / $A0 = #160 , $04 = #4
        ; row 2 $04F0 = 1264 / $F0 = #240 , $04 = #4
        ; row 3 $0540 = 1344 / $40 = #64  , $05 = #5
        ; row 4 $0590 = 1424 / $90 = #144 , $05 = #5
        byte 160,4,240,4,64,5,144,5
row_color_adrress
        byte 160,216,240,216,64,217,144,217
brick_row_char_data
        ;bricks are 2 char high, 4 char wide, there are 10 bricks per row
        ;row brick of tops
        byte 108,98,98,123,108,98,98,123,108,98,98,123,108,98,98,123
        byte 108,98,98,123,108,98,98,123,108,98,98,123,108,98,98,123
        byte 108,98,98,123,108,98,98,123
        ;row of brick bottoms
        byte 124,226,226,126,124,226,226,126,124,226,226,126,124,226,226,126
        byte 124,226,226,126,124,226,226,126,124,226,226,126,124,226,226,126
        byte 124,226,226,126,124,226,226,126
brick_color_values
        ;red = 2, orange = 8, green = 5, yellow = 7
        byte 2,2,8,8,5,5,7,7