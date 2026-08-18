{ STDEFINE.INC - reconstructed 2026-08-18.

  Global feature/configuration switches for DN 1.51. Included by:
      DN.PAS  DNUTIL.PAS  FILECOPY.PAS  FILESCOL.PAS  FLPANELX.PAS
      PHONES.PAS  TREE.PAS  UUCODE.PAS  VERSION.PAS

  The original file was absent from this repository. This reconstruction is
  deliberately MINIMAL: optional subsystems start switched OFF so the build
  surface is as small as possible while the toolchain is being brought up.
  Turn features back on one at a time once the core compiles.

  Every symbol below is one this tree actually tests; the counts are how
  many {$IFDEF}/{$IFNDEF} sites reference it.

  Platform symbols (DPMI, OS2, WINDOWS) are intentionally NOT defined:
  the current target is 16-bit real-mode DOS via FPC's i8086-msdos
  compiler (see TOOLCHAIN.md). }

{ ---------------------------------------------------------------- target }

{ Leave all three undefined for plain real-mode DOS.
  {$DEFINE DPMI}      16-bit protected mode      (6 sites)
  {$DEFINE OS2}       OS/2                       (12 sites)
  {$DEFINE WINDOWS}   16-bit Windows             (16 sites) }

{$IFNDEF DPMI}
  {$DEFINE REALMODE}
{$ENDIF}

{ FPC accepts most Turbo Pascal syntax under -Mtp, but not TP's
  inline($xx/$yy) machine-code directive. Units that must differ are
  guarded with {$IFDEF FPC}. }
{$IFDEF FPC}
  {$DEFINE NONBP}
{$ENDIF}

{ ------------------------------------------------------------- features }

{ --- enabled: core, low-dependency --- }
{$DEFINE UUENCODE}        { 2 sites  }
{$DEFINE UUDECODE}        { 2 sites  }

{ --- disabled while bootstrapping the toolchain ---
  Each pulls in extra units and, in several cases, inline assembly.

  {$DEFINE MODEM}         { 24 sites - also drags in the Link/CL_* family }
  {$DEFINE SPREADSHEET}   { 7 sites  }
  {$DEFINE PRINTMANAGER}  { 6 sites  }
  {$DEFINE GAME}          { 5 sites  }
  {$DEFINE DBVIEW}        { 5 sites  }
  {$DEFINE CDPLAYER}      { 5 sites  }
  {$DEFINE DISKEDIT}      { 2 sites  }
  {$DEFINE ARVID}
  {$DEFINE PHONES}
}

{ --- diagnostics: off --- }
{ {$DEFINE DEBUG}         ( 4 sites )
  {$DEFINE FMTDBG}        ( 4 sites )
  {$DEFINE DEMO}          ( 5 sites ) }

{ --- overlays ---
  DN 1.51 used a BP7 overlay manager. FPC has no equivalent, and the
  i8086-msdos target does not need one for a first build. }
{$DEFINE NO_OVERLAY}

{ ------------------------------------------------ derived / consistency }

{ CL_MASTER is the "this build owns the link master side" marker; it is
  only meaningful when both Modem support and the DN program itself are
  being built. Mirrors the rule used across this family of sources. }
{$IFDEF Modem}
  {$IFDEF DN}
    {$DEFINE CL_MASTER}
  {$ENDIF}
  {$IFDEF NLCLIENT}
    {$DEFINE CL_MASTER}
  {$ENDIF}
{$ENDIF}

{ The Link logging symbols (CL_LOG, 53 sites; CL_PACK, 8 sites) belong to
  the Link subsystem and are configured in LINK.INC, which the five
  COMLNK/LINKTYP/LINKUTIL/NAVYLINK units include directly. }
