100 REM ************************************
110 REM ************************************
120 REM
130 REM C64 BASIC BREAKOUT
140 REM
150 REM ************************************
160 REM ************************************
170 PRINT CHR$(147): REM Clear Screen
180 POKE 53280, 1  : REM Set Border to White
190 POKE 53281, 0  : REM Set Background to Black
200 REM ********************
210 REM Initalize Variables
220 REM *******************
230 BX% = 20   : REM X position of the Ball
240 BY% = 12   : REM Y postion of the Ball
250 OX% = 20   : REM Old X position of the Ball
260 OY% = 3    : REM Old Y position of the Ball
270 DX% = 1    : REM X direction of the Ball
280 DY% = 1    : REM Y direction fo the Ball
290 PX% = 20   : REM X position of the center of the Paddle
300 OPX% = PX% : REM old X position
310 PY% = 20   : REM Y position fo the Paddle
320 SC% = 0    : REM Score
330 REM ***************
340 REM Setup Playfield
350 REM ***************
360 GOSUB 1250
370 REM *******************
380 REM BEGIN MAIN
390 REM *******************
400 REM ********************
410 REM PRINT SCORE
420 REM ********************
430 s1% = 0 : s2% = 0 : s3% = 0
440 s1% = int(SC%/100)
450 s2% = int(SC%/10) - 10 * s1%
460 s3% = int(SC%) - (10 * s2% + 100 * s1%)
470 POKE 1024+0+40*24,s1%+48:POKE 55296+0+40*24,1
480 POKE 1024+1+40*24,s2%+48:POKE 55296+1+40*24,1
490 POKE 1024+2+40*24,s3%+48:POKE 55296+2+40*24,1
500 REM *********************
510 REM Get keyboard input
520 REM ********************
530 K% = PEEK(197)
540 IF K% = 10 AND PX%>=2 THEN PX%=PX%-2
550 IF K% = 18 AND PX%<=37 THEN PX%=PX%+2
560 IF PX% > 37 THEN PX% = 37
570 IF PX% < 2 THEN PX% = 2
580 REM *********************
590 REM Erase previous Paddle
600 REM *********************
610 IF OPX% = PX% THEN GOTO 660
620 FOR I=-2 TO 2
630 POKE 1024+OPX%+I+40*PY%,32:POKE 55296+OPX%+I+40*PY%,0
640 NEXT I
650 OPX%=PX%
660 REM ***********
670 REM Draw Paddle
680 REM ***********
690 FOR I = -2 TO 2
700 POKE 1024+PX%+I+40*PY%,228:POKE 55296+PX%+I+40*PY%,14
710 NEXT I
720 REM *******************
730 REM Erase previous Ball
740 REM *******************
750 IF (BX%=OX% AND BY%=OY%) THEN GOTO 820
760 POKE 1024+OX%+40*OY%,32:POKE 55296+OX%+40*OY%,0
770 REM *****************************
780 REM Update previous Ball position
790 REM *****************************
800 OX%=BX%
810 OY%=BY%
820 REM *********
830 REM Draw Ball
840 REM *********
850 POKE 1024+BX%+40*BY%, 81 : POKE 55296+BX%+40*BY%, 1
860 REM ********************
870 REM Update Ball position
880 REM ********************
890 BX%=BX%+DX%
900 BY%=BY%+DY%
910 REM *************************
920 REM Check for wall collisions
930 REM *************************
940 IF BX%<=0 OR BX%>=39 THEN DX%=-DX%
950 REM ************************************
960 REM Check for ceiling or floor collision
970 REM ************************************
980 IF BY% <= 0 OR BY% >= 23 THEN DY% = DY% * -1
990 REM
1000 REM **************************
1010 REM Check for paddle collision
1020 REM ***************************
1030 REM IF BY% < 19 THEN GOTO 4100
1040 REM IF BY% = 19 AND BX% <= PX%+2 AND BX% >=  PX%-2 THEN DY% = DY% * -1
1050 REM
1060 REM ****************************
1070 REM Check Brick collision
1080 REM ***************************
1090 IF PEEK(1024+BX%+40*BY%) = 32 THEN GOTO 370
1100 REM Collision detected !
1110 X% = INT(BX%/4)*4 : Y% = BY%
1120 IF NOT (Y%/2 = INT(Y%/2)) THEN Y% = Y% - 1
1130 rem Increment score is if collision in brick area
1140 IF Y% < = 10 THEN SC% = SC%+1
1150 DY% = DY% * -1
1160 GOSUB 1600 : REM Erase Brick
1170 rem **** reset playfield
1180 IF INT(SC%/40) = SC%/40 THEN GOSUB 1250
1190 GOTO 370
1200 END
1210 REM *********************
1220 REM        END
1230 REM**********************
1240 REM
1250 REM ***************
1260 REM Draw Playfield
1270 REM ***************
1280 X% = 0 : Y% = 4 : C% = 2 : GOSUB 1380  : REM Draw Red Bricks
1290 X% = 0 : Y% = 6 : C% = 8 : GOSUB 1380  : REM Draw Orange Bricks
1300 X% = 0 : Y% = 8 : C% = 5 : GOSUB 1380  : REM Draw Green Bricks
1310 X% = 0 : Y% = 10 : C% = 7 : GOSUB 1380 : REM Draw Yellow Bricks
1320 BX% = 20 : BY% = 12 : DX% = 1 : DY% = 1 
1325 IF SC%  > 999 THEN SC% = 0
1330 RETURN
1340 REM
1350 REM ***************************************************
1360 REM Draw a row of bricks starting at X%,Y% with Color C%
1370 REM ***************************************************
1380 FOR I = 0 TO 39 STEP 4
1390 X% =  I
1400 GOSUB 1470
1410 NEXT I
1420 RETURN
1430 REM
1440 REM *****************
1450 REM Draw BRICK
1460 REM *****************
1470 POKE 1024+X%+40*Y%, 108 : POKE 55296+X%+40*Y%, C%
1480 POKE 1024+X%+1+40*Y%, 98 : POKE 55296+X%+1+40*Y%, C%
1490 POKE 1024+X%+2+40*Y%, 98 : POKE 55296+X%+2+40*Y%, C%
1500 POKE 1024+X%+3+40*Y%, 123 : POKE 55296+X%+3+40*Y%, C%
1510 POKE 1024+X%+40*(Y%+1), 124 : POKE 55296+X%+40*(Y%+1), C%
1520 POKE 1024+X%+1+40*(Y%+1), 226 : POKE 55296+X%+1+40*(Y%+1), C%
1530 POKE 1024+X%+2+40*(Y%+1), 226 : POKE 55296+X%+2+40*(Y%+1), C%
1540 POKE 1024+X%+3+40*(Y%+1), 126 : POKE 55296+X%+3+40*(Y%+1), C%
1550 RETURN
1560 REM
1570 REM *****************
1580 REM Erase Brick
1590 REM ****************
1600 FOR I = 0 TO 3
1610 POKE 1024+X%+I+40*Y%, 32 : POKE 55296+X%+I+40*Y%, 0
1620 POKE 1024+X%+I+40*(Y%+1), 32 : POKE 55296+X%+I+40*(Y%+1), 0
1630 NEXT I
1640 RETURN