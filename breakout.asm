;===============================================================================
; DIRECTIVES
;===============================================================================
Operator Calc ; IMPORTANT - calculations are made BEFORE hi/lo bytes
              ;             in precidence (for expressions and tables)

;===============================================================================
; CONSTANTS
;===============================================================================
SCREEN_MEM = $0400                  ; $0400-$07FF, 1024-2047 Default screen memory
COLOR_MEM  = $D800                  ; Color mem never changes
COLOR_DIFF = COLOR_MEM - SCREEN_MEM ; difference between color and screen ram
                                    ; a workaround for CBM PRG STUDIOs poor
                                    ; expression handling
VIC_SPRITE0_X_POS    =  $D000
VIC_SPRITE0_Y_POS    =  $D001
VIC_SPRITE1_X_POS    =  $D002
VIC_SPRITE1_Y_POS    =  $D003

VIC_SPRITE_X_EXTEND  =  $D010 ;msb

VIC_RASTER_LINE      =  $D012       ; Read: Current raster line (bits #0-#7)
                                    ; Write: Raster line to generate interrupt at (bits #0-#7).


VIC_SPRITE_COLLISION     =  $D01E
VIC_BACKGROUND_COLLISION =  $D01F

VIC_BORDER_COLOR      = $D020      ; (53280) Border color
VIC_BACKGROUND_COLOR  = $D021      ; (53281) Background color
VIC_SPRITE_ENABLE     = $D015      ; (53269) set bits 0-7 to enable repective sprite
VIC_SPRITE0_COLOR     = $D027      ; (53287) Sprite 0 Color
VIC_SPRITE1_COLOR     = $D028

JOY_2                 = $DC00

SID_FREQ_LO           = $D400
SID_FREQ_HI           = $D401
SID_WAVEFORM_GATEBIT  = $D404
SID_ATTACK_DELAY      = $D405 
SID_SUSTAIN_RELEASE   = $D406
SID_FILTERMODE_VOLUME = $D418
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
        lda #COLOR_BLACK
        sta VIC_BORDER_COLOR     ; Set border and background to 0
        sta VIC_BACKGROUND_COLOR
        jsr display_title

setup_sprites
        lda #%00000011
        sta VIC_SPRITE_ENABLE ;enable sprite 0 + 1
        
        ;clear all sprites msbs
        lda #0
        sta VIC_SPRITE_X_EXTEND  ;sprite_msb

        ;paddle
        lda #%00000001
        sta $d01d ;x-expand sprite 0
        sta $d017 ;y-expand
        lda #COLOR_LTBLUE
        sta VIC_SPRITE0_COLOR ;sprite 0 color
        lda #168  ;set x coordinate
        sta VIC_SPRITE0_X_POS ;sprite 0 x
        lda #224  ;set y coordinate
        sta VIC_SPRITE0_Y_POS ;sprite 0 y
        lda #$ec   ;236 sprite data at $3b00 = 236 * 64 
        sta $7f8  ;sprite 0 pointer
        ;ball
        lda #$01  ;    
        sta VIC_SPRITE1_COLOR ;sprite 1 color
        lda #180  ;set x coordinate
        sta VIC_SPRITE1_X_POS ;sprite 1 x
        lda #144  ;set y coordinate
        sta VIC_SPRITE1_Y_POS ;sprite 1 y
        lda #$ed ;237
        sta $7f9 ;sprite 1 pointer
        rts

;========================================
; MAIN GAME LOOP
;=========================================
main
        jsr WaitFrame
        
        jsr JoyButton
        lda BUTTON_RELEASED
        bne @display_title 
        
        ;jsr move_paddle
        ;jsr move_paddle
        jsr auto_paddle
        jsr auto_paddle
  
        jsr move_ball
        jsr check_sprite_collision
        jsr check_sprite_background_collision

        jmp main
@display_title  
        jmp display_title

;=====================================
; MOVE PADDLE
;=====================================
move_paddle
        clc
        lda JOY_2 ;joystick port 2
        lsr ;up
        lsr ;down
        lsr ;left
        bcc move_paddle_left
        lsr ;right
        bcc move_paddle_right
        ;lsr ;button
        ;bcc fire_button
        rts

auto_paddle
        lda VIC_SPRITE_X_EXTEND 
        cmp #1 ;if paddle (sprite 0)msb is set but ball is not set
        beq @left
        cmp #2 ;if ball (sprite 1)msb is set but paddle is not set
        beq @right
        
        lda VIC_SPRITE1_X_POS ;ball x
        ;ldx VIC_SPRITE0_X_POS ;paddle x
        cmp VIC_SPRITE0_X_POS
        bcc move_paddle_left ;a less than x
        cmp VIC_SPRITE0_X_POS
        bcs move_paddle_right ;a greater or equal x
        rts
@left
        jsr move_paddle_left
        rts
@right 
        jsr move_paddle_right
        rts

move_paddle_left
        lda VIC_SPRITE0_X_POS  ;sprite 0 x position
        bne @dont_toggle_msb
        lda VIC_SPRITE_X_EXTEND  ;sprite_msb
        eor #%00000001
        sta VIC_SPRITE_X_EXTEND  ;sprite_msb
@dont_toggle_msb
        lda VIC_SPRITE_X_EXTEND
        and #%00000001 
        beq @msb_not_set
        dec VIC_SPRITE0_X_POS
        rts
@msb_not_set
        lda VIC_SPRITE0_X_POS
        cmp #24
        beq @hit_left_wall
        dec VIC_SPRITE0_X_POS  ;sprite 0 x position
@hit_left_wall
        ;don't dec the x position
        rts

move_paddle_right
        inc VIC_SPRITE0_X_POS  ;sprite 0 x position
        bne @dont_toggle_msb ;checks zero flag
        lda VIC_SPRITE_X_EXTEND  ;sprite0 x-axis msb
        eor #%00000001   
        sta VIC_SPRITE_X_EXTEND  ;sprite0 x-axis msb
@dont_toggle_msb
        lda VIC_SPRITE_X_EXTEND
        and #%00000001 
        bne @msb_is_set
        rts
@msb_is_set
        lda VIC_SPRITE0_X_POS
        cmp #63
        beq @hit_right_wall
        rts
@hit_right_wall
        dec VIC_SPRITE0_X_POS
        rts  

;=====================================
; MOVE BALL
;=====================================
move_ball
        jsr move_ball_horz
        jsr move_ball_vert
        rts

move_ball_horz
        lda dir_x
        beq move_ball_left
        jsr move_ball_right
        rts

move_ball_vert
        lda dir_y
        beq moveball_up
        jsr moveball_down
        rts

move_ball_left
        lda VIC_SPRITE1_X_POS
        bne @dont_toggle_msb
        lda VIC_SPRITE_X_EXTEND  
        eor #%00000010   
        sta VIC_SPRITE_X_EXTEND  
@dont_toggle_msb
        dec VIC_SPRITE1_X_POS
        lda VIC_SPRITE_X_EXTEND
        and #%00000010 
        beq @msb_not_set
        rts
@msb_not_set
        lda VIC_SPRITE1_X_POS
        cmp #24
        beq @hit_left_wall
        rts
@hit_left_wall
        lda #1
        sta dir_x
        jsr sound_bounce
        rts

move_ball_right
        inc VIC_SPRITE1_X_POS
        bne @dont_toggle_msb
        lda VIC_SPRITE_X_EXTEND  
        eor #%00000010   
        sta VIC_SPRITE_X_EXTEND  
@dont_toggle_msb
        lda VIC_SPRITE_X_EXTEND
        and #%00000010
        bne @msb_is_set
        rts
@msb_is_set
        lda VIC_SPRITE1_X_POS
        cmp #82
        beq @hit_right_wall
        rts
@hit_right_wall
        lda #0
        sta dir_x
        jsr sound_bounce
        rts

moveball_up
        dec VIC_SPRITE1_Y_POS
        lda VIC_SPRITE1_Y_POS
        cmp #50
        beq hit_ceiling
        rts
hit_ceiling
        lda #1
        sta dir_y
        jsr sound_bounce
        rts

moveball_down
        inc VIC_SPRITE1_Y_POS
        lda VIC_SPRITE1_Y_POS
        ;cmp #244
        ;cmp #235
        cmp #255
        beq hit_floor
        rts
hit_floor
        ;lda #0
        ;sta dir_y

        ;jsr sound_bounce
        jsr sound_bing

        ;update ball count
        dec ball_count
        jsr display_ball_count
        lda ball_count
        beq game_over
        jsr reset_ball
        rts

;===============================
; G A M E   O V E R
;===============================
game_over
        lda #%00000000
        sta VIC_SPRITE_ENABLE 

        lda #<GAME_OVER_TEXT                
        sta ZEROPAGE_POINTER_1          
        lda #>GAME_OVER_TEXT               
        sta ZEROPAGE_POINTER_1 + 1                                 
        lda #10                          
        sta PARAM1                      
        lda #12
        sta PARAM2                      
        lda #COLOR_WHITE  
        sta PARAM3
        jsr DisplayText
        jsr display_start_message
game_over_loop
        jsr WaitFrame
        jsr JoyButton
        lda BUTTON_RELEASED
        bne @start_game
        jmp game_over_loop
@start_game
        jmp start_game
        
;============================================
; CHECK FOR BALL/PADDEL SPRITE COLLISION
;============================================
check_sprite_collision
        lda VIC_SPRITE_COLLISION
        and #%00000001
        bne @is_collision
        rts
@is_collision
        lda VIC_SPRITE_COLLISION
        eor #%00000001
        sta VIC_SPRITE_COLLISION
        lda #0
        sta dir_y
        jsr sound_bounce
        rts

;============================================
; CHECK FOR BALL/BACKGROUND COLLISION
;============================================
check_sprite_background_collision
        lda VIC_BACKGROUND_COLLISION
        and #%00000010
        bne @is_collision
        rts
@is_collision
        jsr calc_ball_xchar
        jsr calc_ball_ychar
        ;jsr display_char_coord
        
        ldx  ychar
        lda SCREEN_LINE_OFFSET_TABLE_LO,x 
        sta ZEROPAGE_POINTER_1
        lda SCREEN_LINE_OFFSET_TABLE_HI,x 
        sta ZEROPAGE_POINTER_1 + 1
        ldy xchar
        lda (ZEROPAGE_POINTER_1),y
        ;cmp #32 ;is it a space?
        ;beq @no_collision
        jsr check_is_brick
        lda isBrick
        cmp #0
        beq @no_collision ;if so, then no collision

        ;calc x,y parms to erase brick
        lda xchar
        sec
        lsr     ;/2
        lsr     ;/4 
        asl     ;*2
        asl     ;*4
        sta PARAM1
        lda ychar
        sec
        sbc #3  ;brick rows start on 4th line
        lsr     ;/2 (bricks are 2 char high)
        asl     ;*2
        adc #3
        sta PARAM2
        lda #COLOR_BLACK  
        sta PARAM3
        jsr erase_brick
        ;
        ;clear the sprite collision bit
        lda VIC_BACKGROUND_COLLISION
        eor #%00000010 
        sta VIC_BACKGROUND_COLLISION
        ;flip verticle direction
        lda dir_y
        eor #%00000001 
        sta dir_y
        ;move ball out of collision
        jsr move_ball_vert 
        jsr move_ball_vert
        jsr move_ball_vert
        jsr move_ball_vert
        jsr sound_bounce
        jsr calc_brick_points

        ;update bick count
        ldx brick_count
        dex
        stx brick_count
        ;check is last brick
        cpx #0
        beq reset_playfield
@no_collision
        rts

;=============================================
; CALCULATE POINTS SCORE
;       outputs point value to "brick_points"
;       calls routines to update score total "add_score"
;       and display updated score "display_score"
;==============================================
calc_brick_points
        clc
        lda ychar
        cmp #9
        bcs point_yellow
        cmp #7
        bcs point_green
        cmp #5
        bcs point_orange
        cmp #3
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
        rts

;========================
; RESET PLAYFIELD
;========================
reset_playfield
        jsr draw_playfield
        lda #$28
        sta brick_count
        jsr display_score
        jsr reset_ball
        lda #1
        sta dir_y
        jsr move_ball_vert
        rts

;=========================
; RESET BALL 
;=========================
reset_ball
        lda #180  ;set x coordinate
        sta VIC_SPRITE1_X_POS ;sprite 1 x
        lda #144  ;set y coordinate
        sta VIC_SPRITE1_Y_POS ;sprite 1 y
        lda #1 ;set ball moving downward
        sta dir_y
        lda VIC_SPRITE_X_EXTEND
        and #%00000010 
        beq @msb_not_set
        lda VIC_SPRITE_X_EXTEND 
        eor #%00000010
        sta VIC_SPRITE_X_EXTEND
@msb_not_set
        rts

display_char_coord
        lda #<CHAR_COORD_LABEL                
        sta ZEROPAGE_POINTER_1          
        lda #>CHAR_COORD_LABEL               
        sta ZEROPAGE_POINTER_1 + 1                                 
        lda #15                          
        sta PARAM1                      
        lda #24
        sta PARAM2                      
        lda #COLOR_GREY3  
        sta PARAM3
        jsr DisplayText
        ldx #24
        ldy #17
        lda xchar
        jsr DisplayByte
        ldx #24
        ldy #22
        lda ychar
        jsr DisplayByte
        rts

;=================================================
; CALCULATE THE BALL'S X CHARACTER CO-ORDINATE
; xchar = (sprite0_x - left) / 8
calc_ball_xchar
        lda VIC_SPRITE_X_EXTEND ;check if sprite's msb is set
        and #%00000010 
        beq @msb_not_set
        lda VIC_SPRITE1_X_POS
        sec
        sbc #24 ;24 left
        ;if msb is then set rotate in the carry bit
        ror     ;/2
        jmp @continue
@msb_not_set
        lda VIC_SPRITE1_X_POS
        sec
        sbc #24 ;24 left
        lsr     ;/2
@continue
        lsr     ;/4
        lsr     ;/8
        sta xchar
        rts
;==============================================
; CALCULATE THE BALLS Y CHARACTER CO-ORDINATE
; ychar = (sprite0_y - top) / 8
calc_ball_ychar
        lda VIC_SPRITE1_Y_POS
        sec
        sbc #50 ;displayable top of screen starts at pixel 50 
        lsr
        lsr
        lsr
        sta ychar
        rts

;===========================================
; CHECK CHAR IS A BRICK CHARACTER
; A register holds character code to check
; output boolean value to 'isBrick'
; 0 = false , 1 = true
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
        
;===========================================
; START GAME
;===========================================
start_game
        lda #$20 ;space
        ldy #COLOR_WHITE
        jsr ClearScreen
        jsr clear_sound
        jsr draw_playfield
        jsr setup_sprites
        jsr reset_ball
        
        lda #0
        sta score
        sta score+1
        jsr display_score
        ;display the score label
        lda #<SCORE_LABEL                
        sta ZEROPAGE_POINTER_1          
        lda #>SCORE_LABEL               
        sta ZEROPAGE_POINTER_1 + 1                                 
        lda #30                          
        sta PARAM1                      
        lda #24
        sta PARAM2                      
        lda #COLOR_WHITE  
        sta PARAM3
        jsr DisplayText

        lda #5
        sta ball_count
        jsr display_ball_count
        ;display the ball label
        lda #<BALL_LABEL                
        sta ZEROPAGE_POINTER_1          
        lda #>BALL_LABEL               
        sta ZEROPAGE_POINTER_1 + 1                                 
        lda #0                          
        sta PARAM1                      
        lda #24
        sta PARAM2                      
        lda #COLOR_WHITE  
        sta PARAM3
        jsr DisplayText

        jmp main

;=====================
; DRAW PLAYFIELD
;=====================
draw_playfield
        lda #3
        sta PARAM2                      
        lda #COLOR_RED  
        sta PARAM3
        jsr draw_brick_row

        lda #5
        sta PARAM2                      
        lda #COLOR_ORANGE  
        sta PARAM3
        jsr draw_brick_row

        lda #7
        sta PARAM2                      
        lda #COLOR_GREEN  
        sta PARAM3
        jsr draw_brick_row

        lda #9
        sta PARAM2                      
        lda #COLOR_YELLOW  
        sta PARAM3
        jsr draw_brick_row

        rts

;add_score
;        sed
;        clc
;        lda brick_points
;        adc score
;        sta score
;        bcs @carry_bit
;        cld
;        rts
;@carry_bit
;        sed
;        clc 
;        lda #1;??????
;        sta score+1
;        cld
;        rts


add_score
        sed
        clc
        lda score
        adc brick_points
        sta score
        bcc @return
        lda score+1
        adc #0
        sta  score+1       
@return
        cld
        rts

;=======================================
; DISPLAY SCORE
;=======================================
display_score
        ;hi byte
        lda score+1
        pha ;store orginal value
        lsr ;shift out the first digit
        lsr
        lsr
        lsr
        clc
        adc #48 ;add petscii code for zero
        sta 2020 ;write digit to screen
        pla ;get orginal value
        and #%00001111 ;mask out last digit
        clc
        adc #48 ;add petscii code for zero
        sta 2021 ;write digit to screen
        
        ;lo byte 
        lda score
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

display_ball_count
        clc
        lda ball_count
        adc #48
        sta 1989
        rts

;=======================================
; DRAW A ROW OF BRICKS
;=======================================
; PARAM2 = Y
; PARAM3 = Color
draw_brick_row
        lda #0                          
        sta PARAM1
        lda PARAM2
        sta brick_row
draw_brick_row_loop
        lda brick_row
        sta PARAM2
        jsr draw_brick
        clc        
        lda PARAM1
        adc #4
        sta PARAM1
        cmp #40
        bne draw_brick_row_loop
        rts

;========================================
; DRAW A SINGLE BRICK
;=======================================
; PARAM1 = X
; PARAM2 = Y
; PARAM3 = Color
;=======================================
draw_brick       
        lda #<BRICK_TEXT
        sta ZEROPAGE_POINTER_1          
        lda #>BRICK_TEXT               
        sta ZEROPAGE_POINTER_1 + 1
        jsr DisplayText
        rts

erase_brick
        lda #<ERASE_BRICK_TEXT
        sta ZEROPAGE_POINTER_1          
        lda #>ERASE_BRICK_TEXT               
        sta ZEROPAGE_POINTER_1 + 1
        jsr DisplayText
        rts

;========================================
; DISPLAY TITLE SCREEN
;=======================================
display_title
        lda #%00000000
        sta VIC_SPRITE_ENABLE 

        lda #$20 ;space
        ldy #COLOR_BLACK
        jsr ClearScreen

        lda #<TITLE1                
        sta ZEROPAGE_POINTER_1          
        lda #>TITLE1               
        sta ZEROPAGE_POINTER_1 + 1                                 
        lda #1                          
        sta PARAM1                      
        lda #3
        sta PARAM2                      
        lda #COLOR_RED  
        sta PARAM3
        jsr DisplayText

        lda #<TITLE2                
        sta ZEROPAGE_POINTER_1          
        lda #>TITLE2               
        sta ZEROPAGE_POINTER_1 + 1                                  
        lda #1                          
        sta PARAM1                      
        lda #5
        sta PARAM2                      
        lda #COLOR_ORANGE  
        sta PARAM3
        jsr DisplayText

        lda #<TITLE3                
        sta ZEROPAGE_POINTER_1          
        lda #>TITLE3               
        sta ZEROPAGE_POINTER_1 + 1                                  
        lda #1                          
        sta PARAM1                      
        lda #7
        sta PARAM2                      
        lda #COLOR_GREEN  
        sta PARAM3
        jsr DisplayText

        lda #<TITLE4                
        sta ZEROPAGE_POINTER_1          
        lda #>TITLE4               
        sta ZEROPAGE_POINTER_1 + 1                                
        lda #1                          
        sta PARAM1                      
        lda #9
        sta PARAM2                      
        lda #COLOR_YELLOW  
        sta PARAM3
        jsr DisplayText
        jsr display_start_message
title_loop
        jsr WaitFrame
        jsr JoyButton
        lda BUTTON_RELEASED
        bne @start_game
        jmp title_loop
@start_game
        jmp start_game

display_start_message
        lda #<START_TEXT                
        sta ZEROPAGE_POINTER_1          
        lda #>START_TEXT               
        sta ZEROPAGE_POINTER_1 + 1                                  
        lda #11                          
        sta PARAM1                      
        lda #23
        sta PARAM2                      
        lda #COLOR_GREY3  
        sta PARAM3
        jsr DisplayText
        rts

JoyButton
        lda #1 ; checks for a previous button action
        cmp BUTTON_RELEASED ; and clears it if set
        bne @buttonTest
        lda #0                                  
        sta BUTTON_RELEASED
@buttonTest
        lda #$10 ; test bit #4 in JOY_2 Register
        bit JOY_2
        bne @buttonNotPressed
        lda #1   ; if it's pressed - save the result
        sta BUTTON_PRESSED ; and return - we want a single press
        rts      ; so we need to wait for the release
@buttonNotPressed
        lda BUTTON_PRESSED ; and check to see if it was pressed first
        bne @buttonAction  ; if it was we go and set BUTTON_ACTION
        rts
@buttonAction
        lda #0
        sta BUTTON_PRESSED
        lda #1
        sta BUTTON_RELEASED
        rts

;===============================
; VARIABLES AND DATA
;===============================

ball_count
        byte $05
brick_points 
        byte $00
isBrick 
        byte $00
brick_count 
        byte $28
xchar   
        byte $00
ychar   
        byte $00
dir_x   
        byte $00
dir_y   
        byte $01
score 
        byte $00, $00
brick_row ;index for draw_brick_row
        byte $00
BUTTON_PRESSED ; holds 1 when the button is held down
        byte $00
BUTTON_RELEASED; holds 1 when a single press is made (button released)
        byte $00

SCORE_LABEL
        byte 'score@'
BALL_LABEL
        byte 'ball@'
CHAR_COORD_LABEL
        byte 'x:   y:@'

BRICK_TEXT
        byte 108,98,98,123,47,124,226,226,126,0
ERASE_BRICK_TEXT
        byte 32,32,32,32,47,32,32,32,32,0

GAME_OVER_TEXT
        byte ' g a m e   o v e r @'
START_TEXT
        byte 'press fire to play@'

TITLE1
        byte 160,160,160,32,32,160,160,160,32,32,160,160,160,160,32,32,160,160,32,32,160,32,32,160,32,160,160,160,160,32,160,32,32,160,118,160,160,160,160,47
        byte 160,32,32,160,32,160,32,32,160,32,160,32,32,32,32,32,160,32,160,32,160,32,32,160,32,160,32,32,160,32,160,32,32,160,32,32,160,47
TITLE2        
        byte 160,32,32,160,32,160,32,32,160,32,160,32,32,32,32,160,32,32,160,32,160,32,160,32,32,160,32,32,160,32,160,32,32,160,32,32,160,47
        byte 160,160,160,32,32,160,160,160,32,32,160,160,160,32,32,160,160,160,160,32,160,160,160,32,32,160,32,32,160,32,160,32,32,160,32,32,160,47
TITLE3        
        byte 160,32,32,160,32,160,32,32,160,32,160,32,32,32,32,160,32,32,160,32,160,32,32,160,32,160,32,32,160,32,160,32,32,160,32,32,160,47
        byte 160,160,32,160,32,160,160,32,160,32,160,160,32,32,32,160,160,32,160,32,160,160,32,160,32,160,160,32,160,32,160,160,32,160,32,32,160,160,47
TITLE4
        byte 160,160,32,160,32,160,160,32,160,32,160,160,32,32,32,160,160,32,160,32,160,160,32, 160,32,160,160,32,160,32,160,160,32,160,32,32,160,160,47
        byte 160,160,160,32,32,160,160,32,160,32,160,160,160,160,32,160,160,32,160,32,160,160,32,160,32,160,160,160,160,32,160,160,160,160,32,32,160,160,0

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
; DISPLAY BYTE DATA
;---------------------------------------------------------------------------------------------------
; Displays the data stored in a given byte on the screen as readable text in hex format (0-F)
; X = screen line - Yes, this is a little arse-backwards (X and Y) but I don't think
; Y = screen column   addressing modes allow me to swap them around
; A = byte to display
; MODIFIES : ZEROPAGE_POINTER_1, ZEROPAGE_POINTER_3, PARAM4
;---------------------------------------------------------------------------------------------------
DisplayByte
        sta PARAM4                                      ; store the byte to display in PARAM4

        lda SCREEN_LINE_OFFSET_TABLE_LO,x               ; look up the address for the screen line
        sta ZEROPAGE_POINTER_1                          ; store lower byte for address for screen
        sta ZEROPAGE_POINTER_3                          ; and color
        lda SCREEN_LINE_OFFSET_TABLE_HI,x               ; store high byte for screen
        sta ZEROPAGE_POINTER_1 + 1
        clc
        adc #>COLOR_DIFF                                ; add the difference to color mem
        sta ZEROPAGE_POINTER_3 + 1                      ; for the color address high byte

        lda PARAM4                                      ; load the byte to be displayed
        and #$0F                                        ; mask for the lower half (0-F)
        adc #$30                                        ; add $30 (48) to display character set
                                                        ; numbers
        clc                                             ; clear carry flag
        cmp #$3A                                        ; less than the code for A (10)?
        bcc @writeDigit                                  ; Go to the next digit
        
        sbc #$39                                        ; if so we set the character code back to
                                                        ; display A-F ($01 - $0A)
@writeDigit                                              
        iny                                             ; increment the position on the line                                       
        sta (ZEROPAGE_POINTER_1),y                      ; write the character code
        lda #COLOR_WHITE                                ; set the color to white
        sta (ZEROPAGE_POINTER_3),y                      ; write the color to color ram

        dey                                             ; decrement the position on the line
        lda PARAM4                                      ; fetch the byte to DisplayText
        and #$F0                                        ; mask for the top 4 bits (00 - F0)
        lsr                                             ; shift it right to a value of 0-F
        lsr
        lsr
        lsr
        adc #$30                                        ; from here, it's the same
        
        clc
        cmp #$3A                                        ; check for A-F
        bcc @lastDigit
        sbc #$39

@lastDigit
        sta (ZEROPAGE_POINTER_1),y                      ; write character and color
        lda #COLOR_WHITE
        sta (ZEROPAGE_POINTER_3),y

        rts

;====================================
; SOUND EFFECTS
sound_bing
        ;jsr clear_sound
        lda #5;#$00
        sta SID_ATTACK_DELAY  ;$d405 SID_ATTACK_DELAY
        lda #5;#$02
        sta SID_SUSTAIN_RELEASE  ;$d406 SID_SUSTAIN_RELEASE
        lda #$07
        sta SID_FREQ_HI  ;$d401 SID_FREQ_HI
        lda #$00
        sta SID_FREQ_LO  ;$d400 SID_FREQ_LO
        lda #$21 ;trigger #$21
        sta SID_WAVEFORM_GATEBIT  ;$d404 SID_WAVEFORM_GATEBIT
        lda #$20 ;release
        sta SID_WAVEFORM_GATEBIT ;$d404 SID_WAVEFORM_GATEBIT
        rts

sound_bounce
        ;jsr clear_sound
        lda #5
        sta SID_ATTACK_DELAY ;$d405      ;voice 1 attack / decay
        lda #5
        sta SID_SUSTAIN_RELEASE ;$d406      ;voice 1 sustain / release
        ;lda #15
        ;sta $d418       ;volume
        lda #7
        sta SID_FREQ_LO ;$d400      ;voice 1 frequency lo
        lda #27
        sta SID_FREQ_HI ;$d401      ;voice 1 frequency hi
        lda #$11;#33
        sta SID_WAVEFORM_GATEBIT ;$d404      ;voice 1 control register
        lda #$10;#32
        sta SID_WAVEFORM_GATEBIT ;$d404      ;voice 1 control register
        rts
 
clear_sound
       ldy #23
@loop
       lda #0
       sta $d400,y
       dey
       bne @loop

       lda #$0f ;set max volume
       sta $d418
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
