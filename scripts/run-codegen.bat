@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

cd /d "%~dp0.."

if not exist "logs" mkdir "logs"
set "LOG_FILE=%CD%\logs\codegen_latest.log"

:: 清空或初始化最新日志文件
type nul > "%LOG_FILE%"

echo ==============================================================================
echo   Shutokou Battle X [Tokyo Xtreme Racer] - ReXGlue Ahead-Of-Time Codegen
echo   Root: %CD%
echo   Log:  %LOG_FILE%
echo ==============================================================================
echo.

echo [1/3] Checking game files...
if not exist "game_root\default.xex" (
    echo [ERROR] Game executable not found: %CD%\game_root\default.xex
    echo Please make sure default.xex and DATA are in %CD%\game_root\
    goto :script_exit
)
echo   [OK] Found game executable: game_root\default.xex

echo.
echo [2/3] Checking dependencies and rexglue tool...
if exist "scripts\download-dependencies.bat" (
    call "scripts\download-dependencies.bat"
)

set "REXGLUE_BIN="
if exist "out\win-amd64\Release\rexglue.exe" set "REXGLUE_BIN=out\win-amd64\Release\rexglue.exe"
if not defined REXGLUE_BIN if exist "out\win-amd64\rexglue.exe" set "REXGLUE_BIN=out\win-amd64\rexglue.exe"
if not defined REXGLUE_BIN if exist "out\build\win-amd64\Release\rexglue.exe" set "REXGLUE_BIN=out\build\win-amd64\Release\rexglue.exe"
if not defined REXGLUE_BIN if exist "out\build\win-amd64\rexglue.exe" set "REXGLUE_BIN=out\build\win-amd64\rexglue.exe"
if not defined REXGLUE_BIN if exist "build\Release\rexglue.exe" set "REXGLUE_BIN=build\Release\rexglue.exe"
if not defined REXGLUE_BIN if exist "build\rexglue.exe" set "REXGLUE_BIN=build\rexglue.exe"
if not defined REXGLUE_BIN if exist "dist\rexglue.exe" set "REXGLUE_BIN=dist\rexglue.exe"
if not defined REXGLUE_BIN if exist "D:\ShutokouBattleX\rexglue.exe" set "REXGLUE_BIN=D:\ShutokouBattleX\rexglue.exe"

REM Ensure rexglue.exe is up to date with any source patches
if exist "out\build\win-amd64\build.ninja" (
    echo Checking rexglue.exe tool...
    cmake --build out/build/win-amd64 --config Release --target rexglue >> "%LOG_FILE%" 2>&1
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] Failed to update rexglue.exe! Check log: %LOG_FILE%
        powershell -NoProfile -Command "Get-Content '%LOG_FILE%' -Tail 25" 2>nul || type "%LOG_FILE%"
        goto :script_exit
    )
    if exist "out\win-amd64\Release\rexglue.exe" set "REXGLUE_BIN=out\win-amd64\Release\rexglue.exe"
    if not defined REXGLUE_BIN if exist "out\win-amd64\rexglue.exe" set "REXGLUE_BIN=out\win-amd64\rexglue.exe"
    if not defined REXGLUE_BIN if exist "out\build\win-amd64\Release\rexglue.exe" set "REXGLUE_BIN=out\build\win-amd64\Release\rexglue.exe"
    if not defined REXGLUE_BIN if exist "out\build\win-amd64\rexglue.exe" set "REXGLUE_BIN=out\build\win-amd64\rexglue.exe"
) else if not defined REXGLUE_BIN (
    echo Configuring CMake (LLVM Clang + Ninja)...
    echo Logging to: %LOG_FILE%
    
    if exist "out\build\win-amd64\CMakeCache.txt" del /f /q "out\build\win-amd64\CMakeCache.txt" >nul 2>nul
    if exist "build\CMakeCache.txt" del /f /q "build\CMakeCache.txt" >nul 2>nul

    cmake --preset win-amd64 > "%LOG_FILE%" 2>&1
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] CMake configuration failed!
        echo Check log: %LOG_FILE%
        goto :script_exit
    )

    echo Building rexglue compiler...
    cmake --build out/build/win-amd64 --config Release --target rexglue >> "%LOG_FILE%" 2>&1
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] Failed to build rexglue.exe!
        echo Check log: %LOG_FILE%
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
        goto :script_exit
    )
)

echo   [OK] Recompiler ready: !REXGLUE_BIN!

echo.
echo [3/3] Generating Ahead-Of-Time C++ code for Shutokou Battle X...
echo Command: "!REXGLUE_BIN!" codegen manifest.toml --ignore-stamp
"!REXGLUE_BIN!" codegen manifest.toml --ignore-stamp
if !ERRORLEVEL! neq 0 (
    echo [ERROR] Codegen failed!
    goto :script_exit
)

echo.
echo ==============================================================================
echo [SUCCESS] AOT Codegen completed successfully!
echo Generated C++ source files in: %CD%\src\generated\entrypoint\
echo Log saved to: %LOG_FILE%
echo Next step: run scripts\build-windows.bat
echo ==============================================================================

:script_exit
echo.
pause
