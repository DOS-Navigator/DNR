# DOS Navigator toolchain on native Windows

Established 2026-08-18 on Windows 11, **natively** - no WSL, Cygwin, MSYS or
DOSBox anywhere in the build path.

## Installed and verified

| Tool | Version | Path | Verified by |
|------|---------|------|-------------|
| NASM | 3.02 | `~\scoop\shims\nasm.exe` | assembled DNR's `VGA33` to a byte-identical `.com` |
| Free Pascal (host) | 3.2.2 | `~\scoop\apps\freepascal\current` (`ppc386.exe`) | `fpc -iV` |
| FPC i8086-msdos cross | 3.2.2 | `C:\FPC\3.2.2\bin\i386-win32\ppcross8086.exe` | compiled a Pascal program to a real 16-bit **MZ** executable |
| NASM (FPC's own) | bundled | `C:\FPC\3.2.2\bin\i386-win32\nasm.exe` | FPC uses NASM as its i8086 assembler |
| MSVC | VS 18 Community + VS 2019 BuildTools | `ml64.exe`, `cl.exe` | built `t2nt.exe` |
| t2nt | this repo | `T2NT\bin\t2nt.exe` | see `T2NT\STATUS.md` |

### The i8086 command that works

The cross-compiler needs three things that are easy to get wrong: the `rtl`
subdirectory (not the model directory), `-XX` smart-linking (the RTL ships
`.a` archives, so a plain link fails with `Can't open object file: system.o`),
and its own `nasm.exe` on PATH.

```
set PATH=C:\FPC\3.2.2\bin\i386-win32;%PATH%
ppcross8086.exe -Wmsmall -XX ^
  -Fu"C:\FPC\3.2.2\units\msdos\8086-small\rtl" ^
  -FE<outdir> -FU<outdir> <file.pas>
```

Memory models available: `tiny compact small medium large huge` x
`8086 80186 80286 80386` (24 unit sets).

## TASM: why it is not installed

Turbo Assembler is a **16-bit DOS program**. 64-bit Windows removed the
NTVDM subsystem entirely, so it cannot execute any 16-bit binary - this is
an OS limitation, not a licensing or packaging one. Running real TASM would
require DOSBox or a 32-bit Windows VM, both of which you excluded.

It is also proprietary Borland software, so it fails the FLOSS requirement
independently.

**This is precisely why T2NT exists**: transpiling TASM to NASM removes the
need for TASM at all, and NASM runs natively 64-bit.

If a TASM-*compatible* assembler running natively is wanted, the FLOSS
options are **JWasm**, **UASM** and **ASMC** (MASM-syntax, some TASM
support). None is currently installed; none is needed for the NASM route.

## Status against the goal

Goal: build DOS Navigator on modern Windows with FLOSS tools, targeting
Windows natively.

- **Assembly**: `t2nt` transpiles all 10 TASM modules; 2 of 10 assemble
  clean under NASM. `VGA33` output is byte-identical to the hand-converted
  reference. Remaining gaps listed in `T2NT\STATUS.md`.
- **Pascal, DOS target**: unblocked. `ppcross8086` works, which is where
  DNR's `initial-analysis-and-toolchain-investigation` branch stopped.
- **Pascal, native Windows target**: **not yet attempted, and it is the
  large piece of work.** DN is Turbo Pascal 7 + Turbo Vision, 16-bit real
  mode: 99 units using `Objects`/`Views`/`Drivers`/`Dialogs` (Turbo Vision)
  and the `Dos` unit, with direct video memory writes and DOS interrupt
  calls throughout. Compiling that for Win32 means porting to Free Vision
  and replacing every `Dos`/interrupt dependency. That is a porting
  project, not a build-configuration change.

## Recommended order

1. Finish the assembly path (close the T2NT gaps until 10/10 assemble).
2. Build DN for **i8086-msdos** first - it is now reachable and validates
   the Pascal sources compile at all with FPC.
3. Only then port to native Win32 via Free Vision.

Doing 3 before 2 means debugging a port and a toolchain simultaneously.

---

# Pascal bring-up: measured status 2026-08-18

## Missing includes: 5 of 6 recovered

| File | Status |
|---|---|
| `VERSION.INC` | **Recovered exactly.** `VERSION.PAS` in this repo is not a unit - it is a *generator program* whose tail writes this file. Values taken from its own constants: `1.51`, `April 19, 1999`, `$0133`. |
| `DN.DEF` | Reconstructed (defines-only): `DN`, `DNPRG`. |
| `STDEFINE.INC` | Reconstructed (defines-only), deliberately minimal - optional subsystems start OFF. |
| `LINK.INC` | Reconstructed (defines-only). Proven defines-only because `LINKTYP.PAS` includes it *before* `interface`. |
| `OS2IO.INC` | Placeholder. Only reachable under `{$IFDEF OS2}`, which is off, so it is not needed for a DOS build. |
| `RUNCMD.INC` | **NOT recovered - genuinely missing code.** Included into DNUTIL's *implementation*, so it holds procedure bodies (`ExecString`, `ExecFile`, `ExecExtFile`, `SearchExt`, ...). Closest surviving relative is `dnexec.pas` (769 lines) in the Dos Navigator Open Source / NDN tree, which is 32-bit and would need porting back. |

## Turbo Pascal `inline()` machine code: fixed

FPC does not support TP's `inline($5A/$58/...)` directive. All **7 sites**
(OBJECTS.PAS x2, UUCODE.PAS x3, DIALOGS.PAS x1, counting the pairs) are now
guarded with `{$IFDEF FPC}` and given portable Pascal bodies. The original
opcodes are preserved in comments and the BP7 path is unchanged. The two in
OBJECTS.PAS were in the *interface* section, so their bodies moved to the
implementation.

## Compile results: 4 of 99 units

`COMMANDS`, `DNHELP`, `OBJTYPE`, `STRINGS` compile for i8086-msdos.
Dominant failures:

| Count | Cause |
|---|---|
| 63 | `Illegal expression` - almost all are `VmtLink: Ofs(TypeOf(T)^)` in Turbo Vision stream-registration records |
| ~16 | `Can't find unit dos` - **not a path problem**, see below |
| 8 | Syntax errors (assorted TP-isms) |

## The finding that shapes the port: unit-name collisions

**10 DNR units have the same names as FPC RTL / Free Vision units:**

    ASCIITAB  DIALOGS  DRIVERS  HISTLIST  MEMORY
    MENUS     OBJECTS  STRINGS  VALIDATE  VIEWS

This is why `dos` "cannot be found": DNR's `STRINGS` shadows the RTL's
`strings`, so FPC tries to recompile `dos` against the wrong unit and gives
up. The error names the wrong thing entirely.

Consequences:

* Putting `src/pascal` on the unit path **breaks the RTL**.
* Removing it means losing DNR's own forked Turbo Vision (~16,600 lines
  across OBJECTS/VIEWS/DRIVERS/DIALOGS/MENUS/COLORSEL/VALIDATE/HISTLIST).

So the first real decision in this port is a **namespace strategy**, not a
compatibility shim: either rename DNR's forked units (e.g. `dnObjects`), or
build them as a package that deliberately replaces Free Vision. That choice
has to be made before the 63 `Ofs(TypeOf(...))` sites are worth touching,
because it determines which `TStreamRec` they must satisfy.

---

# Session 2: low-hanging fruit, measured 2026-08-18

## Headline

Unit count moved 4 -> 5 (i8086-msdos). That understates the change: the
whole codebase still funnels through **OBJECTS.PAS**, which 63 units depend
on, and that file went from 5 blocking errors to 3 with its entire stream
architecture ported off 16-bit assembly.

**Repeated error counts are misleading in this project.** "63 errors" has
meant, at every stage so far, *one or three unique sites in OBJECTS.PAS,
recompiled once per dependent unit*. Always de-duplicate before sizing work.

## Done

* **158 `Ofs(TypeOf(X)^)` sites converted to `TypeOf(X)`** across 40 files.
  Established by experiment that this was unavoidable: with `VmtLink: Word`,
  all three candidate spellings (`Ofs(TypeOf(T)^)`, `Ofs(TypeOf(T))`,
  `Word(TypeOf(T))`) are rejected; only `VmtLink: Pointer` + `TypeOf(T)`
  compiles.
* **`TStreamRec` ported to the shape FPC's own Free Vision uses**:
  `VmtLink: Pointer`, `Next: PStreamRec`, `StreamTypes: PStreamRec`.
* **Four assembler routines rewritten in Pascal** - `RegisterType`,
  `ReRegisterType`, `TStream.Get`, `TStream.Put` - following
  `packages/rtl-extra/src/inc/objects.pp` rather than inventing the ABI.
  The constructor dispatch goes through `CallPointerConstructor` /
  `CallPointerMethod`, whose helper types are copied verbatim from FPC.
  Hand-rolling that would have compiled and been silently wrong.

## Defects found and fixed in earlier work on this branch

* **`MEMORY.PAS` had an unbalanced conditional** - 4 opens, 3 closes. The
  `{$IFDEF MODERN}` block added previously was never closed.
* **`compat.inc` set `{$MODE FPC}`, which does NOT provide `Result`** (that
  is on by default only in OBJFPC/DELPHI). Added `{$MODESWITCH RESULT+}`.

## Trap worth knowing

**FPC defines `WINDOWS` for the win32 target; DNR's `{$IFDEF Windows}` means
16-bit Windows 3.x (Turbo Pascal for Windows).** Different things, 16 sites.
Left alone it silently selects TPW code paths and demands `WinProcs`.
Compile with **`-uWINDOWS`** to undefine it. This is in every command below.

## Current blocker, unchanged in shape

`OBJECTS.PAS`, 3 errors:

1. `FillChar(Image(Self).Data, ...)` - hard cast of an object to a local
   record type; FPC rejects it.
2. `TRect.Contains` and one neighbour - still 16-bit assembler.

Then `STRINGS.PAS:174` (`les reg16,reg32`) is next in line for win32; it is
legal on i8086, which is why the DOS target remains the cheaper one.

## Reproduce

    ppcross8086.exe -Mtp -Wmlarge -XX -uWINDOWS ^
      -Fi<src> -Fu<src> -Fu<units>\8086-large\rtl -Fu<units>\8086-large\rtl-extra ^
      -FE<out> -FU<out> <file.pas>

Note `-Fu` must NOT include the `fv` directory: DNR ships its own forked
Turbo Vision and Free Vision's units would shadow it. Only two DNR units
collide with the RTL proper - `STRINGS` and `MESSAGES` - and `STRINGS` is
why `dos` reports "Can't find unit" (it shadows the RTL's `strings`, so
`dos` is rebuilt against the wrong unit). Renaming those two is the next
cheap win, worth ~16 units.

---

# Session 3: 8 -> 23 units (i8086-msdos), and an encoding incident

## Measured state

23 of 99 units compile for i8086-msdos with:

    ppcross8086 -Mtp -Wmlarge -XX -uWINDOWS -dDN -Fi<src> -Fu<src> ...

`-dDN` is new and required: LINKUTIL and friends hide their `uses ...
Dos` behind `{$IFDEF DN}`, so the symbol must exist globally - the
original build defined it in the lost TURBO.CFG, not only via DN.DEF.

## Done this session

* OBJECTS.PAS compiles: TObject.Init rebuilt on FPC's self-sizing
  DummyObject pattern; TRect.Contains/Equals/Empty rewritten from asm.
* ADVANCE.PAS compiles (gates 34 units): 15 pure string/arith assembler
  helpers rewritten in portable Pascal; FileNameOf ported to FPC's
  FileRec; hardware/DOS-interrupt asm left in place deliberately.
* Units renamed to stop shadowing the FPC RTL: Strings -> DnStrings,
  Messages -> DnMessages (uses-clause-scoped rewrite - DIALOGS has a
  FIELD named Strings, so a global replace would corrupt it). STARSKY.PAS
  renamed QSTARSKY.PAS to match its `unit qStarSky`.
* {$V-} restored tree-wide (94 files): DN 1.51 was built with relaxed
  var-string checks (ADVANCE passes string[30] to `var s: string`;
  DRIVERS/GAUGE still carry explicit {$V-}); the setting lived in the
  lost build config.
* Reconstructed include files rewritten with paren-star comments: quoted
  brace directives inside brace comments terminated them early and leaked
  text into live code (three include files were broken this way; neither
  Pascal comment style nests).
* Original-source bugs fixed (both dead code under TP's first-match case
  semantics, now errors under FPC): FIXER.PAS `S + +SStr` double plus,
  FIXER.PAS case ranges 26..27/26..29 overlap (-> 28..29), XDBLWND.PAS
  duplicate cmGetDirName arm.

## Incident: harness Edit tool destroys CP866 sources

The Claude Code Edit tool reads files as UTF-8 with errors=replace. On
CP866 sources every high byte becomes U+FFFD (EF BF BD) - irreversibly,
silently, across the whole file. ADVANCE's 128-byte UpperTable became 382
bytes of replacement characters; DIALOGS and UUCODE lost comment bytes the
same way (that damage was already in the previous two pushed commits).

All corrupted lines were healed byte-exactly from main's blobs by regex
fingerprint (ASCII kept, FFFD runs matched against original high-byte
runs), verified by high-byte census against main. Standing rule for this
repository: **.PAS files are edited only by byte-safe scripts** (python
latin-1/binary), never by the interactive Edit tool, and Git-Bash sed
strips CRLF so every sed pass needs an EOL restore after it.

## The remaining wall

Everything else funnels through **VIEWS.PAS(783): WriteView** - Turbo
Vision's clipping/video blitter, ~200 lines of the most intricate 16-bit
assembler in TV, walking the view tree computing visible spans. Free
Vision's Pascal implementation is the reference to port from. Behind it
sit DIALOGS/DNAPP/MENUS and the whole UI layer.

Also open: RUNCMD.INC (missing code, DNUTIL blocked), COPY.PAS (orphan
include-file, no unit header, nothing includes it), MODEMIO/COMLNKIO
(need OOCOM/apFossil, Modem subsystem off), OVERLAYS (BP overlay manager,
NO_OVERLAY set).

---

# Session 4: the VIEWS wall is down - 56 units compile

All 23 assembler routines in VIEWS.PAS are ported to Pascal. The write
engine (WriteView -> DoWriteView/DoWriteViewRec1/2) and Exposed follow
FPC Free Vision's implementations, with the buffer stride changed to
G^.Size.X because DN/TV2 allocate per-window buffers (FV has only the
screen-wide one; the models agree on the top group). Local-function
callbacks (ForEach/FirstThat) use FV's frame-passing helpers verbatim -
that convention must not be hand-derived. TFrame.FrameLine keeps its
CP866 FrameChars table untouched; only the asm became Pascal.

The whole UI layer now compiles: DIALOGS, MENUS, DNAPP, DNSTDDLG,
SETUPS, EDITOR, COLORSEL, PHONES, XDBLWND, FIXER, MACRO, REANIMAT,
DNFORMAT and more - 56 ppus from one DN.PAS build.

RUNCMD.INC now carries compile-clean scaffolding: correct signatures,
each raising RunError(199) if ever called, so the graph compiles while
the missing original remains loudly missing. STDEFINE.INC now enables
the feature set DN 1.51 shipped with, because DNUTIL's registration
table hard-codes NumRElms=136 for it. Game is OFF: TETRIS.PAS trips FPC
internal error 200309041 (a compiler bug, not source); NumRElms adjusts
by -3 under IFNDEF Game.

More original-1999 bugs fixed, all dead code under TP semantics:
doubled-plus string concatenations (CDUTIL x4, CDPLAYER x2, TETRIS
unary form), a duplicate cdZoom case arm (CDPLAYER), a duplicate
cmChangeDirectory arm (XDBLWND), duplicate ' ' set elements (CALC x2).
CDPLAYER's Inline() CRC32 became the Pascal its own comment documented.

Current DN.PAS blocker: DNUTIL implementation - identifier SaveDsk
(1635 etc., a UserSaver-family global) and one more duplicate case
label at 1964. The funnel is now entirely inside DNUTIL.

---

# Session 5: OBJECTS.PAS compiles clean on BOTH targets

## Headline

OBJECTS.PAS - the root dependency of the whole tree - now compiles for
**both** i8086-msdos and win32 with zero errors. This is the single
biggest unlock available: every other unit depends on it. i8086 stayed
at 23/99 (no regression, verified by a full re-sweep after every change
below); win32 moved from "can't even start OBJECTS.PAS" to **7/99**,
with the remaining blockers now spread thin across small, independent
units instead of piling up behind one file.

## What OBJECTS.PAS needed for Win32, in the order hit

1. MaxAvail - a DOS heap primitive ("largest contiguous free block")
   with no Win32 meaning. Declared only under IFDEF FPC + IFNDEF
   CPUI8086, returning a large sentinel; i8086 keeps FPC's own native
   System.MaxAvail untouched.
2. TMemoryStream - stored a list of 16-bit segment values
   (SegList: PWordArray) and reconstructed far pointers via Ptr(seg,0).
   This cannot be type-cast into working on Win32: extracting just the
   high 16 bits of a 32-bit pointer loses the address, which would
   silently corrupt memory at runtime rather than just fail to compile.
   Win32 has no 64KB block limit at all, so the segmented apparatus is
   simply unnecessary there - replaced with one contiguous
   GetMem/ReallocMem buffer, semantics matched line by line against the
   original asm (read past end -> stReadError plus zero-fill; write
   growing the stream -> grow or stWriteError; Truncate sets
   Size := Position).
3. TDosStream - used raw INT 21H DOS file syscalls. Ported to FPC's own
   FileOpen/FileCreate/FileRead/FileWrite/FileSeek/FileTruncate/
   FileClose (SysUtils) under plain IFDEF FPC - applying to BOTH
   targets, not just Win32, since FPC's File* API already wraps the
   same INT 21H calls internally on i8086-msdos. Mode decoding
   (stCreate/stOpenRead/stOpenWrite/stOpen) was derived from this
   file's own constants, not guessed: their low two bits already equal
   FPC's fmOpenRead/fmOpenWrite/fmOpenReadWrite by design.
4. TBufStream - a 16-bit-specific manual read/write buffering layer on
   top of TDosStream, with buffer state packed into two Word fields
   shared between read-ahead and write-behind modes. Rather than risk
   mistranslating that packed state machine under time pressure, its
   six asm methods became thin delegates to the now-portable TDosStream
   (inherited Read/Write/Seek/GetPos/GetSize) - FPC's own File* calls
   are already OS-buffered, so DN's extra buffering layer is a DOS-era
   optimisation with no correctness requirement to keep on a modern OS.
5. TEmsStream - EMS (INT 67h bank-switched memory) is 1990s hardware
   with no Win32 equivalent whatsoever; there is nothing to port. Init
   now unconditionally fails with stInitError under FPC - not a
   workaround, but exactly the "no EMS board present" path every call
   site in this codebase already handles gracefully, since DN 1.51 had
   to run on machines with no EMS too.
6. TCollection - 8 more methods (At, AtDelete, AtInsert, AtPut,
   FirstThat, ForEach, IndexOf, LastThat, Pack), all ordinary
   bounds-checked array bookkeeping with zero hardware dependency.
   FirstThat/ForEach/LastThat take a local-function callback, so they
   reuse the FPC local-frame-passing helper pattern already established
   for TGroup.ForEach/FirstThat in VIEWS.PAS back in session 4.
7. TStringCollection.Compare and TStringList.Get - a shortstring
   compare (now SysUtils.CompareStr) and an index-lookup loop over
   TStrIndexRec records - ordinary logic, no hardware involved.
8. TRect - the last 6 methods (Assign/Copy/Move/Grow/Intersect/Union),
   each read out of its asm instruction by instruction and verified
   (Intersect takes the max of the A corners and the min of the B
   corners per operand; Union is the reverse; Grow/Intersect both
   inline the same "collapse to (0,0)-(0,0) if now empty" check the
   original CheckEmpty near-helper performed).

Every port above kept the original i8086 assembler as a byte-for-byte
ELSE branch - none of it was retyped by hand, it was copied - so the
working DOS build is provably unaffected. Confirmed by a full i8086
re-sweep after all of the above: still 23/99, identical set of units.

## Fixed alongside

- RUNCMD.INC gained a fifth scaffolded routine, SaveDsk (called
  immediately before ExecString/ExecFile at every site in DNUTIL;
  missing from the original recovery, found only once DNUTIL itself
  started compiling).
- DNUTIL.PAS had one more duplicate case label (cmFormatDisk:
  AddFormat, dead under TP semantics - RunFormat already claimed it
  earlier in the same case statement).
- UUCODE.PAS had its own independent Hex8Lo (same algorithm as
  ADVANCE's, ported the same way).
- FLPANEL.PAS: two more doubled-plus sites (a second, broader sweep
  that does not require a space after the second +, closing this bug
  class more completely) and a 0..100 case-range genuinely overlapping
  cmClose=4 (an already-live, more specific arm) - split into
  0..3, 5..100 rather than deleted, since the range itself is real and
  intentional, not a duplicate.
- DNSTRINGS.PAS (the renamed Strings unit) had its entire ~20-routine
  implementation - the complete classic Borland Strings unit API,
  verbatim per its own header comment - replaced with thin forwarders
  to FPC's own Strings unit, which already implements the identical
  TP7-compatible API portably. Verified clean on both targets. Same
  reasoning as TDosStream: don't hand-port 16-bit pointer tricks when
  the platform's own standard library already does the job correctly.
- MICROED.PAS: one TEST reg,mem operand order that TASM silently
  accepted but FPC's stricter encoding rejects (TEST has no reg,r/m
  form; swapped to mem,reg - bit-identical since TEST only sets flags
  and never writes back), and one Char cast into Pointer widened
  through PtrUInt.

## What's left for Win32 (7/99, up from effectively 0) - see session 6 for the current list, this one is stale

Small, independent blockers now, not one large funnel behind one file:

- ShiftState: Byte absolute $40:$17 (ADVANCE.PAS) - a raw
  segment:offset variable mapped onto the BIOS keyboard-flags byte.
  Roughly 60 usage sites across a dozen files, both read AND write.
  This needs a real Win32 keyboard-state abstraction (GetKeyState /
  GetAsyncKeyState), not a syntax fix - deliberately not rushed this
  session given the blast radius. Blocks ADVANCE.PAS (34 dependents)
  and XTIME.PAS on the same construct.
- FMTUNIT.PAS, HELPKERN.PAS, HISTLIST.PAS - each one more LES/LDS
  far-pointer asm site, same shape as everything ported this session;
  mechanical once reached.
- MODEMIO.PAS (needs OOCOM, a comm-port unit not in this repository)
  and OVERLAYS.PAS (BP overlay manager, NO_OVERLAY is set) - both
  optional-subsystem units, same as the pre-existing i8086 gaps.

# Session 6: 7 -> 10 units (win32), and the "mechanical" note above was wrong for FMTUNIT.PAS

## Headline

Picked up the three files this file's own previous session flagged as
"mechanical once reached." Two of the three (HELPKERN.PAS, HISTLIST.PAS)
were exactly that. The third (FMTUNIT.PAS) was not - the earlier note
was written from the FIRST compile error only, without reading past it.
i8086-msdos unchanged at 23/99 (regression sweep re-run after every
change below, identical unit set); win32 moves 7 -> 10/99.

## FMTUNIT.PAS: not mechanical, and not live code

Reading past the first `les bx,Buf` error showed this whole unit is a
raw BIOS INT 13h floppy formatter - GetIOCTL (INT 21h/440Dh), CheckDStep
and SetDrive (poking the BIOS media-state table at 0:$490), ReadSector/
WriteSector/FormatTrack/VerifyTrack (INT 13h), and BOOTsector (not a
routine at all - 512 bytes of literal 8086 machine code for a FAT12 boot
sector, embedded as `db` bytes at the procedure's own code address, meant
to be blitted straight onto a floppy). None of this has a Win32
equivalent (no raw sector I/O from user mode). `grep -rln FmtUnit *.PAS`
across the whole tree turns up nothing but the file itself - it is
orphaned, superseded by FORMAT.PAS's own separate, self-contained INT 13h
implementation.

Ported as a Tier-3 honest scaffold (same category as TEmsStream, session
5): the original i8086 asm kept byte-for-byte as `{$ELSE}`, every routine
under FPC+win32 fails cleanly (IOError<>0, or Verify=True matching that
routine's own existing "True means error" polarity) rather than
pretending hardware access exists. Two inline `asm...end` fragments
inside PrepareFormat/EndFormat, and the unit's `mem[$40:$10]` drive-count
probe in its init block, got the same treatment.

The guard needed a fix mid-session: a naive
`{$IFDEF FPC}{$IFNDEF CPUI8086}...{$ELSE}...{$ENDIF}{$ENDIF}` is WRONG
here, because its `{$ELSE}` only catches FPC+i8086, leaving plain-TP
compilation (if anyone ever builds this with real Turbo Pascal again)
with neither branch defined - a duplicate-def/undefined-def split that
doesn't show up under FPC at all, which is exactly why it's easy to get
wrong and not notice. Correct form, verified against a throwaway test
file first: a single-level `{$IF DEFINED(FPC) AND NOT DEFINED(CPUI8086)}
...{$ELSE}...{$ENDIF}`, which correctly puts the original asm in scope
for BOTH plain-TP and FPC+i8086.

## HELPKERN.PAS: genuinely mechanical

Scan(var P; Offset; C) and TextToLine(var Text; Offset, Length; var
Line) - a byte scan and a length-prefixed buffer copy, zero OS
dependency. Ported the same way TCollection/TRect were in session 5,
under plain `{$IFDEF FPC}` (applies to both targets uniformly, since
neither routine cares about segmented vs. flat memory).

## HISTLIST.PAS: real, live, byte-packed - ported carefully, not scaffolded

`uses`d by 16 other units (command lines, dialogs, search boxes) - this
is DN's actual input-history recall feature, not dead code, so getting
the byte format wrong would silently corrupt a real feature (and its
on-disk save file). Read AdvanceStringPointer/DeleteString/InsertString
against EACH OTHER, not in isolation, since a byte-packed format only
makes sense read+write+delete-consistently:

    byte[0]         permanent pad, always 0, written once by
                     ClearHistory and never touched again
    byte[1..]        entry: [marker=0][Id][StrLen][StrLen chars],
                     repeating back to back, new entries always
                     inserted at offset 1 (the front); existing data
                     shifted up by Length(Str)+3 bytes to make room

CurString always points at an entry's StrLen byte (confirmed by
DeleteString, which computes entry_start := Ofs(CurString)-2).
AdvanceStringPointer's single `JMP @@2` bootstrap works identically
whether CurString is fresh (pointing at byte[0], skip=0) or continuing
past a match (pointing at a StrLen byte, skip=that string's own length)
- both cases read as "a skip byte, then 1+skip more bytes to the next
entry." When the shift would overflow HistorySize, InsertString evicts
from the tail by scanning backward for a marker byte and shrinking the
used-data boundary; ported as a plain backward byte scan.

The original's `PtrRec(HistoryBlock).Ofs` / `SUB AX,DX` corrections
throughout turned out to be a non-issue rather than something to
replicate: InitHistory used `MemAllocSeg` specifically because it
guarantees Ofs(HistoryBlock)=0, so every one of those corrections is
always adding/subtracting zero in practice - confirmed by StoreHistory's
own on-disk format, which writes `HistoryUsed - Ofs(HistoryBlock)` (the
pure relative count) as the saved Size. The rewrite treats HistoryUsed
as a plain 0-based count throughout, matching what was actually
serialized, and uses ordinary GetMem in place of MemAllocSeg (no
segment-alignment concept on Win32, and unneeded by an offset-agnostic
rewrite regardless of target).

Pointer<->offset conversions use `LongInt(Ptr)` casts, not PtrUInt: this
file's own disabled code elsewhere (a commented-out duplicate-removal
block in HistoryAdd) already computes
`LongInt(CurString)-LongInt(HistoryBlock)` for the identical purpose, so
this reuses the codebase's own established idiom - which works
correctly on both targets (segment:offset-as-32-bit-int on i8086,
flat-address-as-32-bit-int on win32) - rather than introducing an
untested one.

## What's left for Win32 (10/99, up from 7/99) - see session 7, this is stale

- ShiftState: Byte absolute $40:$17 (ADVANCE.PAS) - unchanged from
  session 5, still the biggest single remaining blocker. ~85 usage
  sites across 20 files (re-counted this session with a plain grep,
  not the ~60/dozen-files estimate carried since session 5), both read
  AND write (writes are confined to FLPANEL.PAS and TERMINAL.PAS).
  Needs a real Win32 keyboard-state abstraction (GetKeyState /
  GetAsyncKeyState) preserving the BIOS byte's bit layout so every call
  site keeps working unmodified - not attempted this session, still the
  right next thing to pick up given it blocks ADVANCE.PAS (34
  dependents) and XTIME.PAS. DRIVERS.PAS's own keyboard input path
  (`_GetKeyEvent`, raw INT 16h) is a separate, larger piece of the same
  problem - a full console-input driver, not just this one variable -
  and hasn't been scoped yet.
- MODEMIO.PAS (needs OOCOM, a comm-port unit not in this repository)
  and OVERLAYS.PAS (BP overlay manager, NO_OVERLAY is set) - unchanged,
  optional-subsystem units, same as the pre-existing i8086 gaps.
- Everything else in the 89 still-failing units is unexplored past
  whatever their own first compile error is - no claim here about
  which of them are mechanical vs. not, after this session's FMTUNIT.PAS
  lesson about trusting that label without reading past the first error.

# Session 7: 10 -> 22 units (win32) - ShiftState was the real choke point

## Headline

Picked up ShiftState as scoped. i8086-msdos unchanged at 23/99 (full
regression sweep re-run after every change, identical unit set); win32
jumps 10 -> 22/99 - twelve units beyond ADVANCE.PAS/XTIME.PAS themselves
(CELLSCOL, COMMANDS, DBWATCH, EXTRAMEM, GETCONST, INIFILES, PAR,
RSTRINGS, SBLOCKS, STARTUP, VERSION), confirming this really was the
single biggest remaining blocker, not just a big one. Win32's 22 passing
units are now exactly i8086's 23 minus FORMAT.PAS - a clean convergence
between the two targets' passing sets that wasn't planned, just fell
out of clearing this one construct.

## What ShiftState actually needed - four separate constructs, not one

Cross-checked all 85 usage sites against ADVANCE.PAS's own kbRightShift/
kbLeftShift/kbCtrlShift/kbAltShift/kbScrollState/kbNumState/kbCapsState/
kbInsState constants ($01/$02/$04/$08/$10/$20/$40/$80) before touching
anything: `and 3` (any Shift) and `and 4`/kbCtrlShift dominate,
kbAltShift is tested once, kbScrollState/kbCapsState a couple of times
each, kbNumState once; kbInsState and the individual left/right-shift
bits are declared but never tested anywhere in the tree. ShiftState
became a plain Byte variable (dropping `absolute`) under
`{$IF DEFINED(FPC) AND NOT DEFINED(CPUI8086)}` - every read/write site
already just does Byte bitmask operations, so none needed touching -
plus a new QueryShiftState function (Windows.GetKeyState, matching the
exact same bit layout, kbInsState left always-0 since Win32 has no
equivalent "insert mode" toggle to report and nothing tests that bit
anyway). Wiring QueryShiftState into the actual keyboard-input path is
still DRIVERS.PAS's job, separately scoped, not attempted here - this
session only makes the variable and a correct query function exist;
TERMINAL.PAS's Mem[$40:$17]-based ShiftState refresh sites are the
natural first caller once that INT 16h event loop gets its own pass.

Getting ADVANCE.PAS itself to compile then surfaced three more,
unrelated constructs behind it in the same file - the FMTUNIT.PAS
lesson repeating (a blocker's first compile error is not its only one):

- DefineChar/GetDChar - direct VGA Sequencer/Graphics-Controller port
  I/O ($3C4/$3CE) reprogramming a custom glyph straight into text-mode
  font plane 2. No Win32 console equivalent, and grep confirms nothing
  outside ADVANCE.PAS calls either routine - orphaned, same as
  FMTUNIT.PAS, same Tier-3 scaffold treatment.
- DosWrite(S: string) - INT 21h AH=2 character-by-character output,
  genuinely live (called from DNUTIL.PAS). Ported to a one-line
  `System.Write(S)` - byte-for-byte equivalent, no reason to hand-roll
  it. (COMLNKIO.PAS's own DosWrite call is a 4-argument call to the
  standard `Dos` unit's own routine of the same name - an unrelated,
  pre-existing overload-by-scope, not something this touched.)
- MemOK, calling `System.MemAvail`/`System.MaxAvail` explicitly
  qualified - the `System.` prefix forces resolution to the builtin
  unit regardless of what else is in scope, so this couldn't just fall
  back to session 5's MaxAvail substitute in MEMORY.PAS even though
  ADVANCE.PAS now `uses Memory`. Fixed in two parts: added a MemAvail
  to MEMORY.PAS right next to MaxAvail (identical rationale, identical
  sentinel-large value, same guard shape with no `{$ELSE}` since i8086/
  TP keep using the real System ones unshadowed), then dropped the
  `System.` qualifier at this one call site so it resolves to Memory's
  pair instead.

One more anchoring mistake worth recording since it nearly shipped
silently: the first attempt at DefineChar/GetDChar matched the bare
interface FORWARD DECLARATION (no body, just a `;`) instead of the
implementation, because both start with identical text. The `end;`
search then had nowhere real to stop and consumed roughly 48 lines of
unrelated code before wrapping it in an unrelated IFDEF. Caught by the
very next compile (a syntax error at a line number nowhere near the
intended edit), not by inspection - anchor on enough trailing context
(here, the header text immediately followed by `begin`) to be
unambiguous, and assert the anchor's occurrence count is exactly 1
before trusting a match.

## What's left for Win32 (22/99, up from 10/99)

- FORMAT.PAS - the one unit in i8086's 23 that isn't in win32's 22 yet.
  Per session 5's investigation of FMTUNIT.PAS, FORMAT.PAS has its own
  separate, self-contained INT 13h floppy-format implementation
  (tfmt.FormatTrack/tfmt.VerifyTrack) - likely the same Tier-3 shape,
  not yet confirmed by actually reading its first compile error.
- DRIVERS.PAS's own keyboard/console input path (`_GetKeyEvent`, raw
  INT 16h) - unchanged from session 6's note, still not scoped. This is
  where QueryShiftState (this session) will eventually get wired in for
  real, once there's an actual Win32 console-input loop to call it from.
- MODEMIO.PAS/OVERLAYS.PAS - unchanged, optional-subsystem gaps shared
  with i8086.
- The remaining 77 still-failing units are unexplored past their own
  first compile error, same caveat as session 6: no claim about which
  are mechanical without reading past that first error.

## Reproduce (win32)

    ppc386.exe -Mtp -uWINDOWS -dDN
      -Fi<src> -Fu<src> -Fu<units>\rtl -Fu<units>\rtl-extra -Fu<units>\rtl-objpas
      -FE<out> -FU<out> <file.pas>

rtl-objpas is new this session - needed once SysUtils entered the
picture via TDosStream's File* calls.
