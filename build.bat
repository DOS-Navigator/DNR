@echo off
setlocal

set "ROOT=%~dp0"
set "BUILD_DIR=%ROOT%build"
set "DIST_DIR=%ROOT%dist"

if /I "%~1"=="clean" (
    echo Cleaning build directory...
    if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
    if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
    echo Cleaned build and dist directories.
    exit /b 0
)

echo Creating build directories...
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%BUILD_DIR%\units" mkdir "%BUILD_DIR%\units"
if not exist "%BUILD_DIR%\asm" mkdir "%BUILD_DIR%\asm"
if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"

echo.
echo === Step 1: Compiling Resource Compiler (RCP.PAS) ===
echo.
if not exist "%BUILD_DIR%\RCP.exe" (
    fpc -Twin32 -Pi386 -WC -Mtp -O2 -Xs -dWINDOWS -dDN -Fisrc/pascal -Fusrc/pascal -FEbuild -FUbuild/units "%ROOT%src\pascal\RCP.PAS" -o"%BUILD_DIR%\RCP.exe"
    if errorlevel 1 (
        echo ERROR: RCP compilation failed.
        exit /b 1
    )
)

echo.
echo === Step 2: Compiling English and Russian Resource Files ===
echo.
if not exist "%BUILD_DIR%\DN.DLG" (
    "%BUILD_DIR%\RCP.exe" "%ROOT%rcp.ini"
    if errorlevel 1 (
        echo ERROR: RCP compilation failed.
        exit /b 1
    )
)

echo.
echo === Step 3: Compiling Help Compiler (TVHC.PAS) and Building Help Files ===
echo.
if not exist "%BUILD_DIR%\TVHC.exe" (
    fpc -Twin32 -Pi386 -WC -Mtp -O2 -Xs -dWINDOWS -Fisrc/pascal -Fusrc/pascal -FEbuild -FUbuild/units "%ROOT%src\pascal\TVHC.PAS"
    if errorlevel 1 (
        echo ERROR: TVHC compilation failed.
        exit /b 1
    )
)
if not exist "%BUILD_DIR%\DN.HLP" (
    cmd.exe /c ""%BUILD_DIR%\TVHC.exe" "%ROOT%RESOURCE\ENGLISH\DNHELP.HTX" "%BUILD_DIR%\DN.HLP""
    if errorlevel 1 (
        echo ERROR: DN.HLP compilation failed.
        exit /b 1
    )
)
if not exist "%BUILD_DIR%\DNRUS.HLP" (
    cmd.exe /c ""%BUILD_DIR%\TVHC.exe" "%ROOT%RESOURCE\RUSSIAN\DNHELP.HTX" "%BUILD_DIR%\DNRUS.HLP""
    if errorlevel 1 (
        echo ERROR: DNRUS.HLP compilation failed.
        exit /b 1
    )
)

echo.
echo === Step 4: Generating Embedded Pascal Resource Include ===
echo.
python "%ROOT%generate_embedded_resources.py"
if errorlevel 1 (
    echo ERROR: Failed to generate embedded_resources.inc.
    exit /b 1
)

echo.
echo === Step 5: Building DOS Navigator (DN.PAS) Monolithic Binary ===
echo.
fpc -Twin32 -Pi386 -WC -Mtp -O2 -Xs -dWINDOWS -dDN -Fisrc/pascal -Fisrc/asm -Fusrc/pascal -Fubuild -Fubuild/units -Fubuild/asm -FEbuild -FUbuild/units "%ROOT%src\pascal\DN.PAS" -o"%BUILD_DIR%\dn.exe"
if errorlevel 1 (
    echo.
    echo ERROR: FPC compilation failed.
    exit /b 1
)

copy /y "%BUILD_DIR%\dn.exe" "%DIST_DIR%\dn.exe" >nul
copy /y "%BUILD_DIR%\DN.HLP" "%DIST_DIR%\DN.HLP" >nul
copy /y "%BUILD_DIR%\DNRUS.HLP" "%DIST_DIR%\DNRUS.HLP" >nul
copy /y "%ROOT%RESOURCE\DN.MNU" "%DIST_DIR%\DN.MNU" >nul

echo.
echo === Build succeeded ===
for %%F in ("%BUILD_DIR%\dn.exe") do (
    echo Build Output: %%~dpnxF
    echo Size:         %%~zF bytes
)
for %%F in ("%DIST_DIR%\dn.exe") do (
    echo Dist Output:  %%~dpnxF
    echo Size:         %%~zF bytes
)

endlocal
exit /b 0
