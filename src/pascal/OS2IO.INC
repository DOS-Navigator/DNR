(* OS2IO.INC - placeholder, 2026-08-18.

   Referenced from exactly one site, COMLNKIO.PAS, guarded by IFDEF OS2,
   so it is only reached when building for OS/2. STDEFINE.INC leaves OS2
   undefined - the current target is 16-bit real-mode DOS - so this file
   is never included by any current configuration.

   The original was absent from the repository. It would contain the OS/2
   serial-port I/O implementation used by the Link subsystem - real code,
   not defines. This placeholder exists so the reference resolves if
   someone defines OS2; it deliberately does NOT provide the
   implementation, because a silent empty stub would produce link-time
   gaps that look like something else.

   If you enable OS2, expect the error directive below to fire; that is
   the intended behaviour, pointing at TOOLCHAIN.md. *)

{$IFDEF OS2}
  {$MESSAGE ERROR 'OS2IO.INC is a placeholder: the OS/2 serial I/O implementation is missing from this repository. See TOOLCHAIN.md.'}
{$ENDIF}
