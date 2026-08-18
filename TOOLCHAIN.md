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
