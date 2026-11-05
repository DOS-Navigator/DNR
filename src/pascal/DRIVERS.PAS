{/////////////////////////////////////////////////////////////////////////
//
//  Dos Navigator  Version 1.51  Copyright (C) 1991-99 RIT Research Labs
//
//  This programs is free for commercial and non-commercial use as long as
//  the following conditions are aheared to.
//
//  Copyright remains RIT Research Labs, and as such any Copyright notices
//  in the code are not to be removed. If this package is used in a
//  product, RIT Research Labs should be given attribution as the RIT Research
//  Labs of the parts of the library used. This can be in the form of a textual
//  message at program startup or in documentation (online or textual)
//  provided with the package.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are
//  met:
//
//  1. Redistributions of source code must retain the copyright
//     notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer in the
//     documentation and/or other materials provided with the distribution.
//  3. All advertising materials mentioning features or use of this software
//     must display the following acknowledgement:
//     "Based on Dos Navigator by RIT Research Labs."
//
//  THIS SOFTWARE IS PROVIDED BY RIT RESEARCH LABS "AS IS" AND ANY EXPRESS
//  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
//  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
//  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
//  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The licence and distribution terms for any publically available
//  version or derivative of this code cannot be changed. i.e. this code
//  cannot simply be copied and put under another distribution licence
//  (including the GNU Public Licence).
//
//////////////////////////////////////////////////////////////////////////}

unit Drivers;

{-----------------------------------------------------}
{ This module is based on Turbo Vision Drivers Unit   }
{ Copyright (c) 1990 by Borland International         }
{-----------------------------------------------------}

interface

uses Objects, xTime;

{$I Version.INC}

var
  LSliceTimer: TEventTimer;
  LSliceCnt: LongInt;


procedure SliceAwake;
procedure FlushScreenBuffer;
procedure SliceYield;

{ ******** EVENT MANAGER ******** }

const

{ Event codes }

  evMouseDown = $0001;
  evMouseUp   = $0002;
  evMouseMove = $0004;
  evMouseAuto = $0008;
  evKeyDown   = $0010;
  evCommand   = $0100;
  evBroadcast = $0200;

{ Event masks }

  evNothing   = $0000;
  evMouse     = $000F;
  evKeyboard  = $0010;
  evMessage   = $FF00;

  AltSpaceChar: Char = #240;

  AltCodes1: array[$10..$34] of Char =
    'QWERTYUIOP'#0#0#0#0'ASDFGHJKL'#0#0#0#0#0'ZXCVBNM'#0#0;

{ Mouse button state masks }

  mbLeftButton  = $01;
  mbRightButton = $02;

type

{ Event record }

  PEvent = ^TEvent;
  TEvent = record
    What: Word;
    case Word of
      evNothing: ();
      evMouse: (
        Buttons: Byte;
        Double: Boolean;
        Where: TPoint);
      evKeyDown: (
        case Integer of
          0: (KeyCode: Word);
          1: (CharCode: Char;
              ScanCode: Byte));
      evMessage: (
        Command: Word;
        case Word of
          0: (InfoPtr: Pointer);
          1: (InfoLong: Longint);
          2: (InfoWord: Word);
          3: (InfoInt: Integer);
          4: (InfoByte: Byte);
          5: (InfoChar: Char));
  end;

  CharDef = Array [0..15] of Byte;


{ Initialized variables }
Const

  ButtonCount: Byte = 0;
  MouseEvents: Boolean = False;
  MouseReverse: Boolean = False;
  MouseButtons: Byte = 0;
  DoubleDelay: Word = 8;
  RepeatDelay: Word = 8;
  UserScreen: Pointer = nil;
  GraphMouse: Boolean = False;
  MouseMouse: Boolean = True;
  CharHeight: Byte = 16;
  ScreenSaved: Boolean = False;
  DESQDetected: Boolean = False;
  NeedAbort: Boolean = False;
  StdMouse: Boolean = False; { Is engine really using standard mouse }
  XSens: Byte = 11;
  YSens: Byte = 11;
  CLSAct: Boolean = True;
  CurrentBlink : Boolean = False;

var

{ Uninitialized variables }
  OldBlink: Boolean;

  MouseIntFlag: Byte;
  MouseWhere: TPoint;
  UserScreenSize: Word;
  UserScreenWidth: Word;
  MouseX, MouseY,
  OldMouseX, OldMouseY: Word;
  ShowMouseProc,
  HideMouseProc: Pointer;

{ Event manager routines }


procedure InitDrivers;
procedure InitEvents;
{procedure InitMouse;}
procedure DoneEvents;
procedure ShowMouse;
procedure HideMouse;
procedure GetMouseEvent(var Event: TEvent);
procedure GetKeyEvent(var Event: TEvent);
procedure SetMouseSpeed(XS, YS: Byte);
{function GetShiftState: Byte;}
procedure GetCrtMode; { used to fixup screen before application starts }

{ ******** SCREEN MANAGER ******** }

type

  vga_pal = array [1..3,0..15] of Byte  ;

const

 { VGA palette }

  VGA_palette : vga_pal = (
  { red   } (0,0,0,0,42,42,42,42,21,21,21,21,63,63,63,63),
  { green } (0,0,42,42,0,0,21,42,21,21,63,63,21,21,63,63),
  { blue  } (0,42,0,42,0,42,0,42,21,63,21,63,21,63,21,63)
                          ) ;
  { default values }

  VGA_Default : vga_pal = (
  { red   } (0,0,0,0,42,42,42,42,21,21,21,21,63,63,63,63),
  { green } (0,0,42,42,0,0,21,42,21,21,63,63,21,21,63,63),
  { blue  } (0,42,0,42,0,42,0,42,21,63,21,63,21,63,21,63)
                          ) ;
  { palette slot }
  SL     : Array[0..15] of Byte =(0,1,2,3,4,5,20,7,56,57,58,59,60,61,62,63);

{ Screen modes }

  smBW80    = $0002;
  smCO80    = $0003;
  smMono    = $0007;
  smFont8x8 = $0100;
  smSVGALo: Word = $100; { - $109}
  smSVGAHi: Word = $10A;

const

{ Initialized variables }

  StartupMode: Word = $FFFF;
  SkyEnabled: Integer = 0;
  TottalExit: Boolean = False; { Set it only when leaving your program }

var

{ Uninitialized variables }

  ScreenMode: Word;
  ScreenWidth: Word;
  ScreenHeight: Word;
  HiResScreen: Boolean;
  CheckSnow: Boolean;
  ScreenBuffer: Pointer;
  CursorLines: Word;
  OldCursorShape: Word;
  OldCursorPos: Word;

{ Screen manager routines }

procedure InitVideo;
procedure DoneVideo;
procedure SetVideoMode(Mode: Word);
procedure ClearScreen;

Procedure InitVGApalette ;     { To be called at startup time !!!! }
Procedure ResetVGApalette( Update : Boolean );  { reset palette to default          }
Procedure GetPalette(var Buf); { fill buff with palette 64 bytes   }
Procedure SetPalette(var Buf); { set palette using buf 64 bytes    }
Function  VGASystem: Boolean;
Procedure Set_palette( slot:Word; sred,sgreen,sblue : Byte);
Procedure Get_palette( Var   slot,gred,ggreen,gblue : Byte);
{ ******** SYSTEM ERROR HANDLER ******** }

type

{ System error handler function type }

  TSysErrorFunc = function(ErrorCode: Integer; Drive: Byte): Integer;

{ Default system error handler routine }

function SystemError(ErrorCode: Integer; Drive: Byte): Integer;

const

{ Initialized variables }

  SysErrorFunc: TSysErrorFunc = SystemError;
  SysColorAttr: Word = $4E4F;
  SysColorButtonAttr: Word = $0E0F;
  SysMonoAttr: Word = $7070;
  CtrlBreakHit: Boolean = False;
  SaveCtrlBreak: Boolean = False;
  SysErrActive: Boolean = False;

{ System error handler routines }

procedure InitSysError;
procedure DoneSysError;

{ ******** UTILITY ROUTINES ******** }

{ Keyboard support routines }

function GetAltChar(KeyCode: Word): Char;
function GetAltCode(Ch: Char): Word;
function GetCtrlChar(KeyCode: Word): Char;
function GetCtrlCode(Ch: Char): Word;
function CtrlToArrow(KeyCode: Word): Word;

{ String routines }

procedure FormatStr(var Result: String; const Format: String; var Params);
procedure PrintStr(const S: String);

{ Buffer move routines }

procedure MoveColor(var Buf; Num, Attr: Byte);
procedure MoveBuf(var Dest; var Source; Attr: Byte; Count: Word);
procedure MoveChar(var Dest; C: Char; Attr: Byte; Count: Word);
procedure MoveCStr(var Dest; const Str: String; Attrs: Word);
procedure MoveStr(var Dest; const Str: String; Attr: Byte);
function CStrLen(const S: String): Integer;

implementation

{$IF DEFINED(FPC) AND NOT DEFINED(CPUI8086)}
uses
  Windows,
  Dos,
  Advance,
  Commands,
  Views,
  Startup,
  DnApp,
  FlPanelX;
{$ELSE}
uses
  Dos,
  Advance,
  Commands,
  Views,
  Startup,
  DnApp,
  FlPanelX;
{$ENDIF}

{$IFNDEF CPUI8086}
const
  Seg0040 = $0040;
  PrefixSeg: Word = 0;
  HeapOrg: Pointer = nil;
  HeapEnd: Pointer = nil;
  HeapPtr: Pointer = nil;
  StackLimit: Word = 0;
  ConsoleInputHandle: THandle = 0;
  ConsoleOutputHandle: THandle = 0;

function MemAvail: LongInt; begin MemAvail := $7FFFFFFF; end;
function MaxAvail: LongInt; begin MaxAvail := $7FFFFFFF; end;
{$ENDIF}



const
      MCurMP    : CharDef=($00,$40,$60,$30,$18,$3C,$3E,$3E,$3E,$1F,$07,$06,$00,$00,$00,$00);
      MCurSP    : CharDef=($BF,$1F,$0F,$87,$C3,$80,$80,$80,$80,$C0,$E0,$F0,$F0,$FF,$FF,$FF);
      MCurLP    : CharDef=($00,$00,$38,$04,$36,$4E,$0E,$6E,$3E,$1F,$07,$06,$00,$00,$00,$00);
      MCurLSP   : CharDef=($FF,$C7,$83,$C1,$80,$00,$00,$00,$80,$C0,$E0,$F0,$F0,$FF,$FF,$FF);
      MCurM0    : CharDef=($00,$40,$60,$70,$78,$7C,$7E,$78,$4C,$0E,$06,$00,$00,$00,$00,$00);
      MCurS0    : CharDef=($1F,$0F,$07,$03,$01,$00,$00,$00,$01,$00,$F0,$F8,$F8,$FF,$FF,$FF);

      MCurM1    : CharDef=($00,$18,$3C,$3C,$19,$7E,$BC,$3D,$7E,$98,$08,$04,$04,$08,$00,$00);
      MCurS1    : CharDef=($FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF);
      MCurM2    : CharDef=($00,$18,$3C,$3C,$98,$7E,$3D,$BC,$7E,$19,$10,$20,$20,$10,$00,$00);
      MCurS2    : CharDef=($FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF);

      StdMouseBlock  : Array [0..5] of Byte = ($D6,$D7,$D0,$D2,$B7,$B8);

      LastMouseMouse : Boolean = False;
      EGAVGA         : Boolean = False;
      MouseVisible   : Boolean = True;

{ ******** EVENT MANAGER ******** }

const

{ Event manager constants }

  EventQSize = 16;

var

{ Event manager variables }


  OldAttr: Byte;
  OldSymbols: Array [0..5] of Byte;
  SaveFont: Array [0..5] of CharDef;
  LastButtons: Byte;
  DownButtons: Byte;
  LastDouble: Boolean;
  LastWhere: TPoint;
  DownWhere: TPoint;
  DownTicks: Word;
  AutoTicks: Word;
  AutoDelay: Word;
  EventCount: Word;
  EventQHead: Word;
  EventQTail: Word;
  EventQueue: array[0..EventQSize - 1] of TEvent;
  EventQLast: record end;
  VESA_Found: ShortInt;

{$IF DEFINED(FPC) AND NOT DEFINED(CPUI8086)}
{ Ticks: Word absolute $40:$6C; dropped here - win32 rejects
  `absolute segment:offset` at the parser level, not just in
  codegen. The 3 asm sites that referenced Ticks as ES:Ticks are
  ported separately. }
{$ELSE}
var
  Ticks: Word absolute $40:$6C;
{$ENDIF}

{ Detect mouse driver }
{$IF DEFINED(FPC) AND NOT DEFINED(CPUI8086)}
procedure DetectMouse;
begin
  { No mouse driver detection on win32 - a console mouse is
    enabled, not probed for. Real support is deferred (see
    TOOLCHAIN.md session 10); this correctly runs DN keyboard-only
    in the meantime, matching a real supported DOS configuration. }
  ButtonCount := 0;
end;
{$ELSE}
procedure DetectMouse; near; assembler;
asm
        MOV     AX,3533H
        INT     21H
        MOV     AX,ES
        OR      AX,BX
        JE      @@1
        MOV     AX,21H
        INT     33H
        SUB     AX,21H
        JE      @@2
@@3:    PUSH    BX
        MOV     AX,4
        XOR     CX,CX
        XOR     DX,DX
        INT     33H
        POP     AX
        jmp     @@1
@@2:    XOR     AX,AX
        INT     33H
        OR      AX, AX
        JNE     @@3
@@1:    MOV     ButtonCount,AL
end;
{$ENDIF}

{procedure InitMouse;
begin
 DetectMouse;
end;}

{ Store event in GetMouseEvent and GetKeyEvent }

procedure StoreEvent; near; assembler;
asm
{$IFDEF CPUI8086}

        MOV     DI,SP
        LES     DI,SS:[DI+8]
        CLD
        STOSW
        XCHG    AX,BX
        STOSW
        XCHG    AX,CX
        STOSW
        XCHG    AX,DX
        STOSW

{$ELSE}
  xor eax, eax;
{$ENDIF}
end;

{ Get mouse state }
{ Out   BL = Button mask }
{       CX = X coordinate }
{       DX = Y coordinate }
{       DI = Timer ticks }

{$IF DEFINED(FPC) AND NOT DEFINED(CPUI8086)}
procedure GetMouseState;
begin
  { Unreachable on win32: GetMouseEvent below never calls this -
    mouse input is deferred, see DetectMouse. Kept only so the
    unit compiles; real mouse support replaces this. }
end;
{$ELSE}
procedure GetMouseState; near; assembler;
asm
        CLI
        CMP     EventCount,0
        JNE     @@1
        MOV     BL,MouseButtons
        MOV     CX,MouseWhere.Word[0]
        MOV     DX,MouseWhere.Word[2]
        MOV     ES,Seg0040
        MOV     DI,ES:Ticks
        JMP     @@3
@@1:    MOV     SI,EventQHead
        CLD
        LODSW
        XCHG    AX,DI
        LODSW
        XCHG    AX,BX
        LODSW
        XCHG    AX,CX
        LODSW
        XCHG    AX,DX
        CMP     SI,OFFSET EventQLast
        JNE     @@2
        MOV     SI,OFFSET EventQueue
@@2:    MOV     EventQHead,SI
        DEC     EventCount
@@3:    STI
        CMP     MouseReverse,0
        JE      @@4
        MOV     BH,BL
        AND     BH,3
        JE      @@4
        CMP     BH,3
        JE      @@4
        XOR     BL,3
@@4:
end;
{$ENDIF}

procedure ShowMouse; assembler;
asm
        CMP     ButtonCount,0
        JE      @@1
        cmp     StdMouse, 0
        je      @@@1
        push    AX
        mov     ax, 1
        int     33h
        pop     AX
        jmp     @@1
      @@@1:
        CMP     MouseVisible, 0
        JNE     @@1
        PUSH    AX
        PUSH    BX
        PUSH    DX
        PUSH    CX
        PUSH    DI
        PUSH    SI
        PUSH    ES
        PUSH    BP
        MOV     MouseVisible, 1
        CALL    ShowMouseProc
        POP     BP
        POP     ES
        POP     SI
        POP     DI
        POP     CX
        POP     DX
        POP     BX
        POP     AX
@@1:
end;

procedure HideMouse; assembler;
asm
        CMP     ButtonCount,0
        JE      @@1
        cmp     StdMouse, 0
        je      @@@1
        push    AX
        mov     ax, 2
        int     33h
        pop     AX
        jmp     @@1
      @@@1:
        {CMP     MouseVisible, 0
        JE      @@1}
        PUSH    AX
        PUSH    BX
        PUSH    DX
        PUSH    CX
        PUSH    DI
        PUSH    SI
        PUSH    ES
        PUSH    BP
        CALL    HideMouseProc
        MOV     MouseVisible, 0
        MOV     OldMouseX, $FFFF
        MOV     OldMouseY, $FFFF
        POP     BP
        POP     ES
        POP     SI
        POP     DI
        POP     CX
        POP     DX
        POP     BX
        POP     AX
@@1:
end;

{$IF DEFINED(FPC) AND NOT DEFINED(CPUI8086)}
procedure GetMouseEvent(var Event: TEvent);
begin
  { Mouse input deferred (MouseEvents is always False here - see
    DetectMouse's win32 scaffold above). Real Win32 Console API
    mouse support (ENABLE_MOUSE_INPUT + MOUSE_EVENT_RECORD) is the
    natural next piece after keyboard's own real port - see
    TOOLCHAIN.md session 10. }
  Event.What := evNothing;
end;
{$ELSE}
procedure GetMouseEvent(var Event: TEvent); assembler;
asm
        CMP     MouseEvents,0
        JE      @@2
        CALL    GetMouseState
        MOV     BH,LastDouble
        MOV     AL,LastButtons
        CMP     AL,BL
        JE      @@1
        OR      AL,AL
        JE      @@3
        OR      BL,BL
        JE      @@5
        MOV     BL,AL
@@1:    CMP     CX,LastWhere.X
        JNE     @@6
        CMP     DX,LastWhere.Y
        JNE     @@6
        CMP     RepeatDelay, 0
        JE      @@6
        OR      BL,BL
        JE      @@2
        MOV     AX,DI
        SUB     AX,AutoTicks
        CMP     AX,AutoDelay
        JAE     @@7
@@2:    XOR     AX,AX
        MOV     BX,AX
        MOV     CX,AX
        MOV     DX,AX
        JMP     @@9
@@3:    MOV     BH,0
        CMP     BL,DownButtons
        JNE     @@4
        CMP     CX,DownWhere.X
        JNE     @@4
        CMP     DX,DownWhere.Y
        JNE     @@4
        MOV     AX,DI
        SUB     AX,DownTicks
        CMP     AX,DoubleDelay
        JAE     @@4
        MOV     BH,1
@@4:    MOV     DownButtons,BL
        MOV     DownWhere.X,CX
        MOV     DownWhere.Y,DX
        MOV     DownTicks,DI
        MOV     AutoTicks,DI
        MOV     AX,RepeatDelay
        MOV     AutoDelay,AX
        MOV     AX,evMouseDown
        JMP     @@8
@@5:    MOV     AX,evMouseUp
        JMP     @@8
@@6:    MOV     AX,evMouseMove
        JMP     @@8
@@7:    MOV     AutoTicks,DI
        MOV     AutoDelay,1
        MOV     AX,evMouseAuto
@@8:    MOV     LastButtons,BL
        MOV     LastDouble,BH
        MOV     LastWhere.X,CX
        MOV     LastWhere.Y,DX
@@9:    CALL    StoreEvent
end;
{$ENDIF}

procedure _GetKeyEvent(var Event: TEvent);
{$IFDEF CPUI8086}
assembler;
asm
        MOV     AH,11h
        INT     16H
        MOV     AX,0
        MOV     BX,AX
        JE      @@1
        MOV     AH,10h
        INT     16H


        cmp     ah,$E0
        jne     @NotExt

        cmp     al,$0D
        jne     @NotEnter
        mov     bx,kbEnter
        jmp     @PUT

@NotEnter:


@NotExt:

        XCHG    AX,BX
@PUT:   MOV     AX,evKeyDown
@@1:    XOR     CX,CX
        MOV     DX,CX
        CALL    StoreEvent
end;
{$ELSE}
var
  Rec: TInputRecord;
  NumWaiting, NumRead: LongWord;
  Ok: LongBool;
  H: THandle;
  VK, Scan: Word;
  Ch: Char;
  CtrlState: LongWord;
  IsAlt, IsCtrl, IsShift: Boolean;
begin
  Event.What := evNothing;
  Event.KeyCode := 0;
  if (ConsoleInputHandle = 0) or (ConsoleInputHandle = INVALID_HANDLE_VALUE) then
  begin
    H := GetStdHandle(STD_INPUT_HANDLE);
    if not GetConsoleMode(H, NumWaiting) then
      H := CreateFileA('CONIN$', GENERIC_READ or GENERIC_WRITE,
        FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
    ConsoleInputHandle := H;
  end;
  H := ConsoleInputHandle;
  if (H = 0) or (H = INVALID_HANDLE_VALUE) then Exit;
  while True do
  begin
    Ok := GetNumberOfConsoleInputEvents(H, NumWaiting);
    if (not Ok) or (NumWaiting = 0) then Exit;
    Ok := ReadConsoleInputA(H, Rec, 1, NumRead);
    if (not Ok) or (NumRead = 0) then Exit;
    if (Rec.EventType <> KEY_EVENT) or (not Rec.Event.KeyEvent.bKeyDown) then Continue;

    VK := Rec.Event.KeyEvent.wVirtualKeyCode;
    Scan := Rec.Event.KeyEvent.wVirtualScanCode;
    Ch := Rec.Event.KeyEvent.AsciiChar;
    CtrlState := Rec.Event.KeyEvent.dwControlKeyState;

    { Skip modifier keys alone }
    if (VK = $10) or (VK = $11) or (VK = $12) or
       (VK = $14) or (VK = $90) or (VK = $91) then Continue;

    IsAlt := (CtrlState and ($0001 or $0002)) <> 0;
    IsCtrl := (CtrlState and ($0004 or $0008)) <> 0;
    IsShift := (CtrlState and $0010) <> 0;

    if IsAlt then
    begin
      if (VK >= $70) and (VK <= $79) then
        Event.KeyCode := ($68 + (VK - $70)) shl 8
      else if VK = $7A then Event.KeyCode := $8B00
      else if VK = $7B then Event.KeyCode := $8C00
      else if (VK >= Ord('1')) and (VK <= Ord('9')) then
        Event.KeyCode := ($78 + (VK - Ord('1'))) shl 8
      else if (VK = Ord('0')) or (VK = $30) then Event.KeyCode := $8100
      else if VK = $BD then Event.KeyCode := $8200
      else if VK = $BB then Event.KeyCode := $8300
      else if VK = $08 then Event.KeyCode := $0E00
      else if VK = $0D then Event.KeyCode := $1C00
      else if VK = $09 then Event.KeyCode := $A500
      else if VK = $20 then Event.KeyCode := $C200
      else if VK = $1B then Event.KeyCode := $011B
      else
        Event.KeyCode := Scan shl 8;
    end
    else if IsCtrl then
    begin
      if (VK >= $70) and (VK <= $79) then
        Event.KeyCode := ($5E + (VK - $70)) shl 8
      else if VK = $7A then Event.KeyCode := $8900
      else if VK = $7B then Event.KeyCode := $8A00
      else if VK = $09 then Event.KeyCode := $9400
      else if VK = $0D then Event.KeyCode := $1C0A
      else if VK = $08 then Event.KeyCode := $0E7F
      else if VK = $25 then Event.KeyCode := $7300
      else if VK = $27 then Event.KeyCode := $7400
      else if VK = $26 then Event.KeyCode := $8D00
      else if VK = $28 then Event.KeyCode := $9100
      else if VK = $24 then Event.KeyCode := $7700
      else if VK = $23 then Event.KeyCode := $7500
      else if VK = $21 then Event.KeyCode := $8400
      else if VK = $22 then Event.KeyCode := $7600
      else if VK = $2D then Event.KeyCode := $9200
      else if VK = $2E then Event.KeyCode := $9300
      else if (VK >= Ord('A')) and (VK <= Ord('Z')) then
        Event.KeyCode := (Scan shl 8) or (VK - Ord('A') + 1)
      else if Ch <> #0 then
        Event.KeyCode := (Scan shl 8) or Byte(Ch)
      else
        Event.KeyCode := Scan shl 8;
    end
    else if IsShift then
    begin
      if (VK >= $70) and (VK <= $79) then
        Event.KeyCode := ($54 + (VK - $70)) shl 8
      else if VK = $7A then Event.KeyCode := $8700
      else if VK = $7B then Event.KeyCode := $8800
      else if VK = $09 then Event.KeyCode := $0F00
      else if VK = $2D then Event.KeyCode := $C300
      else if VK = $2E then Event.KeyCode := $C400
      else if Ch <> #0 then
        Event.KeyCode := (Scan shl 8) or Byte(Ch)
      else
        Event.KeyCode := Scan shl 8;
    end
    else
    begin
      if (VK >= $70) and (VK <= $79) then
        Event.KeyCode := ($3B + (VK - $70)) shl 8
      else if VK = $7A then Event.KeyCode := $8500
      else if VK = $7B then Event.KeyCode := $8600
      else if VK = $26 then Event.KeyCode := $4800
      else if VK = $28 then Event.KeyCode := $5000
      else if VK = $25 then Event.KeyCode := $4B00
      else if VK = $27 then Event.KeyCode := $4D00
      else if VK = $24 then Event.KeyCode := $4700
      else if VK = $23 then Event.KeyCode := $4F00
      else if VK = $21 then Event.KeyCode := $4900
      else if VK = $22 then Event.KeyCode := $5100
      else if VK = $2D then Event.KeyCode := $5200
      else if VK = $2E then Event.KeyCode := $5300
      else if VK = $1B then Event.KeyCode := $011B
      else if VK = $0D then Event.KeyCode := $1C0D
      else if VK = $09 then Event.KeyCode := $0F09
      else if VK = $08 then Event.KeyCode := $0E08
      else if Ch <> #0 then
        Event.KeyCode := (Scan shl 8) or Byte(Ch)
      else
        Event.KeyCode := Scan shl 8;
    end;

    Event.What := evKeyDown;
    Exit;
  end;
end;
{$ENDIF}


procedure GetKeyEvent;
begin
  FlushScreenBuffer;
  _GetKeyEvent(Event);
  if Event.What = evNothing then Exit;
  {$IF DEFINED(FPC) AND NOT DEFINED(CPUI8086)}
  if (Event.KeyCode = kbCtrlTab) and (QueryShiftState and 3 <> 0) then Event.KeyCode := kbAltTab;
  {$ELSE}
  if (Event.KeyCode = kbCtrlTab) and (0 and 3 <> 0) then Event.KeyCode := kbAltTab;
  {$ENDIF}
  if (Event.CharCode = #$e0) and
     (Event.ScanCode in [$52,$92,$A2,
                         $47,$77,$97,
                         $49,$84,$99,
                         $93,$53,$A3,
                         $4F,$75,$9F,
                         $51,$76,$A1,
                         $48,$8D,$98,
                         $4B,$73,$9B,
                         $50,$91,$A0,
                         $4D,$9D,$74])
  then
                           Event.CharCode := #0
  else
  if Event.What = evKeyDown then
    if (Event.CharCode >= '0') and (Event.CharCode <= '9') and
     (ShiftState and 3 <> 0) then Event.CharCode := #0;
end;


{function GetShiftState: Byte; assembler;
asm
        MOV     ES,Seg0040
        MOV     AL,ES:ShiftState
end;}

{ ******** SCREEN MANAGER ******** }

{$IF DEFINED(FPC) AND NOT DEFINED(CPUI8086)}
{ Equipment: Word absolute $40:$10; CrtInfo: Byte absolute $40:$87;
  dropped here (win32 rejects `absolute segment:offset` at the
  parser level) - both used only inside SetCrtMode, scaffolded
  below. CrtRows: Byte absolute $40:$84; is unused anywhere in
  this file and simply dropped. }
{$ELSE}
var
  Equipment: Word absolute $40:$10;
  CrtRows: Byte absolute $40:$84;
  CrtInfo: Byte absolute $40:$87;
{$ENDIF}

{ Save registers and call video interrupt }

procedure VideoInt; near; assembler;
asm
        PUSH    BP
        PUSH    ES
        INT     10H
        POP     ES
        POP     BP
end;

{ Return CRT mode in AX and dimensions in DX }

procedure GetCrtMode; assembler;
asm
        MOV     AH,0FH
        CALL    VideoInt
        PUSH    AX
        MOV     AX,1130H
        MOV     BH,0
        MOV     DL,0
        CALL    VideoInt
        POP     AX
        MOV     DH,AH
        CMP     AH, 2
        JE      @@1
        CMP     AH, 3
        JE      @@1
        XOR     AH, AH
        JMP     @@2
@@1:
        CMP     DL,25
        SBB     AH,AH
        INC     AH
@@2:
end;

procedure VGA30; assembler;
asm
        cli
        mov       dx,3C4h
         mov   al,0
         out   dx,al
         mov   al,1
         inc   dx
         out   dx,al
         dec   dx

         mov   dx,3D4h
         mov   al,23
         out   dx,al
         inc   dx
         in    al,dx
         and   al,127
         out   dx,al
         dec   dx

         mov   al,17
         out   dx,al
        inc       dx
        in        al,dx
        and       al,127
        out       dx,al

        mov       dx,3CCh
        in        al,dx
        or        al,192
        mov       dx,3C2h
        out       dx,al

        mov       dx,3D4h

         mov   al,6
         out   dx,al
         mov   al,11
         inc   dx
         out   dx,al
         dec   dx
         mov   al,7
         out   dx,al
         mov   al,62
         inc   dx
         out   dx,al
         dec   dx
         mov   al,9
         out   dx,al
         mov   al,79
         inc   dx
         out   dx,al
         dec   dx
         mov   al,16
         out   dx,al
         mov   al,234
         inc   dx
         out   dx,al
         dec   dx
         mov   al,17
         out   dx,al
         mov   al,140
         inc   dx
         out   dx,al
         dec   dx
         mov   al,18
         out   dx,al
         mov   al,223
         inc   dx
         out   dx,al
         dec   dx
         mov   al,21
         out   dx,al
         mov   al,231
         inc   dx
         out   dx,al
         dec   dx
         mov   al,22
         out   dx,al
         mov   al,4
         inc   dx
         out   dx,al
         dec   dx

          mov     al,17
          out     dx,al

        inc       dx
        in        al,dx
        or        al,128
        out       dx,al
        dec       dx

          mov     al,23
          out     dx,al
        inc       dx
        in        al,dx
        or        al,128
        out       dx,al
        mov       dx,3C4h
         mov   al,0
         out   dx,al
         mov   al,3
         inc   dx
         out   dx,al
         dec   dx

        sti
        mov ax,40h
        mov es,ax
        mov byte ptr es:[84h],29
end;
{ Set CRT mode to value in AX }

{$IF DEFINED(FPC) AND NOT DEFINED(CPUI8086)}
procedure SetCrtMode;
begin
  { Screen Manager / video-mode BIOS+VGA-register programming -
    out of scope for this pass (Input). Real Win32 port is the
    Console Screen Buffer API, not INT10h - see TOOLCHAIN.md
    session 10. Callers (InitVideo/ClearScreen) have their own
    unrelated BIOS-byte issues still to resolve regardless. }
end;
{$ELSE}
procedure SetCrtMode; near; assembler;
asm
        MOV     ES,Seg0040
        MOV     BL,20H
        CMP     AL,smMono
        JNE     @@1
        MOV     BL,30H
@@1:    AND     ES:Equipment.Byte,0CFH
        OR      ES:Equipment.Byte,BL
        AND     ES:CrtInfo,0FEH
        PUSH    AX
        OR      AL, AL
        JNZ     @@@1
        MOV     AL, smCO80
@@@1:
        MOV     AH,0
        CALL    VideoInt
        POP     AX
        OR      AH,AH
        JE      @@2
        OR      AL, AL
        JNZ     @@@2
        CALL    VGA30
        JMP     @@2
@@@2:
        MOV     AX,1112H
        MOV     BL,0
        CALL    VideoInt
        MOV     AX,1130H
        MOV     BH,0
        MOV     DL,0
        CALL    VideoInt
        CMP     DL,42
        JNE     @@2
        OR      ES:CrtInfo,1
        MOV     AH,1
        MOV     CX,600H
        CALL    VideoInt
        MOV     AH,12H
        MOV     BL,20H
        CALL    VideoInt
@@2:
end;
{$ENDIF}

{ Fix CRT mode in AX if required }

procedure FixXGAmode; near;
  var R: Array [0..255] of Byte;
      P: Pointer;
begin
  P := @R;
  asm
{$IFDEF CPUI8086}

     mov  ax, $4E04
     xor  bx, bx
     push bp
     int  10h
     pop  bp
     mov  ax, $4E01
     les  di, P
     mov  cx, bx
     xor  dx, dx
     push bp
     int  10h
     pop  bp
  
{$ELSE}
  xor eax, eax;
{$ENDIF}
end;
  if  R[$0C] <> 0 then
    asm
      mov  AX, smCO80
      call SetCRTmode;
    end;
end;


procedure FixSVGAMode; near;
  var R: Array [0..255] of Byte;
      P: Pointer;
begin
  P := @R;
  asm
{$IFDEF CPUI8086}

     mov  ax, $4F03
     push bp
     int  10h
     pop  bp
     mov  ax, $4F01
     mov  cx, bx
     les  di, P
     push bp
     int  10h
     pop  bp
  
{$ELSE}
  xor eax, eax;
{$ENDIF}
end;
  if R[0] and $10 <> 0 then
    asm
      mov  AX, smCO80
      call SetCRTmode
    end;
end;

procedure FixCrtMode; near; assembler;
asm
        CMP     AL,smMono
        JE      @@1
        CMP     AL,smCO80
        JE      @@1
        CMP     AL,smBW80
        JE      @@1
        CMP     AL,byte ptr smSVGAHi
        JE      @@1
        CMP     AL,byte ptr smSVGALo
        JE      @@1
        MOV     AX,smCO80
@@1:
end;

{ Set CRT data areas and mouse range }

procedure SetCrtData; near;
{$IFDEF CPUI8086}
assembler;
asm
        CALL    GetCrtMode
        MOV     CL,1
        OR      DL,DL
        JNE     @@1
        MOV     CL,0
        MOV     DL,24
@@1:    INC     DL
        MOV     ScreenMode,AX
        MOV     byte ptr ScreenWidth,DH
        MOV     byte ptr ScreenWidth + 1, 0
        MOV     byte ptr ScreenHeight,DL
        MOV     byte ptr ScreenHeight + 1, 0
        MOV     HiResScreen,CL
        XOR     CL,1
        MOV     BX,$B800
        CMP     AL,smMono
        JNE     @@2
        MOV     CL,0
        MOV     BX,$B000
@@2:    MOV     CheckSnow,CL
        XOR     AX,AX
        MOV     ScreenBuffer.Word[0],AX
        MOV     ScreenBuffer.Word[2],BX

        {$ifndef DPMI}
        { Check for DESQ View or compatible }

        MOV     AX, $1022
        XOR     BX, BX
        INT     15H
        OR      BX, BX
        JZ      @@@1
        MOV     AH, 1
        MOV     DESQDetected, AH
        MOV     BX, ScreenBuffer.Word[2]
        MOV     ES, BX
        XOR     DI, DI
        MOV     AH, $FE
        INT     10H
        MOV     ScreenBuffer.Word[0],DI
        MOV     BX, ES
        MOV     ScreenBuffer.Word[2],BX
        {$endif}
@@@1:

        { end check }

        MOV     AH,3
        MOV     BH,0
        CALL    VideoInt
        {MOV     CX, $0607;}
        MOV     CursorLines,CX
        MOV     AH,1
        MOV     CX,2000H
        CALL    VideoInt
        CMP     ButtonCount,0
        JE      @@4
        MOV     AX,7
        MOV     DL,byte ptr ScreenWidth
        CALL    @@3
        MOV     AX,8
        MOV     DL,byte ptr ScreenHeight
@@3:    XOR     DH,DH
        MOV     CL,3
        SHL     DX,CL
        DEC     DX
        XOR     CX,CX
        INT     33H
@@4:
end;
{$ELSE}
begin
  ScreenMode := smCO80;
  ScreenWidth := 80;
  ScreenHeight := 25;
  HiResScreen := True;
  CheckSnow := False;
  CursorLines := $0607;
  if ScreenBuffer = nil then
  begin
    GetMem(ScreenBuffer, ScreenWidth * ScreenHeight * 2);
    FillWord(ScreenBuffer^, ScreenWidth * ScreenHeight, $0720);
  end;
end;
{$ENDIF}

{ Detect video modes

procedure DetectVideo; assembler;
asm
        CALL    GetCrtMode
        CALL    FixCrtMode
        MOV     ScreenMode,AX
end;
}

procedure CheckVESA;
  var  R: record
            Id: Array [1..4] of char;
            B: Array [1..300] of byte;
          end;
       P: Pointer;
begin
  if VESA_Found <> -1 then Exit;
  P := @R; R.ID := 'QQQQ';
  asm
{$IFDEF CPUI8086}

    mov ax, $4E00
    les di, P
    int 10h
  
{$ELSE}
  xor eax, eax;
{$ENDIF}
end;
  if R.Id = 'VESA' then VESA_Found := 1
   else begin
         asm
{$IFDEF CPUI8086}

           mov ax, $4F00
           les di, P
           int 10h
         
{$ELSE}
  xor eax, eax;
{$ENDIF}
end;
         if R.Id = 'VESA' then VESA_Found := 2 else VESA_Found := 0;
        end;
end;



procedure InitVideo;
begin
{$IFDEF CPUI8086}
    asm
      CMP       ScreenSaved, 0
      JNZ       @@2
      MOV       AH, 3
      XOR       BX,BX
      INT       10H
      MOV       OldCursorShape, CX
      MOV       OldCursorPos, DX
@@2:
      CALL      GetCrtMode
      MOV       StartupMode,AX
      CALL      FixCrtMode
      CMP       StartupMode,AX
      JE        @@1
      { Check XGA mode }
      call  CheckVESA
      cmp   VESA_Found, 1
      JNZ   @@@2
      push  bp
      call  FixXGAmode
      pop   bp
      JMP @@1
@@@2: { check SVGA mode }
      push  bp
      call  FixSVGAmode
      pop   bp
      jmp   @@1
{      CMP      AX,ScreenMode
      JE        @@1
      MOV       AX,ScreenMode}
      MOV       StartupMode,AX
      CALL      SetCrtMode
@@1:  CALL      SetCrtData
    end;
   if WordRec(CursorLines).Hi > $10 then CursorLines := $607;
{$ELSE}
  if Windows.GetConsoleWindow = 0 then
    Windows.AllocConsole;
  Windows.SetConsoleOutputCP(866);
  Windows.SetConsoleCP(866);
  SetCrtData;
{$ENDIF}
   if not ScreenSaved then
    begin
     if UserScreen <> nil then FreeMem(UserScreen, UserScreenSize);
     UserScreenSize := {memw[$40:$4C];} ScreenWidth * ScreenHeight * 2;
     UserScreenWidth := ScreenWidth;
     GetMem(UserScreen, UserScreenSize);
     Move(ScreenBuffer^, UserScreen^, UserScreenSize);
     ScreenSaved := True;
    end;
   if (ScreenWidth = 80) and (ScreenHeight = 30) and (ScreenMode = 3) then
      ScreenMode := 256;
   SetBlink(CurrentBlink);
   if VGASystem and (StartupData.Load and osuResetPalette <> 0) then SetPalette(VGA_Palette);
end;

procedure DoneVideo;
{$IFDEF CPUI8086}
var
  I, J, H: Integer;
  Shift: Integer;
{$IFDEF CPUI8086}
procedure FillEStr( X, Y: Integer ); assembler;
  asm
{$IFDEF CPUI8086}

    mov  cx,ScreenWidth
    sub  cx,X
    les  di,ScreenBuffer
    mov  ax,ScreenWidth
    shl  ax,1
    mul  Y
    add  ax,X
    add  ax,X
    add  di,ax
    mov  ax,0720h
    cld
    rep  stosw
  
{$ELSE}
  xor eax, eax;
{$ENDIF}
end;
{$ELSE}
  procedure FillEStr( X, Y: Integer );
  var
    I, Offset, Count: Integer;
    Buf: PWordArray;
  begin
    Buf := PWordArray(ScreenBuffer);
    if Buf = nil then Exit;
    Count := ScreenWidth - X;
    Offset := Y * ScreenWidth + X;
    for I := 0 to Count - 1 do
      Buf^[Offset + I] := $0720;
  end;
{$ENDIF}
begin
  if (ScreenSaved) and (UserScreen <> nil) then begin
    J := UserScreenWidth; if J > ScreenWidth then J := ScreenWidth;
    if WordRec(OldCursorPos).Hi > ScreenHeight - 1 then WordRec(OldCursorPos).Hi := ScreenHeight - 1;
    if WordRec(OldCursorPos).Lo > ScreenWidth - 1 then WordRec(OldCursorPos).Lo := ScreenWidth - 1;
{    Shift := Byte(( SkyEnabled = 0 ) and ( InterfaceData.Options and ouiHideStatus = 0 ));}
    Shift := 0; {////////////////////}
    H := UserScreenSize div (UserScreenWidth * 2) - 1 - Shift;
    For I := 0 to H do begin
      Move(PWordArray(UserScreen)^[(I+Shift)*UserScreenWidth], PWordArray(ScreenBuffer)^[I*ScreenWidth], J*2);
      If J < ScreenWidth then FillEStr( J, I );
    end;
    For I := H + 1 to ScreenHeight - 1 do FillEStr( 0, I );
    If Shift > 0 then begin
      FillEStr( 0, H + 1 );
      Dec( WordRec( OldCursorPos ).Hi );
    end;
    if OldCursorShape <> $FFFF then begin
      if WordRec(OldCursorShape).Hi > $10 then OldCursorShape := $607;
      WordRec(PWordArray(ScreenBuffer)^[Lo(OldCursorPos)+Hi(OldCursorPos)*ScreenWidth]).Hi := 7;
    end;
  end else
    If ClsAct then ClearScreen;
  asm
    MOV  AH,1
    MOV  CX,CursorLines
    CALL VideoInt
  end;
  asm
    MOV     CX, OldCursorShape
    MOV     AH, 1
    XOR     BX, BX
    INT     10H
    MOV     DX, OldCursorPos
    MOV     AH, 2
    XOR     BX, BX
    INT     10H
(*    TEST    StartupData.Unload,osuBlinking {///////////}
    JNZ     @@1*)
  end;
end;

{$ELSE}
begin
  if ScreenBuffer <> nil then
  begin
    FreeMem(ScreenBuffer, ScreenWidth * ScreenHeight * 2);
    ScreenBuffer := nil;
  end;
end;
{$ENDIF}

const ModeChanged: Boolean = False;

procedure SetXGAMode; near;
  var R: Array[0..255] of Byte;
      M: Word;
      P: Pointer;
begin
  asm mov  M, ax end;
  P := @R;
  asm
{$IFDEF CPUI8086}

    mov  cx, M
    mov  ax, $4E02
    les  di, P
    xor  dx, dx
    push bp
    int  10h
    pop  bp
  
{$ELSE}
  xor eax, eax;
{$ENDIF}
end;
  if R[$0C] <> 0 then Exit;
  ModeChanged := True;
  asm
    mov ax, $4E03
    xor dx, dx
    mov bx, M
    xor cx, cx
    push bp
    int  10h
    pop  bp
  end;
end;

procedure SetSVGAMode; near;
  var R: Array[0..255] of Byte;
      M: Word;
      P: Pointer;
begin
  asm mov  M, ax end;
  P := @R;
  asm
{$IFDEF CPUI8086}

    mov  cx, M
    mov  ax, $4F01
    les  di, P
    push bp
    int  10h
    pop  bp
  
{$ELSE}
  xor eax, eax;
{$ENDIF}
end;
  if R[0] and $11 <> 1 then Exit;
  ModeChanged := True;
  asm
    mov ax, $4F02
    mov bx, M
    push bp
    int  10h
    pop  bp
  end;
end;



procedure SetVideoMode(Mode: Word);
begin
{$IFDEF CPUI8086}
asm
        MOV     AX,Mode
        CMP     AX,$100
        JZ      @@3
        CMP     AX,$103
        JZ      @@3
        CMP     AX,$102
        JZ      @@3
        TEST    AX,$FF00
        JZ      @@3
        call    CheckVESA
        CMP     VESA_Found, 1
        JNZ     @@1
        CALL    SetXGAMode
        JMP     @@2
@@1:    CMP     VESA_Found, 2
        JNZ     @@3
        CALL    SetSVGAMode
        JMP     @@2
@@3:
        CALL    FixCrtMode
        CALL    SetCrtMode
@@2:
        CALL    SetCrtData
        MOV     AX,Mode
        CMP     AX,$100
        JZ      @@5
        CMP     AX,$103
        JZ      @@5
        CMP     AX,$102
        JZ      @@5
        TEST    AX,$FF00
        JZ      @@4
        CMP     ModeChanged, 0
        JZ      @@4
@@5:
        MOV     ScreenMode, AX

@@4:    XOR     AL, AL
        MOV     ModeChanged, AL
end;
   SetBlink(CurrentBlink);
   if VGASystem and (StartupData.Load and osuResetPalette <> 0) then SetPalette(VGA_Palette);
      {
        if isVideo( osvEnableVgaPal ) then
        if not isSame( VGA_Default, VGA_Palette, SizeOf(VGA_Palette)) then
           SetPalette(VGA_palette);
      }

{$ELSE}
  SetCrtData;
{$ENDIF}
end;

procedure ClearScreen;
{$IFDEF CPUI8086}
assembler;
asm
        MOV     AX,600H
        MOV     BH,07H
        XOR     CX,CX
        MOV     DL,byte ptr ScreenWidth
        DEC     DL
        MOV     DH,byte ptr ScreenHeight
        DEC     DH
        CALL    VideoInt
        MOV     AH,2
        MOV     BH,0
        XOR     DX,DX
        CALL    VideoInt
end;
{$ELSE}
begin
  if ScreenBuffer <> nil then
    FillWord(ScreenBuffer^, ScreenWidth * ScreenHeight, $0720);
end;
{$ENDIF}


     Function VGASystem: Boolean;
{$IFDEF CPUI8086}
assembler ;
      asm
        mov ax,1C00h
        mov cx,7
        int 10h
        cmp al,1Ch {VGA}
        je  @@1
        mov Ax , 1200h;
        mov Bl , 32h;
        int 10h
        cmp al,12h {MCGA}
        je  @@1
        sub ax,ax
        jmp @@2
@@1:    mov ax,1
@@2:
     end;
{$ELSE}
begin
  VGASystem := True;
end;
{$ENDIF}

   Procedure InitVGApalette ;
{$IFDEF CPUI8086}
     Var
       regs : Registers;
       idx  : Byte;
     begin
       if VGASystem then
       begin
         With regs do
         begin
           AL:=0;
           AH:=11;
         end;
         For idx:=0 to 15 do
         begin
           regs.BH:=sl[idx];
           regs.BL:=idx;
           Intr($10,Regs);
         end;
       end;
     end;
{$ELSE}
begin
end;
{$ENDIF}

     Procedure Set_palette(slot:Word; sred,sgreen,sblue : Byte);
     Var
       regs : Registers;
     begin
       With regs do
       begin
         AL:=$10;
         AH:=$10;
         BX:=slot;
         DH:=sred;
         CH:=sgreen;
         CL:=sblue;
       end;
       Intr($10,Regs);
     end;

     Procedure Get_palette(Var slot,gred,ggreen,gblue : Byte);
     Var
       regs : Registers;
     begin
       With regs do
       begin
         AL:=21;
         AH:=16;
         BX:=slot;
       end;
       Intr($10,Regs);
       With regs do
       begin
         gred:=DH;
         ggreen:=CH;
         gblue:=CL;
       end;
     end;

 Procedure GetPalette;
 var PAL : VGA_pal absolute Buf ;
     I,y : byte ;
  begin
  PAL := VGA_default ;
  if not VGAsystem then Exit ;
   for I:=0 to 15 do
     Get_palette( sl[I], pal[1,i], pal[2,i], pal[3,i]);
  end;

 Procedure SetPalette;
 var PAL : VGA_pal absolute Buf ;
     I{,y} : byte ;
  begin
  if not VGAsystem then Exit ;
   for i:=0 to 15 do
     Set_palette( sl[i], pal[1,i], pal[2,i], pal[3,i]);
  end;

 Procedure ResetVGApalette ;
  begin
    if Update then VGA_palette := VGA_default ;
    SetPalette( VGA_default );
  end;

{ ******** SYSTEM ERROR HANDLER ******** }

{$IFDEF CPUI8086}
{$IFDEF DPMI}
{$L SYSINT.OBP}
{$ELSE}
{$L SYSINT.OBJ}
{$ENDIF}
{$ENDIF}

const

{ System error messages }

 (*
  SCriticalError:    string[31] = 'Critical disk error on drive %c';
  SWriteProtected:   string[35] = 'Disk is write-protected in drive %c';
  SDiskNotReady:     string[29] = 'Disk is not ready in drive %c';
  SDataIntegrity:    string[32] = 'Data integrity error on drive %c';
  SSeekError:        string[22] = 'Seek error on drive %c';
  SUnknownMedia:     string[30] = 'Unknown media type in drive %c';
  SSectorNotFound:   string[28] = 'Sector not found on drive %c';
  SOutOfPaper:       string[20] = 'Printer out of paper';
  SWriteFault:       string[23] = 'Write fault on drive %c';
  SReadFault:        string[22] = 'Read fault on drive %c';
  SGeneralFailure:   string[28] = 'Hardware failure on drive %c';
  SBadImageOfFAT:    string[32] = 'Bad memory image of FAT detected';
  SDeviceError:      string[19] = 'Device access error';
  SInsertDisk:       string[27] = 'Insert diskette in drive %c';
  SSharingViolation: string[17] = 'Sharing violation';
  ButAbort:          string[11] = '[ ~A~bort ]';
  ButRetry:          string[11] = '[ ~R~etry ]';
  ButIgnore:         string[12] = '[ ~I~gnore ]';
*)

  NumButtons: array[0..16] of Byte =
  (2,2,2,2,3,2,3,2,3,2,3,3,2,2,2,2,2);
  ButtonX: array[2..3] of array [1..3] of Byte =
  ((8,23,0),(3,15,27));
  XErrTable: Array [1..3] of Byte = (3,1,0);

  (*
  ButtonOffset: array[1..3] of Word =
  (Ofs(ButAbort), Ofs(ButRetry), Ofs(ButIgnore));
  *)


{ Critical error message translation table }

  (*
  ErrorString: array[0..16] of Word = (
    Ofs(SWriteProtected),
    Ofs(SCriticalError),
    Ofs(SDiskNotReady),
    Ofs(SCriticalError),
    Ofs(SDataIntegrity),
    Ofs(SCriticalError),
    Ofs(SSeekError),
    Ofs(SUnknownMedia),
    Ofs(SSectorNotFound),
    Ofs(SOutOfPaper),
    Ofs(SWriteFault),
    Ofs(SReadFault),
    Ofs(SGeneralFailure),
    Ofs(SBadImageOfFAT),
    Ofs(SDeviceError),
    Ofs(SInsertDisk),
    Ofs(SSharingViolation)
    );
   *)

  CE_LastMsg = 16;
  CE_Idx: array[0..CE_LastMsg] of TStrIdx = (
    dlCE_WriteProtected,
    dlCE_CriticalError,
    dlCE_DiskNotReady,
    dlCE_CriticalError,
    dlCE_DataIntegrity,
    dlCE_CriticalError,
    dlCE_SeekError,
    dlCE_UnknownMedia,
    dlCE_SectorNotFound,
    dlCE_OutOfPaper,
    dlCE_WriteFault,
    dlCE_ReadFault,
    dlCE_GeneralFailure,
    dlCE_BadImageOfFAT,
    dlCE_DeviceError,
    dlCE_InsertDisk,
    dlCE_SharingViolation);


var
  CE_Buttons:  array[1..3] of PString;
  CE_Messages: array[0..CE_LastMsg] of PString;
  CE_K: array[1..3] of Byte;
  ErrWndTitle: PString;

{ System error handler routines }

{$IFDEF CPUI8086}
procedure InitSysError; external;
procedure DoneSysError; external;
{$ELSE}
procedure InitSysError; begin end;
procedure DoneSysError; begin end;
{$ENDIF}

{$V-}
procedure SwapStatusLine(var Buffer; ShadowAttr: Byte); near; assembler;
asm
{$IFDEF CPUI8086}
     cld
        mov     cl,ScreenWidth.Byte
        xor     ch,ch
        mov     al,ScreenHeight.Byte
        sub     al,6
        shr     al,1
        mul     cl
        shl     ax,1
        les     di,ScreenBuffer
        add     di,ax
        mov     al,ScreenWidth.Byte
        mov     dl,al
        mov     dh,0
        shl     dx,1
        sub     al,40
        shr     al,1
        cbw
        shl     ax,1
        add     di,ax
        push    ds
        lds     si,Buffer
        mov     bl,6
@@0:    mov     cx,40
        push    di
@@1:    mov     ax,es:[di]
        movsw
        mov     ds:[si-2],ax
        loop    @@1
        cmp     bl,6
        jne     @@2
        add     si,4
        add     di,4
        jmp     @@3
@@2:    mov     ax,es:[di]
        mov     ds:[si],ax
        mov     ah,ShadowAttr
        stosw
        add     si,2
        mov     ax,es:[di]
        mov     ds:[si],ax
        mov     ah,ShadowAttr
        stosw
        add     si,2
@@3:    pop     di
        add     di,dx
        dec     bl
        jne     @@0
        add     di,4
        mov     cx,40
@@4:    mov     ax,es:[di]
        mov     ds:[si],ax
        mov     ah,ShadowAttr
        stosw
        add     si,2
        loop    @@4
        pop     ds

{$ELSE}
  xor eax, eax;
{$ENDIF}
end;

function SystemError(ErrorCode: Integer; Drive: Byte): Integer;
var
  C,AC,WW,K : Word;
  P : Pointer;
  S : string[63];
  B,SW : PWordArray;
  I : Byte;
  Event: TEvent;
  PExit, ActiveButton: Byte;

function GetCoord(X, Y: Integer): Word;
begin
 GetCoord := ((ScreenHeight-6) div 2+Y)*(ScreenWidth*2)+((ScreenWidth-40) div 2+X)*2;
end;

Procedure DrawButton(No : Byte; State : Boolean);
var X,I : Word;
    P   : PString;
begin
 I:=NumButtons[ErrorCode];
 X:=ButtonX[I,No]; X := GetCoord(X, 4);
 P := CE_Buttons[No];
 MoveCStr(PByteArray(ScreenBuffer)^[X], P^, Byte(State)*AC+Byte(not State)*C);
end;

function MPos(P: Objects.TPoint): Integer;
  var X, I, N: Integer;
begin
 MPos := -1; N := NumButtons[ErrorCode];
 X := P.X - ((ScreenWidth-40) div 2);
 if P.Y = (ScreenHeight-6) div 2+4 then
    for I := 1 to N do
      if (X >= ButtonX[N, I]) and (X< ButtonX[N, I]+CStrLen(CE_Buttons[I]^)) then
        begin MPos := I; Exit end;
end;

procedure ControlMousePos(P: Objects.TPoint);
  var I,J: Integer;
begin
  J := MPos(P);
  if (J < 0) or (J = ActiveButton) then Exit;
  ActiveButton := J;
  HideMouse;
  for i:=1 to NumButtons[ErrorCode] do DrawButton(i,i=ActiveButton);
  ShowMouse;
end;

var LM: Objects.TPoint;

begin

 if NeedAbort then
  begin
   SystemError := 3;
   Abort := On;
   NeedAbort := Off;
   Exit;
  end;

if Abort then
 begin
   SystemError := 3;
   Exit ;
 end;

 asm    MOV     AH,3
        MOV     BH,0
        CALL    VideoInt
        PUSH    CX
        MOV     AH,1
        MOV     CX,2000H
        CALL    VideoInt

        MOV     AH, 59h
        xor     bx, bx
        INT     21h
        mov     WW, AX
 end;
 if (WW = 32) or (WW = 33) then ErrorCode := 16;
  if Lo(ScreenMode) = smMono then
    begin C := SysMonoAttr; AC := $0F07 end else
    begin C := SysColorAttr; AC := SysColorButtonAttr end;
  GetMem(B, 42*7*2); GetMem(SW, 42*7*2);
  MoveChar(B^, ' ', Byte(C), 42*6);
  MoveChar(B^, 'Í', Byte(C), 40);
  MoveChar(B^, 'É', Byte(C), 1);
  MoveChar(B^[39], '»', Byte(C), 1);
  MoveChar(B^[42*5], 'Í', Byte(C), 40);
  MoveChar(B^[42*5], 'È', Byte(C), 1);
  MoveChar(B^[42*5+39], '¼', Byte(C), 1);
  for i:=1 to 4 do
      begin
       MoveChar(B^[42*i], 'º', Byte(C), 1);
       MoveChar(B^[42*i+39], 'º', Byte(C), 1);
      end;
  MoveStr(B^[(40-Length(ErrWndTitle^))div 2], ' '+ErrWndTitle^+' ', Byte(C));
  if (ErrorCode < 0) or (ErrorCode > CE_LastMsg) then ErrorCode := 12;
  S := CE_Messages[ErrorCode]^;
  I := Pos('%', S);
  if I > 0 then begin S[I] := Char(Drive+65); S[I+1] := ':' end;
  MoveStr(B^[42*2+1+(38-Length(S)) div 2], S, Byte(C));
  for I := 0 to 6 do
   Move(PByteArray(ScreenBuffer)^[GetCoord(0,I)], SW^[I*42], 84);
  HideMouse;
  SwapStatusLine(B^, ShadowAttr);
  for i:=1 to NumButtons[ErrorCode] do DrawButton(i,i=2);
  ActiveButton := 2;
  ShowMouse;
  repeat
   PExit := 0;
   GetMouseEvent(Event);
   case Event.What of
     evMouseMove: ControlMousePos(Event.Where);
     evMouseDown: LM := Event.Where;
     evMouseUp: if (MPos(LM) = ActiveButton) and (MPos(Event.Where) = ActiveButton)
                  then begin PExit := ActiveButton; Break; end;
       else GetKeyEvent(Event);
   end;
   if Event.What = evKeyDown then
    begin
     if Event.CharCode = #$e0 then Event.CharCode := #0;
     K := Event.KeyCode;
     case K of
      kbLeft : if ActiveButton > 1 then Dec(ActiveButton) else ActiveButton :=  NumButtons[ErrorCode];
      kbRight : if ActiveButton < NumButtons[ErrorCode] then Inc(ActiveButton) else ActiveButton := 1;
      kbSpace,
      kbEnter : PExit := ActiveButton;
      kbESC   : PExit := 1;
       else
       begin
         K := K shr 8;
         if K = CE_K[1] then PExit := 1 else
         if K = CE_K[2] then PExit := 2 else
         if K = CE_K[3] then if NumButtons[ErrorCode] > 2 then PExit := 3;
       end;
     end;
     HideMouse;
     for i:=1 to NumButtons[ErrorCode] do DrawButton(i,i=ActiveButton);
     ShowMouse;
    end;
  until (PExit  > 0);
  HideMouse;
  for I := 0 to 6 do
   Move(SW^[I*42], PByteArray(ScreenBuffer)^[GetCoord(0,I)], 84);
  ShowMouse;
  FreeMem(B, 42*7*2);
  FreeMem(SW, 42*7*2);
  asm   POP     CX
        PUSH    DX
        MOV     AH,1
        CALL    VideoInt
        POP     AX
 end;
 I := XErrTable[PExit];
 Abort := I = 3;
 SystemError := I;
end;

{$V+}

{ ******** UTILITY ROUTINES ******** }

{ Keyboard support routines }

const
  AltCodes2: array[$78..$83] of Char =
    '1234567890-=';

function GetAltChar(KeyCode: Word): Char;
begin
  GetAltChar := #0;
  if Lo(KeyCode) = 0 then
    case Hi(KeyCode) of
      $C2: GetAltChar := {#240} AltSpaceChar;
      $10..$34: GetAltChar := AltCodes1[Hi(KeyCode)];
      $78..$83: GetAltChar := AltCodes2[Hi(KeyCode)];
    end;
end;

function GetAltCode(Ch: Char): Word;
var
  I: Word;
begin
  GetAltCode := 0;
  if Ch = #0 then Exit;
  Ch := UpCase(Ch);
  if Ch = #240 then
  begin
    GetAltCode := $0200;
    Exit;
  end;
  for I := $10 to $34 do
    if AltCodes1[I] = Ch then
    begin
      GetAltCode := I shl 8;
      Exit;
    end;
  for I := $78 to $83 do
    if AltCodes2[I] = Ch then
    begin
      GetAltCode := I shl 8;
      Exit;
    end;
end;

function GetCtrlChar(KeyCode: Word): Char;
begin
  GetCtrlChar := #0;
  if (Lo(KeyCode) <> 0) and (Lo(KeyCode) <= Byte('Z') - Byte('A') + 1) then
    GetCtrlChar := Char(Lo(KeyCode) + Byte('A') - 1);
end;

function GetCtrlCode(Ch: Char): Word;
begin
  GetCtrlCode := GetAltCode(Ch) or (Byte(UpCase(Ch)) - Byte('A') + 1);
end;

function CtrlToArrow(KeyCode: Word): Word;
const
  NumCodes = 11;
  CtrlCodes: array[0..NumCodes-1] of Char = ^S^D^E^X^A^F^G^V^R^C^H;
  ArrowCodes: array[0..NumCodes-1] of Word =
    (kbLeft, kbRight, kbUp, kbDown, kbHome, kbEnd, kbDel, kbIns,
     kbPgUp, kbPgDn, kbBack);
var
  I: Integer;
begin
  CtrlToArrow := KeyCode; Exit;
  for I := 0 to NumCodes - 1 do
    if WordRec(KeyCode).Lo = Byte(CtrlCodes[I]) then
    begin
      CtrlToArrow := ArrowCodes[I];
      Exit;
    end;
end;

{ String formatting routines }

{$IFDEF CPUI8086}
{$L FORMAT.OBJ}
procedure Format_Str(var Result: String; const Format: String; var Params); far; external;
{$ELSE}
procedure Format_Str(var Result: String; const Format: String; var Params);
type
  PParamArray = ^TParamArray;
  TParamArray = array[0..63] of LongWord;
var
  ParamPtr: PParamArray;
  ParamIdx: Integer;
  FPos, FLen: Integer;
  Ch, PadChar: Char;
  LeftJust: Boolean;
  Width: Integer;
  StrVal: String;
  NumVal: LongInt;
  PStr: PString;

  function IntToHex(Val: LongWord): String;
  const
    HexChars: array[0..15] of Char = '0123456789ABCDEF';
  var
    H: String;
  begin
    if Val = 0 then
    begin
      IntToHex := '0';
      Exit;
    end;
    H := '';
    while Val > 0 do
    begin
      H := HexChars[Val and $F] + H;
      Val := Val shr 4;
    end;
    IntToHex := H;
  end;

begin
  Result := '';
  ParamPtr := @Params;
  ParamIdx := 0;
  FPos := 1;
  FLen := Length(Format);
  while FPos <= FLen do
  begin
    Ch := Format[FPos];
    Inc(FPos);
    if Ch <> '%' then
    begin
      Result := Result + Ch;
    end
    else
    begin
      if FPos > FLen then Break;
      Ch := Format[FPos];
      Inc(FPos);
      if Ch = '%' then
      begin
        Result := Result + '%';
      end
      else
      begin
        PadChar := ' ';
        LeftJust := False;
        Width := 0;
        if Ch = '0' then
        begin
          PadChar := '0';
          if FPos <= FLen then
          begin
            Ch := Format[FPos];
            Inc(FPos);
          end;
        end;
        if Ch = '-' then
        begin
          LeftJust := True;
          if FPos <= FLen then
          begin
            Ch := Format[FPos];
            Inc(FPos);
          end;
        end;
        while (Ch >= '0') and (Ch <= '9') do
        begin
          Width := Width * 10 + (Ord(Ch) - Ord('0'));
          if FPos <= FLen then
          begin
            Ch := Format[FPos];
            Inc(FPos);
          end
          else
            Break;
        end;
        if Ch = '#' then
        begin
          ParamIdx := Width;
          Width := 0;
          if FPos <= FLen then
          begin
            Ch := Format[FPos];
            Inc(FPos);
          end;
        end;
        StrVal := '';
        case UpCase(Ch) of
          'C':
            begin
              if ParamPtr <> nil then
              begin
                StrVal := Char(ParamPtr^[ParamIdx] and $FF);
                Inc(ParamIdx);
              end;
            end;
          'S':
            begin
              if ParamPtr <> nil then
              begin
                PStr := PString(Pointer(ParamPtr^[ParamIdx]));
                Inc(ParamIdx);
                if PStr <> nil then
                  StrVal := PStr^;
              end;
            end;
          'D':
            begin
              if ParamPtr <> nil then
              begin
                NumVal := LongInt(ParamPtr^[ParamIdx]);
                Inc(ParamIdx);
                Str(NumVal, StrVal);
              end;
            end;
          'X':
            begin
              if ParamPtr <> nil then
              begin
                StrVal := IntToHex(ParamPtr^[ParamIdx]);
                Inc(ParamIdx);
              end;
            end;
        end;
        if Length(StrVal) < Width then
        begin
          if LeftJust then
          begin
            while Length(StrVal) < Width do
              StrVal := StrVal + ' ';
          end
          else
          begin
            if (PadChar = '0') and (Length(StrVal) > 0) and (StrVal[1] = '-') then
            begin
              Delete(StrVal, 1, 1);
              while Length(StrVal) < Width - 1 do
                StrVal := '0' + StrVal;
              StrVal := '-' + StrVal;
            end
            else
            begin
              while Length(StrVal) < Width do
                StrVal := PadChar + StrVal;
            end;
          end;
        end;
        Result := Result + StrVal;
      end;
    end;
  end;
end;
{$ENDIF}

procedure FormatStr;
begin
  if @Params = nil then Result := Format else Format_Str(Result, Format, Params);
end;

procedure PrintStr(const S: String);
{$IFDEF CPUI8086}
assembler;
asm
{$IFDEF CPUI8086}

        PUSH    DS
        LDS     SI,S
        CLD
        LODSB
        XOR     AH,AH
        XCHG    AX,CX
        MOV     AH,40H
        MOV     BX,1
        MOV     DX,SI
        INT     21H
        POP     DS

{$ELSE}
  xor eax, eax;
{$ENDIF}
end;
{$ELSE}
begin
  Write(S);
end;
{$ENDIF}

{ Buffer move routines }

{$IFDEF CPUI8086}
procedure MoveBuf(var Dest; var Source; Attr: Byte; Count: Word); assembler;
asm
{$IFDEF CPUI8086}

        MOV     CX,Count
        JCXZ    @@5
        MOV     DX,DS
        LES     DI,Dest
        LDS     SI,Source
        MOV     AH,Attr
        CLD
{       OR      AH,AH
        JE      @@3
}
@@1:    LODSB
        STOSW
        LOOP    @@1
{
        JMP     @@4
@@2:    INC     DI
@@3:    MOVSB
        LOOP    @@2
}
@@4:    MOV     DS,DX
@@5:

{$ELSE}
  xor eax, eax;
{$ENDIF}
end;

procedure MoveChar(var Dest; C: Char; Attr: Byte; Count: Word); assembler;
asm
{$IFDEF CPUI8086}

        MOV     CX,Count
        JCXZ    @@4
        LES     DI,Dest
        MOV     AL,C
        MOV     AH,Attr
        CLD
        OR      AL,AL
        JE      @@1
        {
        OR      AH,AH
        JE      @@3
        }
        REP     STOSW
        JMP     @@4
@@1:    MOV     AL,AH
@@2:    INC     DI
@@3:    STOSB
        LOOP    @@2
@@4:


{$ELSE}
  xor eax, eax;
{$ENDIF}
end;

procedure MoveCStr(var Dest; const Str: String; Attrs: Word); assembler;
asm
{$IFDEF CPUI8086}

        MOV     DL,'~'
        PUSH    DS
        LDS     SI,Str
        CLD
        LODSB
        MOV     CL,AL
        XOR     CH,CH
        JCXZ    @@3
        LES     DI,Dest
        MOV     BX,Attrs
        MOV     AH,BL
@@1:    LODSB
        CMP     AL,DL
        JE      @@2
        CMP     AL,0
        JNE     @ST
        MOV     DL,0
        JMP     @@LP
@ST:    STOSW
        LOOP    @@1
        JMP     @@3
@@2:    XCHG    AH,BH
@@LP:   LOOP    @@1
@@3:    POP     DS

{$ELSE}
  xor eax, eax;
{$ENDIF}
end;

procedure MoveStr(var Dest; const Str: String; Attr: Byte); assembler;
asm
{$IFDEF CPUI8086}

        MOV     DX,DS
        LDS     SI,Str
        CLD
        LODSB
        MOV     CL,AL
        XOR     CH,CH
        JCXZ    @@4
        LES     DI,Dest
        MOV     AH,Attr

        {OR      AH,AH
        JE      @@3}

@@1:    LODSB
        STOSW
        LOOP    @@1
{
        JMP     @@4

@@2:    INC     DI
@@3:    MOVSB
        LOOP    @@2
}
@@4:    MOV     DS,DX

{$ELSE}
  xor eax, eax;
{$ENDIF}
end;

function CStrLen(const S: String): Integer; assembler;
asm
{$IFDEF CPUI8086}

        MOV     DL,'~'
        LES     DI,S
        MOV     CL,ES:[DI]
        INC     DI
        XOR     CH,CH
        MOV     BX,CX
        JCXZ    @@2
@@LOD:  MOV     AL, ES:[DI]
        INC     DI
        CMP     AL,DL
        JE      @@DEC
        CMP     AL,0
        JNE     @@AA
        MOV     DL,0
@@DEC:  DEC     BX
@@AA:   LOOP    @@LOD
@@2:    MOV     AX,BX

{$ELSE}
  xor eax, eax;
{$ENDIF}
end;
{$ELSE}
procedure MoveBuf(var Dest; var Source; Attr: Byte; Count: Word);
var
  I: Integer;
  D: PWordArray;
  S: PByteArray;
  A: Word;
begin
  if Count = 0 then Exit;
  D := @Dest;
  S := @Source;
  A := Word(Attr) shl 8;
  for I := 0 to Count - 1 do
    D^[I] := A or S^[I];
end;

procedure MoveChar(var Dest; C: Char; Attr: Byte; Count: Word);
var
  I: Integer;
  D: PWordArray;
  W: Word;
begin
  if Count = 0 then Exit;
  D := @Dest;
  if C <> #0 then
  begin
    W := (Word(Attr) shl 8) or Ord(C);
    for I := 0 to Count - 1 do
      D^[I] := W;
  end
  else
  begin
    W := Word(Attr) shl 8;
    for I := 0 to Count - 1 do
      D^[I] := (D^[I] and 255) or W;
  end;
end;

procedure MoveCStr(var Dest; const Str: String; Attrs: Word);
var
  I, Len, DIdx: Integer;
  D: PWordArray;
  NormAttr, HighAttr, CurAttr: Word;
  C, Tilde: Char;
begin
  Len := Length(Str);
  if Len = 0 then Exit;
  D := @Dest;
  NormAttr := Byte(Lo(Attrs));
  HighAttr := Byte(Hi(Attrs));
  CurAttr := NormAttr;
  Tilde := '~';
  DIdx := 0;
  for I := 1 to Len do
  begin
    C := Str[I];
    if C = Tilde then
    begin
      if CurAttr = NormAttr then
        CurAttr := HighAttr
      else
        CurAttr := NormAttr;
    end
    else if C = #0 then
    begin
      Tilde := #0;
    end
    else
    begin
      D^[DIdx] := (CurAttr shl 8) or Ord(C);
      Inc(DIdx);
    end;
  end;
end;

procedure MoveStr(var Dest; const Str: String; Attr: Byte);
var
  I, Len: Integer;
  D: PWordArray;
  A: Word;
begin
  Len := Length(Str);
  if Len = 0 then Exit;
  D := @Dest;
  A := Word(Attr) shl 8;
  for I := 1 to Len do
    D^[I - 1] := A or Ord(Str[I]);
end;

function CStrLen(const S: String): Integer;
var
  I, Len, Count: Integer;
  C, Tilde: Char;
begin
  Len := Length(S);
  Count := Len;
  Tilde := '~';
  for I := 1 to Len do
  begin
    C := S[I];
    if C = Tilde then
      Dec(Count)
    else if C = #0 then
    begin
      Tilde := #0;
      Dec(Count);
    end;
  end;
  CStrLen := Count;
end;
{$ENDIF}

{ Drivers unit initialization and shutdown }

const
  AltFlag : Boolean = False;
var
  SaveExit: Pointer;
  Old09   : Pointer;
  {$IFDEF CPUI8086}
  Vect09: Pointer absolute $0000:$0024;
{$ELSE}
  Vect09: Pointer;
{$ENDIF}
  ErrAdd  : Longint ;

Procedure FatalError ;

var
  C,AC,PP,FH : Word;
  P : Pointer;
  B : array[0..42] of Word;

  {!!!!!}
  PPP: TByteArray absolute FreeStr;

  I : Byte;
  Event: TEvent;
  PExit, ActiveButton: Byte;

function GetCoord(X, Y: Integer): Word;
begin
 GetCoord := ((ScreenHeight-8) div 2+Y)*(ScreenWidth*2)+((ScreenWidth-40) div 2+X)*2;
end;


procedure NewLine;
var CO : word ;
  begin


  MoveChar(B, ' ', Byte(C), 42 );

   if  I in [0,8] then
      MoveChar(B, 'Í', Byte(C), 42)
       else
         begin
           MoveChar(B,     'º', Byte(C), 1);
           MoveChar(B[41], 'º', Byte(C), 1);
         end;

   if  I = 0 then
        begin
         MoveChar(B, 'É', Byte(C), 1);
         MoveChar(B[41], '»', Byte(C), 1);
        end;

         CO := C;

   if  I = 8 then
        begin
         MoveChar(B,     'È', Byte(C), 1);
         MoveChar(B[41], '¼', Byte(C), 1);
        end;

   if I = 7 then CO := AC;

    if FreeStr<>'' then
         MoveStr(B[ ( 42 - Length(FreeStr)) div 2], FreeStr , Byte(CO));
    Move(B,PByteArray(ScreenBuffer)^[GetCoord(0,I)], 84);

    if I > 0 then
     begin
       PByteArray(ScreenBuffer)^[GetCoord(42,I)+1] := 8;
       PByteArray(ScreenBuffer)^[GetCoord(43,I)+1] := 8;
     end;

  end;


  Function StoreBuffer(var Buf; Size:word ; FH : word ):word;assembler;
    asm
{$IFDEF CPUI8086}

       mov  bx,FH
       push ds
        mov cx,Size
          mov  ah,40h
          sub  al,al
          lds  dx,Buf
          int  21h
          mov  ax,0
          jnc  @@1
          inc  ax
         @@1:
       pop  ds
    
{$ELSE}
  xor eax, eax;
{$ENDIF}
end;


begin
 asm    MOV     AH,3
        MOV     BH,0
        CALL    VideoInt
        PUSH    CX
        MOV     AH,1
        MOV     CX,2000H
        CALL    VideoInt
 end;

    { Create Report File }

    I := length(SourceDir);
    SourceDir := SourceDir + 'DN.ERR'#0;

    FH := $FFFF ;
 asm
    push ds
    push bp

    mov ax,6C00h { extended dos 4+ open  }
    mov si,offset SourceDir
    inc si
    mov cx,0
    mov dx,11h   { if exist open, if not create and open }
    mov bx,7042h { 42 file mode ; do not use int 24 , write
                   w/o buffering }

    int 21h
    jnc @@1
    jmp @@99     { other error - exit }
@@1:
    mov bx,ax
    mov ax,4202H { lseek to end of file }
    sub dx,dx
    sub cx,cx
    int 21h
    jnc @@2
    jmp @@99      { other error - exit }
@@2:
    mov FH,bx    { save handle        }
@@99:
    pop bp
    pop ds
    end;

 if FH<>$FFFF then
   begin
     FreeStr :=
          ^M^J +
       '----<' + GetDateTime(false) +' '+ GetDateTime(true) +'>'^M^J +
       'VER :' + VersionName + ^M^J +
       'DATE:' + VersionDate + ^M^J +
       'ERR :' + Hex2(ExitCode) + ^M^J +
       'ADDR:' + Hex8(ErrAdd) + ^M^J ;
     StoreBuffer( FreeStr[1] , length(FreeStr), FH );

     FreeStr :=
       'PSP :' + Hex4( PrefixSeg ) + ^M^J +
       'CS  :' + Hex4(CSeg) + ^M^J +
       'DS  :' + Hex4(DSeg) + ^M^J +
       'SS  :' + Hex4(SSeg) + ^M^J +
       'SP  :' + Hex4(Word(LongInt(SPtr))) + ^M^J +
       'MEMm:' + Hex8(MaxAvail) + ^M^J +
       'MEMa:' + Hex8(MemAvail) + ^M^J +
       'hOrg:' + Hex8(Longint(HeapOrg)) + ^M^J +
       'hEnd:' + Hex8(Longint(HeapEnd)) + ^M^J +
       'hPtr:' + Hex8(Longint(HeapPtr)) + ^M^J +
       'hLim:' + Hex4( StackLimit ) + ^M^J +
       'SCR :' + Hex8(Longint(ScreenBuffer)) + ^M^J ;
     StoreBuffer( FreeStr[1] , length(FreeStr), FH );

     for C:=0 to Pred(ScreenHeight) do
      begin
          PP := (ScreenWidth*C) shl 1;
          for AC := 0 to Pred(ScreenWidth) do
          PPP[AC] :=  PByteArray(ScreenBuffer)^[PP+AC*2];
          PPP[ScreenWidth] := $0d ;
          PPP[ScreenWidth+1] := $0a ;
          if StoreBuffer( PPP , ScreenWidth+2 , FH ) <> 0 then Break;
      end; { for lines }
     asm
       mov  ah,3Eh     { close file }
       mov  bx,FH
       int  21h
     end
   end; { file write ok }

  SourceDir[0] := Char(I);


  { Display Error Box }
  if Lo(ScreenMode) = smMono then
    begin C := SysMonoAttr; AC := $0F07 end else
    begin C := SysColorAttr; AC := SysColorButtonAttr end;

   I := 0 ;
     for I:=0 to 8
      do
       begin
        case I of
             0 : FreeStr := ' Fatal Error ';
             2 : FreeStr := 'Exception 0' + Hex2(ExitCode)
                     + 'h at address '+Hex4( ErrAdd shr 16 ) +
                       ':' + Hex4( ErrAdd );

             4 : FreeStr := 'Please report to RIT.';
             5 : FreeStr := '( file DN.ERR )';
             7 : FreeStr := '[ Press a key to exit now ]';
            else FreeStr := '';
        end; { case }
      NewLine;
    end; { begin }
  for I := 0 to 41 do
    PByteArray(ScreenBuffer)^[GetCoord(I+2,9)+1] := 8; { shadow }


 {
 for I := 1 to 3 do
 for C := 1 to 3 do
  begin
    sound(1000);
    if I=2 then Delay(400)
           else Delay(200);
    Nosound;
    Delay(100);
  end;
 }
  {repeat}
   PExit := 0;
   asm
     sub ax,ax
     int 16h
   end;
   {
   GetKeyEvent(Event);
   if Event.What = evKeyDown then Break ;
    asm
       Int 28h
    end;
  until false;
  }
end;


procedure ExitDrivers; far;
begin
  DoneSysError;
  DoneEvents;
     ExitProc := SaveExit;
      (*{$ifndef release}
      if False then
      {$endif}*)
      if ErrorAddr <> Nil then
          begin
           ErrAdd := Longint(ErrorAddr);
           ErrorAddr := Nil;
           FatalError;
           DoneVideo;
          end;
end;

procedure MoveColor(var Buf; Num, Attr: Byte);
{$IFDEF CPUI8086}
assembler;
asm
{$IFDEF CPUI8086}

   les    bx,Buf
   xor    ch,ch
   mov    cl,Num
   or     cl,cl
   jz     @End
   mov    al,Attr
@Rep:
   mov    es:[bx+1],al
   add    bx,2
   loop   @Rep
@End:

{$ELSE}
  xor eax, eax;
{$ENDIF}
end;
{$ELSE}
var
  I: Integer;
  D: PWordArray;
  A: Word;
begin
  if Num = 0 then Exit;
  D := @Buf;
  A := Word(Attr) shl 8;
  for I := 0 to Num - 1 do
    D^[I] := (D^[I] and 255) or A;
end;
{$ENDIF}

procedure MakeCoords; near; assembler;
asm
{$IFDEF CPUI8086}

    les  bx, ScreenBuffer
    mov  ax, si
    mov  cl, 3
    shr  ax, cl
    add  ax, ax
    add  bx, ax
    mov  ax, di
    mov  cl, 3
    shr  ax, cl
    xor  ch, ch
    mov  cl, byte ptr ScreenWidth
    add  cx, cx
    mul  cx
    add  bx, ax

{$ELSE}
  xor eax, eax;
{$ENDIF}
end;

{$IFDEF CPUI8086}
procedure HideGraphCursor; far; assembler;
asm
    cmp OldMouseX, 0
    js  @@1
    cmp MouseVisible, 0
    jz  @@1
    mov  si, OldMouseX
    mov  di, OldMouseY
    call MakeCoords
    lea  di, OldSymbols
    mov  si, cx
    mov  ax, word ptr ds:[di]
    cmp  byte ptr es:[bx], $D6
    jne  @@@1
    mov  es:[bx], al
@@@1:
    cmp  byte ptr es:[bx+2], $D7
    jne  @@@2
    mov  es:[bx+2], ah
@@@2:
    mov  ax, word ptr ds:[di+2]
    cmp  byte ptr es:[bx+si], $D0
    jne  @@@3
    mov  es:[bx+si], al
@@@3:
    cmp  byte ptr es:[bx+si+2], $D2
    jne  @@@4
    mov  es:[bx+si+2], ah
@@@4:
    add  si, si
    mov  ax, word ptr ds:[di+4]
    cmp  byte ptr es:[bx+si], $B7
    jne  @@@5
    mov  es:[bx+si], al
@@@5:
    cmp  byte ptr es:[bx+si+2], $B8
    jne  @@1
    mov  es:[bx+si+2], ah
    add  si, si
@@1:
end;

procedure PrepareCharGen; assembler;
asm
 mov dx, $3C4
 mov ax, $0402
 out dx, ax
 mov ax, $0704
 out dx, ax
 mov dx, $3CE
 mov ax, $0005
 out dx, ax
 mov ax, $0406
 out dx, ax
 mov ax, $0204
 out dx, ax
end;

procedure DoneCharGen; assembler;
asm
 mov dx, $3C4
 mov ax, $0302
 out dx, ax
 mov ax, $0304
 out dx, ax
 mov dx, $3CE
 mov ax, $1005
 out dx, ax
 mov ax, $0E06
 out dx, ax
 mov ax, $0004
 out dx, ax
end;

procedure ShowGraphCursor; far;
 var GraphBlock: Array[0..5,0..15] of Byte;
     I: Integer;
begin
 if not MouseVisible then Exit;
 asm
    call HideGraphCursor
    mov  si, MouseX
    mov  di, MouseY
    mov  OldMouseX, si
    mov  OldMouseY, di
    call MakeCoords
    lea  di, OldSymbols
    mov  si, cx
    mov  al, es:[bx]
    mov  ah, es:[bx+2]
    mov  ds:[di], ax
    mov  al, es:[bx+si]
    mov  ah, es:[bx+si+2]
    mov  ds:[di+2], ax
    add  si, si
    mov  al, es:[bx+si]
    mov  ah, es:[bx+si+2]
    mov  ds:[di+4], ax
 end;

 PrepareCharGen;
 for I := 0 to 5 do
  Move(mem[$A000:32*OldSymbols[I]], GraphBlock[I,0], 16);
 DoneCharGen;

 asm
  mov dx, MouseY
  and dx, 7
  cmp CharHeight, 14
  jl @@1
  add dx, dx
  cmp dl, CharHeight
  jl  @@1
  dec dx
@@1:
  lea si, GraphBlock
  add si, dx
  push dx
  mov  dx, MouseX
  and  dx, 7
  mov  cl, dl
  pop  ax
  mov  dl, al
  cmp  MouseMouse, 0
  jz   @STDMouse
  mov  al, LastMouseMouse
  xor  al, 1
  mov  LastMouseMouse, al
  jz   @@@1
  lea  di, MCurM1
  jmp  @@5
@@@1:
  lea  di, MCurM2
  jmp  @@5
@StdMouse:
  xor  bh, bh
  mov  bl, MouseButtons
  test bx, 1
  jz   @@4
  lea  di, MCurLP
  jmp  @@5
@@4:
  test bx, 2
  jz   @@6
  lea  di, MCurM0
  jmp  @@5
@@6:
  lea di, MCurMP
@@5:
  mov  ch, 16
@@2:
  xor al, al
  mov ah, ds:[di+16]
  not ah
  shr ax, cl
  not ax
  and ss:[si], ah
  and ss:[si+16], al
  xor al, al
  mov ah, ds:[di]
  shr ax, cl
  or  ss:[si], ah
  or  ss:[si+16], al
  inc di
  inc si
  inc bx
  inc dl
  cmp dl, CharHeight
  jl  @@3
  mov dx, 32
  sub dl, CharHeight
  add si, dx
  xor dx, dx
@@3:
  dec ch
  jnz @@2

 end;

 PrepareCharGen;
 for I := 0 to 5 do
  Move(GraphBlock[I,0], mem[$A000:32*StdMouseBlock[I]], 16);
 DoneCharGen;

 asm
    mov  si, MouseX
    mov  di, MouseY
    call MakeCoords
    mov  si, cx
    lea  di, StdMouseBlock
    mov  dx, MouseX
    mov  cl, 3
    shr  dx, cl
    inc  dx
    xor  dh, dh
    sub  dl, byte ptr ScreenWidth
    mov  ax, ds:[di]
    mov  es:[bx], al
    or   dx, dx
    jz  @@1
    mov  es:[bx+2], ah
@@1:mov  ax, ds:[di+2]
    mov  es:[bx+si], al
    or   dx, dx
    jz  @@2
    mov  es:[bx+si+2], ah
@@2:add  si, si
    mov  ax, ds:[di+4]
    mov  es:[bx+si], al
    or   dx, dx
    jz  @@3
    mov  es:[bx+si+2], ah
@@3:
 end;
end;

procedure HideTextCursor; far; assembler;
asm
    cmp OldMouseX, 0
    jl  @@1
    mov  si, OldMouseX
    mov  di, OldMouseY
    call MakeCoords
    mov  al, OldAttr
    inc  bx
    mov  es:[bx], al
@@1:
end;

procedure ShowStdCursor; far; assembler;
asm
   mov ax, 1
   int 33h
end;

procedure HideStdCursor; far; assembler;
asm
   mov ax, 2
   int 33h
end;

procedure ShowTextCursor; far; assembler;
asm
   call HideTextCursor
   cli
   mov  si, MouseX
   mov  di, MouseY
   mov  OldMouseX, si
   mov  OldMouseY, di
   call MakeCoords
   inc  bx
   mov  al, es:[bx]
   mov  OldAttr, al
   not  al
   and  al, $7F
   mov  es:[bx], al
   sti
end;


procedure MouseInt; far; assembler;
asm
        MOV     SI,SEG @DATA
        MOV     DS,SI
        MOV     SI,CX
        MOV     CL,3
        MOV     MouseX,SI
        MOV     MouseY,DX
        SHR     SI,CL
        SHR     DX,CL
        MOV     MouseButtons,BL
        MOV     MouseWhere.X,SI
        MOV     MouseWhere.Y,DX
        TEST    AX,11110B
        JE      @@2
        CMP     EventCount,EventQSize
        JE      @@2
        MOV     ES,Seg0040
        MOV     AX,ES:Ticks
        MOV     DI,EventQTail
        PUSH    DS
        POP     ES
        CLD
        STOSW
        XCHG    AX,BX
        STOSW
        XCHG    AX,SI
        STOSW
        XCHG    AX,DX
        STOSW
        CMP     DI,OFFSET EventQLast
        JNE     @@1
        MOV     DI,OFFSET EventQueue
@@1:    MOV     EventQTail,DI
        INC     EventCount
@@2:    MOV     MouseIntFlag,1
end;

procedure MouseHandler; far; assembler;
asm
{$IFDEF CPUI8086}

        PUSHF
        PUSH    AX
        CLI
        MOV     SI,SEG @Data
        MOV     DS,SI

        MOV     MouseButtons, BL
        mov   ax, 0Bh
        int   33h

        add   cx, MouseX
        add   dx, MouseY

        cmp   cx, 0
        jnl   @@@2
        xor   cx, cx
  @@@2:
        cmp   dx, 0
        jnl   @@@3
        xor   dx, dx
  @@@3:
        mov   MouseX, cx
        mov   MouseY, dx
        mov   bx, cx
        mov   cl, 3
        shr   bx, cl
        cmp   bx, ScreenWidth
        jl    @@@4
        mov   bx, ScreenWidth
        dec   bx
        shl   bx, cl
        add   bx, 7
        mov   MouseX, bx
  @@@4:
        shr   dx, cl
        cmp   dx, ScreenHeight
        jl    @@@5
        mov   dx, ScreenHeight
        dec   dx
        shl   dx, cl
        add   dx, 7
        mov   MouseY, dx
  @@@5:
        cmp   MouseVisible, 0
        jz    @@@6
        les   bx, ShowMouseProc
        mov   ax, es
        or    bx, ax
        jz    @@@6
        call  ShowMouseProc
  @@@6:
        MOV     SI, MouseX
        MOV     DX, MouseY
        MOV     CL,3
        SHR     SI,CL
        SHR     DX,CL
        XOR     BH, BH
        MOV     BL, MouseButtons
        MOV     MouseWhere.X,SI
        MOV     MouseWhere.Y,DX
        POP     AX
        TEST    AX,11110B
        JE      @@2
        CMP     EventCount,EventQSize
        JE      @@2
        MOV     ES,Seg0040
        MOV     AX,ES:Ticks
        MOV     DI,EventQTail
        PUSH    DS
        POP     ES
        CLD
        STOSW
        XCHG    AX,BX
        STOSW
        XCHG    AX,SI
        STOSW
        XCHG    AX,DX
        STOSW
        CMP     DI,OFFSET EventQLast
        JNE     @@1
        MOV     DI,OFFSET EventQueue
@@1:    MOV     EventQTail,DI
        INC     EventCount
@@2:    MOV     MouseIntFlag,1
        STI
        POPF

{$ELSE}
  xor eax, eax;
{$ENDIF}
end;

procedure StdMouseHide; far; assembler;
asm
   cmp MouseButtons, 0
   je  @@1
   push bp
   mov  ax, 1
   int  33h
   pop bp
 @@1:
end;

procedure StdMouseShow; far; assembler;
asm
   cmp MouseButtons, 0
   je  @@1
   push bp
   mov  ax, 2
   int  33h
   pop bp
 @@1:
end;

procedure InstallMouseHandler(MouseHandler, ShowProc, HideProc: Pointer);
 var p : Pointer;
     I : Integer;
begin
{$IFDEF FPC}{$IFNDEF CPUI8086}
   { CharHeight already defaults to 16 (DRIVERS.PAS) - the standard
     VGA 80x25 value; no BIOS byte to refresh it from on Win32. }
{$ELSE}
 CharHeight := mem[$40:$85];
{$ENDIF}{$ENDIF}
 (*
 {$ifndef DPMI}
 if EGAVGA then
  begin
   PrepareCharGen;
   for I := 0 to 5 do
    Move(mem[$A000:32*StdMouseBlock[I]], SaveFont[I], 16);
   DoneCharGen;
  end;
 {$endif}
 *)
 MouseX := 0;
 OldMouseX := $FFFF;
 OldMouseY := 0;
 MouseY := 0;
 p := MouseHandler;
 ShowMouseProc := ShowProc;
 HideMouseProc := HideProc;
 asm
{$IFDEF CPUI8086}

  les dx,dword ptr p
  mov bx, dx
{  mov ax, ds
  mov es:[bx+2], ax}
  mov cx,$ff
  mov ax,12
  int 33h
 
{$ELSE}
  xor eax, eax;
{$ENDIF}
end;
end;

procedure UninstallMouseHandler;
 var I: Integer;
begin
 asm
    call HideMouseProc
    xor dx,dx
    mov es,dx
    xor cx,cx
    mov ax,12
    int 33h
 end;
 (*
 { $ifndef DPMI}
 if EGAVGA then
  begin
   PrepareCharGen;
   for I := 0 to 5 do
    Move(SaveFont[I], mem[$A000:32*StdMouseBlock[I]], 16);
   DoneCharGen;
  end;
 { $endif}
 *)
 ShowMouseProc := nil;
 HideMouseProc := nil;
end;

procedure StdInitEvents; assembler;
asm
        XOR     AX,AX
        CMP     AL,ButtonCount
        JE      @@1
        MOV     DownButtons,AL
        MOV     LastDouble,AL
        MOV     EventCount,AX
        MOV     AX,OFFSET DS:EventQueue
        MOV     EventQHead,AX
        MOV     EventQTail,AX
        MOV     AX,3
        INT     33H
        XCHG    AX,CX
        MOV     CL,3
        SHR     AX,CL
        SHR     DX,CL
        MOV     MouseButtons,BL
        MOV     MouseWhere.X,AX
        MOV     MouseWhere.Y,DX
        MOV     LastButtons,BL
        MOV     LastWhere.X,AX
        MOV     LastWhere.Y,DX
        MOV     AX,12
        MOV     CX,0FFFFH
        MOV     DX,OFFSET CS:MouseInt
        PUSH    CS
        POP     ES
        INT     33H
        MOV     AX,1
        INT     33H
        MOV     MouseEvents,1
@@1:
end;

procedure InitEvents;
label 1;
var
  I: Integer;
begin
  if ButtonCount = 0 then Exit;
  StdMouse := ( MouseData.Options and omsCursor <> 0 ){ or ( ScreenWidth = 80 )};
  if StdMouse then begin
    if (ScreenWidth > 80) then begin
      I := mem[$40:$49];
      mem[$40:$49] := 3;
      asm
        push bp
        xor  ax, ax
        int  33h
        pop  bp
      end;
      mem[$40:$49] := I;
    end;
    StdInitEvents;
    Goto 1
  end;
  asm
         XOR     AX,AX
         MOV     DownButtons,AL
         MOV     LastDouble,AL
         MOV     EventCount,AX
         MOV     AX,OFFSET DS:EventQueue
         MOV     EventQHead,AX
         MOV     EventQTail,AX
         MOV     AX,3
         INT     33H
         MOV     CX, 0
         MOV     DX, 0
         XCHG    AX,CX
         MOV     CL,3
         SHR     AX,CL
         SHR     DX,CL
         MOV     MouseButtons,BL
         MOV     MouseWhere.X,AX
         MOV     MouseWhere.Y,DX
         MOV     LastButtons,BL
         MOV     LastWhere.X,AX
         MOV     LastWhere.Y,DX
         MOV     MouseEvents,1
  @@1:
  end;
  InstallMouseHandler(@MouseHandler, @ShowTextCursor, @HideTextCursor);
1:
  SetMouseSpeed(XSens, YSens);
end;

procedure SetMouseSpeed(XS, YS: Byte);
 var I: Integer;
     J: Integer;

 function II(X: Byte): Integer;
 begin
    case X of
      0..11: II := X+1;
      12: II := 14;
      13: II := 16;
      14: II := 20;
      15: II := 24;
      16: II := 28;
      17: II := 32;
      18: II := 36;
      19: II := 40;
      20: II := 44;
      21: II := 48;
      22: II := 56;
    end;
 end;

begin
    XSens := XS; YSens := YS;
    I := ScreenWidth * (XSens+1);
    J := ScreenHeight * (YSens+1);
    I := 200 * 22 div I;
    J := 200 * 22 div J;
    asm
      mov  ax, $0F
      mov  cx, I
      mov  dx, J
      push bp
      int  33h
      pop  bp
    end;
end;

procedure StdDoneEvents; assembler;
asm
        CMP     ButtonCount,0
        JE      @@1
        CMP     MouseEvents,0
        JE      @@1
        MOV     MouseEvents,0
        MOV     AX,2
        INT     33H
        MOV     AX,12
        XOR     CX,CX
        MOV     DX,CX
        MOV     ES,CX
        INT     33H
@@1:
end;

procedure DoneEvents;
begin
  if (StdMouse) and (ButtonCount > 0) and (ScreenWidth > 80) then
       asm
          push bp
          xor  ax, ax
          int  33h
          pop  bp
       end;

 if StdMouse then begin StdDoneEvents; Exit; end;
 if (ButtonCount = 0) or not MouseEvents then Exit;
 MouseEvents := False;
 UninstallMouseHandler;
end;
{$ELSE}
procedure HideGraphCursor; begin end;
procedure PrepareCharGen; begin end;
procedure DoneCharGen; begin end;
procedure ShowGraphCursor; begin end;
procedure HideTextCursor; begin end;
procedure ShowStdCursor; begin end;
procedure HideStdCursor; begin end;
procedure ShowTextCursor; begin end;
procedure MouseInt; begin end;
procedure MouseHandler; begin end;
procedure StdMouseHide; begin end;
procedure StdMouseShow; begin end;
procedure InstallMouseHandler; begin end;
procedure UninstallMouseHandler; begin end;
procedure StdInitEvents; begin end;
procedure InitEvents; begin end;
procedure SetMouseSpeed(XS, YS: Byte); begin end;
procedure StdDoneEvents; begin end;
procedure DoneEvents; begin end;
{$ENDIF}

const
  DriversInit: Boolean = False;


procedure InitDrivers;
var I: Integer;
    S: string;
begin
  if DriversInit then Exit;
  DriversInit := True;

  S := GetString(dlAltTable);
  if S <> '' then Move(S[1], AltCodes1, Min(Length(S), 37));

  for I := 0 to CE_LastMsg do
    CE_Messages[I] := NewStr(GetString(CE_Idx[I]));

  for I := 1 to 3 do
  begin
    S := GetString(TStrIdx(Ord(dlCE_ButAbort)+I-1));
    CE_Buttons[I] := NewStr(S);
    CE_K[I] := GetAltCode(HotKey(S)) shr 8;
  end;

  ErrWndTitle := NewStr(GetString(dlCE_ErrWndTitle));

  InitSysError;
end;

procedure FlushScreenBuffer;
var
  H: Windows.THandle;
  DummyMode: Windows.DWORD;
  BufferSize, BufferCoord: Windows.TCoord;
  WriteRegion: Windows.TSmallRect;
  CharInfoBuf: array[0..80*50-1] of Windows.TCharInfo;
  I, TotalCells: Integer;
  Src: PWordArray;
begin
{$IFNDEF CPUI8086}
  if ScreenBuffer = nil then Exit;
  if (ConsoleOutputHandle = 0) or (ConsoleOutputHandle = Windows.INVALID_HANDLE_VALUE) then
  begin
    H := Windows.GetStdHandle(Windows.STD_OUTPUT_HANDLE);
    if not Windows.GetConsoleMode(H, DummyMode) then
      H := Windows.CreateFileA('CONOUT$', Windows.GENERIC_READ or Windows.GENERIC_WRITE,
        Windows.FILE_SHARE_READ or Windows.FILE_SHARE_WRITE, nil, Windows.OPEN_EXISTING, 0, 0);
    ConsoleOutputHandle := H;
  end;
  H := ConsoleOutputHandle;
  if (H = 0) or (H = Windows.INVALID_HANDLE_VALUE) then Exit;
  TotalCells := ScreenWidth * ScreenHeight;
  if TotalCells > High(CharInfoBuf) + 1 then TotalCells := High(CharInfoBuf) + 1;
  Src := PWordArray(ScreenBuffer);
  for I := 0 to TotalCells - 1 do
  begin
    CharInfoBuf[I].AsciiChar := Char(Lo(Src^[I]));
    CharInfoBuf[I].Attributes := Hi(Src^[I]);
  end;
  BufferSize.X := ScreenWidth;
  BufferSize.Y := ScreenHeight;
  BufferCoord.X := 0;
  BufferCoord.Y := 0;
  WriteRegion.Left := 0;
  WriteRegion.Top := 0;
  WriteRegion.Right := ScreenWidth - 1;
  WriteRegion.Bottom := ScreenHeight - 1;
  Windows.WriteConsoleOutputA(H, @CharInfoBuf[0], BufferSize, BufferCoord, WriteRegion);
{$ENDIF}
end;

procedure SliceYield;
begin
{$IFNDEF CPUI8086}
  FlushScreenBuffer;
  Windows.Sleep(10);
{$ENDIF}
end;

procedure SliceAwake;
begin
  NewTimerSecs(LSliceTimer, 3);
  LSliceCnt := -2;
end;

begin
{$IFDEF CPUI8086}
 asm
     mov  ah,12h
     mov  bl,10h
     int  10h
     cmp  bl,10h
     jz   @NoEGAVGA
     mov  EGAVGA, 1
@NoEGAVGA:
 end;
{$ELSE}
  EGAVGA := True;
{$ENDIF}
  DetectMouse;
  Vesa_Found := -1;
{$IFDEF FPC}{$IFNDEF CPUI8086}
   { CharHeight already defaults to 16 (DRIVERS.PAS) - the standard
     VGA 80x25 value; no BIOS byte to refresh it from on Win32. }
{$ELSE}
  CharHeight := Mem[$40:$85];
{$ENDIF}{$ENDIF}
{$IF DEFINED(FPC) AND NOT DEFINED(CPUI8086)}
  { Ctrl+C as an ordinary keystroke, not a termination signal;
    QuickEdit off so a future mouse click is not a text-selection
    drag. Mouse input stays off until GetMouseEvent is real too. }
  SetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), ENABLE_EXTENDED_FLAGS);
{$ENDIF}
  SaveExit := ExitProc;
  ExitProc := @ExitDrivers;
end.

