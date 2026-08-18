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
