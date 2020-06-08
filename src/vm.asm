; vm.asm
;
; The kForth Virtual Machine
;
; Copyright (c) 1998--2003 Krishna Myneni, Creative Consulting
;   for Research and Education
;
; This software is provided under the terms of the GNU
;   General Public License
;
; Usage from C++
;
;       extern "C" int vm (byte* ip);
;       ecode = vm(ip);
;
; Written for the A386 assembler
;
;       a386 +c+O vm.asm
;
; Revisions:
;	9-8-1998  additional functions added: c@, c!, f=, f<>
;	9-10-1998 added: and, or, not, xor
;	9-11-1998 added: = , <>, <, >, <=, >=
;	9-15-1998 added: +!, fsqrt, fsin, fcos, -rot, sp@, rp@
;	9-17-1998 added: a@
;	9-27-1998 added: mod, 2*, 2/
;	10-1-1998 added: pick
;	10-4-1998 fixed signed integer division and mod; added /MOD
;	10-6-1998 added ?dup
;	10-14-1998 added count
;	10-16-1998 fixed L_div error
;	10-19-1998 added 0<, 0=, 0>, true, false
;	10-20-1998 added 2+, 2-
;	02-09-1999 added execute
;	03-01-1999 added open, lseek, close, read, write
;	03-02-1999 added ioctl
;	03-03-1999 added usleep
;	03-07-1999 added fill, cmove
;	03-09-1999 interchanged meaning of execute and call
;		   to be consistent with ANS Forth
;	03-27-1999 added +loop, unloop
;	03-29-1999 added roll
;	03-31-1999 added cmove>, key
;	05-05-1999 fixed +loop
;	05-06-1999 added fround
;	05-15-1999 added floor
;	05-26-1999 added fatan2, lshift, rshift
;	05-27-1999 added u<, quit, base
;	06-02-1999 added */, */mod
;	06-09-1999 call CPP functions from vm
;	07-18-1999 added find
;	09-06-1999 added pTIB, word, tick
;	09-12-1999 added system
;	10-04-1999 added create, variable, fvariable as intrinsic words
;	10-06-1999 added constant, fconstant as intrinsic words
;	10-07-1999 added chdir
;   10-08-1999 added erase, brackettick
;	10-09-1999 added time&date, ms, question, bl
;   10-10-1999 added char, forget, cold
;   10-20-1999 added >file, console
;	10-28-1999 added key?
;	12-24-1999 added hooks for f0=, f0<, f0>, u>, s>d, d>f, f>d,
;	              um*, um/mod, m*, m+, m/, m*/
;	12-25-1999 added cells, cell+, dfloats, dfloat+
;	12-27-1999 added bye
;	01-08-2000 fixed f0<, increased vm loop efficiency
;	01-13-1999 added ?allot, fixed f0=
;	01-22-2000 modified + to remove ordering sensitivity for address arithmetic
;	01-23-2000 added 0<>, [char], .r, u.r, changed opcodes for
;	             relational operators
;	01-24-2000 added CPP_literal, CPP_cquote, CPP_squote, CPP_dotquote
;	02-04-2000 implemented m*, um*
;	02-26-2000 fixed fm/mod, added sm/rem, um/mod
;	03-02-2000 modified QUIT to clear the return stacks, added CPP_do
;	03-05-2000 added CPP_begin, CPP_while, CPP_repeat, CPP_until, CPP_again,
;	             CPP_leave, CPP_if, CPP_else, CPP_then, CPP_lparen
;	05-17-2000 added CPP_does
;	05-18-2000 fix L_plusloop for negative increments
;	06-04-2000 fix L_roll to roll the typestack as well
;	06-11-2000 added CPP_case, CPP_endcase, CPP_of, and CPP_endof
;	06-15-2000 added CPP_querydo, CPP_abortquote
;
        .386p

public _GlobalSp, _GlobalTp, _GlobalIp, _GlobalRp, _GlobalRtp
public _BottomOfStack, _BottomOfReturnStack, _BottomOfTypeStack
public _BottomOfReturnTypeStack, _vmEntryRp, _Base, _State
public _pTIB, _TIB, _WordBuf, _NumberCount, _NumberBuf
public _JumpTable

EXTRN _C_ftan:NEAR, _C_facos:NEAR, _C_fasin:NEAR, _C_fatan:NEAR
EXTRN _C_fexp:NEAR, _C_fln:NEAR, _C_flog:NEAR, _C_fpow:NEAR
EXTRN _C_fmin:NEAR, _C_fmax:NEAR, _C_open:NEAR, _C_close:NEAR
EXTRN _C_lseek:NEAR, _C_read:NEAR, _C_write:NEAR, _C_ioctl:NEAR
EXTRN _C_key:NEAR, _C_accept:NEAR, _C_numberquery:NEAR
EXTRN _C_system:NEAR, _C_chdir:NEAR, _C_timeanddate:NEAR
EXTRN _CPP_dot:NEAR, _CPP_udot:NEAR
EXTRN _CPP_dotr:NEAR, _CPP_udotr:NEAR
EXTRN _CPP_fdot:NEAR, _CPP_dots:NEAR
EXTRN _CPP_emit:NEAR, _CPP_cr:NEAR,
EXTRN _CPP_spaces:NEAR
EXTRN _CPP_type:NEAR, _CPP_words:NEAR
EXTRN _CPP_word:NEAR, _CPP_allot:NEAR
EXTRN _CPP_queryallot:NEAR
EXTRN _CPP_create:NEAR, _CPP_variable:NEAR
EXTRN _CPP_fvariable:NEAR, _CPP_constant:NEAR
EXTRN _CPP_fconstant:NEAR, _CPP_brackettick:NEAR
EXTRN _CPP_bracketchar:NEAR, _CPP_char:NEAR
EXTRN _CPP_forget:NEAR, _CPP_cold:NEAR
EXTRN _CPP_squote:NEAR, _CPP_cquote:NEAR
EXTRN _CPP_lparen:NEAR, _CPP_literal:NEAR
EXTRN _CPP_dotquote:NEAR, _CPP_if:NEAR
EXTRN _CPP_else:NEAR, _CPP_then:NEAR
EXTRN _CPP_case:NEAR, _CPP_endcase:NEAR
EXTRN _CPP_of:NEAR, _CPP_endof:NEAR
EXTRN _CPP_do:NEAR, _CPP_querydo:NEAR
EXTRN _CPP_leave:NEAR, _CPP_abortquote:NEAR
EXTRN _CPP_recurse:NEAR, _CPP_begin:NEAR
EXTRN _CPP_while:NEAR, _CPP_repeat:NEAR
EXTRN _CPP_until:NEAR, _CPP_again:NEAR
EXTRN _CPP_does:NEAR
EXTRN _Sleep@4:NEAR

WSIZE   equ 4

OP_ADDR equ 65
OP_FVAL equ 70
OP_IVAL equ 73
OP_RET  equ 238
SIGN_MASK  equ  080000000H

; Error Codes

E_NOT_ADDR      equ     1
E_DIV_ZERO      equ     4
E_RET_STK_CORRUPT equ   5
E_UNKNOWN_OP    equ     6
E_DIV_OVERFLOW  equ    20

_DATA SEGMENT PUBLIC FLAT
NDPcw     dd  0
FCONST_180 dq 180.
_GlobalSp dd 0
_GlobalTp dd 0
_GlobalIp dd 0
_GlobalRp dd 0
_GlobalRtp dd 0
_BottomOfStack dd 0
_BottomOfReturnStack dd 0
_BottomOfTypeStack dd 0
_BottomOfReturnTypeStack dd 0
_vmEntryRp dd 0
_Base dd 0
_State dd 0
_Precision dd 0
_pTIB dd 0
_TIB db 256 dup 0
_WordBuf db 256 dup 0
_ParseBuf db 1024 dup 0
_NumberCount dd 0
_NumberBuf db 256 dup 0

_JumpTable dd L_false, L_true, L_cells, L_cellplus ; 0 -- 3
          dd L_dfloats, L_dfloatplus, _CPP_case, _CPP_endcase ; 4 -- 7
          dd _CPP_of, _CPP_endof, _C_open, _C_lseek   ; 8 -- 11
          dd _C_close, _C_read, _C_write, _C_ioctl ; 12 -- 15
          dd L_usleep, L_ms, _C_msfetch, L_nop     ; 16 -- 19
          dd L_fill, L_cmove, L_cmovefrom, _CPP_dotparen  ; 20 -- 23
          dd _CPP_bracketsharp, _CPP_tofile, _CPP_console, _CPP_sharpbracket   ; 24 -- 27
          dd _CPP_sharps, _CPP_squote, _CPP_cr, L_bl      ; 28 -- 31
          dd _CPP_spaces, L_store, _CPP_cquote, _CPP_sharp ; 32 -- 35
          dd _CPP_sign, L_mod, L_and, _L_tick      ; 36 -- 39
          dd _CPP_lparen, _CPP_hold, L_mul, L_add        ; 40 -- 43
          dd L_nop, L_sub, _CPP_dot, L_div     ; 44 -- 47
          dd _L_dabs, L_dnegate, L_umstar, L_umslashmod   ; 48 -- 51
          dd L_mstar, L_mplus, L_mslash, _L_mstarslash ; 52 -- 55
          dd L_fmslashmod, L_smslashrem, L_nop, L_nop        ; 56 -- 59
          dd L_lt, L_eq, L_gt, L_question      ; 60 -- 63
          dd L_fetch, L_addr, L_base, L_call    ; 64 -- 67
          dd L_definition, L_erase, L_fval, _CPP_forget      ; 68 -- 71
          dd L_tobody, L_ival, _CPP_evaluate, _C_key       ; 72 -- 75
          dd L_lshift, L_slashmod, _C_numberquery, _CPP_dotr   ; 76 -- 79
          dd _CPP_ddot, _C_keyquery, L_rshift, _CPP_dots ; 80 -- 83
          dd _C_accept, _CPP_char, _CPP_bracketchar, _CPP_word    ; 84 -- 87
          dd L_starslash, L_starslashmod, _CPP_udotr, _CPP_lbracket   ; 88 -- 91
          dd _CPP_backslash, _CPP_rbracket, L_xor, _CPP_literal  ; 92 -- 95
          dd _CPP_queryallot, _CPP_allot, L_binary, L_count ; 96 -- 99
          dd L_decimal, _CPP_emit, _CPP_fdot, _CPP_cold   ; 100 -- 103
          dd L_hex, L_i, L_j, _CPP_brackettick ; 104 -- 107
          dd _CPP_fvariable, _C_timeanddate, _CPP_find, _CPP_constant  ; 108 -- 111
          dd _CPP_immediate, _CPP_fconstant, _CPP_create, _CPP_dotquote ; 112 -- 115
          dd _CPP_type, _CPP_udot, _CPP_variable, _CPP_words ; 116 -- 119
          dd _CPP_does, _C_system, _C_chdir, _C_search        ; 120 -- 123
          dd L_or, _C_compare, L_not, L_nop         ; 124 -- 127
          dd L_fsin, L_fcos, _C_ftan, _C_fasin ; 128 -- 131
          dd _C_facos, _C_fatan, _C_fexp, _C_fln   ; 132 -- 135
          dd _C_flog, L_fatan2, L_ftrunc, L_ftrunctos   ; 136 -- 139
          dd _C_fmin, _C_fmax, L_floor, L_fround ; 140 -- 143
          dd L_dlt, L_dzeroeq, L_deq, L_twopush  ; 144 -- 147
          dd L_twopop, L_tworfetch, L_stod, L_stof      ; 148 -- 151
          dd L_dtof, L_froundtos, L_ftod, L_degtorad ; 152 -- 155
          dd L_radtodeg, L_dplus, _L_dminus, L_nop   ; 156 -- 159
          dd L_inc, L_dec, L_abs, L_neg        ; 160 -- 163
          dd L_min, L_max, L_twostar, L_twodiv ; 164 -- 167
          dd L_twoplus, L_twominus, L_cfetch, L_cstore ; 168 -- 171
          dd L_wfetch, L_wstore, L_dffetch, L_dfstore  ; 172 -- 175
          dd L_sffetch, L_sfstore, L_spfetch, L_plusstore ; 176 -- 179
          dd L_fadd, L_fsub, L_fmul, L_fdiv    ; 180 -- 183
          dd L_fabs, L_fneg, _C_fpow, L_fsqrt   ; 184 -- 187
          dd L_nop, L_nop, L_feq, L_fne        ; 188 -- 191
          dd L_flt, L_fgt, L_fle, L_fge        ; 192 -- 195
          dd L_fzeroeq, L_fzerolt, L_fzerogt, L_nop ; 196 -- 199
          dd L_drop, L_dup, L_swap, L_over     ; 200 -- 203
          dd L_rot, L_minusrot, L_nip, L_tuck  ; 204 -- 207
          dd L_pick, L_roll, _L_2drop, _L_2dup   ; 208 -- 211
          dd L_2swap, L_2over, L_2rot, _L_depth ; 212 -- 215
          dd L_querydup, _CPP_if, _CPP_else, _CPP_then ; 216 -- 219
          dd L_push, L_pop, L_puship, L_rfetch ; 220 -- 223
          dd L_rpfetch, L_afetch, _CPP_do, _CPP_leave ; 224 -- 227
          dd _CPP_querydo, _CPP_abortquote, L_jz, L_jnz ; 228 -- 231
          dd L_jmp, L_loop, L_plusloop, L_unloop ; 232 -- 235
          dd L_execute, _CPP_recurse, _L_ret, _L_abort  ; 236 -- 239
          dd _L_quit, L_ge, L_le, L_ne         ; 240 -- 243
          dd L_zeroeq, L_zerone, L_zerolt, L_zerogt ; 244 -- 247
          dd L_ult, L_ugt, _CPP_begin, _CPP_while ; 248 -- 251
          dd _CPP_repeat, _CPP_until, _CPP_again, _CPP_bye ; 252 -- 255
_DATA ENDS

_TEXT   SEGMENT PUBLIC  FLAT

public _L_depth, _L_abort, _L_quit, _L_tick, _L_ret, _L_dabs
public _L_2dup, _L_2drop, _L_dminus, _L_mstarslash
public _vm

LDSP     MACRO  mov ebx, _GlobalSp  #EM
STSP     MACRO  mov _GlobalSp, ebx  #EM
INC_DSP  MACRO  add ebx, WSIZE      #EM
DEC_DSP  MACRO  sub ebx, WSIZE      #EM
INC2_DSP MACRO  add ebx, 2*WSIZE    #EM
INC_DTSP MACRO  inc _GlobalTp       #EM
DEC_DTSP MACRO  dec _GlobalTp       #EM
INC2_DTSP MACRO add _GlobalTp, 2    #EM

STD_IVAL MACRO  
  mov edx, _GlobalTp
  mov B[edx], OP_IVAL
  dec _GlobalTp
#EM

STD_ADDR MACRO
  mov edx, _GlobalTp
  mov B[edx], OP_ADDR
  dec _GlobalTp
#EM

UNLOOP MACRO
  add _GlobalRp, 3*WSIZE
  add _GlobalRtp, 3
#EM

NEXT MACRO
	inc ebp
	mov _GlobalIp, ebp
	mov al, B[ebp]
	shl eax, 2
	mov ecx, offset _JumpTable
	add ecx, eax
	xor eax, eax
	jmp [ecx]
#EM

DROP MACRO
	INC_DSP
	STSP
	INC_DTSP
#EM

_DUP MACRO
	mov ecx, [ebx + WSIZE]
	mov [ebx], ecx
	DEC_DSP
	STSP
	mov ecx, _GlobalTp
	mov al, B [ecx + 1]
	mov [ecx], al
	xor eax, eax
	DEC_DTSP
#EM

_NOT MACRO  not [ebx + WSIZE]  #EM

STOD MACRO
	LDSP
	mov ecx, WSIZE
	mov eax, [ebx + WSIZE]
	cdq
	mov [ebx], edx
	sub ebx, ecx
	STSP
	STD_IVAL
	xor eax, eax
#EM

DPLUS MACRO
	LDSP
	INC2_DSP
	mov eax, [ebx]
	clc
	add eax, [ebx + 2*WSIZE]
	mov [ebx + 2*WSIZE], eax
	mov eax, [ebx + WSIZE]
	adc eax, [ebx - WSIZE]
	mov [ebx + WSIZE], eax
	STSP
	INC2_DTSP
	xor eax, eax
#EM

DMINUS MACRO
	LDSP
	INC2_DSP
	mov eax, [ebx + 2*WSIZE]
	clc
	sub eax, [ebx]
	mov [ebx + 2*WSIZE], eax
	mov eax, [ebx + WSIZE]
	sbb eax, [ebx - WSIZE]
	mov [ebx + WSIZE], eax
	STSP
	INC2_DTSP
	xor eax, eax
#EM


FETCH MACRO
      mov ebx, _GlobalTp
      inc ebx
      mov al, B[ebx]
      cmp al, OP_ADDR
      jnz E_NOT_ADDR
      mov B[ebx], #1
      LDSP
      INC_DSP
      mov eax, [ebx]
      mov eax, [eax]
      mov [ebx], eax
      xor eax, eax
#EM

SWAP MACRO
	LDSP
	INC_DSP
	mov eax, [ebx]
	INC_DSP
	mov ecx, [ebx]
	mov [ebx], eax
	mov [ebx - WSIZE], ecx
	mov ebx, _GlobalTp
	inc ebx
	mov al, B[ebx]
	inc ebx
	mov cl, B[ebx]
	mov B[ebx] al
	mov B[ebx-1], cl
	xor eax, eax
#EM

OVER MACRO
	LDSP
	mov eax, [ebx + 2*WSIZE]
	mov [ebx], eax
	DEC_DSP
	STSP
	mov ebx, _GlobalTp
	mov al, B[ebx + 2]
	mov B[ebx], al
	dec _GlobalTp
	xor eax, eax
#EM

FDUP MACRO
	LDSP
	mov ecx, ebx
	INC_DSP
	mov edx, [ebx]
	INC_DSP
	mov eax, [ebx]
	mov ebx, ecx
	mov [ebx], eax
	DEC_DSP
	mov [ebx], edx
	DEC_DSP
	STSP
	mov ebx, _GlobalTp
	inc ebx
	mov ax, W[ebx]
	sub ebx, 2
	mov W[ebx], ax
	dec ebx
	mov _GlobalTp, ebx
	xor eax, eax
#EM

FDROP MACRO
	mov eax, 2*WSIZE
	add _GlobalSp, eax
	INC2_DTSP
	xor eax, eax
#EM

FSWAP MACRO
#EM

FOVER MACRO
#EM

PUSH_R MACRO
#EM

POP_R MACRO
#EM

; Dyadic Logic operators

; Error jumps
E_notaddr:
	mov eax, E_NOT_ADDR
	ret

E_retstkcorrupt:
	mov eax, E_RET_STK_CORRUPT
	ret

E_divzero:
	mov eax, E_divzero
	ret

E_divoverflow:
	mov eax, E_DIV_OVERFLOW
	ret

; set kForth's default fpu settings
L_initfpu:
	mov ebx, _GlobalSp
	fnstcw offset NDPcw
	mov ecx, NDPcw
	and ch, 240
	or  ch, 2
	mov [ebx], ecx
	fldcw [ebx]
	ret


_vm     proc    near
;
        push ebp
        push ebx
        push ecx
        push edx
	push _GlobalIp
	push _vmEntryRp
        mov ebp, esp
        mov ebp, [ebp+28]      ; load the Forth instruction pointer
        mov _GlobalIp, ebp
	mov eax, _GlobalRp
	mov _vmEntryRp, eax
	xor eax, eax
next:
        mov al, [ebp]		; get the opcode
        shl eax, 2              ; determine offset of opcode
        mov ebx, offset _JumpTable
        add ebx, eax            ; address of machine code
        xor eax, eax            ; clear error code
        call [ebx]              ; call the word
	mov ebp, _GlobalIp
	inc ebp			; increment the Forth instruction ptr
	mov _GlobalIp, ebp
        cmp al, 0               ; check for error
        jz next                 ;
exitloop:
        cmp eax, OP_RET         ; return from vm?
        jnz vmexit
        xor eax, eax            ; clear the error
vmexit:
	pop _vmEntryRp
	pop _GlobalIp 
	pop edx
        pop ecx
        pop ebx
        pop ebp
        ret

_L_ret:
	mov eax, _vmEntryRp	; Return Stack Ptr on entry to VM
	mov ecx, _GlobalRp
	cmp ecx, eax
	jl ret1
	mov eax, OP_RET		; exhausted the return stack so exit 
	ret
ret1:
	add ecx, WSIZE
	mov _GlobalRp, ecx
	inc _GlobalRtp
	mov ebx, _GlobalRtp
	mov al, [ebx]
        cmp al, OP_ADDR
        jnz E_RET_STK_CORRUPT
	mov eax, [ecx]   
        mov _GlobalIp, eax	; reset the instruction ptr
        xor eax, eax
retexit:
        ret

L_nop:
        mov eax, E_UNKNOWN_OP   ; unknown operation
        ret

_L_quit:
        mov eax, _BottomOfReturnStack   ; clear the return stacks
        mov _GlobalRp, eax
	mov _vmEntryRp, eax
        mov eax, _BottomOfReturnTypeStack
        mov _GlobalRtp, eax
        mov eax, 8              ; exit the virtual machine
        ret

_L_abort:
        mov eax, _BottomOfStack
        mov _GlobalSp, eax
        mov eax, _BottomOfTypeStack
        mov _GlobalTp, eax
        jmp _L_quit

L_base:
        LDSP
        mov D[ebx], offset _Base
        DEC_DSP
        STSP
	STD_ADDR
	xor eax, eax
        ret

L_precision:
	LDSP
	mov ecx, _Precision
	mov [ebx], ecx
	DEC_DSP
	STSP
	STD_IVAL
	xor eax, eax
	ret

L_setprecision:
	LDSP
	DROP
	mov ecx, [ebx]
	mov _Precision, ecx
	ret

L_binary:
        mov _Base, 2
        ret

L_decimal:
        mov _Base, 10
        ret

L_hex:
        mov _Base, 16
        ret

L_false:
        LDSP
        mov D[ebx], 0
        DEC_DSP
        STSP
        STD_IVAL
        ret

L_true:
        LDSP
        mov D[ebx], -1
        DEC_DSP
        STSP
        STD_IVAL
        ret

L_cells:
        LDSP
        add ebx, WSIZE
        mov eax, [ebx]
        sal eax, 2
        mov [ebx], eax
        xor eax, eax
        ret

L_cellplus:
        LDSP
        add ebx, WSIZE
        mov eax, [ebx]
        add eax, WSIZE
        mov [ebx], eax
        xor eax, eax
        ret

L_dfloats:
        LDSP
        add ebx, WSIZE
        mov eax, [ebx]
        sal eax, 3
        mov [ebx], eax
        xor eax, eax
        ret

L_dfloatplus:
        LDSP
        add ebx, WSIZE
        mov eax, [ebx]
        add eax, WSIZE
        add eax, WSIZE
        mov [ebx], eax
        xor eax, eax
        ret

L_bl:
        LDSP
        mov D[ebx], 32
        DEC_DSP
        STSP
        STD_IVAL
        ret

_L_tick:
        LDSP
        mov D[ebx], 32
        sub _GlobalSp, WSIZE
        dec _GlobalTp
        call _CPP_word
        call _CPP_find
        call L_drop
        ret

L_tobody:
	LDSP
	INC_DSP
	mov ecx, [ebx]	; code address
	inc ecx		; the data address is offset by one
	mov ecx, [ecx]
	mov [ebx], ecx
	ret
;
; For precision delays, use MS instead of USLEEP
; Use USLEEP when task can be put to sleep and reawakened by OS
;
L_usleep:
	mov eax, WSIZE
        add _GlobalSp, eax
        inc _GlobalTp
        mov ebx, _GlobalSp
        mov eax, [ebx]
        cdq
        mov ebx, 1000
        idiv ebx
        push eax
        call _Sleep@4
        ; pop eax
        xor eax, eax
        ret

L_ms:
        mov ebx, _GlobalSp
        add ebx, WSIZE
        mov eax, 1000
        imul D[ebx]
        mov [ebx], eax
        call L_usleep
        ret

L_fill:
        call L_swap
        mov eax, WSIZE
        add _GlobalSp, eax
        inc _GlobalTp
        mov ebx, _GlobalSp
        mov ebx, [ebx]
        push ebx
        add _GlobalSp, eax
        inc _GlobalTp
        mov ebx, _GlobalSp
        mov ebx, [ebx]
        push  ebx
        add _GlobalSp, eax
        inc _GlobalTp
        mov ebx, _GlobalTp
        mov al, [ebx]
        cmp al, OP_ADDR
        jz fill2
        pop ebx
        pop ebx
        mov eax, E_NOT_ADDR
        jmp fillexit
fill2:  mov ebx, _GlobalSp
        mov ebx, [ebx]
        push ebx
        call _memset
        add esp, 12
        xor eax, eax
fillexit:
        ret
L_erase:
        mov ebx, _GlobalSp
        mov D[ebx], 0
        sub ebx, WSIZE
        mov _GlobalSp, ebx
        dec _GlobalTp
        call L_fill
        ret
L_cmove:
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalSp
        mov ebx, [ebx]
        push ebx
        call L_swap
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalTp
        mov al, [ebx]
        cmp al, OP_ADDR
        jz cmove2
        pop ebx
        mov eax, E_NOT_ADDR
        ret
cmove2: mov ebx, _GlobalSp
        mov ebx, [ebx]
        push ebx
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalTp
        mov al, [ebx]
        cmp al, OP_ADDR
        jz cmove3
        pop ebx
        pop ebx
        mov eax, E_NOT_ADDR
        ret
cmove3: mov ebx, _GlobalSp
        mov ebx, [ebx]
        push ebx
        call _memcpy
        add esp, 12
        xor eax, eax
        ret
L_cmovefrom:
        mov eax, WSIZE
        add _GlobalSp, eax
        inc _GlobalTp
        mov ebx, _GlobalSp
        mov ecx, [ebx]	; load count register
        add _GlobalSp, eax
        inc _GlobalTp
        mov ebx, _GlobalTp
        mov al, [ebx]
        cmp al, OP_ADDR
        jz cmovefrom2
        mov eax, E_NOT_ADDR
        ret
cmovefrom2:
        mov ebx, _GlobalSp
        mov ebx, [ebx]
        mov eax, ecx
        dec eax
        add ebx, eax
        mov edx, ebx	; dest addr in edx
        mov eax, WSIZE
        add _GlobalSp, eax
        inc _GlobalTp
        mov ebx, _GlobalTp
        mov al, [ebx]
        cmp al, OP_ADDR
        jz cmovefrom3
        mov eax, E_NOT_ADDR
        ret
cmovefrom3:
        mov ebx, _GlobalSp
        mov ebx, [ebx]
        mov eax, ecx
	  cmp eax, 0
	  jnz cmovefrom4
	  ret
cmovefrom4:
        dec eax
        add ebx, eax	; src addr in ebx
cmovefromloop:
        mov al, [ebx]
        dec ebx
        xchg edx, ebx
        mov B[ebx], al
        dec ebx
        xchg edx, ebx
        loop cmovefromloop
        xor eax, eax
        ret
L_call:
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalSp
        call [ebx]
        xor eax, eax
        ret
L_push:
        mov eax, WSIZE
        mov ebx, _GlobalSp
        add ebx, eax
        mov _GlobalSp, ebx
        mov ecx, [ebx]
        mov ebx, _GlobalRp
        mov [ebx], ecx
        sub ebx, eax
        mov _GlobalRp, ebx
        mov ebx, _GlobalTp
        inc ebx
        mov _GlobalTp, ebx
        mov al, [ebx]
        mov ebx, _GlobalRtp
        mov B[ebx], al
        dec ebx
        mov _GlobalRtp, ebx
        xor eax, eax
        ret
L_pop:
        mov eax, WSIZE
        mov ebx, _GlobalRp
        add ebx, eax
        mov _GlobalRp, ebx
        mov ecx, [ebx]
        mov ebx, _GlobalSp
        mov [ebx], ecx
        sub ebx, eax
        mov _GlobalSp, ebx
        mov ebx, _GlobalRtp
        inc ebx
        mov _GlobalRtp, ebx
        mov al, [ebx]
        mov ebx, _GlobalTp
        mov B[ebx], al
        dec ebx
        mov _GlobalTp, ebx
        xor eax, eax
        ret
L_twopush:
	mov ebx, _GlobalSp
	add ebx, WSIZE
	mov edx, [ebx]
	add ebx, WSIZE
	mov eax, [ebx]
	mov _GlobalSp, ebx
	mov ebx, _GlobalRp
	mov [ebx], eax
	sub ebx, WSIZE
	mov [ebx], edx
	sub ebx, WSIZE
	mov _GlobalRp, ebx
	mov ebx, _GlobalTp
	inc ebx
	mov ax, W[ebx]
	inc ebx
	mov _GlobalTp, ebx
	mov ebx, _GlobalRtp
	dec ebx
	mov W[ebx], ax
	dec ebx
	mov _GlobalRtp, ebx
	xor eax, eax
	ret
L_twopop:
	mov ebx, _GlobalRp
	add ebx, WSIZE
	mov edx, [ebx]
	add ebx, WSIZE
	mov eax, [ebx]
	mov _GlobalRp, ebx
	mov ebx, _GlobalSp
	mov [ebx], eax
	sub ebx, WSIZE
	mov [ebx], edx
	sub ebx, WSIZE
	mov _GlobalSp, ebx
	mov ebx, _GlobalRtp
	inc ebx
	mov ax, W[ebx]
	inc ebx
	mov _GlobalRtp, ebx
	mov ebx, _GlobalTp
	dec ebx
	mov W[ebx], ax
	dec ebx
	mov _GlobalTp, ebx
	xor eax, eax				
	ret
L_puship:
        mov eax, _GlobalIp
        mov ebx, _GlobalRp
        mov [ebx], eax
        sub _GlobalRp, WSIZE
        mov ebx, _GlobalRtp
        mov B[ebx], OP_ADDR
        dec _GlobalRtp
        xor eax, eax
        ret
L_execute:
        mov ecx, _GlobalIp
        mov ebx, _GlobalRp
        mov [ebx], ecx
        mov eax, WSIZE
        sub ebx, eax
        mov _GlobalRp, ebx
        mov ebx, _GlobalRtp
        mov B[ebx], OP_ADDR
        dec ebx
        mov _GlobalRtp, ebx
        mov ebx, _GlobalSp
        add ebx, eax
        mov _GlobalSp, ebx
        mov eax, [ebx]
        dec eax
        mov _GlobalIp, eax
        inc _GlobalTp
        xor eax, eax
        ret
L_definition:
        mov ebx, _GlobalIp
	  mov eax, WSIZE
	  inc ebx
	  mov ecx, [ebx]  ; address to execute
	  add ebx, 3
	  mov edx, ebx
	  mov ebx, _GlobalRp
	  mov [ebx], edx
	  sub ebx, eax
	  mov _GlobalRp, ebx
	  mov ebx, _GlobalRtp
	  mov B[ebx], OP_ADDR
	  dec ebx
	  mov _GlobalRtp, ebx
	  dec ecx
	  mov _GlobalIp, ecx
        xor eax, eax	
	  ret	
L_rfetch:
        mov ebx, _GlobalRp
        add ebx, WSIZE
        mov eax, [ebx]
        mov ebx, _GlobalSp
        mov [ebx], eax
        sub _GlobalSp, WSIZE
        mov ebx, _GlobalRtp
        inc ebx
        mov al, [ebx]
        mov ebx, _GlobalTp
        mov B[ebx], al
        dec _GlobalTp
        xor eax, eax
        ret
L_tworfetch:
	  mov ebx, _GlobalRp
	  add ebx, WSIZE
	  mov edx, [ebx]
	  add ebx, WSIZE
	  mov eax, [ebx]
	  mov ebx, _GlobalSp
	  mov [ebx], eax
	  sub ebx, WSIZE
	  mov [ebx], edx
	  sub ebx, WSIZE
	  mov _GlobalSp, ebx
	  mov ebx, _GlobalRtp
	  inc ebx
	  mov ax, W[ebx]
	  inc ebx
	  mov ebx, _GlobalTp
	  dec ebx
	  mov W[ebx], ax
	  dec ebx
	  mov _GlobalTp, ebx
	  xor eax, eax				
	  ret	
L_rpfetch:
        mov eax, _GlobalRp
        add eax, WSIZE
        mov ebx, _GlobalSp
        mov [ebx], eax
        sub ebx, WSIZE
        mov _GlobalSp, ebx
        mov ebx, _GlobalTp
        mov B[ebx], OP_ADDR
        dec ebx
        mov _GlobalTp, ebx
        xor eax, eax
        ret
L_spfetch:
        mov eax, _GlobalSp
        mov ebx, eax
        add eax, WSIZE
        mov [ebx], eax
        sub ebx, WSIZE
        mov _GlobalSp, ebx
        mov ebx, _GlobalTp
        mov B[ebx], OP_ADDR
        dec ebx
        mov _GlobalTp, ebx
        xor eax, eax
        ret
L_i:
        mov ebx, _GlobalRtp
        mov al, [ebx+3]
        mov ebx, _GlobalTp
        mov B[ebx], al
        dec ebx
        mov _GlobalTp, ebx
        mov ebx, _GlobalRp
        mov eax, [ebx+3*WSIZE]
        mov ebx, _GlobalSp
        mov [ebx], eax
        mov eax, WSIZE
        sub ebx, eax
        mov _GlobalSp, ebx
        xor eax, eax
        ret
L_j:
        mov ebx, _GlobalRtp
        mov al, [ebx+6]
        mov ebx, _GlobalTp
        mov B[ebx], al
        dec ebx
        mov _GlobalTp, ebx
        mov ebx, _GlobalRp
        mov eax, [ebx + 6*WSIZE]
        mov ebx, _GlobalSp
        mov [ebx], eax
        mov eax, WSIZE
        sub ebx, eax
        mov _GlobalSp, ebx
        xor eax, eax
        ret
L_loop:
        mov ebx, _GlobalRtp
        inc ebx
        mov al, [ebx]
        cmp al, OP_ADDR
        jnz loopbad
        mov ebx, _GlobalRp
        mov eax, WSIZE
        add ebx, eax
        mov edx, [ebx]
        add ebx, eax
        mov ecx, [ebx]
        add ebx, eax
        mov eax, [ebx]
        inc eax
        cmp eax, ecx
        jz L_unloop
loop1:
        mov [ebx], eax	; set loop counter to next value
        mov _GlobalIp, edx	; set instruction ptr to start of loop
        xor eax, eax
        ret
L_unloop:
        mov eax, WSIZE
	  shl eax, 1
        add eax, WSIZE
        add _GlobalRp, eax      ; terminal count reached, discard top 3 items
        mov eax, 3
        add _GlobalRtp, eax
        xor eax, eax
        ret
loopbad:
        mov eax, E_RET_STK_CORRUPT
        ret
L_plusloop:
        mov ebx, _GlobalRtp
        inc ebx
        mov al, [ebx]
        cmp al, OP_ADDR
        jnz loopbad
        mov eax, WSIZE
        mov ebx, _GlobalSp
        add ebx, eax
        mov ebp, [ebx]          ; get loop increment
        mov _GlobalSp, ebx
        inc _GlobalTp
        mov ebx, _GlobalRp
        add ebx, eax            ; get ip and save in edx
        mov edx, [ebx]
        add ebx, eax
        mov ecx, [ebx]          ; get terminal count in ecx
        add ebx, eax
        mov eax, [ebx]          ; get current loop count
        add eax, ebp            ; offset loop count
        cmp ebp, 0
        jl plusloop1
        cmp eax, ecx
        jge L_unloop
        mov [ebx], eax	; set loop counter to incremented value
        mov _GlobalIp, edx	 ; set instruction ptr to start of loop
        xor eax, eax
        ret
plusloop1:
        cmp eax, ecx
        jl L_unloop
        mov [ebx], eax
        mov _GlobalIp, edx
        xor eax, eax
        ret
L_jz:
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalSp
        mov eax, [ebx]
        cmp eax, 0
        jz jz1
        add _GlobalIp, 4        ; do not jump
        xor eax, eax
	  ret
jz1:    mov ebx, _GlobalIp
        inc ebx
        mov eax, [ebx]          ; get the relative jump count
        dec eax
        add _GlobalIp, eax
jzexit: xor eax, eax
        ret
L_jnz:                          ; not implemented
        ret
L_jmp:
        mov ebx, _GlobalIp
        inc ebx
        mov eax, [ebx]          ; get the relative jump count
        add ebx, eax
        sub ebx, 2
        mov _GlobalIp, ebx      ; set instruction ptr
        xor eax, eax
        ret

L_calladdr:
	inc ebp
	mov ecx, ebp
	add ebp, 3
	mov _GlobalIp, ebp
;	call *[ecx]
	mov ebp, _GlobalIp
	ret

L_count:
        mov ebx, _GlobalTp
        mov al, B[ebx + 1]
        cmp al, OP_ADDR
        jnz counterror
        mov B[ebx], OP_IVAL
        dec _GlobalTp
        mov ebx, _GlobalSp
        mov ebx, [ebx + WSIZE]
        xor eax, eax
        mov al, B[ebx]
        mov ebx, _GlobalSp
        inc D[ebx + WSIZE]
        mov [ebx], eax
        sub _GlobalSp, WSIZE
        xor eax, eax
        ret
counterror:
        mov eax, E_NOT_ADDR
        ret
L_ival:
        mov ebx, _GlobalIp
        inc ebx
        mov eax, [ebx]
	  add ebx, WSIZE-1
	  mov _GlobalIp, ebx
        mov ebx, _GlobalSp
        mov [ebx], eax
        sub ebx, WSIZE
        mov _GlobalSp, ebx
        mov ebx, _GlobalTp
        mov al, OP_IVAL
        mov B[ebx], al
        dec ebx
        mov _GlobalTp, ebx
        xor eax, eax
        ret
L_addr:
        mov ebx, _GlobalIp
        inc ebx
        mov eax, [ebx]
	  add ebx, WSIZE-1
	  mov _GlobalIp, ebx
        mov ebx, _GlobalSp
        mov [ebx], eax
        sub ebx, WSIZE
        mov _GlobalSp, ebx
        mov ebx, _GlobalTp
        mov al, OP_ADDR
        mov B[ebx], al
        dec ebx
        mov _GlobalTp, ebx
        xor eax, eax
        ret
L_fval:
        mov ebx, _GlobalIp
        inc ebx
	  mov ebp, _GlobalSp
	  sub ebp, WSIZE
	  mov eax, [ebx]
	  mov [ebp], eax
	  mov eax, [ebx+WSIZE]
	  mov [ebp+WSIZE], eax
	  sub ebp, WSIZE
	  mov _GlobalSp, ebp
	  add ebx, 2*WSIZE-1
	  mov _GlobalIp, ebx
	  mov ebx, _GlobalTp
	  mov B[ebx], OP_IVAL
	  dec ebx
	  mov B[ebx], OP_IVAL
	  dec ebx
	  mov _GlobalTp, ebx
	  xor eax, eax	  
        ret
L_and:
	  mov ebx, _GlobalSp
	  add ebx, WSIZE
	  mov eax, [ebx]
	  add ebx, WSIZE
	  mov ecx, ebx
	  mov ebx, [ebx]
	  and eax, ebx
	  mov ebx, ecx
	  mov [ebx], eax
	  sub ebx, WSIZE
	  mov _GlobalSp, ebx
	  inc _GlobalTp
	  mov ebx, _GlobalTp
	  mov B[ebx+1], OP_IVAL
	  xor eax, eax
        ret
L_or:
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalSp
        mov eax, [ebx]
        mov ebx, [ebx + WSIZE]
        or eax, ebx
        mov ebx, _GlobalSp
        mov [ebx + WSIZE], eax
        mov ebx, _GlobalTp
        mov B[ebx + 1], OP_IVAL
        xor eax, eax
        ret
L_not:
        mov ebx, _GlobalSp
        mov eax, [ebx + WSIZE]
        not eax
        mov [ebx + WSIZE], eax
        xor eax, eax
        ret
L_xor:
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalSp
        mov eax, [ebx]
        mov ebx, [ebx + WSIZE]
        xor eax, ebx
        mov ebx, _GlobalSp
        mov [ebx + WSIZE], eax
        mov ebx, _GlobalTp
        mov B[ebx + 1], OP_IVAL
        xor eax, eax
        ret
L_lshift:
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalSp
        mov ecx, [ebx]
        mov eax, [ebx + WSIZE]
        shl eax, cl
        mov [ebx + WSIZE], eax
        xor eax, eax
        ret
L_rshift:
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalSp
        mov ecx, [ebx]
        mov eax, [ebx + WSIZE]
        shr eax, cl
        mov [ebx + WSIZE], eax
        xor eax, eax
        ret
L_eq:
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalSp
        mov eax, [ebx]
        mov ebx, [ebx + WSIZE]
        cmp eax, ebx
        jne eq2
eq1:    mov ebx, _GlobalSp
        mov D[ebx + WSIZE], -1
        jmp eq3
eq2:    mov ebx, _GlobalSp
        mov D[ebx + WSIZE], 0
eq3:    mov ebx, _GlobalTp
        mov B[ebx + 1], OP_IVAL
        xor eax, eax
        ret
L_ne:
        call L_eq
        call L_not
        ret
L_ult:
        mov eax, WSIZE
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalSp
        mov eax, [ebx]
        mov ebx, [ebx + WSIZE]
        cmp ebx, eax
        jae eq2
        jmp eq1
        ret
L_ugt:
        mov eax, WSIZE
        add _GlobalSp, eax
        inc _GlobalTp
        mov ebx, _GlobalSp
        mov eax, [ebx]
        mov ebx, [ebx + WSIZE]
        cmp ebx, eax
        jbe eq2
        jmp eq1
        ret
L_lt:
	  mov ebx, _GlobalTp
	  inc ebx
	  mov B[ebx], OP_IVAL
	  mov _GlobalTp, ebx
	  mov ebx, _GlobalSp
	  mov eax, WSIZE
	  add ebx, eax
	  mov _GlobalSp, ebx
	  mov ecx, [ebx]
	  add ebx, eax
	  mov eax, [ebx]
	  cmp eax, ecx
	  jge lt1
	  mov D[ebx], -1
	  xor eax, eax
	  ret
lt1:
	  mov D[ebx], 0
	  xor eax, eax
	  ret
L_gt:
	  mov ebx, _GlobalTp
	  inc ebx
	  mov B[ebx], OP_IVAL
	  mov _GlobalTp, ebx
	  mov ebx, _GlobalSp
	  mov eax, WSIZE
	  add ebx, eax
	  mov _GlobalSp, ebx
	  mov ecx, [ebx]
	  add ebx, eax
	  mov eax, [ebx]
	  cmp eax, ecx
	  jle gt1
	  mov D[ebx], -1
	  xor eax, eax
	  ret
gt1:
	  mov D[ebx], 0
	  xor eax, eax
	  ret
L_le:
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalSp
        mov eax, [ebx]
        mov ebx, [ebx + WSIZE]
        cmp ebx, eax
        jg eq2
        jmp eq1
L_ge:
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalSp
        mov eax, [ebx]
        mov ebx, [ebx + WSIZE]
        cmp ebx, eax
        jl eq2
        jmp eq1
L_zerolt:
        mov ebx, _GlobalSp
        mov eax, [ebx + WSIZE]
        cmp eax, 0
        jl zerolt2
zerolt1:
        mov D[ebx + WSIZE], 0
        jmp zeroltexit
zerolt2:
        mov D[ebx + WSIZE], -1
zeroltexit:
        mov ebx, _GlobalTp
        mov B[ebx + 1], OP_IVAL
        xor eax, eax
        ret
L_zeroeq:
        mov ebx, _GlobalSp
        mov eax, [ebx + WSIZE]
        cmp eax, 0
        je zerolt2
        jmp zerolt1
L_zerone:
        mov ebx, _GlobalSp
        mov eax, [ebx + WSIZE]
        cmp eax, 0
        je zerolt1
        jmp zerolt2
L_zerogt:
        mov ebx, _GlobalSp
        mov eax, [ebx + WSIZE]
        cmp eax, 0
        jg zerolt2
        jmp zerolt1
L_deq:
	  mov ebx, _GlobalTp
	  add ebx, 4
	  mov B[ebx], OP_IVAL
	  dec ebx
	  mov _GlobalTp, ebx
	  mov ebx, _GlobalSp
	  add ebx, WSIZE
	  mov edx, [ebx]
	  add ebx, WSIZE
	  mov ecx, [ebx]
	  add ebx, WSIZE
	  mov _GlobalSp, ebx
	  mov eax, [ebx]
	  sub eax, edx
	  add ebx, WSIZE
	  mov edx, [ebx]
	  sub edx, ecx
	  or  eax, edx
	  cmp eax, 0
	  jz deq1
	  mov D[ebx], 0
	  xor eax, eax
	  ret
deq1:	  mov D[ebx], -1
	  xor eax, eax	
	  ret
L_dzeroeq:
	  mov ebx, _GlobalTp
	  add ebx, 2
	  mov B[ebx], OP_IVAL
	  dec ebx
	  mov _GlobalTp, ebx
	  mov ebx, _GlobalSp
	  add ebx, WSIZE
	  mov _GlobalSp, ebx
	  mov eax, [ebx]
	  add ebx, WSIZE
	  or  eax, [ebx]
	  cmp eax, 0
	  jz  deq1
	  mov D[ebx], 0
	  xor eax, eax
	  ret
L_dlt:
	  call _L_dminus
	  mov ebx, _GlobalTp
	  inc ebx
	  mov _GlobalTp, ebx
	  inc ebx
	  mov B[ebx], OP_IVAL
	  mov ebx, _GlobalSp
	  add ebx, WSIZE
	  mov _GlobalSp, ebx
	  mov eax, [ebx]
	  add ebx, WSIZE
	  cmp eax, 0
	  jl deq1
	  mov D[ebx], 0
	  xor eax, eax	
	  ret
L_dult:	
	  ret
L_querydup:
        mov ebx, _GlobalSp
        mov eax, [ebx + WSIZE]
        cmp eax, 0
        je L_querydupexit
        mov [ebx], eax
        mov ebx, _GlobalTp
        mov al, B[ebx + 1]
        mov B[ebx], al
        dec _GlobalTp
        sub _GlobalSp, WSIZE
        xor eax, eax
L_querydupexit:
        ret
L_drop:
        add _GlobalSp, WSIZE
        inc _GlobalTp
        ret
L_dup:
        mov ebx, _GlobalSp
        mov eax, [ebx + WSIZE]
        mov [ebx], eax
	  sub ebx, WSIZE
	  mov _GlobalSp, ebx
        mov ebx, _GlobalTp
        mov al, B[ebx + 1]
        mov B[ebx], al
        dec _GlobalTp
        xor eax, eax
        ret
L_swap:
        mov ebx, _GlobalSp
        add ebx, WSIZE
        mov eax, [ebx + WSIZE]
        xchg eax, D[ebx]
        mov [ebx + WSIZE], eax
        mov ebx, _GlobalTp
        inc ebx
        mov al, [ebx + 1]
        xchg al, B[ebx]
        mov B[ebx + 1], al
        xor eax, eax
        ret
L_over:
        mov ebx, _GlobalSp
        mov eax, [ebx + 2*WSIZE]
        mov [ebx], eax
        mov eax, ebx
        sub eax, WSIZE
        mov _GlobalSp, eax
        mov ebx, _GlobalTp
        mov al, B[ebx + 2]
        mov B[ebx], al
        dec _GlobalTp
        xor eax, eax
        ret
L_rot:
        call L_swap
        mov ebx, _GlobalSp
        add ebx, WSIZE
        mov eax, [ebx + 2*WSIZE]
        xchg eax, [ebx]
        xchg eax, [ebx + 2*WSIZE]
        mov ebx, _GlobalTp
        inc ebx
        mov al, B[ebx + 2]
        xchg al, B[ebx]
        xchg al, B[ebx + 2]
        xor eax, eax
        ret
L_minusrot:
        mov ebx, _GlobalSp
        mov eax, [ebx + WSIZE]
        mov [ebx], eax
        add ebx, WSIZE
        mov eax, [ebx + WSIZE]
        mov [ebx], eax
        add ebx, WSIZE
        mov eax, [ebx + WSIZE]
        mov [ebx], eax
        mov eax, [ebx - 2*WSIZE]
        mov [ebx + WSIZE], eax
        mov ebx, _GlobalTp
        mov al, [ebx + 1]
        mov B[ebx], al
        inc ebx
        mov ax, [ebx + 1]
        mov W[ebx], ax
        mov al, [ebx - 1]
        mov B[ebx + 2], al
        xor eax, eax
        ret
L_nip:
        call L_swap
        add _GlobalSp, WSIZE
        inc _GlobalTp
        ret
L_tuck:
        call L_swap
        call L_over
        ret
L_pick:
        mov ebx, _GlobalSp
        mov eax, [ebx + WSIZE]
        inc eax
        inc eax
        imul eax, WSIZE
        add ebx, eax
        mov eax, [ebx]
        mov ebx, _GlobalSp
        mov [ebx], eax
        mov eax, [ebx + WSIZE]
        inc eax
        inc eax
        mov ebx, _GlobalTp
        add ebx, eax
        mov al, [ebx]
        mov ebx, _GlobalTp
        mov B[ebx + 1], al
        mov ebx, _GlobalSp
        mov eax, [ebx]
        mov [ebx + WSIZE], eax
        xor eax, eax
        ret
L_roll:
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalSp
        mov eax, [ebx]
        inc eax
        push eax
        push eax
        push eax
        push ebx
        imul eax, WSIZE
        add ebx, eax	; addr of item to roll
        mov eax, [ebx]
        pop ebx
        mov [ebx], eax
        pop eax		; number of cells to copy
        mov ecx, eax
        imul eax, WSIZE
        add ebx, eax
        mov edx, ebx	; dest addr
        sub ebx, WSIZE	; src addr
rollloop:
        mov eax, [ebx]
        sub ebx, WSIZE
        xchg edx, ebx
        mov [ebx], eax
        sub ebx, WSIZE
        xchg edx, ebx
        loop rollloop

        pop eax             ; roll the typestack
        mov ebx, _GlobalTp
        add ebx, eax
        mov al, B[ebx]
        mov ebx, _GlobalTp
        mov B[ebx], al
        pop eax
        mov ecx, eax
        add ebx, eax
        mov edx, ebx
        dec ebx
rolltloop:
        mov al, B[ebx]
        dec ebx
        xchg edx, ebx
        mov B[ebx], al
        dec ebx
        xchg edx, ebx
        loop rolltloop
        xor eax, eax
        ret
_L_depth:
        mov ebx, _GlobalSp
        mov eax, _BottomOfStack
        sub eax, ebx
        mov D[ebx], WSIZE
        mov edx, 0
        idiv D[ebx]
        mov [ebx], eax
        sub _GlobalSp, WSIZE
        mov ebx, _GlobalTp
        mov B[ebx], OP_IVAL
        dec _GlobalTp
        xor eax, eax
        ret
_L_2drop:
        add _GlobalSp, 2*WSIZE
        add _GlobalTp, 2
        ret
_L_2dup:
        mov ebx, _GlobalSp
	  mov ecx, ebx
	  add ebx, WSIZE
	  mov edx, [ebx]
	  add ebx, WSIZE
	  mov eax, [ebx]
	  mov ebx, ecx
	  mov [ebx], eax
	  sub ebx, WSIZE
	  mov [ebx], edx
	  sub ebx, WSIZE
	  mov _GlobalSp, ebx
	  mov ebx, _GlobalTp
	  inc ebx
	  mov ax, W[ebx]
	  sub ebx, 2
	  mov W[ebx], ax
	  dec ebx
	  mov _GlobalTp, ebx
	  xor eax, eax
	  ret
L_2swap:
	  mov ebx, _GlobalSp
	  add ebx, WSIZE
	  mov edx, [ebx]
	  add ebx, WSIZE
	  mov eax, [ebx]
	  add ebx, WSIZE
	  xchg [ebx], edx
	  add ebx, WSIZE
	  xchg [ebx], eax
	  sub ebx, 2*WSIZE
	  mov [ebx], eax
	  sub ebx, WSIZE
	  mov [ebx], edx
	  mov ebx, _GlobalTp
	  inc ebx
	  mov ax, W[ebx]
	  add ebx, 2
	  xchg W[ebx], ax
	  sub ebx, 2
	  mov W[ebx], ax
	  xor eax, eax
	  ret
L_2over:
	  mov ebx, _GlobalSp
	  mov ecx, ebx
	  add ebx, 3*WSIZE
	  mov edx, [ebx]
	  add ebx, WSIZE
	  mov eax, [ebx]
	  mov ebx, ecx
	  mov [ebx], eax
	  sub ebx, WSIZE
	  mov [ebx], edx
	  sub ebx, WSIZE
	  mov _GlobalSp, ebx
	  mov ebx, _GlobalTp
	  mov ecx, ebx
	  add ebx, 3
	  mov ax, W[ebx]
	  mov ebx, ecx
	  dec ebx
	  mov W[ebx], ax
	  dec ebx
	  mov _GlobalTp, ebx
	  xor eax, eax
	  ret
L_2rot:
	  mov ebx, _GlobalSp
	  add ebx, WSIZE
	  mov ecx, ebx
	  mov edx, [ebx]
	  add ebx, WSIZE
	  mov eax, [ebx]
	  add ebx, WSIZE
	  xchg [ebx], edx
	  add ebx, WSIZE
	  xchg [ebx], eax
	  add ebx, WSIZE
	  xchg [ebx], edx
	  add ebx, WSIZE
	  xchg [ebx], eax
	  mov ebx, ecx
	  mov [ebx], edx
	  add ebx, WSIZE
	  mov [ebx], eax
	  mov ebx, _GlobalTp
	  inc ebx
	  mov ecx, ebx
	  mov ax, W[ebx]
	  add ebx, 2
	  xchg W[ebx], ax
	  add ebx, 2
	  xchg W[ebx], ax
	  mov ebx, ecx
	  mov W[ebx], ax
	  xor eax, eax
	  ret
L_question:
        call L_fetch
        cmp eax, 0
        jnz questionexit
        call _CPP_dot
questionexit:
        ret
L_fetch:
        mov edx, _GlobalSp
        mov ebx, _GlobalTp
        inc ebx
        mov al, [ebx]
        cmp al, OP_ADDR
        jnz fetcherror
        mov B[ebx], OP_IVAL
        add edx, WSIZE
	  mov ebx, [edx]
	  mov eax, [ebx]
	  mov [edx], eax
        xor eax, eax
        ret
fetcherror:
        mov eax, E_NOT_ADDR
        ret
L_store:
        mov ebx, _GlobalTp
        inc ebx
	  mov ebp, ebx
        mov al, B[ebx]
        cmp al, OP_ADDR
        jnz fetcherror
        mov eax, WSIZE
        mov ebx, _GlobalSp
        add ebx, eax
        mov ecx, [ebx]          ; address to store in ecx
        add ebx, eax
        mov edx, [ebx]          ; value to store in edx
        mov _GlobalSp, ebx
        mov [ecx], edx
        inc ebp
        mov _GlobalTp, ebp
        xor eax, eax
        ret
L_afetch:
	  mov edx, _GlobalSp
	  mov ebx, _GlobalTp
	  inc ebx
	  mov al, B[ebx]
	  cmp al, OP_ADDR
	  jnz fetcherror
	  mov B[ebx], OP_ADDR
	  add edx, WSIZE
	  mov ebx, [edx]
	  mov eax, [ebx]
	  mov [edx], eax
	  xor eax, eax
        ret
L_cfetch:
        mov ebx, _GlobalTp
	  inc ebx
	  mov al, B[ebx]
        cmp al, OP_ADDR
        jnz fetcherror
        mov B[ebx], OP_IVAL
        xor eax, eax
        mov ebx, _GlobalSp
	  add ebx, WSIZE
	  mov ecx, [ebx]
	  mov al, B[ecx]
	  mov [ebx], eax
	  xor eax, eax
        ret
L_cstore:
	  mov edx, _GlobalTp
	  inc edx
	  mov al, B[edx]
	  cmp al, OP_ADDR
	  jnz fetcherror
	  mov ebx, _GlobalSp
	  add ebx, WSIZE
	  mov ecx, [ebx]	; address to store
	  add ebx, WSIZE
	  mov eax, [ebx]	; value to store
	  mov B[ecx], al
	  mov _GlobalSp, ebx
	  inc edx
	  mov _GlobalTp, edx
	  xor eax, eax
	  ret
L_wfetch:
        mov ebx, _GlobalTp
        mov al, [ebx + 1]
        cmp al, OP_ADDR
        jnz fetcherror
        mov B[ebx + 1], OP_IVAL
        mov ebx, _GlobalSp
        mov ebx, [ebx + WSIZE]
        mov ax, W[ebx]
        cwde
        mov ebx, _GlobalSp
        mov [ebx + WSIZE], eax
        xor eax, eax
        ret
L_wstore:
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalTp
        mov al, B[ebx]
        cmp al, OP_ADDR
        jnz fetcherror
        mov ebx, _GlobalSp
        mov eax, [ebx]
        push eax
        add ebx, WSIZE
        mov eax, [ebx]
        pop ebx
        mov W[ebx], ax
        add _GlobalSp, WSIZE
        inc _GlobalTp
        xor eax, eax
        ret
L_sffetch:
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalTp
        mov al, [ebx]
        cmp al, OP_ADDR
        jnz fetcherror
        mov B[ebx], OP_IVAL
        dec ebx
        mov B[ebx], OP_IVAL
        dec _GlobalTp
        dec _GlobalTp
        mov ebx, _GlobalSp
        mov ebx, [ebx]
        FLD D[ebx]
        sub _GlobalSp, WSIZE
        mov ebx, _GlobalSp
        FSTP Q[ebx]
        sub _GlobalSp, WSIZE
        xor eax, eax
        ret
L_sfstore:
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalTp
        mov al, [ebx]
        cmp al, OP_ADDR
        jnz fetcherror
        mov ebx, _GlobalSp
        add ebx, WSIZE
        FLD Q[ebx]              ; load the f number into NDP
        sub ebx, WSIZE
        mov ebx, [ebx]          ; load the dest address
        FSTP D[ebx]             ; store as single precision float
        add _GlobalSp, 2*WSIZE
        add _GlobalTp, 2
        xor eax, eax
        ret
L_dffetch:
        mov ebx, _GlobalTp
        inc ebx
        mov al, [ebx]
        cmp al, OP_ADDR
        jnz fetcherror
	  mov B[ebx], OP_IVAL
	  dec ebx
	  mov B[ebx], OP_IVAL
	  dec ebx
	  mov _GlobalTp, ebx
        mov ebx, _GlobalSp
	  mov edx, ebx
        add ebx, WSIZE
        mov ecx, [ebx]      ; address to fetch from in ecx
	  mov eax, [ecx]
	  mov [edx], eax
	  add ecx, WSIZE
	  mov eax, [ecx]
	  mov [ebx], eax
	  sub edx, WSIZE
	  mov _GlobalSp, edx
	  xor eax, eax
	  ret
L_dfstore:
        mov ebx, _GlobalTp
        inc ebx
        mov al, [ebx]
        cmp al, OP_ADDR
        jnz fetcherror
	  add ebx, 2
	  mov _GlobalTp, ebx
        mov ebx, _GlobalSp
	  mov edx, WSIZE
        add ebx, edx
	  mov eax, ebx
	  mov ebx, [ebx]	; address to store
	  add eax, edx
	  mov ecx, [eax]
	  mov [ebx], ecx
	  add eax, edx
	  add ebx, edx
	  mov ecx, [eax]
	  mov [ebx], ecx
	  mov _GlobalSp, eax
	  xor eax, eax
	  ret
L_inc:
        mov ebx, _GlobalSp
        inc D[ebx + WSIZE]
        ret
L_dec:
        mov ebx, _GlobalSp
        dec D[ebx + WSIZE]
        ret
L_twoplus:
        mov ebx, _GlobalSp
        inc D[ebx + WSIZE]
        inc D[ebx + WSIZE]
        ret
L_twominus:
        mov ebx, _GlobalSp
        dec D[ebx + WSIZE]
        dec D[ebx + WSIZE]
        ret
L_abs:
        mov ebx, _GlobalSp
        add ebx, WSIZE
        mov eax, [ebx]
        cmp eax, 0
        jl abs1
        xor eax, eax
        ret
abs1:   neg eax
        mov [ebx], eax
        xor eax, eax
        ret
L_neg:
        mov ebx, _GlobalSp
        add ebx, WSIZE
        mov eax, [ebx]
        neg eax
        mov [ebx], eax
        xor eax, eax
        ret
L_max:
        add _GlobalSp, WSIZE
        mov ebx, _GlobalSp
        mov eax, [ebx]
        mov ebx, [ebx + WSIZE]
        cmp ebx, eax
        jl max1
        mov eax, ebx
        mov ebx, _GlobalSp
        mov [ebx + WSIZE], eax
        jmp maxexit
max1:   mov ebx, _GlobalSp
        mov [ebx + WSIZE], eax
maxexit:
        inc _GlobalTp
        xor eax, eax
        ret
L_min:
        add _GlobalSp, WSIZE
        mov ebx, _GlobalSp
        mov eax, [ebx]
        mov ebx, [ebx + WSIZE]
        cmp ebx, eax
        jg min1
        mov eax, ebx
        mov ebx, _GlobalSp
        mov [ebx + WSIZE], eax
        jmp minexit
min1:   mov ebx, _GlobalSp
        mov [ebx + WSIZE], eax
minexit:
        inc _GlobalTp
        xor eax, eax
        ret
L_dmax:
	ret
L_dmin:
	ret
L_twostar:
        mov ebx, _GlobalSp
        sal D[ebx + WSIZE], 1
        ret
L_twodiv:
        mov ebx, _GlobalSp
        sar D[ebx + WSIZE], 1
        ret
L_add:
        mov eax, WSIZE
        mov ebx, _GlobalSp
        add ebx, eax
        mov eax, [ebx]
        add [ebx + WSIZE], eax
        mov _GlobalSp, ebx
        mov ebx, _GlobalTp
        inc ebx
        mov _GlobalTp, ebx
        mov ax, W[ebx]
        and al, ah  ; and the two type to preserve address
        inc ebx
        mov B[ebx], al
        xor eax, eax
        ret
L_sub:
        mov eax, WSIZE
        mov ebx, _GlobalSp
        add ebx, eax
        mov eax, [ebx]
        sub [ebx + WSIZE], eax
        mov _GlobalSp, ebx
        inc _GlobalTp   ; result will have type of first operand
        xor eax, eax
        ret
L_mul:
        mov ecx, WSIZE
        mov ebx, _GlobalSp
        add ebx, ecx
        mov _GlobalSp, ebx
        mov eax, [ebx]
        add ebx, ecx
        imul D[ebx]
        mov [ebx], eax
        inc _GlobalTp
        xor eax, eax
        ret
L_div:
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalSp
        mov eax, [ebx]
        cmp eax, 0
        jnz div1
        mov eax, E_DIV_ZERO
        jmp divexit
div1:   add ebx, WSIZE
        mov eax, [ebx]
        cdq
        idiv D[ebx - WSIZE]
        mov [ebx], eax
        xor eax, eax
divexit:
        ret
L_mod:
        call L_div
        mov [ebx], edx
        ret
L_slashmod:
        call L_div
        sub ebx, WSIZE
        mov [ebx], edx
        sub ebx, WSIZE
        mov _GlobalSp, ebx
        dec _GlobalTp
        call L_swap
        ret
L_starslash:
        mov eax, WSIZE
        sal eax, 1
        add _GlobalSp, eax
        mov ebx, _GlobalSp
        mov eax, [ebx + WSIZE]
        imul D[ebx]
        idiv D[ebx - WSIZE]
        mov [ebx + WSIZE], eax
        inc _GlobalTp
        inc _GlobalTp
        xor eax, eax
        ret
L_starslashmod:
        call L_starslash
        mov [ebx], edx
        sub ebx, WSIZE
        mov _GlobalSp, ebx
        dec _GlobalTp
        call L_swap
        ret
L_plusstore:
        mov ebx, _GlobalTp
        mov al, [ebx + 1]
        cmp al, OP_ADDR
        jnz fetcherror
        mov ebx, _GlobalSp
        push ebx
        push ebx
        push ebx
        mov ebx, [ebx + WSIZE]
        mov eax, [ebx]
        pop ebx
        mov ebx, [ebx + 2*WSIZE]
        add eax, ebx
        pop ebx
        mov ebx, [ebx + WSIZE]
        mov [ebx], eax
        pop ebx
        mov eax, WSIZE
        sal eax, 1
        add ebx, eax
        mov _GlobalSp, ebx
        inc _GlobalTp
        inc _GlobalTp
        xor eax, eax
        ret
_L_dabs:
	  mov ebx, _GlobalSp
	  add ebx, WSIZE
	  mov ecx, [ebx]
	  mov eax, ecx
	  cmp eax, 0
	  jl dabs_go
	  xor eax, eax
	  ret
dabs_go:
	  add ebx, WSIZE
	  mov eax, [ebx]
	  clc
	  sub eax, 1
	  not eax
	  mov [ebx], eax
	  mov eax, ecx
	  sbb eax, 0
	  not eax
	  mov [ebx-WSIZE], eax
	  xor eax, eax
	  ret
L_dnegate:
	  mov ebx, _GlobalSp
	  add ebx, WSIZE
	  mov ecx, ebx
	  add ebx, WSIZE
	  mov eax, [ebx]
	  not eax
	  clc
	  add eax, 1
	  mov [ebx], eax
	  mov ebx, ecx
	  mov eax, [ebx]
	  not eax
	  adc eax, 0
	  mov [ebx], eax
	  xor eax, eax	
	  ret	
L_dplus:
	  mov ebx, _GlobalSp
	  add ebx, 2*WSIZE
	  mov eax, [ebx]
	  clc
	  add eax, [ebx+2*WSIZE]
	  mov [ebx+2*WSIZE], eax
	  mov eax, [ebx+WSIZE]
	  adc eax, [ebx-WSIZE]
	  mov [ebx+WSIZE], eax
	  mov _GlobalSp, ebx
	  inc _GlobalTp
	  inc _GlobalTp
	  xor eax, eax
	  ret
_L_dminus:
	  mov ebx, _GlobalSp
	  add ebx, 2*WSIZE
	  mov eax, [ebx+2*WSIZE]
	  clc
	  sub eax, [ebx]
	  mov [ebx+2*WSIZE], eax
	  mov eax, [ebx+WSIZE]
	  sbb eax, [ebx-WSIZE]
	  mov [ebx+WSIZE], eax
	  mov _GlobalSp, ebx
	  inc _GlobalTp
	  inc _GlobalTp
	  xor eax, eax
	  ret
L_umstar:
        mov eax, WSIZE
        mov ebx, _GlobalSp
        add ebx, eax
        mov ecx, [ebx]
        add ebx, eax
        mov eax, ecx
        mul D[ebx]
        mov [ebx], eax
        sub ebx, WSIZE
        mov [ebx], edx
        xor eax, eax
        ret
L_umslashmod:
        mov ebx, _GlobalSp
        mov eax, WSIZE
        add ebx, eax
        mov _GlobalSp, ebx
        mov ecx, [ebx]
        add ebx, eax
	  mov edx, 0
	  mov eax, [ebx]
	  div ecx
	  cmp eax, 0
	  jne umslashmod_ovflow
        mov edx, [ebx]
	  add ebx, WSIZE
        mov eax, [ebx]
        div ecx
	  jmp umslashmod_exit
umslashmod_ovflow:
	  add ebx, WSIZE
	  mov edx, -1
	  mov eax, -1
umslashmod_exit:
        mov [ebx], edx
        sub ebx, WSIZE
        mov [ebx], eax
        inc _GlobalTp
        xor eax, eax
        ret
L_mstar:
        mov eax, WSIZE
        mov ebx, _GlobalSp
        add ebx, eax
        mov ecx, [ebx]
        add ebx, eax
        mov eax, ecx
        imul D[ebx]
        mov [ebx], eax
        sub ebx, WSIZE
        mov [ebx], edx
        xor eax, eax
        ret
L_mplus:
	  mov eax, WSIZE
	  mov ebx, _GlobalSp
	  add ebx, eax
	  mov ecx, [ebx]
	  mov _GlobalSp, ebx
	  inc _GlobalTp
	  add ebx, eax
	  mov edx, [ebx]
	  add ebx, eax
	  mov eax, [ebx]
	  clc
	  add eax, ecx
	  js mplus1
	  adc edx, 0
mplus1:
	  mov [ebx], eax
	  mov [ebx-WSIZE], edx
	  xor eax, eax
	  ret
L_mslash:
	  mov eax, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalSp
	  add ebx, eax
        mov ecx, [ebx]
	  inc _GlobalTp
	  add ebx, eax
	  mov _GlobalSp, ebx
        cmp ecx, 0
        je mslash1
	  add ebx, eax
        mov edx, [ebx]
	  add ebx, eax
	  mov eax, [ebx]
        idiv ecx
        mov [ebx], eax
	  xor eax, eax		
	  ret
mslash1:			
        mov eax, E_DIV_ZERO
        ret
L_udmstar:
	  ; multiply unsigned double and unsigned to give triple length product
	  mov ebx, _GlobalSp
	  add ebx, WSIZE
	  mov ecx, [ebx]
	  add ebx, WSIZE
	  mov eax, [ebx]
	  mul ecx
	  mov [ebx-WSIZE], edx
	  mov [ebx], eax
	  add ebx, WSIZE
	  mov eax, ecx
	  mul D[ebx]
	  mov [ebx], eax
	  sub ebx, WSIZE
	  mov eax, [ebx]
	  sub ebx, WSIZE
	  clc
	  add eax, edx
	  mov [ebx+WSIZE], eax
	  ; subl $WSIZE, %ebx
	  mov eax, [ebx]
	  adc eax, 0
	  mov [ebx], eax
	  xor eax, eax 		
	  ret
L_utmslash:
	; divide unsigned triple length by unsigned to give ud quotient
	mov ebx, _GlobalSp
	add ebx, WSIZE
	mov ecx, [ebx]	; divisor in ecx
	add ebx, WSIZE
	mov eax, [ebx]	; ut3
	mov edx, 0
	div ecx		; ut3/u
	push ebx		; keep local stack ptr
	mov ebx, _GlobalSp
	mov [ebx-4*WSIZE], eax	; q3
	mov [ebx-5*WSIZE], edx	; r3
	pop ebx
	add ebx, WSIZE
	mov eax, [ebx]		; ut2
	mov edx, 0
	div ecx			; ut2/u
	push ebx
	mov ebx, _GlobalSp
	mov [ebx-2*WSIZE], eax	; q2
	mov [ebx-3*WSIZE], edx	; r2
	pop ebx
	add ebx, WSIZE
	mov eax, [ebx]		; ut1
	mov edx, 0
	div ecx			; ut1/u
	push ebx
	mov ebx, _GlobalSp
	mov [ebx], eax		; q1
	mov [ebx-WSIZE], edx	; r1
	mov edx, [ebx-5*WSIZE]	; r3 << 32
	mov eax, 0
	div ecx			; (r3 << 32)/u
	mov [ebx-6*WSIZE], eax	; q4
	mov [ebx-7*WSIZE], edx	; r4
	mov edx, [ebx-3*WSIZE]	; r2 << 32
	mov eax, 0
	div ecx			; (r2 << 32)/u
	mov [ebx-8*WSIZE], eax	; q5
	mov [ebx-9*WSIZE], edx	; r5
	mov edx, [ebx-7*WSIZE]	; r4 << 32
	mov eax, 0
	div ecx			; (r4 << 32)/u
	mov [ebx-10*WSIZE], eax	; q6
	mov [ebx-11*WSIZE], edx	; r6
	mov eax, [ebx-WSIZE]	; r1
	add eax, [ebx-9*WSIZE]	; r1 + r5
	add eax, [ebx-11*WSIZE]	; r1 + r5 + r6
	mov edx, 0
	div ecx
	add eax, [ebx-10*WSIZE]	; q7 + q6
	add eax, [ebx-8*WSIZE]	; q7 + q6 + q5
	add eax, [ebx]		; q7 + q6 + q5 + q1
	pop ebx
	mov [ebx], eax
	sub ebx, WSIZE
	push ebx
	mov ebx, _GlobalSp
	mov eax, [ebx-2*WSIZE]	; q2
	add eax, [ebx-6*WSIZE]	; q2 + q4
	pop ebx
	mov [ebx], eax
	sub ebx, WSIZE
	mov _GlobalSp, ebx
	add _GlobalTp, 2
	xor eax, eax
	ret
_L_mstarslash:
	mov ebx, _GlobalSp
	add ebx, WSIZE
	add ebx, WSIZE
	mov eax, [ebx]
	add ebx, WSIZE
	xor eax, [ebx]
	shr eax, 31
	push eax	; keep sign of result -- negative is nonzero
	mov ebx, _GlobalSp
	add ebx, WSIZE
	mov _GlobalSp, ebx
	inc _GlobalTp
	call L_abs
	mov ebx, _GlobalSp
	add ebx, WSIZE
	mov _GlobalSp, ebx
	inc _GlobalTp
	call _L_dabs
	mov ebx, _GlobalSp
	sub ebx, WSIZE
	mov _GlobalSp, ebx
	dec _GlobalTp
	call L_udmstar
	mov ebx, _GlobalSp
	sub ebx, WSIZE
	mov _GlobalSp, ebx
	dec _GlobalTp
	call L_utmslash	
	pop eax
	cmp eax, 0
	jnz mstarslash_neg
	xor eax, eax
	ret
mstarslash_neg:
	call L_dnegate
	xor eax, eax
	ret
L_fmslashmod:
        mov ebx, _GlobalSp
        mov eax, WSIZE
        add ebx, eax
        mov _GlobalSp, ebx
        mov ecx, [ebx]
        add ebx, eax
        mov edx, [ebx]
        add ebx, eax
        mov eax, [ebx]
        idiv ecx
        mov [ebx], edx
        sub ebx, WSIZE
        mov [ebx], eax
	  inc _GlobalTp
	  cmp ecx, 0
	  jg fmslashmod2
        cmp edx, 0
	  jg fmslashmod3
	  xor eax, eax
	  ret
fmslashmod2:
	  cmp edx, 0
        jge fmslashmodexit
fmslashmod3:
        dec eax     ; floor the result
        mov [ebx], eax
        add ebx, WSIZE
        add [ebx], ecx
fmslashmodexit:
        xor eax, eax
        ret
L_smslashrem:
        mov ebx, _GlobalSp
        mov eax, WSIZE
        add ebx, eax
        mov _GlobalSp, ebx
        mov ecx, [ebx]
        add ebx, eax
        mov edx, [ebx]
        add ebx, eax
        mov eax, [ebx]
        idiv ecx
        mov [ebx], edx
        sub ebx, WSIZE
        mov [ebx], eax
        inc _GlobalTp
        xor eax, eax
        ret
L_stod:
        mov ebx, _GlobalSp
        mov eax, [ebx + WSIZE]
        push edx
        cdq
        mov [ebx], edx
        pop edx
        mov eax, WSIZE
        sub ebx, eax
        mov _GlobalSp, ebx
        mov ebx, _GlobalTp
        mov B[ebx], OP_IVAL
        dec _GlobalTp
        xor eax, eax
        ret
L_stof:
        add _GlobalSp, WSIZE
        inc _GlobalTp
        mov ebx, _GlobalSp
        FILD D[ebx]
        mov ebx, _GlobalTp
        mov B[ebx], OP_IVAL
        dec ebx
        mov B[ebx], OP_IVAL
        dec _GlobalTp
        dec _GlobalTp
        mov ebx, _GlobalSp
        sub ebx, WSIZE
        FSTP Q[ebx]
        sub _GlobalSp, 2*WSIZE
        ret
L_dtof:
        mov eax, WSIZE
        mov ebx, _GlobalSp
        add ebx, eax
        mov eax, [ebx]
        xchg eax, [ebx + WSIZE]
        mov [ebx], eax
        FILD Q[ebx]
        FSTP Q[ebx]
        xor eax, eax
        ret
L_froundtos:
        add _GlobalSp, WSIZE
        mov ebx, _GlobalSp
        FLD Q[ebx]
        add ebx, WSIZE
        FISTP D[ebx]
        inc _GlobalTp
        mov ebx, _GlobalTp
        inc ebx
        mov B[ebx], OP_IVAL
        ret
L_ftrunctos:
	mov eax, WSIZE
	add _GlobalSp, eax
	mov ebx, _GlobalSp
	FLD Q[ebx]
	FNSTCW [ebx]
	mov ecx, [ebx]	; save NDP control word		
	mov edx, ecx
	mov dh, 12
	mov [ebx], edx
	FLDCW [ebx]
	add ebx, eax
	FISTP D[ebx]
	sub ebx, eax
	mov [ebx], ecx
	FLDCW [ebx]		; restore NDP control word
	inc _GlobalTp
	mov ebx, _GlobalTp
	inc ebx
	mov B[ebx], OP_IVAL
	xor eax, eax	
	ret	
L_ftod:
        mov eax, WSIZE
        mov ebx, _GlobalSp
        add ebx, eax
        FLD Q[ebx]
        sub ebx, eax
        FNSTCW [ebx]
        mov ecx, [ebx]  ; save NDP control word
        mov edx, ecx
        mov dh, 12
        mov [ebx], edx
        FLDCW [ebx]
        add ebx, eax
        FISTP Q[ebx]
        sub ebx, eax
        mov [ebx], ecx
        FLDCW [ebx]     ; restore NDP control word
        add ebx, eax
        mov eax, [ebx]
        xchg eax, [ebx + WSIZE]
        mov [ebx], eax
        xor eax, eax
        ret
L_degtorad:
        mov ebx, _GlobalSp
        add ebx, WSIZE
        FLD Q[ebx]
        FLD Q FCONST_180
        FDIV
        FLDPI
        FMUL
        FSTP Q[ebx]
        ret
L_radtodeg:
        mov ebx, _GlobalSp
        add ebx, WSIZE
        FLD Q[ebx]
        FLDPI
        FDIV
        FLD Q FCONST_180
        FMUL
        FSTP Q[ebx]
        ret
L_fne:
        call L_feq
        mov ebx, _GlobalSp
        not D[ebx + WSIZE]
        ret
L_feq:
        add _GlobalSp, WSIZE
        mov ebx, _GlobalSp
        FLD Q[ebx]
        add _GlobalSp, 2*WSIZE
        mov ebx, _GlobalSp
        FLD Q[ebx]
        FUCOMPP
        FNSTSW ax
        and ah, 69
        xor ah, 64
        jne flt2
        jmp flt1
L_flt:
        add _GlobalSp, WSIZE
        mov ebx, _GlobalSp
        FLD Q[ebx]
        add _GlobalSp, 2*WSIZE
        mov ebx, _GlobalSp
        FCOMP Q[ebx]
        FNSTSW ax
        and ah, 69
        jne flt2
flt1:   mov ebx, _GlobalSp
        mov D[ebx + WSIZE], -1
        jmp fltexit
flt2:   mov ebx, _GlobalSp
        mov D[ebx + WSIZE], 0
fltexit:
        add _GlobalTp, 4
        mov ebx, _GlobalTp
        mov B[ebx], OP_IVAL
        dec _GlobalTp
        xor eax, eax
        ret
L_fgt:
        add _GlobalSp, WSIZE
        mov ebx, _GlobalSp
        FLD Q[ebx]
        add _GlobalSp, 2*WSIZE
        mov ebx, _GlobalSp
        FCOMP Q[ebx]
        FNSTSW ax
        and ah, 69
        cmp ah, 1
        jne flt2
        jmp flt1
L_fle:
        call L_2over
        call L_2over
        call L_feq
        call L_push
        call L_flt
        call L_pop
        call L_or
        ret
L_fge:
        call L_2over
        call L_2over
        call L_feq
        call L_push
        call L_fgt
        call L_pop
        call L_or
        ret
L_fzeroeq:
        mov eax, WSIZE
        mov ebx, _GlobalSp
        add ebx, eax
        mov ecx, [ebx]
        mov _GlobalSp, ebx
        add ebx, eax
        mov eax, [ebx]
        shl eax, 1
        or eax, ecx
        jnz fzeroeq2
fzeroeq1:
        mov D[ebx], -1
        jmp fzeroeqexit
fzeroeq2:
        mov D[ebx], 0
fzeroeqexit:
        mov ebx, _GlobalTp
        inc ebx
        inc ebx
        mov B[ebx], OP_IVAL
        dec ebx
        mov _GlobalTp, ebx
        xor eax, eax
        ret
L_fzerolt:
        mov eax, WSIZE
        add _GlobalSp, eax
        mov ebx, _GlobalSp
        FLD Q[ebx]
        add ebx, eax
        FLDZ
        FCOMPP
        FNSTSW ax
        and ah, 69
        jne fzeroeq2
        jmp fzeroeq1
L_fzerogt:
        ret
L_fadd:
        add _GlobalSp, WSIZE
        mov ebx, _GlobalSp
        FLD Q[ebx]
        add ebx, 2*WSIZE
        FADD Q[ebx]
        FSTP Q[ebx]
        add _GlobalSp, WSIZE
        add _GlobalTp, 2
        ret
L_fsub:
        add _GlobalSp, 3*WSIZE
        mov ebx, _GlobalSp
        FLD Q[ebx]
        sub ebx, 2*WSIZE
        FSUB Q[ebx]
        add ebx, 2*WSIZE
        FSTP Q[ebx]
        sub _GlobalSp, WSIZE
        add _GlobalTp, 2
        ret
L_fmul:
        add _GlobalSp, WSIZE
        mov ebx, _GlobalSp
        FLD Q[ebx]
        add ebx, 2*WSIZE
        FMUL Q[ebx]
        FSTP Q[ebx]
        add _GlobalSp, WSIZE
        add _GlobalTp, 2
        ret
L_fdiv:
        add _GlobalSp, WSIZE
        mov ebx, _GlobalSp
        FLD Q[ebx]
        FTST
        jnz fdiv1
        sub _GlobalSp, WSIZE
        mov eax, E_DIV_ZERO
        jmp fdivexit
fdiv1:  add ebx, 2*WSIZE
        FDIVR Q[ebx]
        FSTP Q[ebx]
        add _GlobalSp, WSIZE
        add _GlobalTp, 2
fdivexit:
        ret
L_fabs:
        mov ebx, _GlobalSp
        add ebx, WSIZE
        FLD Q[ebx]
        FABS
        FSTP Q[ebx]
        ret
L_fneg:
        mov ebx, _GlobalSp
        add ebx, WSIZE
        FLD Q[ebx]
        FCHS
        FSTP Q[ebx]
        ret
L_floor:
        mov ebx, _GlobalSp
        add ebx, WSIZE
        mov eax, [ebx + WSIZE]
        push eax
        mov eax, [ebx]
        push eax
        call _floor
        add esp, 8
        FSTP Q[ebx]
        xor eax, eax
        ret
L_fround:
        mov ebx, _GlobalSp
        add ebx, WSIZE
        FLD Q[ebx]
        FRNDINT
        FSTP Q[ebx]
        ret
L_ftrunc:
	  mov ebx, _GlobalSp
	  add ebx, WSIZE
	  FLD Q[ebx]
	  FNSTCW [ebx]
	  mov ecx, [ebx]	; save NDP control word
	  mov edx, ecx
	  mov dh, 12
	  mov [ebx], edx
	  FLDCW [ebx]
	  FRNDINT
	  mov [ebx], ecx
	  FLDCW [ebx]		; restore NDP control word	
	  FSTP Q[ebx]
	  xor eax, eax
	  ret
L_fsqrt:
        mov ebx, _GlobalSp
        FLD Q[ebx + WSIZE]
        FSQRT
        FSTP Q[ebx + WSIZE]
        ret
L_fcos:
        mov ebx, _GlobalSp
        FLD Q[ebx + WSIZE]
        FCOS
        FSTP Q[ebx + WSIZE]
        ret
L_fsin:
        mov ebx, _GlobalSp
        FLD Q[ebx + WSIZE]
        FSIN
        FSTP Q[ebx + WSIZE]
        ret
L_fatan2:
        mov ebx, _GlobalSp
        add ebx, 2*WSIZE
        FLD Q[ebx + WSIZE]
        FLD Q[ebx - WSIZE]
        FPATAN
        FSTP Q[ebx + WSIZE]
        mov _GlobalSp, ebx
        inc _GlobalTp
        inc _GlobalTp
        ret
L_fpow:
;        add _GlobalSp, WSIZE
;        mov ebx, _GlobalSp
;        FLD Q[ebx]
;        add ebx, 2*WSIZE
;        FLD Q[ebx]
;        FYL2X
        ; FLD1
        ; FSCALE
;        FSTP Q[ebx]
;        add _GlobalSp, WSIZE
;        add _GlobalTp, 2
        ret
;
_vm     endp
_TEXT ENDS
end
