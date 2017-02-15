1 rem by steve marrow
5 rem sprite at char position
10 printchr$(147)
20 poke53269,1:poke53287,7 :rem cursor sprite
30 poke53275,1:poke2040,255: rem selected char
40 rem x=110:y=115:nm=0
45 x=24:y=50
50 a$="Xbcdefghijklmnopqrstuvwxyzabcdefghijklm0"
55 poke646,3:poke53281,0 :rem set background and char color
60 for t = 0 to 22
65 if t >= 2 and t < 6 then next t
70 poke214,t:poke211,0:SYS58732:printa$
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
170 rem xc=(x-40)/8
175 xc=(x-24)/8 :rem minus left boarder 
180 rem yc=(y-25)/8
185 yc=(y-50)/8 :rem minus top boarder  
190 rem vl=1024+xc+17+(40*int(yc-2))-13
192 vl=1024+xc+1+(40*int(yc+1))
195 poke214,2:poke211,12:SYS58732:print"             "
200 poke214,2:poke211,12:SYS58732:print"char:";peek(vl)
205 poke214,3:poke211,15:SYS58732:print"               "
210 poke214,3:poke211,15:SYS58732:print"x:";xc
215 poke214,4:poke211,15:SYS58732:print"               "
220 poke214,4:poke211,15:SYS58732:print"y:";yc
225 poke214,5:poke211,12:SYS58732:print"               "
230 poke214,5:poke211,12:SYS58732:printvl
240 pokevl,peek(vl):poke54272+vl,2
250 goto60