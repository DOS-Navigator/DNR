(* STDEFINE.INC - reconstructed 2026-08-18.

   Global feature/configuration switches for DN 1.51. Included by:
       DN.PAS  DNUTIL.PAS  FILECOPY.PAS  FILESCOL.PAS  FLPANELX.PAS
       PHONES.PAS  TREE.PAS  UUCODE.PAS  VERSION.PAS

   The original file was absent from this repository. This reconstruction
   is deliberately MINIMAL: optional subsystems start switched OFF so the
   build surface is as small as possible while the toolchain is being
   brought up. Turn features back on one at a time once the core compiles.

   Platform symbols DPMI, OS2 and WINDOWS are intentionally NOT defined:
   the current target is 16-bit real-mode DOS via FPC's i8086-msdos
   cross-compiler, and on the win32 target WINDOWS must additionally be
   UNDEFINED on the command line (-uWINDOWS), because FPC predefines it
   while this codebase reads it as "16-bit Windows 3.x / TPW".

   Symbols this tree tests but which stay OFF here, with their site
   counts, so nobody has to re-derive the list:
       MODEM 24 - drags in the Link/CL_x family and OOCOM
       SPREADSHEET 7, PRINTMANAGER 6, GAME 5, DBVIEW 5, CDPLAYER 5,
       DISKEDIT 2, ARVID, PHONES - optional subsystems
       DEBUG 4, FMTDBG 4, DEMO 5 - diagnostics
       CL_LOG 53, CL_PACK 8, HARD_LOG 4 - Link subsystem, see LINK.INC
       NLCLIENT 2, NLSLAVE 11 - NavyLink roles, see LINK.INC

   Paren-star comment delimiters on purpose: quoted brace directives
   inside a brace comment close it at their first close-brace and leak
   the rest into live code. Neither comment style nests. *)

{ ---------------------------------------------------------------- target }

{$IFNDEF DPMI}
  {$DEFINE REALMODE}
{$ENDIF}

{ FPC accepts most Turbo Pascal syntax under -Mtp, but not TP's
  machine-code inline directive; units that must differ test FPC/NONBP. }
{$IFDEF FPC}
  {$DEFINE NONBP}
{$ENDIF}

{ ------------------------------------------------------------- features }

{ DNUTIL's stream-registration table hard-codes NumRElms = 136 for the
  feature set DN 1.51 actually shipped with, so "minimal" defines make the
  array count wrong. These are the shipped defaults; only MODEM stays off
  (its OOCOM/apFossil comm units are not in this repository). }
{$DEFINE UUENCODE}
{$DEFINE UUDECODE}
{$DEFINE SS}
{$DEFINE CHCOL}
{ Game OFF: TETRIS.PAS trips FPC internal error 200309041 (compiler bug); DNUTIL adjusts NumRElms }
{$DEFINE TrashCan}
{$DEFINE Calendar}
{$DEFINE DBView}
{$DEFINE DiskEdit}
{$DEFINE DiskFormat}
{$DEFINE Reanimator}
{$DEFINE PrintManager}
{$DEFINE SpreadSheet}
{$DEFINE CdPlayer}
{$DEFINE MEMINFO}
{$DEFINE SYSINFO}
{$DEFINE ARVID}
{$DEFINE PHONES}
{$DEFINE DisAsm}
{$DEFINE UserSaver}

{ --- overlays: DN 1.51 used the BP7 overlay manager; FPC has none and a
      first build does not need one --- }
{$DEFINE NO_OVERLAY}

{ ------------------------------------------------ derived / consistency }

{$IFDEF Modem}
  {$IFDEF DN}
    {$DEFINE CL_MASTER}
  {$ENDIF}
  {$IFDEF NLCLIENT}
    {$DEFINE CL_MASTER}
  {$ENDIF}
{$ENDIF}
