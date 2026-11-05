@echo off
setlocal

set "ROOT=%~dp0"
set "BUILD_DIR=%ROOT%build"

if /I "%~1"=="clean" (
    echo Cleaning build directory...
    if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
    echo Cleaned %BUILD_DIR%
    exit /b 0
)

echo Creating build directory...
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%BUILD_DIR%\units" mkdir "%BUILD_DIR%\units"
if not exist "%BUILD_DIR%\asm" mkdir "%BUILD_DIR%\asm"

echo.
echo === Building DOS Navigator (DN.PAS) for native Win32 (FPC) ===
echo.

fpc -Twin32 -Pi386 -WC -Mtp -O2 -Xs -dWINDOWS -dDN -Fisrc/pascal -Fisrc/asm -Fusrc/pascal -Fubuild -Fubuild/units -Fubuild/asm -FEbuild -FUbuild/units "%ROOT%src\pascal\DN.PAS" -o"%BUILD_DIR%\dn.exe"
if errorlevel 1 (
    echo.
    echo ERROR: FPC compilation failed.
    exit /b 1
)

echo.
echo === Build succeeded ===
for %%F in ("%BUILD_DIR%\dn.exe") do (
    echo Output: %%~dpnxF
    echo Size:   %%~zF bytes
)

endlocal
exit /b 0
