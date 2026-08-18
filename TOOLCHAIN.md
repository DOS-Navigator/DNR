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
