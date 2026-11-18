@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title Shutokou Battle X - Windows Native Builder

cd /d "%~dp0.."

if exist "%CD%\tools\binutils" set "PATH=%CD%\tools\binutils;!PATH!"
if exist "C:\Program Files\Git\cmd" set "PATH=!PATH!;C:\Program Files\Git\cmd"
if exist "C:\Program Files\CMake\bin" set "PATH=!PATH!;C:\Program Files\CMake\bin"
if exist "C:\Program Files\LLVM\bin" set "PATH=!PATH!;C:\Program Files\LLVM\bin"
if not defined VSCMD_VER if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul 2>nul
)

set "SCRIPT_EXIT_CODE=0"

if not exist "logs" mkdir "logs"
set "LOG_FILE=%CD%\logs\build_latest.log"

:: Initialize latest log file
type nul > "%LOG_FILE%"

echo ==============================================================================
echo   Shutokou Battle X - Windows Native Builder
call :PRINT_CN "  \u9996\u90FD\u9AD8\u8D5B\u8F66X - Windows \u539F\u751F\u7A0B\u5E8F\u7F16\u8BD1\u6784\u5EFA\u5DE5\u5177"
echo   Root: %CD%
echo   Log:  %LOG_FILE%
echo ==============================================================================
echo.

set "REXGLUE_EXEC="
if exist "out\win-amd64\Release\rexglue.exe" set "REXGLUE_EXEC=out\win-amd64\Release\rexglue.exe"
if not defined REXGLUE_EXEC if exist "out\win-amd64\rexglue.exe" set "REXGLUE_EXEC=out\win-amd64\rexglue.exe"
if not defined REXGLUE_EXEC if exist "out\build\win-amd64\Release\rexglue.exe" set "REXGLUE_EXEC=out\build\win-amd64\Release\rexglue.exe"
if not defined REXGLUE_EXEC if exist "out\build\win-amd64\rexglue.exe" set "REXGLUE_EXEC=out\build\win-amd64\rexglue.exe"
if not defined REXGLUE_EXEC if exist "build\Release\rexglue.exe" set "REXGLUE_EXEC=build\Release\rexglue.exe"
if not defined REXGLUE_EXEC if exist "build\rexglue.exe" set "REXGLUE_EXEC=build\rexglue.exe"
if not defined REXGLUE_EXEC if exist "dist\rexglue.exe" set "REXGLUE_EXEC=dist\rexglue.exe"

if defined REXGLUE_EXEC (
    echo [0/2] Syncing recompiled functions from manifest.toml via !REXGLUE_EXEC!...
    "!REXGLUE_EXEC!" codegen manifest.toml --ignore-stamp >> "%LOG_FILE%" 2>&1
) else if not exist "src\generated\entrypoint\shutokou_battle_x_init.h" (
    echo [WARNING] Missing src\generated\entrypoint sources.
    echo If codegen has not run yet, run: scripts\run-codegen.bat
    call :PRINT_CN "[\u63D0\u793A] \u672A\u68C0\u6D4B\u5230\u5DF2\u751F\u6210\u7684\u5165\u53E3\u6E90\u7801\uFF0C\u82E5\u5C1A\u672A\u6267\u884C\u4EE3\u7801\u751F\u6210\uFF0C\u8BF7\u5148\u8FD0\u884C: scripts\\run-codegen.bat"
    echo.
)

echo [1/3] Configuring CMake (LLVM Clang + Ninja)...
echo Logging to: %LOG_FILE%

cmake --preset win-amd64 -DREXGLUE_USE_D3D12=ON -DREXGLUE_USE_VULKAN=ON -DREXGLUE_ENABLE_FIDELITYFX=ON > "%LOG_FILE%" 2>&1
if !ERRORLEVEL! neq 0 (
    echo [ERROR] CMake configuration failed.
    echo Check log: %LOG_FILE%
    call :PRINT_CN "[\u9519\u8BEF] CMake \u914D\u7F6E\u5931\u8D25\uFF0C\u8BF7\u67E5\u770B\u65E5\u5FD7\u6587\u4EF6\uFF01"
    echo.
    echo --- Error Summary ---
    powershell -NoProfile -Command "Get-Content '%LOG_FILE%' -Tail 25" 2>nul || type "%LOG_FILE%"
    goto :script_exit
)

echo.
echo [2/3] Checking recompiler toolchain and syncing codegen...
echo Updating rexglue recompiler tool...
cmake --build out/build/win-amd64 --config Release --target rexglue >> "%LOG_FILE%" 2>&1
if !ERRORLEVEL! neq 0 (
    echo [ERROR] Failed to build rexglue.exe.
    echo Check log: %LOG_FILE%
    call :PRINT_CN "[\u9519\u8BEF] \u66F4\u65B0\u6216\u6784\u5EFA rexglue.exe \u5931\u8D25\uFF0C\u8BF7\u67E5\u770B\u65E5\u5FD7\u6587\u4EF6\uFF01"
    echo.
    echo --- Error Summary ---
    powershell -NoProfile -Command "Get-Content '%LOG_FILE%' -Tail 25" 2>nul || type "%LOG_FILE%"
    goto :script_exit
)

set "REXGLUE_EXEC="
if exist "out\win-amd64\Release\rexglue.exe" set "REXGLUE_EXEC=out\win-amd64\Release\rexglue.exe"
if not defined REXGLUE_EXEC if exist "out\win-amd64\rexglue.exe" set "REXGLUE_EXEC=out\win-amd64\rexglue.exe"
if not defined REXGLUE_EXEC if exist "out\build\win-amd64\Release\rexglue.exe" set "REXGLUE_EXEC=out\build\win-amd64\Release\rexglue.exe"
if not defined REXGLUE_EXEC if exist "out\build\win-amd64\rexglue.exe" set "REXGLUE_EXEC=out\build\win-amd64\rexglue.exe"
if not defined REXGLUE_EXEC if exist "build\Release\rexglue.exe" set "REXGLUE_EXEC=build\Release\rexglue.exe"
if not defined REXGLUE_EXEC if exist "build\rexglue.exe" set "REXGLUE_EXEC=build\rexglue.exe"
if not defined REXGLUE_EXEC if exist "dist\rexglue.exe" set "REXGLUE_EXEC=dist\rexglue.exe"
if not defined REXGLUE_EXEC if exist "..\ShutokouBattleX\rexglue.exe" set "REXGLUE_EXEC=..\ShutokouBattleX\rexglue.exe"

if not defined REXGLUE_EXEC (
    echo [ERROR] rexglue.exe not found. Cannot synchronize manifest.toml.
    call :PRINT_CN "[\u9519\u8BEF] \u672A\u627E\u5230 rexglue.exe\uFF0C\u65E0\u6CD5\u540C\u6B65 manifest.toml\uFF01"
    goto :script_exit
)

echo [Codegen] Translating PPC functions via !REXGLUE_EXEC!...
"!REXGLUE_EXEC!" codegen manifest.toml --ignore-stamp
if !ERRORLEVEL! neq 0 (
    echo [ERROR] Codegen failed. Refusing to build stale generated files.
    call :PRINT_CN "[\u9519\u8BEF] \u4EE3\u7801\u751F\u6210\u5931\u8D25\uFF01\u5DF2\u4E2D\u6B62\u7F16\u8BD1\u4EE5\u907F\u514D\u4F7F\u7528\u8FC7\u671F\u6E90\u7801\u3002"
    goto :script_exit
)
echo [OK] Codegen synchronized successfully.
if exist "..\ShutokouBattleX" (
    copy /y "!REXGLUE_EXEC!" "..\ShutokouBattleX\rexglue.exe" >nul 2>nul
)

REM Refresh CMake configuration so any newly generated sources.cmake entries are included
cmake --preset win-amd64 >> "%LOG_FILE%" 2>&1
if !ERRORLEVEL! neq 0 (
    echo [ERROR] CMake reconfiguration after codegen failed. Check %LOG_FILE%
    call :PRINT_CN "[\u9519\u8BEF] \u4EE3\u7801\u751F\u6210\u540E\u91CD\u65B0\u914D\u7F6E CMake \u5931\u8D25\uFF0C\u8BF7\u67E5\u770B\u65E5\u5FD7\u6587\u4EF6\uFF01"
    powershell -NoProfile -Command "Get-Content '%LOG_FILE%' -Tail 25" 2>nul || type "%LOG_FILE%"
    goto :script_exit
)

echo.
echo [3/3] Compiling Windows Native Targets (shutokou_battle_x, Launcher, rexruntime, rexgpu-xenos)...

REM Clean stale PCH caches to prevent Clang mtime mismatch
if exist "out\build\win-amd64\src\codegen\CMakeFiles\rexcodegen.dir\Release\cmake_pch.hxx.pch" (
    del /f /q "out\build\win-amd64\src\codegen\CMakeFiles\rexcodegen.dir\Release\cmake_pch.hxx.pch" >nul 2>nul
)
if exist "out\build\win-amd64\src\ui\CMakeFiles\rexui.dir\Release\cmake_pch.hxx.pch" (
    del /f /q "out\build\win-amd64\src\ui\CMakeFiles\rexui.dir\Release\cmake_pch.hxx.pch" >nul 2>nul
)

cmake --build out/build/win-amd64 --config Release --target shutokou_battle_x Launcher rexruntime rexgpu-xenos --parallel
if !ERRORLEVEL! neq 0 (
    echo Retrying sequential link...
    cmake --build out/build/win-amd64 --config Release --target shutokou_battle_x Launcher rexruntime rexgpu-xenos
)
if !ERRORLEVEL! neq 0 (
    echo [ERROR] Build failed. Check log: %LOG_FILE%
    call :PRINT_CN "[\u9519\u8BEF] \u7F16\u8BD1\u5931\u8D25\uFF01\u8BF7\u68C0\u67E5\u65E5\u5FD7\u6587\u4EF6\uFF01"
    set "SCRIPT_EXIT_CODE=1"
    goto :script_exit
)

echo.
echo ==============================================================================
echo [SUCCESS] Build completed successfully.
call :PRINT_CN "[\u6210\u529F] \u7F16\u8BD1\u6784\u5EFA\u6210\u529F\u5B8C\u6210\uFF01"

set "OUT_EXE="
if exist "out\win-amd64\Release\shutokou_battle_x.exe" set "OUT_EXE=out\win-amd64\Release\shutokou_battle_x.exe"
if not defined OUT_EXE if exist "out\win-amd64\shutokou_battle_x.exe" set "OUT_EXE=out\win-amd64\shutokou_battle_x.exe"
if not defined OUT_EXE if exist "out\build\win-amd64\Release\shutokou_battle_x.exe" set "OUT_EXE=out\build\win-amd64\Release\shutokou_battle_x.exe"
if not defined OUT_EXE if exist "out\build\win-amd64\shutokou_battle_x.exe" set "OUT_EXE=out\build\win-amd64\shutokou_battle_x.exe"
if not defined OUT_EXE if exist "build\Release\shutokou_battle_x.exe" set "OUT_EXE=build\Release\shutokou_battle_x.exe"
if not defined OUT_EXE if exist "build\shutokou_battle_x.exe" set "OUT_EXE=build\shutokou_battle_x.exe"

if defined OUT_EXE (
    echo Executable: %CD%\!OUT_EXE!

    REM Auto-deploy to ..\ShutokouBattleX if sibling directory exists
    if exist "..\ShutokouBattleX" (
        echo Syncing updated binary and DLLs to ..\ShutokouBattleX\...
        copy /y "!OUT_EXE!" "..\ShutokouBattleX\" >nul 2>nul
        if exist "out\win-amd64\Release\rexruntime.dll" copy /y "out\win-amd64\Release\rexruntime.dll" "..\ShutokouBattleX\" >nul 2>nul
        if exist "out\win-amd64\Release\rexgpu-xenos.dll" copy /y "out\win-amd64\Release\rexgpu-xenos.dll" "..\ShutokouBattleX\" >nul 2>nul
        if exist "out\win-amd64\Release\rexglue.exe" copy /y "out\win-amd64\Release\rexglue.exe" "..\ShutokouBattleX\" >nul 2>nul
        if exist "out\win-amd64\Release\*.dll" copy /y "out\win-amd64\Release\*.dll" "..\ShutokouBattleX\" >nul 2>nul
        if exist "out\win-amd64\Release\Launcher.exe" copy /y "out\win-amd64\Release\Launcher.exe" "..\ShutokouBattleX\Launcher.exe" >nul 2>nul
        echo @echo off > "..\ShutokouBattleX\launch-game.bat"
        echo cd /d "%%~dp0" >> "..\ShutokouBattleX\launch-game.bat"
        echo start "" "%%~dp0shutokou_battle_x.exe" >> "..\ShutokouBattleX\launch-game.bat"
        echo [OK] Updated shutokou_battle_x.exe, Launcher.exe, rexruntime.dll, rexgpu-xenos.dll in ..\ShutokouBattleX\
    )

    if exist "..\ShutokouBattleX\" if not exist "..\ShutokouBattleX\game_root\" if exist "game_root\" (
        echo Syncing game_root to ..\ShutokouBattleX\game_root\...
        xcopy /e /i /y /q "game_root" "..\ShutokouBattleX\game_root" >nul
        if !ERRORLEVEL! equ 0 (
            echo [OK] Copied game_root contents to ..\ShutokouBattleX\game_root\
        ) else (
            echo [WARNING] Failed to copy game_root to ..\ShutokouBattleX\game_root\
        )
    )
)

echo.
echo Features ready:
echo   - Direct3D 12 ^& Vulkan Native Rendering + FSR 1 Upscaling
echo   - Native Win32 GUI Launcher (Launcher.exe)
echo   - Zero-page memory protection fix (null dereference immunity)
echo   - Full indirect call table for entrypoint functions
echo   - Dynamic physical delta timing (stable high speed physics)
echo.
echo Log file: %LOG_FILE%
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
