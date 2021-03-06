\ Aitken             Aitken Interpolation        ACM Algorithm #70

\ Forth Scientific Library Algorithm #9

\ Evaluates the (N-1)th degree Lagrange polynomial given N data coordinates
\ and the value where interpolation is desired.  The polynomial is
\ generated by Aitken's iterative scheme.
\
\ This is an ANS Forth program requiring:
\      1. The Floating-Point word set
\    xx2. The immediate word '%' which takes the next token
\         and converts it to a floating-point literal
\      3. Uses words 'Private:', 'Public:' and 'Reset_Search_Order'
\         to control the visibility of internal code.
\      4. Uses the words 'DArray' and '&!' to alias arrays.
\      5. The immediate word '&' to get the address of an array
\         at either compile or run time.
\      6. Uses '}malloc' and '}free' to allocate and release memory
\         for dynamic arrays ( 'DArray' ).
\      7. The compilation of the test code is controlled by the VALUE TEST-CODE?
\         and the conditional compilation words in the Programming-Tools wordset
\      8. The second test uses 'Logistic' for the logistic function.


\ Collected Algorithms from ACM, Volume 1 Algorithms 1-220,
\ 1980; Association for Computing Machinery Inc., New York,
\ ISBN 0-89791-017-6

\ (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\ author to use this software for any application provided this
\ copyright notice is preserved.
\
\ Revisions:
\   2010-12-25  km  revised the test code for automated and more 
\                   rigorous test of the Lagrange interpolation;
\                   set base to decimal and restore; this version
\                   works on both unified and separate fp stack systems.
\   2011-09-16  km  use Neal Bridges' anonymous module interface.
\   2012-02-19  km  use KM/DNW's modules library.

CR .( AITKEN            V1.1.5         19 February  2012 EFC, KM )
BEGIN-MODULE
BASE @
DECIMAL

Private:

FLOAT DARRAY x{                 \ array pointer
FLOAT DARRAY fx{                \ scratch array
0 value N

[undefined] }fcopy [IF]
: }fcopy ( 'src 'dest u -- )
     >r 0 } swap 0 } swap r> floats move ;
[THEN]

Public:

: Aitken ( r1 &x &f n -- r2 )   \ ( &x &f n -- ) ( f: r1 -- r2 )
        to N
        SWAP & x{  &!                    \ point to x{} data

        & fx{ N }malloc    \ r1 &f

        \ copy passed F data into the local F array
        \ because it gets modified by the subsequent calculation.

        fx{ N }fcopy  \ r1 

        N 1- 0 DO
          N I 1+ DO
            FDUP x{ J } F@ F- fx{ i } F@ F*
            FOVER x{ I } F@ F-
            fx{ J } F@ F* F-
            x{ I } F@ x{ J } F@ F- F/
            fx{ I } F!
          LOOP
        LOOP
        FDROP

        fx{ N 1- } F@
        & fx{ }free
;

BASE !
END-MODULE

TEST-CODE? [IF]   \ test code ==============================================
[undefined] t{      [IF] s" ttester" included [THEN]
[undefined] }Horner [IF] s" horner"  included [THEN]
base @
decimal
9 FLOAT ARRAY x{
9 FLOAT ARRAY y{

\ Generate points to test Lagrange interpolation, using a well-behaved
\   6th order polynomial over the interval [-1,1].
\
\ Our generating polynomial is the radial polynomial, R_6^0:
\
\    y = 20*x^6 - 30*x^4 + 12*x^2 - 1
\
\ cf. http://en.wikipedia.org/wiki/Zernike_polynomials

6 constant Norder
Norder 1+ FLOAT ARRAY a{
 20e  a{ 6 } f!
  0e  a{ 5 } f!
-30e  a{ 4 } f!
  0e  a{ 3 } f!
 12e  a{ 2 } f!
  0e  a{ 1 } f!
 -1e  a{ 0 } f!

: R60 ( F: r -- R )  a{ Norder }Horner ;

\ Points for Lagrange interpolation (need Norder+1 points)
-1.000e  x{ 0 } f!
-0.500e  x{ 1 } f!
-0.125e  x{ 2 } f!
 0.000e  x{ 3 } f!
 0.125e  x{ 4 } f!
 0.500e  x{ 5 } f!
 1.000e  x{ 6 } f!

: gen_R60 ( -- ) Norder 1+ 0 do  x{ I } f@ R60 y{ I } f! loop ;
gen_R60

: lag_int ( F: x -- y )  x{ y{ Norder 1+ aitken ;

1e-256 abs-near f!
1e-15  rel-near f!
set-near
cr
TESTING AITKEN
\ Tests inside the interpolation region
t{  -1.00000000000e  lag_int  ->  -1.00000000000e  R60  r}t
t{  -0.37500000000e  lag_int  ->  -0.37500000000e  R60  r}t
t{  -0.01464843750e  lag_int  ->  -0.01464843750e  R60  r}t
t{   0.00000000000e  lag_int  ->   0.00000000000e  R60  r}t
t{   1.0e-32         lag_int  ->   1.0e-32         R60  r}t
t{   0.09960937500e  lag_int  ->   0.09960937500e  R60  r}t 
t{   0.10009765625e  lag_int  ->   0.10009765625e  R60  r}t
t{   0.75000000000e  lag_int  ->   0.75000000000e  R60  r}t
t{   0.99951171875e  lag_int  ->   0.99951171875e  R60  r}t
t{   1.00000000000e  lag_int  ->   1.00000000000e  R60  r}t

\ We should be able to also obtain similar accuracy outside
\ the interpolation region, since the function being 
\ interpolated (R60) is a polynomial of the same order as 
\ the Lagrange polynomial.
t{ -1.0e6   lag_int  -> -1.0e6  R60  r}t
t{ -100.0e  lag_int  -> -100.0e R60  r}t
t{  -10.0e  lag_int  -> -10.0e  R60  r}t
t{   -5.0e  lag_int  ->  -5.0e  R60  r}t
t{   -2.0e  lag_int  ->  -2.0e  R60  r}t
t{    2.0e  lag_int  ->   2.0e  R60  r}t
t{    5.0e  lag_int  ->   5.0e  R60  r}t
t{   10.0e  lag_int  ->  10.0e  R60  r}t
t{  100.0e  lag_int  -> 100.0e  R60  r}t
t{  1.0e6   lag_int  -> 1.0e6   R60  r}t


0 [IF]   \ ========== original test code ==============
: A_coords1 ( -- )
     9 0 DO I S>F 0.25e F*
          FDUP x{ I } F!
          FSIN y{ I } F!
     LOOP
;

: aitken_test1 ( -- ) ( f: r -- )   \ r can be in the range 0..2 for this test
           A_coords1
           FDUP FDUP CR ." Interpolation point: " F. CR
           FSIN FSWAP             \ get exact value for later
           x{  y{ 9 Aitken
          ."      interpolated value: " F.
          ."   exact value: " F. CR
;

: A_coords2 ( -- )
     5 0 DO I 2* S>F -4.0e F+
            FDUP x{ I } F!
            1.0e 1.0e logistic y{ I } F!
     LOOP
;

: aitken_test2 ( -- ) ( f: r -- )   \ r is in the range -4..4 for this test
           A_coords2
           FDUP FDUP CR ." Interpolation point: " F. CR
           1.0e 1.0e logistic FSWAP             \ get exact value for later
           x{ y{ 5 Aitken
          ."      interpolated value: " F.
          ."   exact value: " F. CR
;
[THEN]  \ =========== end original test code =============

base !
[THEN]




