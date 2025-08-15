;
; CPU Frequency detection
;
;******************************************************************************
;*              HPL, Copyright (C) 1991,92 Sandy Company, ltd.                *
;*                          All Right Reserved                                *
;******************************************************************************
;File:       _MHZ.ASM converted to _MHZ.nasm
;Comments:   Sorry, it's my style :). (Preserved from original)

bits 16

section .text

i8886        equ     0                      ; Intel 8086/88
V2030        equ     1                      ; NEC V20/V30
i188186      equ     2                      ; Intel 80186/188
i80286       equ     3                      ; Intel 80286
i80386       equ     4                      ; Intel 80386/486

global       _mhz                           ; Public name is _mhz

_mhz:    ; Proc _mhz Far
             pushf                          ; Save Flags
             push    di
             push    si
             call    Processor              ; Call Processor Procedure
             call    Speed                  ; Call Speed Procedure
             pop     si
             pop     di
             popf                           ; Restore Flags
             retf                           ; Return to Main Programm

Processor: ; Proc Processor Near                 ; Checking for processors
             push    sp                     ; Save Sp
             pop     ax                     ; Restore Sp into Ax
             cmp     sp,ax                  ; If Sp!=Ax then Check Lower FPU
             jnz     .Low                   ; Jump to .Low
             mov     ax,0x7000              ; Ax=7000h
             push    ax                     ; Save Ax into Stack
             popf                           ; Restore Ax into Flags
             sti                            ; On Interrupt flag
             pushf                          ; Save Flags
             pop     ax                     ; Restore Flags Into Ax
             and     ax,0x7000              ; If highers flags has non zero
             jnz     .is80386               ; Intel 386/486 is present
             mov     dl,i80286              ; Dl=i80286
             jmp     .Exit                  ; Jump to .Exit
.is80386:
             mov     dl,i80386              ; Dl=80386/486/SXs
             jmp     .Exit                  ; Jump to .Exit

.Low:
             mov     cl,0x21                ; Test for lowest processors
             mov     ax,-1                  ; Ax=0FFFFh
             shl     ax,cl                  ; Shift lef on 21h bits
             jz      .NEC                   ; If Zero jump to.NEC
             mov     dl,i188186             ; Else Dl=i80188/186
             jmp     .Exit                  ; Jump to Exit
.NEC:
             mov     al,0x40                ; Al=40h
             mul     al                     ; Ax=Al*Al
             jnz     .is8088                ; If Zero then Jump to .8088
             mov     dl,V2030               ; Else Dl=NECv20/v30
             jmp     .Exit                  ; Jump to Exit
.is8088:
             mov     dl,i8886               ; Dl=i8088/86
.Exit:
             mov      al,dl                 ; Al=Dl
             xor      ah,ah                 ; Ah=0
             retn                           ; Return

SetTimer: ; Proc SetTimer Near
             in      al,0x61                ; Get Al from 61th port
             and     al,0xFC                ; Zero first bit
             out     0x61,al                ; Put Al on 61th port
             mov     al,180                 ; Al=Command
             out     0x43,al                ; Put AL to Command's port
             xor     al,al                  ; Al=0
             out     0x42,al                ; Put low Time to 42th port
             jmp     $+2                    ; Wait
             out     0x42,al                ; Put high Time
             in      al,0x61                ; Get Al from 61th port
             or      al,1                   ; Set First bit
             cli                            ; Clear Interrupt
             out     0x61,al                ; Start Timer
             retn                           ; Return

GetTimer: ; Proc GetTimer Near
             in      al,0x61                ; Get al from 61th port
             and     al,0xFC                ; Zero first bit (stop timer)
             out     0x61,al                ; Put Al into 61th port.
             in      al,0x42                ; Get AL from 42th port
             mov     ah,al                  ; Ah=Al
             in      al,0x42                ; Get Al from 42th port
             xchg    al,ah                  ; Al=Ah ; Ah=Al
             neg     ax                     ; Ax=Negative Ax
             sti                            ; Set interrupt flag
             retn                           ; Return

Speed:   ; Proc Speed Near                   ; Speed procedure ( Inp: Al=CPU )
             push    ax                     ; Save Ax
             mov     si,0x7AAA              ; Si=07AAAh (Air value)
             mov     bx,0x5555              ; Bx=05555h (Air value)
             mov     cx,10                  ; Cx=10
             cmp     al,i8886               ; If Al<=i8086
             jbe     .Test                  ; Jump to Test
             mov     cx,50                  ; Cx=50
             cmp     al,V2030               ; If Al<=NECv20/v30
             jbe     .Test                  ; Jump to Test
             mov     cx,100                 ; Cx=100
             cmp     al,i188186             ; If Al<=I80188/186
             jbe     .Test                  ; Jump to Test
             mov     cx,200                 ; Cx=200
.Test:
             push    cx                     ; Save Cx
             xor     dx,dx                  ; Dx=0
             call    SetTimer
.PASS_A:
             times 66 db 0x8B, 0xC6, 0xF7, 0xF3 ; Sprite
             dec     cx                     ; Cx=Cx-1
             jz      .Passed_A              ; If Cx=0 the Jump to .Passed_A
             jmp     .PASS_A                ; Jump to .Pass_A
.Passed_A:
             call    GetTimer
             mov     di,ax
             pop     cx                     ; Restore Cx
             xor     dx,dx                  ; Dx=0
             call    SetTimer
.PASS_B:
             times 2 db 0x8B, 0xC6, 0xF7, 0xF3 ; Sprite
             dec     cx                     ; Cx=Cx-1
             jz      .Passed_B
             jmp     .PASS_B
.Passed_B:
             call    GetTimer
             sub     di,ax                  ; Di=Di-Ax
             pop     bx                     ; Restore Ax into Bx
             shl     bx,1
             shl     bx,1                   ; Bx=Bx*4
             add     bx, Denom              ; Bx=Bx+&Denom
             mov     ax,[cs:bx]             ; Dx:Ax=Denom
             mov     dx,[cs:bx+2]
             cmp     di,dx                  ; If Di<Dx then Ax=9999
             jb      .Overflow              ; Go to Overflow
             div     di                     ; Ax=Dx:Ax/Di
             jmp     .Exit_Speed
.Overflow:
             mov     ax,33300               ; Ax=33300
.Exit_Speed:
             retn                           ; Return

Denom:   ; Label Denom Word
             dd      0x00B6F062
             dd      0x00B4D716
             dd      0x01D21634
             dd      0x022FE1B0
             dd      0x02469BC6
