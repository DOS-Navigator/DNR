; SYSINT converted to NASM

bits 16

%ifdef _DPMI_
    %define DPMIVersion 1
%else
    %define DPMIVersion 0
%endif

; Keyboard scan codes
scSpaceKey      equ     0x39
scInsKey        equ     0x52
scDelKey        equ     0x53
scBackKey       equ     0x0E
scUpArrow       equ     0x48
scDownArrow     equ     0x50
scLeftArrow     equ     0x4B
scRightArrow    equ     0x4D
scTab           equ     0x0F
scEsc           equ     0x01
scEnter         equ     0x1C
scGrayPlus      equ     0x4E
scGrayMinus     equ     0x4A
scGrayAst       equ     0x37
scSlash         equ     0x35
scLSqBraket     equ     0x1A
scRSqBraket     equ     0x1B
scSemicolon     equ     0x27
scQuote         equ     0x28
scLAngle        equ     0x33
scRAngle        equ     0x34
scPgUpKey       equ     0x49
scPgDnKey       equ     0x51

; Keyboard shift flags
kbShiftKey      equ     0x03
kbCtrlKey       equ     0x04
kbAltKey        equ     0x08
kbNumLock       equ     0x20

; ROM BIOS workspace offsets
KeyFlags        equ     0x17
KeyBufHead      equ     0x1A
KeyBufTail      equ     0x1C
KeyBufOrg       equ     0x80
KeyBufEnd       equ     0x82

; DOS function call classes
cNothing        equ     0       ;No check needed
cName           equ     2       ;Check name at DS:DX
cHandle         equ     4       ;Check handle in BX
cDrive          equ     6       ;Check drive in DL

%if DPMIVersion
; DPMI interrupt vector number
DPMI            equ     0x31

; DPMI function codes
dpmiAllocDesc   equ     0x0000
dpmiFreeDesc    equ     0x0001
dpmiSetSegBase  equ     0x0007
dpmiGetRealInt  equ     0x0200
dpmiSetRealInt  equ     0x0201
dpmiGetProtInt  equ     0x0204
dpmiSetProtInt  equ     0x0205
dpmiAllocRMCB   equ     0x0303
dpmiFreeRMCB    equ     0x0304

; DPMI real mode call-back registers structure offsets
realDI          equ     0x00
realSI          equ     0x04
realBP          equ     0x08
realBX          equ     0x10
realDX          equ     0x14
realCX          equ     0x18
realAX          equ     0x1C
realFlags       equ     0x20
realES          equ     0x22
realDS          equ     0x24
realFS          equ     0x26
realGS          equ     0x28
realIP          equ     0x2A
realCS          equ     0x2C
realSP          equ     0x2E
realSS          equ     0x30
%endif

section .data
    extern   SysErrorFunc
    extern   CtrlBreakHit
    extern   SaveCtrlBreak
    extern   SysErrActive

%if DPMIVersion
    extern   SelectorInc
    extern   Seg0040
    extern   RealModeRegs
    TempSelector    dw      0
%endif

section .text
    global  InitSysError
    global  DoneSysError

OurDataSegment dw 0

SaveInt09       dd      0
SaveInt1B       dd      0
SaveInt21       dd      0
SaveInt23       dd      0
SaveInt24       dd      0

KeyConvertTab:
    db      scSpaceKey,kbAltKey
    dw      0C200H
    db      scInsKey,kbShiftKey
    dw      0C300H
    db      scDelKey,kbShiftKey
    dw      0C400H
    db      scEnter,0
    dw      1C0DH
    db      scEnter,kbCtrlKey
    dw      1C0AH
    db      scEnter,kbAltKey
    dw      01C00H
    db      scSlash, kbAltKey
    dw      0A400h
    db      scSlash, kbCtrlKey
    dw      09500h
    db      scInsKey, kbAltKey
    dw      0A200h
    db      scDelKey, kbAltKey
    dw      0A300h
    db      scLeftArrow, kbAltKey
    dw      0x9B00
    db      scRightArrow, kbAltKey
    dw      0x9D00
    db      scPgUpKey, kbAltKey
    dw      0x9900
    db      scPgDnKey, kbAltKey
    dw      0xA100
KeyConvertCnt   equ     ($-KeyConvertTab)/4

FuncClassTab:
    db      cDrive, cNothing, cNothing, cName, cName, cName, cName, cName
    db      cHandle, cHandle, cHandle, cName, cHandle, cName, cNothing
    db      cNothing, cNothing, cDrive, cNothing, cNothing, cNothing
    db      cName, cNothing, cNothing, cName, cNothing, cNothing
    db      cNothing, cNothing, cNothing, cNothing, cName, cHandle

FuncCheckTab:
    dw      CheckNothing
    dw      CheckName
    dw      CheckHandle
    dw      CheckDrive

InitSysError:
    mov     [cs:OurDataSegment], ds
    mov     ax,0x3300
    int     0x21
    mov     [SaveCtrlBreak],dl
    mov     ax,0x3301
    mov     dl,0
    int     0x21
%if DPMIVersion
    mov     ax,dpmiAllocDesc
    mov     cx,1
    int     DPMI
    mov     [TempSelector],ax
    mov     ax,cs
    add     ax,[SelectorInc]
    mov     es,ax
    mov     di,SaveInt09
    cld
    mov     bl,0x09
    call    GetProtInt
    mov     bl,0x1B
    call    GetRealInt
    mov     bl,0x21
    call    GetProtInt
    mov     bl,0x23
    call    GetProtInt
    mov     bl,0x24
    call    GetRealInt
    mov     bl,0x09
    mov     dx,Int09Handler
    mov     cx,cs
    call    SetProtInt
    mov     bl,0x1B
    mov     dx,Int1BHandler
    mov     cx,cs
    call    SetRealInt
    mov     es,[Seg0040]
    mov     ax,[es:0x10]
    and     ax,0xC1
    dec     ax
    jne     .no_int21
    mov     bl,0x21
    mov     dx,Int21Handler
    mov     cx,cs
    call    SetProtInt
.no_int21:
    mov     bl,0x23
    mov     dx,Int23Handler
    mov     cx,cs
    call    SetProtInt
    mov     bl,0x24
    mov     dx,Int24Handler
    mov     cx,cs
    call    SetRealInt
    mov     ax,dpmiGetProtInt
    mov     bl,0x10
    int     DPMI
    push    cx
    push    dx
    mov     ax,dpmiSetProtInt
    mov     bl,0x10
    mov     dx,Int10Handler
    mov     cx,cs
    int     DPMI
    mov     ah,0x0B
    int     0x21
    pop     dx
    pop     cx
    mov     ax,dpmiSetProtInt
    mov     bl,0x10
    int     DPMI
%else
    push    ds
    xor     ax,ax
    mov     ds,ax
    mov     di,SaveInt09
    push    cs
    pop     es
    cld
    cli
    mov     si,0x09*4
    movsw
    movsw
    mov     si,0x1B*4
    movsw
    movsw
    mov     si,0x21*4
    movsw
    movsw
    mov     si,0x23*4
    movsw
    movsw
    mov     si,0x24*4
    movsw
    movsw
    mov     word [ds:0x09*4+0],Int09Handler
    mov     word [ds:0x09*4+2],cs
    mov     word [ds:0x1B*4+0],Int1BHandler
    mov     word [ds:0x1B*4+2],cs
    mov     ax,[ds:0x410]
    and     ax,0xC1
    dec     ax
    jne     .no_int21_real
    mov     word [ds:0x21*4+0],Int21Handler
    mov     word [ds:0x21*4+2],cs
.no_int21_real:
    mov     word [ds:0x23*4+0],Int23Handler
    mov     word [ds:0x23*4+2],cs
    mov     word [ds:0x24*4+0],Int24Handler
    mov     word [ds:0x24*4+2],cs
    sti
    mov     ax,cs
    xchg    ax,word [ds:0x10*4+2]
    push    ax
    mov     ax,Int10Handler
    xchg    ax,word [ds:0x10*4+0]
    push    ax
    mov     ah,0x0B
    int     0x21
    pop     word [ds:0x10*4+0]
    pop     word [ds:0x10*4+2]
    pop     ds
%endif
    mov     byte [SysErrActive],1
    retf

DoneSysError:
    cmp     byte [SysErrActive],0
    je      .exit_done
    mov     byte [SysErrActive],0
%if DPMIVersion
    push    ds
    mov     si,SaveInt09
    push    cs
    pop     ds
    cld
    mov     bl,0x09
    call    ResetProtInt
    mov     bl,0x1B
    call    ResetRealInt
    mov     bl,0x21
    call    ResetProtInt
    mov     bl,0x23
    call    ResetProtInt
    mov     bl,0x24
    call    ResetRealInt
    pop     ds
    mov     ax,dpmiFreeDesc
    mov     bx,[TempSelector]
    int     DPMI
%else
    push    ds
    mov     si,SaveInt09
    push    cs
    pop     ds
    xor     ax,ax
    mov     es,ax
    cld
    cli
    mov     di,0x09*4
    movsw
    movsw
    mov     di,0x1B*4
    movsw
    movsw
    mov     di,0x21*4
    movsw
    movsw
    mov     di,0x23*4
    movsw
    movsw
    mov     di,0x24*4
    movsw
    movsw
    sti
    pop     ds
%endif
    mov     ax,0x3301
    mov     dl,[SaveCtrlBreak]
    int     0x21
.exit_done:
    retf

%if DPMIVersion
GetRealInt:
    mov     ax,dpmiGetRealInt
    jmp     short GetIntVector
GetProtInt:
    mov     ax,dpmiGetProtInt
GetIntVector:
    int     DPMI
    xchg    ax,dx
    stosw
    xchg    ax,cx
    stosw
    retn
ResetRealInt:
    mov     ax,dpmiGetRealInt
    int     DPMI
    push    cx
    push    dx
    lodsw
    xchg    ax,dx
    lodsw
    xchg    ax,cx
    mov     ax,dpmiSetRealInt
    int     DPMI
    pop     dx
    pop     cx
    mov     ax,dpmiFreeRMCB
    int     DPMI
    retn
SetRealInt:
    mov     ax,dpmiAllocRMCB
    mov     di,RealModeRegs
    push    ds
    pop     es
    mov     si,dx
    mov     ds,cx
    int     DPMI
    push    es
    pop     ds
    mov     ax,dpmiSetRealInt
    int     DPMI
    retn
ResetProtInt:
    lodsw
    xchg    ax,dx
    lodsw
    xchg    ax,cx
SetProtInt:
    mov     ax,dpmiSetProtInt
    int     DPMI
    retn
RealModeIRET:
    cld
    lodsw
    mov     [es:di + realIP],ax
    lodsw
    mov     [es:di + realCS],ax
    lodsw
    mov     [es:di + realFlags],ax
    add     word [es:di + realSP],6
    retn
%endif

Int09Handler:
    db      'IN_9'
    push    ds
    push    di
    push    si
    push    ax
    push    bx
    push    cx
%if DPMIVersion
    mov     ax,[cs:OurDataSegment]
    mov     ds,ax
    mov     ds,[Seg0040]
%else
    mov     ax,0x40
    mov     ds,ax
%endif
    and     byte [ds:0x18],0x7F
    mov     di,[ds:KeyBufTail]
    mov     bx,[ds:KeyBufHead]
    in      al,0x60
    mov     ah,[ds:KeyFlags]
    pushf
    call    [cs:SaveInt09]
    test    al,0x80
    jne     .key_release
    mov     byte [cs:PrevAlt],0
    mov     byte [cs:PrevCtrl],0
    test    ah, 0x07
    jnz     .check_ctrl
    cmp     al,0x38
    jne     .check_ctrl
    mov     byte [cs:PrevAlt],1
    jmp     .no_convert
.check_ctrl:
    test    ah, 0x0B
    jnz     .no_convert
    cmp     al,0x1D
    jne     .no_convert
    mov     byte [cs:PrevCtrl],1
.no_convert:
    mov     si,KeyConvertTab
    mov     cx,KeyConvertCnt
    jcxz    .exit_handler
.find_key:
    cmp     al,[cs:si]
    jne     .next_key
    test    ah,byte [cs:si+1]
    jne     .found_key
.next_key:
    add     si,4
    loop    .find_key
    jmp     short .exit_handler
.found_key:
    mov     [ds:KeyBufTail],di
    mov     [ds:KeyBufHead],bx
    mov     ax,di
    inc     ax
    inc     ax
    cmp     ax,[ds:KeyBufEnd]
    jb      .buffer_ok
    mov     ax,[ds:KeyBufOrg]
.buffer_ok:
    cmp     ax,[ds:KeyBufHead]
    je      .exit_handler
    mov     [ds:KeyBufTail],ax
    mov     ax,[cs:si+2]
    mov     [ds:di],ax
.exit_handler:
    pop     cx
    pop     bx
    pop     ax
    pop     si
    pop     di
    pop     ds
    iret
.key_release:
    cmp     al,0x38 | 0x80
    jne     .ctrl_release
    cmp     byte [cs:PrevAlt],0
    je      .exit_handler
    mov     si, AltCode-2
    jmp     .found_key
.ctrl_release:
    cmp     al,0x1D | 0x80
    jne     .exit_handler
    cmp     byte [cs:PrevCtrl],0
    je      .exit_handler
    mov     si, CtrlCode-2
    jmp     .found_key

PrevAlt  db      0
AltCode  dw      0x3800
PrevCtrl db      0
CtrlCode dw      0x1D00

Int1BHandler:
%if DPMIVersion
    call    RealModeIRET
    mov     ds,[es:Seg0040]
    and     byte [ds:0x71],0x7F
    mov     byte [es:CtrlBreakHit],1
%else
    push    ds
    push    ax
    xor     ax,ax
    mov     ds,ax
    and     byte [ds:0x471],0x7F
    mov     ax,[cs:OurDataSegment]
    mov     ds,ax
    mov     byte [CtrlBreakHit],1
    pop     ax
    pop     ds
%endif
    iret

Int21Handler:
    pushf
    sti
    cmp     ah,0x36
    jb      .original_int21
    cmp     ah,0x57
    ja      .original_int21
    push    dx
    push    bx
    mov     bl,ah
    xor     bh,bh
    mov     bl,[cs:FuncClassTab + bx - 0x36]
    call    [cs:FuncCheckTab + bx]
    pop     bx
    pop     dx
    jc      .error_exit
.original_int21:
    popf
    jmp     [cs:SaveInt21]
.error_exit:
    popf
    sti
    cmp     ah,0x36
    mov     ax,0xFFFF
    je      .set_carry
    mov     ax,5
.set_carry:
    stc
    retf    2

CheckName:
    mov     bx,dx
    mov     dx,[bx]
    and     dl,0x1F
    dec     dl
    cmp     dh,':'
    je      CheckAbsDrive
    jmp     short CheckCurDrive

CheckHandle:
    mov     bx,sp
    mov     bx,[ss:bx+2]
    push    ax
    mov     ax,0x4400
    pushf
    call    [cs:SaveInt21]
    pop     ax
    or      dl,dl
    jns     CheckAbsDrive
    jmp     short CheckNothing

CheckDrive:
    dec     dl
    jns     CheckAbsDrive

CheckCurDrive:
    push    ax
    mov     ah,0x19
    pushf
    call    [cs:SaveInt21]
    mov     dl,al
    pop     ax

CheckAbsDrive:
    cmp     dl,2
    jae     CheckNothing
    push    ds
    push    ax
%if DPMIVersion
    mov     ax,[cs:OurDataSegment]
    mov     ds,ax
    mov     ds,[Seg0040]
    mov     al,[ds:0x104]
%else
    xor     ax,ax
    mov     ds,ax
    mov     al,[ds:0x504]
%endif
    cmp     al,0xFF
    je      .no_swap
    cmp     dl,al
    je      .no_swap
    push    es
    push    ds
    push    di
    push    si
    push    dx
    push    cx
    mov     ax,[cs:OurDataSegment]
    mov     ds,ax
    mov     ax,15
    push    ax
    push    dx
    call    SysErrorFunc
    pop     cx
    pop     dx
    pop     si
    pop     di
    pop     ds
    pop     es
    neg     ax
    jc      .no_swap
%if DPMIVersion
    mov     [ds:0x104],dl
%else
    mov     [ds:0x504],dl
%endif
.no_swap:
    pop     ax
    pop     ds

CheckNothing:
    retn

Int10Handler:
Int23Handler:
    iret

Int24Handler:
    sti
%if DPMIVersion
    call    RealModeIRET
    push    es
    pop     ds
    mov     al,[di + realAX]
    mov     dl,[di + realDI]
    xor     dh,dh
    cmp     dl,9
    je      .is_printer_error
    test    byte [di + realAX + 1], 0x80
    je      .disk_error
    mov     dl,13
    push    dx
    push    ax
    mov     ax,16
    mul     word [di + realBP]
    mov     cx,dx
    mov     dx,ax
    mov     ax,dpmiSetSegBase
    mov     bx,[TempSelector]
    int     DPMI
    mov     es,bx
    mov     bx,[di + realSI]
    test    byte [es:bx+5],0x80
    pop     ax
    pop     dx
    je      .is_printer_error
    inc     dx
.is_printer_error:
    mov     al,0xFF
.disk_error:
    push    di
    push    dx
    push    ax
    call    SysErrorFunc
    pop     di
    or      ax,ax
    mov     al,1
    je      .set_ax
    mov     al,3
.set_ax:
    mov     [di + realAX],al
    push    ds
    pop     es
%else
    push    es
    push    ds
    push    bp
    push    di
    push    si
    push    dx
    push    cx
    push    bx
    and     di,0x00FF
    push    di
    cmp     di,9
    je      .is_printer_error_real
    test    ah,0x80
    je      .disk_error_real
    mov     di,13
    mov     ds,bp
    test    byte [ds:si+5],0x80
    je      .disk_error_real
    inc     di
.is_printer_error_real:
    mov     al,0xFF
.disk_error_real:
    mov     ax,[cs:OurDataSegment]
    mov     ds,ax
    push    di
    push    ax
    call    SysErrorFunc
    pop     di
    cmp     ax,1
    jbe     .retry
    add     sp,(8+3)*2
    pop     ax
    add     di,19
    cmp     ah,0x39
    jae     .dos2_style
    mov     di,0xFFFF
.dos2_style:
    mov     ah,0x54
    int     0x21
    mov     ax,di
    mov     bp,sp
    or      byte [bp+20],1
.retry:
    pop     bx
    pop     cx
    pop     dx
    pop     si
    pop     di
    pop     bp
    pop     ds
    pop     es
%endif
    iret
