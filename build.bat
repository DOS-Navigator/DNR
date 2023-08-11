@echo off
setlocal

if "%~1" == "clean" (
    echo Cleaning build directory...
    rmdir /s /q build
    @REM nmake clean
    exit /b 0
)

echo Creating build directory...
if not exist build mkdir build

cd build
cmake -G "NMake Makefiles" ..
cmake --build .
@REM nmake
cd ..

endlocal
exit /b 0
