SCR_ADDR_LO    = $fb
SCR_ADDR_HI    = $fc

; 10 SYS2064
*=$0801
        byte $0B,$08,$0A,$00,$9E,$32,$30,$36,$34,$00,$00,$00
*=$0810 ;2064
;set up sprites
        lda #%00000011
        sta $d015 ;enable sprite 0 + 1
        ;paddle
        lda #%00000001
        sta $d01d ;x-expand sprite 0
        sta $d017 ;y-expand
        lda #$0e  ;dark blue = 6   light blue = 14
        sta $d027 ;sprite 0 color
        lda #168  ;set x coordinate
        sta $d000 ;sprite 0 x
        lda #224  ;set y coordinate
        sta $d001 ;sprite 0 y
        lda #$ec   ;236 sprite data at $3b00 = 236 * 64 
        sta $7f8  ;sprite 0 pointer
        ;ball
        lda #$01  ;    
        sta $d028 ;sprite 1 color
        lda #180  ;set x coordinate
        sta $d002 ;sprite 1 x
        lda #144  ;set y coordinate
        sta $d003 ;sprite 1 y
        lda #$ed
        sta $7f9
        ;playfield
        jsr draw_playflied
        jsr display_score

main
        jsr WaitFrame
        jsr read_joystick
        jsr read_joystick ;called x2 to move paddle @x2 speed
        jsr move_ball
        jsr check_sprite_collision
        jsr check_sprite_background_collision
        jsr main

read_joystick
        clc
        lda $dc00 ;joystick port 2
        lsr ;up
        lsr ;down
        lsr ;left
        bcc move_paddle_left
        lsr ;right
        bcc move_paddle_right
        lsr ;button
        bcc fire_button
        rts

move_paddle_left
        lda $d000  ;sprite 0 x position
        bne @dont_toggle_msb
        lda $d010  ;sprite_msb
        eor #%00000001
        sta $d010  ;sprite_msb
@dont_toggle_msb
        lda $d010
        and #%00000001 
        beq @msb_not_set
        dec $d000
        rts
@msb_not_set
        lda $d000
        cmp #24
        beq @hit_left_wall
        dec $d000  ;sprite 0 x position
@hit_left_wall
        ;don't dec the x position
        rts

move_paddle_right
        inc $d000  ;sprite 0 x position
        bne @dont_toggle_msb ;checks zero flag
        lda $d010  ;sprite0 x-axis msb
        eor #%00000001   
        sta $d010  ;sprite0 x-axis msb
@dont_toggle_msb
        lda $d010
        and #%00000001 
        bne @msb_is_set
        rts
@msb_is_set
        lda $d000
        cmp #63
        beq @hit_right_wall
        rts
@hit_right_wall
        dec $d000
        rts

fire_button
        jsr WaitFrame
        jsr reset_playfield
        jsr WaitFrame
        rts

rest_ball
        lda #180  ;set x coordinate
        sta $d002 ;sprite 1 x
        lda #144  ;set y coordinate
        sta $d003 ;sprite 1 y
        lda #1 ;set ball moving downward
        sta dir_y
        lda $d010
        and #%00000010 
        beq @msb_not_set
        lda $d010 
        eor #%00000010
        sta $d010
@msb_not_set
        rts

move_ball
        jsr move_ball_horz
        jsr move_ball_vert
        rts

move_ball_horz
        lda dir_x
        cmp #0
        beq move_ball_left
        cmp #1
        beq move_ball_right
        rts

move_ball_vert
        lda dir_y
        cmp #0
        beq moveball_up
        cmp #1
        beq moveball_down  
        rts

move_ball_left
        lda $d002
        bne @dont_toggle_msb
        lda $d010  
        eor #%00000010   
        sta $d010  
@dont_toggle_msb
        dec $d002
        lda $d010
        and #%00000010 
        beq @msb_not_set
        rts
@msb_not_set
        lda $d002
        cmp #24
        beq @hit_left_wall
        rts
@hit_left_wall
        lda #1
        sta dir_x
        jsr sound_bounce
        rts

move_ball_right
        inc $d002
        bne @dont_toggle_msb
        lda $d010  
        eor #%00000010   
        sta $d010  
@dont_toggle_msb
        lda $d010
        and #%00000010
        bne @msb_is_set
        rts
@msb_is_set
        lda $d002
        cmp #82
        beq @hit_right_wall
        rts
@hit_right_wall
        lda #0
        sta dir_x
        jsr sound_bounce
        rts

moveball_up
        dec $d003
        lda $d003
        cmp #50
        beq hit_ceiling
        rts
hit_ceiling
        lda #1
        sta dir_y
        jsr sound_bounce
        rts

moveball_down
        inc $d003
        lda $d003
        ;cmp #236
        cmp #244
        beq hit_floor
        rts
hit_floor
        lda #0
        sta dir_y
        jsr sound_bounce
        rts

check_sprite_collision
        lda $d01e
        and #%00000001
        bne @is_collision
        rts
@is_collision
        lda $d01e
        eor #%00000001
        sta $d01e
        lda #0
        sta dir_y
        jsr sound_bounce
        rts

check_sprite_background_collision
        lda $d01f
        and #%00000010
        bne @is_collision
        rts
@is_collision
        jsr calc_ball_xchar
        jsr calc_ball_ychar
        jsr calc_ball_ychar_scr_addr
        ldy xchar
        lda (SCR_ADDR_LO),y ;check ball screen address
        jsr check_is_brick
        ;cmp #32 ;is it a space?
        lda isBrick
        cmp #0
        beq @no_collision ;if so, then no collision
        
        jsr calc_brick_index
        jsr erase_brick
        jsr sound_bounce
        ;clear the sprite collision bit
        lda $d01f
        eor #%00000010 
        sta $d01f
        ;flip verticle direction
        lda dir_y
        eor #%00000001 
        sta dir_y
        ;move ball out of collision
        jsr move_ball_vert 
        jsr move_ball_vert
        jsr move_ball_vert
        jsr move_ball_vert
        ;update bick count
        ldx brick_count
        dex
        stx brick_count
        ;check is last brick
        cpx #0
        beq reset_playfield
@no_collision
        rts

isBrick byte $00
check_is_brick
        pha
        lda #0
        sta isBrick
        pla
        cmp #98
        beq is_a_brick
        cmp #108
        beq is_a_brick
        cmp #123
        beq is_a_brick
        cmp #124
        beq is_a_brick
        cmp #126
        beq is_a_brick
        cmp #226
        beq is_a_brick
        rts
is_a_brick
        pha
        lda #1
        sta isBrick
        pla
        rts
        

brick_count byte $28
reset_playfield
        jsr draw_playflied
        lda #$28
        sta brick_count
        jsr display_score
        jsr rest_ball
        lda #1
        sta dir_y
        jsr move_ball_vert
        ;jmp main
        rts

dir_x   byte $00
dir_y   byte $01

WaitFrame
        lda $d012               ; fetch the current raster line
        cmp #$F8                ; wait here till line #$f8
        beq WaitFrame           
        
WaitStep2
        lda $d012 ;VIC_RASTER_LINE
        cmp #$F8
        bne WaitStep2
        rts

draw_score_lable
        lda #19 ;'S'
        sta 2014
        lda #3  ;"C"
        sta 2015
        lda #15 ;"O"
        sta 2016
        lda #18 ;"R"
        sta 2017
        lda #5  ;"E"
        sta 2018

        lda #2  ;"B"
        sta 1984
        lda #1  ;"A"
        sta 1985
        lda #12 ;"L"
        sta 1986
        sta 1987
        jsr show_game_over
        rts

show_game_over
        lda #7 ;"G"
        sta 1239
        lda #1 ;"A"
        sta 1240   
        lda #13;"M"
        sta 1241
        lda #5 ;"E"
        sta 1242
        lda #32
        sta 1243
        lda #15 ;"O"
        sta 1244
        lda #22 ;"V"
        sta 1245
        lda #5  ;"E"
        sta 1246
        lda #18 ;"R"
        sta 1247

        lda #12
        sta 55496 + 15
        sta 55496 + 16
        sta 55496 + 17
        sta 55496 + 18
        sta 55496 + 19
        sta 55496 + 20
        sta 55496 + 21
        sta 55496 + 22
        sta 55496 + 23
        
        ldy #10
color_text
        cpy #30
        beq @done
        
        sta 55576,y
        iny
        jmp color_text
@done
        lda #16 ;"P"
        sta 1024 + 290 ;1024 + (y*40) + x  
        lda #18 ;"R"
        sta 1024 + 291
        lda #5  ;"E"
        sta 1024 + 292
        lda #19 ;"S"
        sta 1024 + 293
        sta 1024 + 294
        lda #32
        sta 1024 + 295
        lda #2  ;"B"
        sta 1024 + 296
        lda #21 ;"U"
        sta 1024 + 297
        lda #20 ;"T"
        sta 1024 + 298
        sta 1024 + 299
        lda #15 ;"O"
        sta 1024 + 300
        lda #14 ;"N"
        sta 1024 + 301
        lda #32
        sta 1024 + 302
        lda #20 ;"T"
        sta 1024 + 303
        lda #15 ;"O"
        sta 1024 + 304
        lda #32
        sta 1024 + 305
        lda #16 ;"P"
        sta 1024 + 306
        lda #12 ;"L"
        sta 1024 + 307
        lda #1 ;"A"
        sta 1024 + 308
        lda #25 ;"Y"
        sta 1024 + 309
       
        rts
draw_playflied
        lda #12
        sta $D020  ;boarder color
        lda #0
        sta $D021  ;background color
        jsr $E544  ;clear screen kernal routine
        jsr draw_bricks
        jsr color_bricks
        jsr draw_score_lable
        rts

draw_bricks
        lda #0
        sta brick_index
draw_bricks_loop
        jsr draw_brick
        inc brick_index
        lda brick_index
        cmp #40
        bne draw_bricks_loop
        rts

draw_brick 
        ldx brick_index ;
        lda brick_screen_address_lo,x
        sta SCR_ADDR_LO
        lda brick_screen_address_hi,x
        sta SCR_ADDR_HI
        ldy #0
read_brick_char_data_loop
        lda brick_char_data_top,y
        sta (SCR_ADDR_LO),y
        lda brick_char_data_bottom,y
        sta brick_char
        sty brick_char_y
        tya
        clc
        adc #40
        tay
        lda brick_char
        sta (SCR_ADDR_LO),y
        ldy brick_char_y
        iny
        cpy #4
        bne read_brick_char_data_loop
        rts

erase_brick
        ldx brick_index ;
        lda brick_screen_address_lo,x
        sta SCR_ADDR_LO
        lda brick_screen_address_hi,x
        sta SCR_ADDR_HI
        ldy #0
erase_brick_loop
        lda #32 ;ascii space
        sta (SCR_ADDR_LO),y
        sty brick_char_y
        tya
        clc
        adc #40
        tay
        lda #32 ;ascii space
        sta (SCR_ADDR_LO),y
        ldy brick_char_y
        iny
        cpy #4
        bne erase_brick_loop
        rts

brick_index byte $00
brick_char  byte $00
brick_char_y byte $00
brick_char_data_top
        byte 108,98,98,123 ;brick top
brick_char_data_bottom
        byte 124,226,226,126 ;brick bottom
brick_screen_address_hi
        byte 4,4,4,4,4,4,4,4,4,4
        byte 4,4,4,4,4,4,4,4,4,4
        byte 5,5,5,5,5,5,5,5,5,5
        byte 5,5,5,5,5,5,5,5,5,5
brick_screen_address_lo
        byte 120,124,128,132,136,140,144,148,152,156
        byte 200,204,208,212,216,220,224,228,232,236
        byte 24,28,32,36,40,44,48,52,56,60
        byte 104,108,112,116,120,124,128,132,136,140
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
        cpx #10 ; 4 rows - incr by 2 each interation for hi/lo
        bne read_color_addr_loop
        rts

color_row
        ;lda #5 ;red = 2, orange = 8, green = 5, yellow = 7
        ldy #0 ;     
color_row_loop
        sta (SCR_ADDR_LO),y
        iny
        cpy #80
        bne color_row_loop
        rts
row_color_adrress
        byte 120,216
        byte 200,216
        byte 24,217
        byte 104,217
        byte 192,219
brick_color_values
        ;red = 2, orange = 8, green = 5, yellow = 7, cyan = 3, white =1, lt. gray = 15
        byte 2,0,8,0,5,0,7,0,15,0

xchar   byte $00
ychar   byte $00
y40_LO  byte $00
y40_HI  byte $00
y8_LO   byte $00
y8_HI   byte $00
y32_LO  byte $00
y32_HI  byte $00

;xchar = (sprite0_x - left) / 8
calc_ball_xchar
        lda $d010 ;check if sprite's msb is set
        and #%00000010 
        beq @msb_not_set
        lda $d002
        sec
        sbc #24 ;24 left
        ;if msb is then set rotate in the carry bit
        ror     ;/2
        jmp @continue
@msb_not_set
        lda $d002
        sec
        sbc #24 ;24 left
        lsr     ;/2
@continue
        lsr     ;/4
        lsr     ;/8
        sta xchar
        rts

;ychar = (sprite0_y - top) / 8
calc_ball_ychar
        lda $d003
        sec
        sbc #50 ;displayable top of screen starts at pixel 50 
        lsr
        lsr
        lsr
        sta ychar
        rts

calc_ball_ychar_scr_addr
        ;ychar *32
        lda #0
        sta y32_HI
        lda ychar
        asl     ;*2
        rol y32_HI
        asl     ;*4
        rol y32_HI
        asl     ;*8
        rol y32_HI
        asl     ;*16
        rol y32_HI
        asl     ;*32
        rol y32_HI
        sta y32_LO
;ychar *8
        lda #0
        sta y8_HI
        lda ychar
        asl     ;*2
        rol y8_HI
        asl     ;*4
        rol y8_HI
        asl     ;*8
        rol y8_HI
        sta y8_LO
;(ychar * 40) = ychar *32 + ychar *8
        clc
        lda y32_LO
        adc y8_LO
        sta y40_LO
        lda y32_HI
        adc y8_HI
        sta y40_HI
;SCR_ADDR = 1024 + xchar + (ychar * 40)
        ;load 1024 into hi/lo bytes of zero page SCR_ADDR_LO and SCR_ADDR_HI
        lda #0
        sta SCR_ADDR_LO
        lda #4
        sta SCR_ADDR_HI
        ;add ychar*40
        clc
        lda y40_LO 
        adc SCR_ADDR_LO
        sta SCR_ADDR_LO
        lda y40_HI
        adc SCR_ADDR_HI
        sta SCR_ADDR_HI
        rts

col byte $00
row byte $00
temp byte $00
calc_brick_index
        lda xchar
        sec
        lsr     ;/2
        lsr     ;/4 
        sta col ;divide x char by 4 (brick are 4 chars wide)
        lda ychar
        sec
        sbc #3 ;brick row starts on 4th line
        lsr     ;/2 (bricks are 2 char high)
        sta row
        ;multipy by 10 = ychar*2 + ychar*8
        asl ;*2
        sta temp
        asl ;*4
        asl ;*8
        clc
        adc temp
        adc col
        sta brick_index
        jsr calc_brick_points
return_calc_brick_index
        ;sta 2023 ;debug info bottom right 
        rts

calc_brick_points
        clc
        lda brick_index
        cmp #30
        bcs point_yellow
        cmp #20
        bcs point_green
        cmp #10
        bcs point_orange
        cmp #0
        bcs point_red
        rts

point_yellow
        lda #1
        jmp save_brick_points
        
point_green
        lda #3
        jmp save_brick_points
        
point_orange
        lda #5
        jmp save_brick_points
        
point_red
        lda #7
        jmp save_brick_points
        
save_brick_points
        sta brick_points
        jsr add_score
        jsr display_score
        jmp return_calc_brick_index


brick_points byte $00
score byte $00, $00
add_score
        sed
        clc
        lda brick_points
        adc score
        sta score
        bcs @carry_bit
        cld
        rts
@carry_bit
        sed
        clc 
        lda #1;??????
        adc score+1
        sta score+1
        cld
        rts

display_score
        ldx #1
        lda score,x
        pha
        lsr
        lsr
        lsr
        lsr
        clc
        adc #48
        sta 2020
        pla
        and #%00001111
        clc
        adc #48
        sta 2021
        dex
        lda score,x
        pha
        lsr
        lsr
        lsr
        lsr
        clc
        adc #48
        sta 2022
        pla
        and #%00001111
        clc
        adc #48
        sta 2023
        rts

sound_bounce
        jsr clear_sound
        lda #5
        sta $d405      ;voice 1 attack / decay
        lda #5
        sta $d406      ;voice 1 sustain / release
        lda #15
        sta $d418       ;volume
        lda #7
        sta $d400      ;voice 1 frequency lo
        lda #27
        sta $d401      ;voice 1 frequency hi
        lda #33
        sta $d404      ;voice 1 control register
        rts
 
clear_sound
       ldy #23
@loop
       lda #0
       sta $d400,y
       dey
       bne @loop
       rts
        
;sprite data
*=$3b00 ;236 * 64 
        ;paddle 12x4 top left corner
        byte $ff,$f8,$00,$ff,$f8,$00,$ff,$f8,$00,$ff,$f8,$00,$00,$00,$00,$00
        byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05
        ;small 8x8 ball top left corner
        byte $38,$00,$00,$7c,$00,$00,$fe,$00,$00,$fe,$00,$00,$fe,$00,$00,$7c
        byte $00,$00,$38,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01