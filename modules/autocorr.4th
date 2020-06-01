\ autocorr.4th
\
\ Auto-correlation function for xyplot
\
\ Copyright (c) 2000--2005 Krishna Myneni
\ Provided under the GNU General Public License
\
\ Revisions:
\    2000-3-6   created  km
\    2005-1-14  updated use of DatasetInfo structure  km

( DatasetInfo ds1 ) \ active dataset info structure; ds1 should exist
DatasetInfo ds_acorr
create acorrbuf 32768 dfloats allot

variable np
variable npcorr
fvariable fcorrsum
fvariable fcorrnorm

: autocorrelation ( -- | compute the numerical autocorrelation function )

	\ assume dataset is ordered by increasing abscissas

	?active dup 0 >=
	if
	  ds1 get_ds
	  0 >= if
	    ds1 ->npts np !

	    \ Determine normalization constant

	    0e
	    np @ 0 do
	      i ds1 @xy fswap fdrop fdup f* f+
	    loop
	    fcorrnorm f!

	    \ Compute the normalized autocorrelation function
 
	    np @ 2* 1- npcorr !	\ there are 2N-1 pts in the autocorr func.	    
	    
	    npcorr @ 0 do
	      0e		\ running integral value
	      np @ 0 do
	        i j - np @ + 1-
	        dup dup 0< swap np @ 1- > or 
	        if 
	          drop 
	        else 
	          ds1 @xy fswap fdrop
	          i ds1 @xy fswap fdrop
	          f* f+
	        then
	      loop
	      fcorrnorm f@ f/	\ normalize the integral 
	      fcorrsum f!
	      i np @ - 1+ s>f
	      acorrbuf i 2* sfloats + sf!
	      fcorrsum f@
	      acorrbuf i 2* sfloats + sfloat+ sf!
	    loop
	          
	    \ setup the autocorrelation data structure

	    c" autocorrelation" 1+ ds_acorr DNAME !
	    c"  " 1+ ds_acorr DHEADER !
	    ds1 DTYPE @ ds_acorr DTYPE !
	    npcorr @ ds_acorr DNPTS !
	    2 ds_acorr DSIZE !
	    acorrbuf ds_acorr DDATA !

	    ds_acorr make_ds
		 
	  then
	else
	  drop
	then ;

\ add "AutoCorrelation" as an item in the math menu

MN_MATH  c" AutoCorrelation"  c" autocorrelation draw_window" add_menu_item

