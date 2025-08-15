bits 16
org 0x100

%macro outb 2
    mov   al, %1
    out   dx, al
    mov   al, %2
    inc   dx
    out   dx, al
    dec   dx
%endmacro

%macro outv 1
    mov     al, %1
    out     dx, al
%endmacro

start:
    cli
    mov       dx, 0x3C4
    outb      0, 1

    mov       dx, 0x3D4
    outv      23
    inc       dx
    in        al, dx
    and       al, 127
    out       dx, al
    dec       dx

    outv      17
    inc       dx
    in        al, dx
    and       al, 127
    out       dx, al

    mov       dx, 0x3CC
    in        al, dx
    or        al, 192
    mov       dx, 0x3C2
    out       dx, al

    mov       dx, 0x3D4

    outb      6, 11
    outb      7, 62
    outb      9, 79
    outb      16, 234
    outb      17, 140
    outb      18, 223
    outb      21, 231
    outb      22, 4

    outv      17
    inc       dx
    in        al, dx
    or        al, 128
    out       dx, al
    dec       dx

    outv      23
    inc       dx
    in        al, dx
    or        al, 128
    out       dx, al
    mov       dx, 0x3C4
    outb      0, 3

    sti
    mov ax, 0x40
    mov ds, ax
    mov byte [ds:0x84], 29
    retn
