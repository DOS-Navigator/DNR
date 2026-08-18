# Progress Log: DOS Navigator Modernization

This document logs the progress and challenges encountered during the effort to modernize the DOS Navigator codebase.

## Initial Goal

The primary objective was to update the DNR source code to be compilable with modern, open-source tools, specifically the FreePascal Compiler (FPC) and the Netwide Assembler (NASM), with the ultimate goal of producing a 16-bit DOS executable.

## Phase 1: Assembly Code Conversion

Significant progress was made in converting the original Turbo Assembler (TASM) files to NASM syntax.

### Key Successes:
*   **`_MHZ.ASM` -> `_MHZ.nasm`**: Successfully converted and assembled into a flat binary (`.bin`) file. This module handles CPU frequency detection.
*   **`VGA33.ASM` -> `VGA33.nasm`**: Successfully converted and assembled into a standalone `.com` executable. This module handles direct VGA register manipulation for setting a video mode.
*   **`SYSINT.ASM` -> `SYSINT.nasm`**: This was the most complex assembly module, responsible for hooking system interrupts.
    *   The conversion required significant effort to handle TASM's `GROUP` and `ASSUME` directives, which are not directly supported in NASM.
    *   The initial approach of using NASM's `obj` format-specific directives (`group`, `assume`) failed due to issues with the assembler's TASM compatibility mode in the execution environment.
    *   **Successful Workaround:** A robust solution was implemented by saving the data segment register (`DS`) at runtime during the module's initialization call from Pascal, and then restoring it within the interrupt handlers. This is a standard and reliable technique for writing modular interrupt handlers.
    *   The file was successfully assembled into a linkable object file (`.obj`).

## Phase 2: Pascal Code Conversion & Toolchain Investigation

This phase was marked by a persistent and ultimately insurmountable series of issues with the provided development environment's toolchain.

### The Goal:
The plan was to perform a bottom-up conversion of the Pascal units, starting with dependency-free units like `OBJTYPE.PAS` and compiling them for the target platform.

### The Problem: A Chronology of Failures

The core issue was the inability to compile *any* Pascal code for the target platform, or even for a modern Linux fallback target.

1.  **Initial DOS Target Failure:**
    *   **Command:** `fpc -Tdos ...`
    *   **Error:** `Error: Illegal parameter: -Tdos`
    *   **Investigation:** This error indicated that the FPC installation was missing the cross-compiler for the 16-bit DOS target.

2.  **Attempt to Install DOS Cross-Compiler:**
    *   **Action:** Searched for `fpc-target-dos` and similar packages in the `apt` repository.
    *   **Result:** No such packages were found.

3.  **Pivot 1: Building the Cross-Compiler from Source:**
    *   **Action:** Installed `fpc-source` and attempted to build the `i8086-dos` cross-compiler using the standard `make crossinstall` command.
    *   **Error:** `make: *** No rule to make target 'crossinstall'. Stop.`
    *   **Investigation:** Discovered that the `Makefile.fpc` provided by the Debian `fpc-source` package is not a standard Makefile and does not contain this target.

4.  **Pivot 2: Using DJGPP as a Backend (User Suggestion):**
    *   **Action:** Attempted to follow user instructions to install `djgpp` and `dosemu` and configure FPC to use them.
    *   **Error:** The `djgpp` and `dosemu` packages were not available in the repository.
    *   **Workaround:** Found and installed `binutils-djgpp`. Created a local `fpc.cfg` file pointing to the DJGPP binutils prefix.

5.  **Renewed Compilation Attempt (DOS Target):**
    *   **Action:** Tried to compile `OBJTYPE.PAS` with the new configuration.
    *   **Error:** `Error: ppc8086 can't be executed, error code: 127`
    *   **Investigation:** Confirmed that the `ppc8086` compiler binary, which is required for this to work, was not installed on the system. This made the DJGPP approach a dead end.

6.  **Pivot 3: Targeting Modern Linux as a Fallback:**
    *   **Action:** Abandoned the DOS target for the moment and tried to compile a simple unit (`OBJTYPE.PAS`) for the native Linux environment. This should have been a trivial operation.
    *   **Error:** `Fatal: Cannot open file "OBJTYPE.PAS"`
    *   **Investigation:** This was the most critical and revealing failure. The `fpc` compiler, when run from the project root, could not find the source file at `src/pascal/OBJTYPE.PAS`.

7.  **Final Workaround Attempts (Linux Target):**
    *   **`cd` command:** `cd src/pascal` failed with `No such file or directory`.
    *   **`cp` command:** `cp src/pascal/OBJTYPE.PAS .` failed with `No such file or directory`.
    *   **Conclusion:** This revealed a fundamental inconsistency in the environment. The `ls` and `read_file` tools could see the file system correctly, but the tools in the `run_in_bash_session` sandbox (`fpc`, `cp`, `cd`) could not.

## Current Status: Blocked

The project is currently blocked due to a non-functional and inconsistent development environment. It is impossible to compile any Pascal code, which is the core requirement of the modernization task.

**The key blocking issue is the file system inconsistency.** The compiler cannot see the source files, making it impossible to proceed.

## Next Steps

The environment must be repaired to provide the following before work can continue:
1.  A functional file system where all tools can consistently see and access all files within the repository.
2.  A working FreePascal Compiler installation that is capable of compiling for, at a minimum, the native Linux target, and ideally, the i8086-dos cross-compilation target.

---

# Update 2026-08-18: unblocked on native Windows

The blockage recorded above was environmental, not intrinsic. Re-run on a
native Windows 11 host (no WSL, Cygwin, MSYS or DOSBox), every blocker
listed under "Current Status: Blocked" is resolved.

## 1. Filesystem inconsistency - not reproducible

Did not occur. All tools see the repository consistently.

## 2. `ppc8086` - obtained and working

The missing i8086 cross-compiler is distributed as a prebuilt installer,
so neither `make crossinstall` nor DJGPP is needed:

    fpc-3.2.2.i386-win32.cross.i8086-msdos.exe   (169 MB, SourceForge)

It installs `ppcross8086.exe` (note the name - it is *not* `ppc8086.exe`)
plus 24 sets of RTL units covering `tiny/small/medium/compact/large/huge`
for 8086/80186/80286/80386, and it bundles its own `nasm.exe`, which FPC
uses as the i8086 assembler.

**Verified**: a Pascal program compiles to a genuine 16-bit DOS `MZ`
executable (MZ magic present, no PE signature).

Three things that are easy to get wrong, each of which produces a
misleading error:

* Units live in an `rtl` **subdirectory** of the model directory. Pointing
  `-Fu` at the model directory itself gives `Can't find unit system`.
* `-XX` (smart linking) is **mandatory**. The RTL ships `.a` archives, so
  without it the link fails with `Can't open object file: system.o`, which
  reads like a missing file rather than a missing flag.
* FPC's own `nasm.exe` must be on `PATH`.

Working invocation and the full toolchain table are in `TOOLCHAIN.md`.

## 3. Assembly conversion is now automated

The hand conversions recorded above (`_MHZ`, `VGA33`, `SYSINT`) are
superseded by a working transpiler:
[DOS-Navigator/T2NT](https://github.com/DOS-Navigator/T2NT), branch
`mvp-native-windows`.

All ten TASM modules transpile; two (`VGA33`, `_MHZ`) currently assemble
clean under NASM 3.02. The transpiler's `VGA33` output is **byte-identical
(SHA-256)** to the hand-converted `VGA33.com` committed on this branch,
which is what validates the approach.

Run `build-asm.bat` to regenerate and assemble everything.

## Revised next steps

1. Close the remaining T2NT gaps until all ten modules assemble
   (see `STATUS.md` in that repository).
2. Build DN for **i8086-msdos** first, now that the compiler works. This
   validates that the Turbo Pascal sources compile at all under FPC.
3. Only then port to native Win32. DN is Turbo Pascal 7 + Turbo Vision in
   16-bit real mode: 99 units on `Objects`/`Views`/`Drivers`/`Dialogs` and
   `Dos`, with direct video memory access and interrupt calls. Targeting
   Win32 means porting to Free Vision and replacing every DOS dependency -
   a porting project, not a build-configuration change.

Attempting step 3 before step 2 means debugging a port and a toolchain
simultaneously.
