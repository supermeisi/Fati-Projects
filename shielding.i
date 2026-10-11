point source 
c ------------- cell card ----------------
1 1 -11.35  -1     imp:p=1   $pb
2 2 -7.874  1 -2   imp:p=1   $iron
3 3 -1      2 -3   imp:p=1   $water
4 0 -4 #1 #2 #3    imp:p=1
5 0  4             imp:p=0

c ----------- surface card ----------------
1 rcc 0 0 -5 0 0 10 5
2 rcc 0 0 -10 0 0 20 10
3 rcc 0 0 -15 0 0 30 15
4 so 50

c ---------- data card --------------------
mode p
m1 82000 1                   $pb
m2 26000 1                   $iron
m3 1001 0.3333 8016 0.6667   $Water
sdef pos=0 0 0 par=p erg=2.000
*f2:p 3.1
e2 0.1999 0.2000 0.2001
nps 1e6
