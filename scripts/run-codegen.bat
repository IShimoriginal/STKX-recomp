@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title Shutokou Battle X - ReXGlue AOT Codegen

cd /d "%~dp0.."

if exist "%CD%\tools\binutils" set "PATH=%CD%\tools\binutils;!PATH!"
if exist "C:\Program Files\Git\cmd" set "PATH=!PATH!;C:\Program Files\Git\cmd"
if exist "C:\Program Files\CMake\bin" set "PATH=!PATH!;C:\Program Files\CMake\bin"
if exist "C:\Program Files\LLVM\bin" set "PATH=!PATH!;C:\Program Files\LLVM\bin"
if not defined VSCMD_VER if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul 2>nul
)

if not exist "logs" mkdir "logs"
set "LOG_FILE=%CD%\logs\codegen_latest.log"

:: Initialize latest log file
type nul > "%LOG_FILE%"

echo ==============================================================================
echo   Shutokou Battle X [Tokyo Xtreme Racer] - ReXGlue Ahead-Of-Time Codegen
call :PRINT_CN "  \u9996\u90FD\u9AD8\u8D5B\u8F66X - ReXGlue \u9759\u6001\u91CD\u7F16\u8BD1\u4EE3\u7801\u751F\u6210\u5DE5\u5177"
echo   Root: %CD%
echo   Log:  %LOG_FILE%
echo ==============================================================================
echo.

echo [1/3] Checking game files...
set "SCRIPT_EXIT_CODE=0"
if not exist "game_root\default.xex" (
    echo [ERROR] Game executable not found: %CD%\game_root\default.xex
    echo Please make sure default.xex and DATA are placed in %CD%\game_root\
    call :PRINT_CN "[\u9519\u8BEF] \u672A\u627E\u5230 game_root\\default.xex\uFF0C\u8BF7\u786E\u4FDD\u5DF2\u653E\u5165\u6B63\u7248\u89E3\u5305\u7684 default.xex \u4E0E DATA \u76EE\u5F55\uFF01"
    set "SCRIPT_EXIT_CODE=1"
    goto :script_exit
)
echo   [OK] Found game executable: game_root\default.xex

echo.
echo [2/3] Checking dependencies and rexglue tool...
if /i not "%~2"=="--skip-check" (
    call "scripts\setup-game-assets.bat" --check-only
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] Environment or dependencies are incomplete. Please run scripts\setup-game-assets.bat first.
        call :PRINT_CN "[\u9519\u8BEF] \u73AF\u5883\u6216\u7B2C\u4E09\u65B9\u4F9D\u8D56\u5C1A\u672A\u5C31\u7EEA\uFF0C\u8BF7\u5148\u8FD0\u884C scripts\\setup-game-assets.bat \u5B8C\u6210\u5B89\u88C5\uFF01"
        set "SCRIPT_EXIT_CODE=1"
        goto :script_exit
    )
)

set "REXGLUE_BIN="
if exist "out\win-amd64\Release\rexglue.exe" set "REXGLUE_BIN=out\win-amd64\Release\rexglue.exe"
if not defined REXGLUE_BIN if exist "out\win-amd64\rexglue.exe" set "REXGLUE_BIN=out\win-amd64\rexglue.exe"
if not defined REXGLUE_BIN if exist "out\build\win-amd64\Release\rexglue.exe" set "REXGLUE_BIN=out\build\win-amd64\Release\rexglue.exe"
if not defined REXGLUE_BIN if exist "out\build\win-amd64\rexglue.exe" set "REXGLUE_BIN=out\build\win-amd64\rexglue.exe"
if not defined REXGLUE_BIN if exist "build\Release\rexglue.exe" set "REXGLUE_BIN=build\Release\rexglue.exe"
if not defined REXGLUE_BIN if exist "build\rexglue.exe" set "REXGLUE_BIN=build\rexglue.exe"
if not defined REXGLUE_BIN if exist "dist\rexglue.exe" set "REXGLUE_BIN=dist\rexglue.exe"
if not defined REXGLUE_BIN if exist "..\ShutokouBattleX\rexglue.exe" set "REXGLUE_BIN=..\ShutokouBattleX\rexglue.exe"

REM Ensure rexglue.exe is up to date with any source patches
if exist "out\build\win-amd64\build.ninja" (
    echo Checking rexglue.exe tool...
    cmake --build out/build/win-amd64 --config Release --target rexglue >> "%LOG_FILE%" 2>&1
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] Failed to update rexglue.exe. Check log: %LOG_FILE%
        call :PRINT_CN "[\u9519\u8BEF] \u66F4\u65B0\u6216\u6784\u5EFA rexglue.exe \u5931\u8D25\uFF0C\u8BF7\u67E5\u770B\u65E5\u5FD7\u6587\u4EF6\uFF01"
        powershell -NoProfile -Command "Get-Content '%LOG_FILE%' -Tail 25" 2>nul || type "%LOG_FILE%"
        set "SCRIPT_EXIT_CODE=1"
        goto :script_exit
    )
    if exist "out\win-amd64\Release\rexglue.exe" set "REXGLUE_BIN=out\win-amd64\Release\rexglue.exe"
    if not defined REXGLUE_BIN if exist "out\win-amd64\rexglue.exe" set "REXGLUE_BIN=out\win-amd64\rexglue.exe"
    if not defined REXGLUE_BIN if exist "out\build\win-amd64\Release\rexglue.exe" set "REXGLUE_BIN=out\build\win-amd64\Release\rexglue.exe"
    if not defined REXGLUE_BIN if exist "out\build\win-amd64\rexglue.exe" set "REXGLUE_BIN=out\build\win-amd64\rexglue.exe"
) else if not defined REXGLUE_BIN (
    echo Configuring CMake ^(LLVM Clang + Ninja^)...
    echo Logging to: %LOG_FILE%
    
    if exist "out\build\win-amd64\CMakeCache.txt" del /f /q "out\build\win-amd64\CMakeCache.txt" >nul 2>nul
    if exist "build\CMakeCache.txt" del /f /q "build\CMakeCache.txt" >nul 2>nul

    cmake --preset win-amd64 > "%LOG_FILE%" 2>&1
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] CMake configuration failed. Check log: %LOG_FILE%
        call :PRINT_CN "[\u9519\u8BEF] CMake \u914D\u7F6E\u5931\u8D25\uFF0C\u8BF7\u67E5\u770B\u65E5\u5FD7\u6587\u4EF6\uFF01"
        set "SCRIPT_EXIT_CODE=1"
        goto :script_exit
    )

    echo Building rexglue compiler...
    cmake --build out/build/win-amd64 --config Release --target rexglue >> "%LOG_FILE%" 2>&1
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] Failed to build rexglue.exe. Check log: %LOG_FILE%
        call :PRINT_CN "[\u9519\u8BEF] \u66F4\u65B0\u6216\u6784\u5EFA rexglue.exe \u5931\u8D25\uFF0C\u8BF7\u67E5\u770B\u65E5\u5FD7\u6587\u4EF6\uFF01"
        set "SCRIPT_EXIT_CODE=1"
        goto :script_exit
    )

    if exist "out\win-amd64\Release\rexglue.exe" (
        set "REXGLUE_BIN=out\win-amd64\Release\rexglue.exe"
    ) else if exist "out\win-amd64\rexglue.exe" (
        set "REXGLUE_BIN=out\win-amd64\rexglue.exe"
    ) else if exist "out\build\win-amd64\Release\rexglue.exe" (
        set "REXGLUE_BIN=out\build\win-amd64\Release\rexglue.exe"
    ) else if exist "out\build\win-amd64\rexglue.exe" (
        set "REXGLUE_BIN=out\build\win-amd64\rexglue.exe"
    ) else if exist "build\Release\rexglue.exe" (
        set "REXGLUE_BIN=build\Release\rexglue.exe"
    ) else if exist "build\rexglue.exe" (
        set "REXGLUE_BIN=build\rexglue.exe"
    ) else (
        echo [ERROR] rexglue.exe not found after build.
        call :PRINT_CN "[\u9519\u8BEF] \u7F16\u8BD1\u540E\u672A\u627E\u5230 rexglue.exe\uFF01"
        set "SCRIPT_EXIT_CODE=1"
        goto :script_exit
    )
)

echo   [OK] Recompiler ready: !REXGLUE_BIN!

echo.
echo [3/3] Generating Ahead-Of-Time C++ code for Shutokou Battle X...
echo Command: "!REXGLUE_BIN!" codegen manifest.toml --ignore-stamp
"!REXGLUE_BIN!" codegen manifest.toml --ignore-stamp
if !ERRORLEVEL! neq 0 (
    echo [ERROR] Codegen failed.
    call :PRINT_CN "[\u9519\u8BEF] AOT \u4EE3\u7801\u751F\u6210\u5931\u8D25\uFF01"
    set "SCRIPT_EXIT_CODE=1"
    goto :script_exit
)

echo.
echo ==============================================================================
echo [SUCCESS] AOT Codegen completed successfully.
call :PRINT_CN "[\u6210\u529F] AOT \u9759\u6001\u4EE3\u7801\u751F\u6210\u6210\u529F\uFF01\u4E0B\u4E00\u6B65\u8BF7\u8FD0\u884C: scripts\\build-windows.bat"
echo Generated C++ source files in: %CD%\src\generated\entrypoint\
echo Log saved to: %LOG_FILE%
echo Next step: run scripts\build-windows.bat
echo ==============================================================================

:script_exit
if /i not "%~1"=="--no-pause" (
    echo.
    call :PRINT_CN "\u8BF7\u6309 Enter \u952E\u5173\u95ED\u7A97\u53E3..."
    set /p "_EXIT_WAIT=Press Enter to close this window..."
)
exit /b %SCRIPT_EXIT_CODE%

:PRINT_CN
powershell -NoProfile -Command "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false); [Console]::WriteLine([regex]::Unescape('%~1'))"
exit /b 0
