{ LINK.INC - reconstructed 2026-08-18.

  Configuration for the DN "Link" subsystem (serial/parallel file transfer
  between two machines). Included by exactly five units:

      COMLNK.PAS  COMLNKIO.PAS  LINKTYP.PAS  LINKUTIL.PAS  NAVYLINK.PAS

  In LINKTYP.PAS it appears BEFORE the interface section:

      {$I LINK.INC} interface uses {$IFDEF OS2} ObjOS2 {$ELSE} Objects {$ENDIF};

  so it is defines-only - it cannot contain declarations.

  The original file was absent from this repository. Symbols below are the
  ones the Link units actually test, with their site counts.

  CL_LOG is the highest-traffic symbol in the whole tree after DN itself
  (53 sites). It is left OFF: it enables verbose protocol logging, which is
  a debugging aid, not required behaviour. }

{ --- roles ---------------------------------------------------------- }
{ CL_MASTER (4 sites) is derived in STDEFINE.INC from Modem + DN.
  NLCLIENT (2 sites) / NLSLAVE (11 sites) select the NavyLink end.
  Leave both undefined for a build that is not a dedicated link client. }

{ {$DEFINE NLCLIENT} }
{ {$DEFINE NLSLAVE}  }

{ --- protocol options ----------------------------------------------- }
{ {$DEFINE CL_PACK}   ( 8 sites)  compress blocks before sending }

{ --- diagnostics ----------------------------------------------------- }
{ {$DEFINE CL_LOG}    (53 sites)  verbose protocol log to disk
  {$DEFINE HARD_LOG}  ( 4 sites)  unbuffered logging, survives a crash }

{ --- platform I/O ---------------------------------------------------- }
{ COMLNKIO.PAS selects its I/O backend by platform:
      {$IFDEF OS2} {$I OS2IO.INC} {$ENDIF}
  With OS2 undefined that include is never reached, so the DOS path is
  used and OS2IO.INC is not required for a real-mode build. }
