\ xutils.4th
\
\ xyplot Forth interface utilities
\
\ Copyright (c) 1999-2020 Krishna Myneni
\
\ This software is provided under the terms of the
\ GNU Affero General Public License (AGPL) v3.0 or later.
\

: tdstring ( -- a u | return a date and time string )
        time&date
        s"  "
        rot 0 <# [char] - hold # # # # #> strcat
        rot 0 <# [char] - hold # # #>     strcat
        rot 0 <# bl hold # # #>           strcat
        rot 0 <# [char] : hold # # #>     strcat
        rot 0 <# [char] : hold # # #>     strcat
        rot 0 <# # # #>                   strcat
;


: is-path-delim? ( c -- flag )
    dup dup 
    [char] \ = >r 
    [char] / = >r
    [char] : = 
    r> or r> or ;

\ Split a string containing a path+filename into a path name and 
\ a file name.

: split-path ( c-addr u -- c-pathaddr u1 c-fileaddr u2 )
    ?dup IF
      2dup 1- + 1  \ -- c-addr u  {c-addr+u-1} 1
      begin
        over c@ is-path-delim? 0= >r
        dup 3 pick <= r> and
      while
        1+ >r 1- r>
      repeat
      \ -- c-addr u  c-addr2 u2
      ?dup IF
        1 /string   \ c-addr u c-fileaddr u2
        2dup 2>r nip
        -  2r>
      ELSE
        2>r drop 0 2r>
      THEN
    ELSE
      0 2dup
    THEN ;
 

DatasetInfo ds1
DatasetInfo ds2

fvariable fxmin
fvariable fxmax
fvariable fymin
fvariable fymax


: ds_extrema ( dsaddr1 -- | determine the dataset extrema )
	\ results are stored in the variables fxmin, fxmax, fymin, fymax
	dup 0 swap @xy fdup fymax f! fymin f! fdup fxmax f! fxmin f!
	dup DatasetInfo->Npts @ 1 do
	  i over @xy
	  fdup fymin f@ fmin fymin f!
	  fymax f@ fmax fymax f!
	  fdup fxmin f@ fmin fxmin f!
	  fxmax f@ fmax fxmax f!
	loop
	drop ;


variable dstemp
variable npts
variable ordering
fvariable fdel1
variable jtemp

: findx ( fx addr -- n | return index of point with closest x to fx )
	\ addr is the address of a dataset info structure
	dup dstemp ! DatasetInfo->Npts @ npts !	
	0 dstemp a@ @xy fdrop
	npts @ 1- dstemp a@ @xy fdrop
	f< ordering !
	npts @ 0
	begin
	  2dup - 1 >
	while
	  2dup + 2/ -rot
	  >r >r 
	  dup dstemp a@ @xy fdrop rot 
	  >r fover f<= ordering @ =
	  r> swap r> r> rot
	  if drop swap else nip then 
	repeat
	nip dup jtemp !
	dstemp a@ @xy fdrop fover f- fabs fdel1 f!
	jtemp @ npts @ 1- < if
	  jtemp @ 1+ dstemp a@ @xy fdrop f- fabs
	  fdel1 f@ f< if 1 jtemp +! then
	else
	  fdrop
	then
	jtemp @ ;  


: index_limits ( dsaddr -- n1 n2 | return indices spanning window domain )

;



fvariable fx1
fvariable fx2

: overlap ( dsaddr1 dsaddr2 -- flag | determine the overlap of two datasets )
	\ store the overlap region in fx1 and fx2
	\ flag is true if the regions overlap
	ds_extrema fxmin f@ rot fxmax f@ rot
	ds_extrema fxmax f@ fmin fx2 f!
	fxmin f@ fmax fx1 f!
	fx1 f@ fx2 f@ f<= ;



: index_range ( -- n1 n2 | return starting and ending indices of overlap region in active set )
	?active
	dup 0 >= if
	  ds1 get_ds drop
	  ?operand
	  dup 0 >= if
	    ds2 get_ds drop
	    ds1 ds2 overlap		\ determine if sets overlap
	    if
	      fx1 f@ ds1 findx		\ find starting and ending indices of
	      fx2 f@ ds1 findx		\ overlap region in active dataset
	      1+
	      2dup > if swap then	\ swap if descending order
	      2dup = if 1+ then		\ adjust to prevent infinite loop
	      exit
	    then
	  then
	  drop
	then
	drop
	0 0 ;
	

