# DOS Navigator Revived (DNR)

[![Platform: Windows (x86 32-bit)](https://img.shields.io/badge/platform-Windows%20x86--32-blue.svg)](https://github.com/DOS-Navigator/DNR)
[![Compiler: Free Pascal 3.2.2](https://img.shields.io/badge/compiler-Free%20Pascal%203.2.2-green.svg)](https://www.freepascal.org/)
[![License: Open Source](https://img.shields.io/badge/license-Open%20Source-orange.svg)](https://github.com/DOS-Navigator/DNR)

**DOS Navigator Revived (DNR)** is an ongoing engineering initiative modernizing the legendary **DOS Navigator** file manager and desktop work environment (originally created by Stefan Tanurkov, Dmitry Dotsenko, Andrew Zabolotny, and RIT Research Labs) into a native, modern, 32-bit Windows console application using exclusively Free and Open Source Software (FPC and NASM).

---

## Current Status (November 2026)

- **Native 32-bit Win32 PE Target**: Successfully builds and links `src/pascal/DN.PAS` into a native Windows console binary (`build/dn.exe`). No DOSBox, NTVDM, or 16-bit emulation required.
- **Modern Responsive Console TUI**: Fully responsive terminal layout supporting modern Windows Terminal, ConHost, and PTY environments:
  - **Dynamic Startup Viewport**: Automatically detects the active console buffer and window geometry (from standard 80×25 up to 300×150+).
  - **Live Resize Event Relayout**: Listens to Win32 `WINDOW_BUFFER_SIZE_EVENT` console events and dynamically resizes the view hierarchy (`TProgram`, `TDeskTop`, dual file panels `TDoubleWindow`, menu bar, command line, and status line).
  - **Dynamic Frame Buffering**: Eliminates legacy 80×50 (4,000 cell) limits and 16-bit `Word` size overflows via dynamic `LongInt` heap buffers.
- **Byte-Exact CP866 Preservation**: All source files and build pipelines enforce strict byte-exact single-byte encoding (`latin-1` byte stream) to preserve authentic CP866 extended ASCII box-drawing characters without UTF-8 corruption.
- **Automated TUI Testing**: Validated through headless PTY automation (`tools/surfaces/dn_surface.py` via `surfacekit`).

---

## Features & Modernization Highlights

* **Pure FLOSS Toolchain**: Built strictly using Free Pascal Compiler (FPC 3.2.2) and the Netwide Assembler (NASM 3.02+).
* **Direct Win32 Console API Integration**:
  - Console handles managed cleanly through `CONOUT$` and `CONIN$`.
  - Video rendering routed through `WriteConsoleOutputA` with dynamic `CharInfoBuf` allocation.
  - Keyboard and mouse events bridged to Win32 `ReadConsoleInputA`.
* **Legacy Borland Pascal 7 / Turbo Vision Compatibility**:
  - Provided flat 32-bit memory and heap compatibility shims (`PrefixSeg`, `HeapOrg`, `HeapEnd`, `HeapPtr`, `MemAvail`, `MaxAvail`).
  - Resolved namespace ambiguities between `Objects.TPoint` and `Windows.TPoint`.
  - Guarded 16-bit far-pointer inline assembly (`lds`/`les`) with 32-bit flat register operations.

---

## Prerequisites

1. **Free Pascal Compiler (FPC)**: Version 3.2.2 or later targeting `i386-win32` (`fpc.exe` / `ppc386.exe` on PATH).
2. **Netwide Assembler (NASM)**: Version 3.02 or later (`nasm.exe` on PATH).
3. **Operating System**: Windows 10, Windows 11, Windows Server, or Linux/macOS with Wine.

---

## Building from Source

### Quick Build (Windows Command Prompt or PowerShell)

Run the included automated build batch script:

```cmd
build.bat
```

The script compiles resources, builds assembly objects, compiles `src/pascal/DN.PAS`, and outputs the final standalone executable to `build/dn.exe`.

### Manual Compilation Command

To compile manually with FPC:

```cmd
fpc -Twin32 -Pi386 -WC -Mtp -O2 -Xs -dWINDOWS -dDN -Fisrc/pascal -Fisrc/asm -Fusrc/pascal -Fubuild -Fubuild/units -Fubuild/asm -FEbuild -FUbuild src/pascal/DN.PAS -o"build/dn.exe"
```

---

## Running DOS Navigator

Launch the compiled executable directly from any console (Windows Terminal, Command Prompt, or PowerShell):

```cmd
build\dn.exe
```

### Command-Line Arguments

```
Usage: dn [options]
  /?          Display help message
  /C<file>    Specify configuration file
  /S<dir>     Specify swap directory
  /P<file>    Specify palette file
  /NOXMS      Disable XMS memory
  /NOEMS      Disable EMS memory
```

---

## Automated TUI Testing

Automated testing is driven by the surface test utility in `tools/surfaces/dn_surface.py`:

```cmd
:: Run selftest (verifies startup landmark and clean Alt+X exit)
python tools/surfaces/dn_surface.py selftest

:: Capture the active screen layout across the current terminal dimensions
python tools/surfaces/dn_surface.py screen
```

---

## Repository Structure

```
DNR/
├── build/                 # Compiled binaries and unit output artifacts (.exe, .ppu, .o)
├── helpers/               # Legacy build and conversion utilities
├── resource/              # Binary resources, menus, and help definitions
├── src/
│   ├── asm/               # Assembly sources modernized for NASM / 32-bit
│   └── pascal/            # Turbo Pascal / Turbo Vision sources (DN.PAS, DRIVERS.PAS, etc.)
├── tools/
│   └── surfaces/          # TUI surface automation drivers (dn_surface.py)
├── build.bat              # One-click native Win32 build script
└── README.md              # Project documentation
```

---

## License & Credits

DOS Navigator was originally developed by RIT Research Labs (Stefan Tanurkov, Dmitry Dotsenko, Andrew Zabolotny) and open-sourced under the DOS Navigator Open Source License / GNU General Public License. See `PROGRESS_LOG.md` and source file headers for historical documentation and contributor credits.
