\ xyplot.4th
\
\ Forth interface to xyplot
\
\ Copyright (c) 1999--2021 Krishna Myneni
\
\ This software is provided under the terms of the 
\ GNU Affero General Public License (AGPL), v3.0 or later.
\
\ Requires: xypw32.exe version >= 1.3.0
\
\ XYPLOT defines Forth constants which contain pointers to
\ C++ functions that interface with the Forth environment.
\
\ Defined below are words to execute the C++ interface functions:
\
\  get_color_map  ( acolorref acolornames maxlen maxcolors -- ncolors )
\  get_active_set ( -- n ) Return the set number for the active plot.
\  get_operand_set ( -- n ) Return the set number for the operand plot.
\  ?active ( -- n )	synonymous with get_active_set.
\  ?operand ( -- n ) 	synonymous with get_operand_set.
\  get_active_plot ( -- n ) Return the index of the active plot.
\  get_operand_plot ( -- n ) Return the index of the operand plot.
\  set_active_plot ( n -- ) Set the active plot to plot n.
\  set_operand_plot ( n -- ) Set the operand plot to plot n.
\  get_ds ( i addr -- n ) Return info on dataset i into a structure.
\  set_ds_extrema ( i -- ) Recompute the extrema for dataset i.
\  make_ds ( addr -- )	Make a dataset according to info in structure.
\  get_plot ( i addr -- n ) Return info on plot i into a structure.
\  drop_plot ( -- )  Drop the active plot.
\  make_plot ( addr -- ) Make a plot according to info in structure.
\  set_plot_symbol ( ^symbolname -- ) set active plot symbol.
\  set_plot_color ( ^colorname -- ) set active plot color.
\  draw_plot ( flag -- ) draw the active plot.
\  get_grid ( -- nXtics nYtics bXLines bYLines bXaxis bYaxis ) get grid params.
\  set_grid_tics ( nx ny -- ) set number of tics for x and y axes
\  set_grid_lines ( flagx flagy -- ) set grid lines on/off for x and y axes 
\  get_window_title ( c-addr umax -- c-addr uret ) get title of window.
\  set_window_title ( c-addr u -- )  set title of window.
\  clear_window ( -- )	Clear the plot window.
\  draw_window ( -- ) 	Draw the plot window.
\  reset_window ( -- ) 	Reset the plot window.
\  message_box ( a u -- ) Popup a message window to display text.
\  get_input ( ^prompt -- ^resp flag ) Provide dialog for text input.
\  file_open_dialog ( ^filter -- ^filename flag ) Provide file selection dialog.
\  get_window_limits ( -- fxmin fymin fxmax fymax ) Return window extrema.
\  set_window_limits ( fxmin fymin fxmax fymax -- ) Set window extrema.
\  add_menu_item ( menu name command -- ) Add a new menu item
\  set_background ( colorname -- ) Set plot window background color.
\  set_foreground ( colorname -- ) Set plot window foreground color.

\ Data type and precision constants

0  constant  data_REAL
1  constant  data_COMPLEX  ( currently not used )

0  constant  prec_SINGLE
1  constant  prec_DOUBLE

\ Data set types

prec_SINGLE  8 LSHIFT  data_REAL  OR  constant  REAL_SINGLE
prec_DOUBLE  8 LSHIFT  data_REAL  OR  constant  REAL_DOUBLE

\ Plotting symbol constants
0  constant  sym_LINE
1  constant  sym_DASHED
2  constant  sym_POINT
3  constant  sym_BIG_POINT
4  constant  sym_LINE_PLUS_POINT
5  constant  sym_STICK
6  constant  sym_HISTOGRAM

: get_color_map ( acolorref acolornames maxlen maxcolors -- ncolors )
    \ Return number of colors in the map; ncolors < 0 indicates error
   FN_GET_COLOR_MAP call ;

: get_active_set ( -- n | return the active dataset number )
    \ n less than zero indicates an error.
    FN_GET_ACTIVE_SET call ;

: get_operand_set ( -- n | return the operand dataset number )
    \ n less than zero indicates an error.
    FN_GET_OPERAND_SET call ;

: ?active ( -- n) get_active_set ;
: ?operand ( -- n) get_operand_set ;

: get_active_plot ( -- n | return the active plot number )
    FN_GET_ACTIVE_PLOT call ;

: get_operand_plot ( -- n | return the operand plot number )
    FN_GET_OPERAND_PLOT call ;

: set_active_plot ( n -- | set plot n as the active plot )
    FN_SET_ACTIVE_PLOT call ;

: set_operand_plot ( n -- | set plot n as the operand plot )
    FN_SET_OPERAND_PLOT call ;

: get_ds ( i addr -- n | return info on dataset i into a structure at addr )
    \ n less than zero indicates an error.
    FN_GET_DS call ;

: set_ds_extrema ( i -- | recompute the extrema for dataset i )
    FN_SET_DS_EXTREMA call ;

: make_ds ( addr -- n | make a dataset in xyplot; return set number )
    FN_MAKE_DS call ;

: get_plot ( i addr -- n | return info on plot i into a structure at addr )
    \ n less than zero indicates an error.
    FN_GET_PLOT call ;

: drop_plot ( addr -- | drop the active plot )
    FN_DROP_PLOT call ;

: make_plot ( addr -- | make a plot in xyplot )
    FN_MAKE_PLOT call ;

: set_plot_symbol ( symbolname -- | set active plot symbol )
    FN_SET_PLOT_SYMBOL call ;

: set_plot_color ( colorname -- | set active plot color )
    FN_SET_PLOT_COLOR call ;

: draw_plot ( flag -- | draw active plot, if flag = false use bkg color )
    FN_DRAW_PLOT call ;

: get_grid ( -- nXtics nYtics bXlines bYlines bXaxis bYaxis )
    FN_GET_GRID call ;

: set_grid_tics ( nx ny -- | set number of tics on x and y axes )
    FN_SET_GRID_TICS call ;

: set_grid_lines ( flagx flagy -- | set grid lines on/off on x and y axes )
    FN_SET_GRID_LINES call ;

: get_window_title ( c-addr umax -- uret )
    FN_GET_WINDOW_TITLE call ;

: set_window_title ( c-addr u -- )
    FN_SET_WINDOW_TITLE call ;

: clear_window ( -- | clear the plot window )
    FN_CLEAR_WINDOW call ;

: draw_window ( -- | draw the plot window )
    FN_DRAW_WINDOW call ;

: reset_window ( -- | reset the plot window )
    FN_RESET_WINDOW call ;

: get_window_limits ( -- fx1 fy1 fx2 fy2 | obtain the plot window limits )
    FN_GET_WINDOW_LIMITS call ;

: set_window_limits ( fx1 fy1 fx2 fy2 -- | set the plot window limits )
    FN_SET_WINDOW_LIMITS call ;

: add_menu_item ( menu name command -- | add new menu item )
    FN_ADD_MENU_ITEM call ;

: set_background ( colorname -- | set plot window background color )
    FN_SET_BACKGROUND call ;

: set_foreground ( colorname -- | set plot window foreground color )
    FN_SET_FOREGROUND call ;

: message_box ( a u -- | pop up a message window to display text )
    FN_MESSAGE_BOX call ;

: get_input ( ^prompt -- ^resp flag | get text input from dialog box )
    FN_GET_INPUT call ;

: file_open_dialog ( ^filter -- ^filename flag )
    FN_FILE_OPEN call ;


1 SFLOATS constant SFLOAT       \ size in bytes of single precision float

\ kForth libraries, utilities, and modules support
include ans-words.4th
include strings.4th
include files.4th
include utils.4th
include modules.fs
include struct.4th
include struct-ext.4th

\ Save Options structure
\   HeaderType: 0=none, 1=xyplot format, 2=user-defined line prefix
\   Delimiter:  0=space, 1=tab, 2=comma, other=space
\   NumberFormat: 0=exponential, 1=fixed point, 2=integer, other=exponential
\   EndOfLine:  0=Unix, 1=DOS
\   UserPrefix: text prefix for header type option 2
struct
  cell%  field  SaveOptions->HeaderType
  cell%  field  SaveOptions->Delimiter
  cell%  field  SaveOptions->NumberFormat
  cell%  field  SaveOptions->EndOfLine
  1 16 chars field SaveOptions->UserPrefix
end-struct SaveOptions%

\ Dataset Information Structure
struct
  cell%  field  DataSetInfo->Name    \ pointer to name string
  cell%  field  DataSetInfo->Header  \ pointer to header string
  cell%  field  DataSetInfo->Type    \ dataset type
  cell%  field  DataSetInfo->Npts    \ number of points in set
  cell%  field  DataSetInfo->Size    \ datum dimension
  cell%  field  DataSetInfo->Data    \ pointer to data
end-struct DatasetInfo%

\ Plot Information Structure
struct
  cell%  field  PlotInfo->Set     \ data set number
  cell%  field  PlotInfo->Type    \
  cell%  field  PlotInfo->Symbol  \ plot symbol
  cell%  field  PlotInfo->Color   \ plot color
end-struct PlotInfo%

\ Defining words for making DatasetInfo% and PlotInfo% structures

: DatasetInfo  create DatasetInfo% %allot drop ; nondeferred
: PlotInfo     create PlotInfo%    %allot drop ; nondeferred 
: SaveOptions  create SaveOptions% %allot drop ; nondeferred

\ Useful words to fetch and store the i^th x, y pair from/to
\ a dataset are given below. Note that addr is the address of 
\ the dataset info structure and the index i starts at 0 for 
\ the first point.
\
\ If you want to perform computations efficiently, it's better to
\ work with the pointer to the data directly and increment it
\ to avoid all of the computations for each index. Both methods
\ -- one using the @xy and !xy words, and one that works 
\ directly with the data pointer are illustrated in the words 
\ test1 and test2, contained in test.4th.

: @xy ( i addr -- fx fy | retrieve the i^th x, y pair )
	dup DatasetInfo->Size @ SFLOAT * rot * swap DatasetInfo->Data a@
	swap + dup >r sf@ r> SFLOAT + sf@ ; 

: !xy ( fx fy i addr -- | store the i^th x, y pair )
	dup DatasetInfo->Size @ SFLOAT * rot * swap DatasetInfo->Data a@
	swap + dup >r SFLOAT + sf! r> sf! ; 


\ see the file test.4th for examples of usage

\ Load all of the forth files that provide basic functions
\ and menu items

\ Modules from the Forth Scientific Library (FSL, kForth-port)
include fsl/fsl-util
include fsl/dynmem
include fsl/complex
include fsl/horner
include fsl/lufact
include fsl/dets
include fsl/gaussj
include fsl/extras/determ
include fsl/extras/curvefit
include fsl/extras/four1
include fsl/extras/derivative
include fsl/extras/polyfit

\ XYPLOT modules ( ver >= 1.3.0 )
include xutils
include arithmetic
include xypolyfit
include xyexpfit
include xyhistogram
\ include xyfft
include smooth
include lpf
include autocorr
include xyderiv
include xyarea
include peak_search
include xypeaks
include xysort
include xyswap
include yn_vs_ym
include abs
include ylog
include yln
include xymap
include grace
include xyjoin

\ You can put some initialization stuff here, for example
\  to set the background and foreground colors.

c" white" set_background
c" black" set_foreground
0 0 set_grid_lines

\ end of xyplot.4th

