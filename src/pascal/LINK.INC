(* LINK.INC - reconstructed 2026-08-18.

   Configuration for the DN "Link" subsystem (serial/parallel file transfer
   between two machines). Included by exactly five units:

       COMLNK.PAS  COMLNKIO.PAS  LINKTYP.PAS  LINKUTIL.PAS  NAVYLINK.PAS

   In LINKTYP.PAS it appears BEFORE the interface section, so it is
   defines-only - it cannot contain declarations.

   The original file was absent from this repository. Symbols below are the
   ones the Link units actually test, with their site counts.

   Roles:
     CL_MASTER (4 sites) is derived in STDEFINE.INC from Modem + DN.
     NLCLIENT (2 sites) / NLSLAVE (11 sites) select the NavyLink end.
     Both left undefined: this build is not a dedicated link client.

   Protocol options, all left OFF while bootstrapping:
     CL_PACK   (8 sites)   compress blocks before sending
     CL_LOG    (53 sites)  verbose protocol log to disk - the
                           highest-traffic symbol in the tree after DN
                           itself, but a debugging aid, not behaviour
     HARD_LOG  (4 sites)   unbuffered logging, survives a crash

   Platform I/O: COMLNKIO.PAS selects its backend per platform and only
   reaches OS2IO.INC under OS2, which STDEFINE.INC leaves undefined, so
   the DOS path is used for a real-mode build.

   Paren-star delimiters on purpose: quoted brace directives inside a
   brace comment would close it early and leak text into live code.
   Neither comment style nests, so no literal close delimiter may appear
   in this text either. *)

{ intentionally: no active defines - see comment above }
