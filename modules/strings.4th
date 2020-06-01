\ strings.4th
\
\ String utility words for kForth
\
\ Copyright (c) 1999--2002 Krishna Myneni
\
\ This software is provided under the terms of the
\ GNU General Public License.
\
\ Revisions:
\
\	03-24-1999  created  KM
\	03-25-1999  added number to string conversions  KM
\	08-12-1999  fixed f>string  KM
\	10-11-1999  added blank  KM
\	12-12-1999  fixed f>string for zero case  KM
\	12-22-1999  added -trailing, scan, and skip  KM
\	01-23-2000  replaced char with [char] for ANS Forth compatibility  KM
\	06-16-2000  added isdigit and modified string>s and string>f  KM
\	09-02-2000  fixed u>string to work over full range  KM
\	07-12-2001  used built-in Forth words <# #s #> for conversions,
\	              added ud>string and d>string. f>string now can handle
\                     decimal places greater than 8  KM
\	09-21-2001  changed occurences of DO to ?DO  KM
\	10-02-2001  added parse_args  KM
\	10-10-2001  fixed problem with f>string when number is 0e  KM
\	10-15-2001  added /STRING  KM
\	03-28-2002  added SEARCH, PARSE_TOKEN, PARSE_LINE, IS_LC_ALPHA  KM
\	07-31-2002  added SLITERAL; removed SEARCH since SEARCH and
\		      COMPARE are now part of kForth  KM

: blank ( addr u -- | fill u bytes starting at addr with bl character )
	bl fill ;

: /string ( a1 u1 n -- a2 u2 | adjust size of string by n characters)
	dup >r - swap r> + swap ;

: -trailing ( a n1  -- a n2 | adjust count n1 to remove trailing spaces )
	dup 0> 
	if 
	  dup 
	  0 ?do 
	    2dup + 1- c@ 
	    bl = 
	    if 1- else leave then 
	  loop
	then ;

: scan ( a1 n1 c -- a2 n2 | search for first occurence of character c )
	\ a1 n1 are the address and count of the string to be searched, 
	\ a2 n2 are the address and count of the substring starting with character c
	-rot dup
	if
	  rot over
	  0 ?do
	    >r over c@ r@ = r> swap
	    if
	      leave
	    else
	      >r 1- swap 1+ swap r>
	    then
	  loop
	  drop
	else
	  rot drop
	then ;

: skip ( a1 n1 c -- a2 n2 | search for first occurence of character not equal to c )
	\ a1 n1 are the address and count of the string to be searched,
	\ a2 n2 are the adress and count of the substring
	-rot dup
	if
	  rot over
	  0 ?do
	    >r over c@ r@ <> r> swap
	    if
	      leave
	    else
	      >r 1- swap 1+ swap r>
	    then
	  loop
	  drop
	else
	  rot drop
	then ; 

: sliteral ( a u -- | compile string into definition at compile time )
	swap postpone literal postpone literal ; immediate

: parse_token ( a u -- a2 u2 a3 u3)
	\ parse next token from the string; a3 u3 is the token string
	BL SKIP 2DUP BL SCAN 2>R R@ - 2R> 2SWAP ;

: parse_line ( a u -- a1 u1 a2 u2 ... n )
	( -trailing)
	0 >r
	begin
	  parse_token
	  dup
	while
	  r> 1+ >r
	  2swap
	repeat  
	2drop 2drop r> ;

: is_lc_alpha ( n -- flag | true if n is a lower case alphabetical character)
	DUP 96 > SWAP 123 < AND ;	
	
: isdigit ( n -- flag | return true if n is ascii value of '0' through '9' )
	dup [char] / > swap [char] : < and ;

: strcpy ( ^str addr -- | copy a counted string to addr )
	>r dup c@ 1+ r> swap cmove ;

: strlen ( addr -- len | determine length of a null terminated string )
	\ This word is not intended for use on counted strings;
	\ Use "count" to obtain the length of a counted string.
	0
	begin
	  over c@ 0= dup not if -rot 1+ swap 1+ swap rot then 
	until
	nip ;


16384 constant STR_BUF_SIZE
create string_buf STR_BUF_SIZE allot	\ dynamic string buffer
variable str_buf_ptr
string_buf str_buf_ptr !

: adjust_str_buf_ptr ( u -- | adjust pointer to accomodate u bytes )
	str_buf_ptr a@ swap +
	string_buf STR_BUF_SIZE + >=
	if
	  string_buf str_buf_ptr !	\ wrap pointer
	then ;

: strbufcpy ( ^str1 -- ^str2 | copy a counted string to the dynamic string buffer )
	dup c@ 1+ dup adjust_str_buf_ptr
	swap str_buf_ptr a@ strcpy
	str_buf_ptr a@ dup rot + str_buf_ptr ! ;

: strcat ( addr1 u1 addr2 u2 -- addr3 u3 )
	rot 2dup + 1+ adjust_str_buf_ptr 
	-rot
	2swap dup >r
	str_buf_ptr a@ swap cmove
	str_buf_ptr a@ r@ +
	swap dup r> + >r
	cmove 
	str_buf_ptr a@
	dup r@ + 0 swap c!
	dup r@ + 1+ str_buf_ptr !
	r> ;

: strpck ( addr u -- ^str | create counted string )
	255 min dup 1+ adjust_str_buf_ptr 
	dup str_buf_ptr a@ c!
	tuck str_buf_ptr a@ 1+ swap cmove
	str_buf_ptr a@ over + 1+ 0 swap c!
	str_buf_ptr a@
	dup rot 1+ + str_buf_ptr ! ;

\
\ Base 10 number to string conversions and vice-versa
\

32 constant NUMBER_BUF_LEN
create number_buf NUMBER_BUF_LEN allot

create fnumber_buf 64 allot
variable number_sign
variable number_val
variable fnumber_sign
fvariable fnumber_val
fvariable fnumber_divisor
variable fnumber_power
variable fnumber_digits
variable fnumber_whole_part

variable number_count

: u>string ( u -- ^str | create counted string to represent u in base 10 )
	base @ swap decimal 0 <# #s #> strpck swap base ! ;

: ud>string ( ud -- ^str | create counted string to represent ud in base 10 )
	base @ >r decimal <# #s #> strpck r> base ! ;

: d>string ( d -- ^str | create counted string to represent d in base 10 )
	dup >r dabs ud>string r> 0< if s" -" rot count strcat strpck then ;

: s>string ( n -- ^str | create counted string to represent n in  base 10 )
	dup >r abs u>string
	r> 0< if
	  s" -" rot count strcat strpck
	then ;

: string>s ( ^str -- n | always interpret in base 10 )
	0 number_val !
	false number_sign !
	count
	0 ?do
	  dup c@
	  case
	    [char] -  of true number_sign ! endof 
	    [char] +  of false number_sign ! endof 
	    dup isdigit 
	    if
	      dup [char] 0 - number_val @ 10 * + number_val !
	    then
	  endcase
	  1+
	loop
	drop
	number_val @ number_sign @ if negate then ;


: f>string ( f n -- ^str | conversion is in exponential format with n places )
	>r fdup f0=
	if
	  f>d <# r> 0 ?do # loop #> s" e0" strcat 
	  s"  0." 2swap strcat strpck exit	  
	then
	r>
	dup 16 swap u< if drop fdrop c" ******" exit then  \ test for invalid n
	fnumber_digits !
	0 fnumber_power !
	fdup 0e f< if true else false then fnumber_sign ! 
	fabs
	fdup 1e f<
	if
	  fdup 0e f>
	  if
	    begin
	      10e f* -1 fnumber_power +!
	      fdup 1e f>=
	    until
	  then
	else
	  fdup 
	  10e f>=
	  if
	    begin
	      10e f/ 1 fnumber_power +!
	      fdup 10e f<
	    until
	  then
	then
	10e fnumber_digits @ s>f f**
	f* floor f>d d>string
	count drop dup fnumber_buf
	fnumber_sign @ 
	if [char] - else bl then 
	swap c!
	fnumber_buf 1+ 1 cmove
	1+
	[char] . fnumber_buf 2+ c!
	fnumber_buf 3 + fnumber_digits @ cmove
	fnumber_buf fnumber_digits @ 3 +	
	" e" count strcat
	fnumber_power @ s>string count strcat
	strpck 	;

	 
: string>f ( ^str -- f )
	true fnumber_whole_part !
	0e fnumber_val f!
	1e fnumber_divisor f!
	false fnumber_sign !
	count 2dup + 1- nip swap
	begin
	  dup c@
	  case  
	    [char] - of true fnumber_sign ! endof
	    [char] + of false fnumber_sign ! endof
	    [char] . of false fnumber_whole_part ! endof
	    dup isdigit
	    if  
	      dup [char] 0 - s>f
	      fnumber_whole_part @
	      if
	        fnumber_val f@ 10e f*
	      else
	        fnumber_divisor f@ 10e f*
	        fdup fnumber_divisor f!
	        f/ fnumber_val f@
	      then
	      f+ fnumber_val f!
	    else
	      dup dup [char] E = swap [char] e = or
	      if
	        drop 2dup
		- 
	        dup 0>
	        if
	          number_buf c!
	          dup 1+ number_buf 1+ number_buf c@ cmove
	          2drop
	          number_buf string>s s>f 10e fswap f**
	        else
	          drop 2drop 1e
	        then
	        fnumber_val f@ f* fnumber_sign @ if fnegate then
	        exit
	      then
	    then
	  endcase
	  1+ 2dup <
	until	              
	2drop
	fnumber_val f@ 
	fnumber_sign @ if fnegate then ;	 


: parse_args ( a u -- f1 ... fn n | parse a string delimited by spaces into fp args )
	0 >r 
	2>r
	begin
	  r@ 0>
	while
	  2r> bl skip 
	  2dup 
	  bl scan 2>r
	  r@ - dup 0= 
	  if drop r> 0 >r then
	  strpck string>f
	  2r> r> 
	  1+ >r 2>r
	repeat
	2r> 2drop r> ;
	  
