; 10 SYS (49152)

*=$801

        BYTE    $0E, $08, $0A, $00, $9E, $20, $28,  $34, $39, $31, $35, $32, $29, $00, $00, $00


* = 49152

SCR_ADDR_LO    = 251
SCR_ADDR_HI    = 252

        ;clear screen
        jsr $E544
        jsr draw_brick_chars

        ;lda #$A0                ;$A0 = #160
        ;sta SCR_ADDR_LO         ;low byte
        ;lda #$04                ;$04 = #4
        ;sta SCR_ADDR_HI         ;hi byte (16 bit) $04A0 = 1184
        ;jsr draw_row

        ;lda #$F0                ;$F0 = #240
        ;sta SCR_ADDR_LO         ;low byte
        ;lda #$04                ;$04 = #4
        ;sta SCR_ADDR_HI         ;hi byte (16 bit) $04F0 = 1264
        ;jsr draw_row

        ;lda #$40                ;$40 = #64
        ;sta SCR_ADDR_LO         ;low byte
        ;lda #$05                ;$05 = #5
        ;sta SCR_ADDR_HI         ;hi byte (16 bit) $0540 = 1344
        ;jsr draw_row

        ;lda #$90                ;$90 = #144
        ;sta SCR_ADDR_LO         ;low byte
        ;lda #$05                ;$05 = #5
        ;sta SCR_ADDR_HI         ;hi byte (16 bit) $0590 = 1424
        ;jsr draw_row


        rts

draw_brick_chars        
        ldx #0 ;
loop
        lda row_screen_address,x
        sta SCR_ADDR_LO
        inx
        lda row_screen_address,x
        sta SCR_ADDR_HI
        inx
        jsr draw_row
        cpx #8
        bne loop
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
        byte 160,4,240,4,64,5,144,5
                

brick_row_char_data
        byte 108,98,98,123,108,98,98,123,108,98,98,123,108,98,98,123
        byte 108,98,98,123,108,98,98,123,108,98,98,123,108,98,98,123
        byte 108,98,98,123,108,98,98,123
        
        byte 124,226,226,126,124,226,226,126,124,226,226,126,124,226,226,126
        byte 124,226,226,126,124,226,226,126,124,226,226,126,124,226,226,126
        byte 124,226,226,126,124,226,226,126