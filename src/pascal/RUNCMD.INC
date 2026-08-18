{ RUNCMD.INC - NOT RECOVERED. Placeholder, 2026-08-18.

  ============================================================
   THIS FILE IS A PLACEHOLDER. IT DOES NOT CONTAIN THE CODE.
  ============================================================

  Unlike the other five includes missing from this repository, RUNCMD.INC
  is not a defines file. It is pulled into the IMPLEMENTATION section of
  DNUTIL.PAS, immediately after that unit's `uses` clause:

      implementation
      uses HelpKernel, DNHelp, {$ifdef modem} modemio, {$endif} ColorSel;
      {$I RunCmd.INC}
      {$I Version.INC}

  so it supplies procedure and function BODIES - the command-execution
  layer of DN. It cannot be reconstructed by inference the way DN.DEF,
  STDEFINE.INC, LINK.INC and VERSION.INC could, and it must not be faked:
  an empty stub would turn a clear "file missing" into a pile of
  "identifier not found" errors pointing at the wrong place.

  WHAT IT MUST PROVIDE
  --------------------
  DNUTIL.PAS declares these in its interface and implements none of them
  in the unit body; they are the candidates for this file:

      ExecString    ExecFile    ExecExtFile    SearchExt
      EditFile      ViewFile    RunFormat      AddFormat
      ChgColors

  (Other names in that gap list - InitDesktop, InitMenuBar, InitStatusLine,
  HandleCommand, LoadDesktop, StoreDesktop, OutOfMemory, EventError - are
  TApplication method overrides picked up by the same scan and are probably
  implemented elsewhere; treat the list above as the reliable part.)

  WHERE TO GET IT
  ---------------
  1. An original Dos Navigator 1.51 source distribution (RIT Research Labs)
     is the correct source of truth.

  2. Failing that, the closest surviving relative is `dnexec.pas` in the
     Dos Navigator Open Source / Necromancer's DN tree (769 lines). It
     contains ExecString, ExecFile, ExecExtFile and SearchExt - i.e. it is
     the evolved descendant of this file. It is NOT a drop-in: that tree is
     32-bit and Win32/OS2-aware, so it would need porting back to 16-bit
     real mode.

  Until one of those is done, the 1 unit that includes this file
  (DNUTIL.PAS) cannot compile, and anything depending on DNUTIL is blocked
  with it. See TOOLCHAIN.md for the current status. }

{$MESSAGE ERROR 'RUNCMD.INC is a placeholder - the real file is missing from this repository. See the comment in this file and TOOLCHAIN.md.'}
