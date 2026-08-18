@echo off
REM ---------------------------------------------------------------------------
REM Transpile DNR's TASM sources to NASM and assemble them, natively on Windows.
REM
REM Requires:
REM   * nasm on PATH            (scoop install nasm)
REM   * t2nt.exe                (github.com/DOS-Navigator/T2NT, branch
REM                              mvp-native-windows; run its build.bat)
REM
REM Point T2NT at the transpiler if it is not on PATH:
REM   set T2NT=C:\path\to\T2NT\bin\t2nt.exe
REM
REM   build-asm.bat          - transpile + assemble into build\asm
REM   build-asm.bat clean    - remove build\asm
REM ---------------------------------------------------------------------------
setlocal EnableDelayedExpansion

set "ROOT=%~dp0"
set "SRC=%ROOT%src\asm"
set "OUT=%ROOT%build\asm"

if /I "%~1"=="clean" (
    if exist "%OUT%" rmdir /s /q "%OUT%"
    echo Cleaned %OUT%
    exit /b 0
)

if not defined T2NT set "T2NT=t2nt.exe"
where "%T2NT%" >nul 2>&1 || if not exist "%T2NT%" (
    echo ERROR: t2nt not found. Set T2NT to the built t2nt.exe, or put it on PATH.
    echo        See https://github.com/DOS-Navigator/T2NT
    exit /b 1
)

where nasm >nul 2>&1
if errorlevel 1 (
    echo ERROR: nasm not found on PATH.
    exit /b 1
)

if not exist "%OUT%" mkdir "%OUT%"

set /a OK=0
set /a BAD=0

for %%F in ("%SRC%\*.ASM") do (
    set "BASE=%%~nF"
    echo(
    echo === %%~nxF ===

    "%T2NT%" "%%F" "%OUT%\!BASE!.nasm"
    if errorlevel 4 (
        echo   transpile FAILED
        set /a BAD+=1
    ) else (
        REM A source with ORG is a .COM image; anything else is a linkable object.
        REM /B anchors to line start; t2nt emits `org` in column 0. Do not add
        REM /R here - /C: makes the pattern literal and silently wins over it.
        findstr /I /B /C:"org " "%OUT%\!BASE!.nasm" >nul 2>&1
        if errorlevel 1 (
            set "FMT=obj"
            set "EXT=obj"
        ) else (
            set "FMT=bin"
            set "EXT=com"
        )
        nasm -f !FMT! -o "%OUT%\!BASE!.!EXT!" "%OUT%\!BASE!.nasm"
        if errorlevel 1 (
            echo   assemble FAILED ^(-f !FMT!^)
            set /a BAD+=1
        ) else (
            echo   OK -^> !BASE!.!EXT! ^(-f !FMT!^)
            set /a OK+=1
        )
    )
)

echo(
echo ---------------------------------------------
echo  assembled OK : !OK!
echo  failed       : !BAD!
echo  output       : %OUT%
echo ---------------------------------------------

if !BAD! GTR 0 exit /b 1
exit /b 0
