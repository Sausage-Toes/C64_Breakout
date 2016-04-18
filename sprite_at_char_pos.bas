5 rem sprite at char position
10 printchr$(147)
20 poke53269,1:poke53287,7 :rem cursor sprite
30 poke53275,1:poke2040,255: rem selected char
40 x=110:y=115:nm=0
50 a$="ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLM"
55 poke646,3:poke53281,0 :rem set background and char color
60 for t = 6 to 20
70 poke214,t:poke211,1:printa$
80 next t
90 rem
95 poke1132,32
100 jy=peek(56320)
110 ifjyand8thenx=x-4
120 ifjyand4thenx=x+4
130 ifjyand1theny=y+4
140 ifjyand2theny=y-4
150 rem:
160 poke53248,x:poke53249,y
170 xc=(x-40)/8
180 yc=(y-25)/8
190 vl=1024+xc+17+(40*int(yc-2))-13
200 poke214,1:print:poke211,12:print"CHAR:";peek(vl)
210 poke214,2:print:poke211,15:print"X:";xc
220 poke214,3:print:poke211,15:print"Y:";yc
230 poke214,4:print:poke211,12:printvl
240 pokevl,peek(vl):poke54272+vl,2
250 goto100