;:

; Function: determines CPU & NDP type.

;:

; Caller:   Turbo C:

;           int processors(void);

; INT processors(void);

;:

; Returns:  AL = central processor type (see below) and

AND:

;       AL bit 7 set if protected mode (AL & 80h != 0)

;       AH = coprocessor type (if any - see below)

;:

; References:

; 1) Source algorithm by Bob Felts, PC Tech Journal, November 1987

;    Printed: "Dr.Dobb's Tollbook of 80286/80386 programming,

;    M&T publishing, Inc. Redwood City, California

; 2) SI-System Information, Advanced Edition 4.50, (C) 1987-88, Peter Norton

; 3) PC Tools Deluxe R4.21

;    (C)Copyright 1985,1986,1987,1988 Central Point Software, Inc.

; 4) CHKCOP, Intel's Math CoProcessor Test Program ver 2.10

;    Copyright(c) Intel Corp. 1987-1990.

; 5) HelpPC 2.10 Quick Reference Utility Copyright (c) 1991, David Jurgens

;:

; Adapted & enhanced R.I.Akhmarov & T.V.Shaporev

; Computer Center MTO MFTI

;:

; Added CPUID detectiion

; Pentium and higher detection by Slava Filimonov

AND higher detection by Slava Filimonov

; equ

equ:

equ:

equ:

equ:

equ:

equ:

equ:

equ:

equ:

equ:

equ:

equ:

equ:

equ:

equ:

equ:

equ:

equ:

equ:

macro:

; Force 32-bit operand size db db

; 32-bit immediate value dd endm

macro:

; Hardcoded opcode for CPUID instruction db db endm

section public

PUSH bp

MOV bp,sp

; At first determine central processor type

; 86/186 or 286/386

MOV ax,sp           ; 86/186 or 286/386

; 86/186 will push sp-2

PUSH sp              ; 86/186 will push sp-2

; others will push sp

POP cx              ; others will push sp

CMP ax,cx

; if 80286/80386

;   Place 'inc ax' command to make the code re-enterable

MOV cs:critical,40h

; Prepare to 8018x

MOV dl,CPU186       ; Prepare to 8018x

; distinguish between 86 and 186

MOV ax,0FFFFh       ; distinguish between 86 and 186

; 8086 will shift 32 bits bits

MOV cl,33           ; 8086 will shift 32 bits

; 80186 will shift 0 bits bits

; NZ implies 186

;   Now distinguish Intel from NEC.

MOV dl,CPUNEC20

MOV cx,0FFFFh

PUSH si

; for the God's sake

MOV es,si           ; for the God's sake

; LODSB REP ES: db

POP si

MOV dl,CPU8086

cpu_x808x:PUSH di

PUSH es

PUSH cs

POP es

; nop code

MOV ax,90h          ; nop code

MOV cx,4

critical:lenconv:POP es

POP di

CMP al,90h

ADD dl,CPU8088-CPU8086

jump_cpu_ok:JMP cpu_ok

cpu_2386:MOV dl,CPU286

; 286/386 - 32 or 16 bit operand?

; OR 16 bit operand?

; if pushf pushed 2 bytes

MOV cx,sp           ; if pushf pushed 2 bytes

; then 16 bit operand size

MOV sp,bp           ; then 16 bit operand size

; assume 2 bytes

SUB cx,ax

;   Either 286 or 386 with 16 bit oper

; OR 386 with 16 bit oper

; add sp,-6 = allocate room for SGDT db

; ADD sp,-6 = allocate room for SGDT

; 286 stores -1,

; 386 stores 0 or 1

MOV sp,bp           ; 386 stores 0 or 1

; go check for protected mode

; 386 in 16 or 32 bit code segment section

generic_386:

; OR 32 bit code segment

MOV dl,CPU386

; check for protected mode

; if protection enable,

;                jnz     short cpu_ok    ; the following is impossible

; now check for i486

MOV dl,CPU486       ; now check for i486

; and sp,-4 = align to 4-byte boundary db

; AND sp,-4 = align to 4-byte boundary

; 386 in 32 bit code segment section

; 32-bit flags

; pop eax

POP ax              ; pop eax

; mov ecx,eax = save original flags

MOV cx,ax           ; mov ecx,eax = save original flags

; btc eax,18  = toggle bit 18

; push eax

PUSH ax              ; push eax

; 32-bit flags

; 32-bit flags

; pop  eax

POP ax              ; pop  eax

; push ecx

PUSH cx              ; push ecx

; restore original eflags

; restore stack pointer

MOV sp,bp           ; restore stack pointer

; can 18th bit be changed?

CMP ax,cx           ; can 18th bit be changed?

; yes, it's i486

JMP short test_SX_cpu

; 386 in 16 bit code segment section

cpu_16_bit:

POP eax

; save original flags

MOV ecx,eax         ; save original flags

; toggle bit 18

PUSH eax

POP eax

PUSH ecx

; restore original flags

; restore stack pointer

MOV sp,bp           ; restore stack pointer

; can 18th bit be changed?

CMP eax,ecx         ; can 18th bit be changed?

; yes, it's i486

; let's distinguish SX and DX

test_SX_cpu:

AND DX

MOV dl,CPU386SX

MOV eax,cr0

; coprocessor type flag

; clear flag

MOV cr0,eax

MOV eax,cr0

; if the flag can be cleared, it is DX

re_cop_flag:

; restore the flag

MOV cr0,eax         ; restore the flag

cpu_is_DX:

MOV dl,CPU386DX

JMP short cpu_ok

cpu_ok:

CMP dl,CPU486

check_80486:

; and sp,-4 = align to 4-byte boundary db

; AND sp,-4 = align to 4-byte boundary

PUSH ecx

MOV eax,ecx

PUSH eax

POP eax

MOV sp,bp

CMP eax,ecx

PUSH dx

; otherwise, use as input to CPUID

CMP al,1

;jc      go_tfpu

; cpu family

AND ah,0fh                   ; cpu family

CMP ah,5

POP cx

; set cpu_type with family

MOV dl,ah                   ; set cpu_type with family

ADD dl,CPU586 - 5

JMP test_fpu

go_tfpu:

POP dx

test_fpu:

; At second determine numeric coprocessor generic type

; reserve stack

PUSH cx                      ; reserve stack

MOV dh,NDPNONE

; fninit; Initialize math uP db

MOV [bp-1],0

; fnstcw word [bp-2] db

CMP [bp-1],3

MOV dh,NDP8087

AND [bp-2],7Fh

; fldcw word [bp-2] db

; fdisi ; Disable Interrupts db

; fstcw word [bp-2] db

MOV dh,NDP287

; finit         ; Initialize math uP db

; fld1          ; Push +1.0 to stack db

; PUSH +1.0 to stack

; fldz          ; Push +0.0 to stack db

; PUSH +0.0 to stack

; fdivp st(1),st; st(#)=st(#)/st, pop db

POP:

; fld   st      ; Push onto stack db

; PUSH onto stack

; fchs          ; Change sign in st db

; fcompp        ; Compare st & pop 2 db

POP 2

; fstsw word [bp-2] db

MOV ah,[bp-1]

MOV dh,NDP387

ndp_done:

; restore stack

POP cx                          ; restore stack

; At last analyse main and co-processor combination

; AND co-processor combination

CMP dh,NDP387

CMP dl,CPU486

MOV dl,CPU486SX

JMP short cpu_prot

; i387 detected

analyse_hi:

CMP dl,CPUNEC30

POP bp

JMP CPU_2386

No_V30:

CMP dl,CPU286

; 387 at 8088? Wonderful!

JMP short cpu_prot          ; 387 at 8088? Wonderful!

analyse_386:

; coprocessor type flag

set_287XL:

MOV dh,NDP287XL

JMP short cpu_prot

test_SX_DX:

CMP dl,CPU386SX

MOV dh,NDP387SX

JMP short cpu_prot

no_SX:

CMP dl,CPU386DX

MOV dh,NDP387DX

cpu_prot:

CMP dl,CPU286

; check for protected mode

; if PE = 0 then real mode

; else indicate protected mode

OR dl,al                   ; else indicate protected mode

return:

MOV ax,dx

POP bp