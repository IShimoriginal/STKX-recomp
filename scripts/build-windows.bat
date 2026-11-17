@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title Shutokou Battle X - Windows Native Builder / Windows 原生编译构建工具

cd /d "%~dp0.."

if not exist "logs" mkdir "logs"
set "LOG_FILE=%CD%\logs\build_latest.log"

:: Initialize latest log file
type nul > "%LOG_FILE%"

echo ==============================================================================
echo   Shutokou Battle X [首都高赛车X] - Windows Native Builder
echo   Windows Native Executable ^& Launcher Builder / Windows 原生程序编译构建工具
echo   Root / 根目录: %CD%
echo   Log  / 日志  : %LOG_FILE%
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
    echo [WARNING] Missing src\generated\entrypoint sources. / 未检测到已生成的入口源码。
    echo If codegen has not run yet, run: scripts\run-codegen.bat
    echo 若尚未执行代码生成，请先运行: scripts\run-codegen.bat
    echo.
)

echo [1/3] Configuring CMake (LLVM Clang + Ninja)...
echo Logging to: %LOG_FILE%

cmake --preset win-amd64 -DREXGLUE_USE_D3D12=ON -DREXGLUE_USE_VULKAN=ON -DREXGLUE_ENABLE_FIDELITYFX=ON > "%LOG_FILE%" 2>&1
if !ERRORLEVEL! neq 0 (
    echo [ERROR] CMake configuration failed. / CMake 配置失败！
    echo Check log / 请检查日志: %LOG_FILE%
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
    echo [ERROR] Failed to build rexglue.exe! / 编译 rexglue.exe 失败！
    echo Check log / 请检查日志: %LOG_FILE%
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
if not defined REXGLUE_EXEC if exist "D:\ShutokouBattleX\rexglue.exe" set "REXGLUE_EXEC=D:\ShutokouBattleX\rexglue.exe"

if not defined REXGLUE_EXEC (
    echo [ERROR] rexglue.exe not found. Cannot synchronize manifest.toml.
    echo [错误]  未找到 rexglue.exe，无法同步 manifest.toml！
    goto :script_exit
)

echo [Codegen] Translating PPC functions via !REXGLUE_EXEC!...
"!REXGLUE_EXEC!" codegen manifest.toml --ignore-stamp
if !ERRORLEVEL! neq 0 (
    echo [ERROR] Codegen failed. Refusing to build stale generated files.
    echo [错误]  代码生成失败！已中止编译以避免使用过期源码。
    goto :script_exit
)
echo [OK] Codegen synchronized successfully.
if exist "D:\ShutokouBattleX" (
    copy /y "!REXGLUE_EXEC!" "D:\ShutokouBattleX\rexglue.exe" >nul 2>nul
)

REM Refresh CMake configuration so any newly generated sources.cmake entries are included
cmake --preset win-amd64 >> "%LOG_FILE%" 2>&1
if !ERRORLEVEL! neq 0 (
    echo [ERROR] CMake reconfiguration after codegen failed. Check %LOG_FILE%
    echo [错误]  代码生成后重新配置 CMake 失败！请查看 %LOG_FILE%
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
    echo [ERROR] Build failed. / 编译失败！请检查日志: %LOG_FILE%
    goto :script_exit
)

echo.
echo ==============================================================================
echo [SUCCESS] Build completed successfully. / 编译构建成功完成！

set "OUT_EXE="
if exist "out\win-amd64\Release\shutokou_battle_x.exe" set "OUT_EXE=out\win-amd64\Release\shutokou_battle_x.exe"
if not defined OUT_EXE if exist "out\win-amd64\shutokou_battle_x.exe" set "OUT_EXE=out\win-amd64\shutokou_battle_x.exe"
if not defined OUT_EXE if exist "out\build\win-amd64\Release\shutokou_battle_x.exe" set "OUT_EXE=out\build\win-amd64\Release\shutokou_battle_x.exe"
if not defined OUT_EXE if exist "out\build\win-amd64\shutokou_battle_x.exe" set "OUT_EXE=out\build\win-amd64\shutokou_battle_x.exe"
if not defined OUT_EXE if exist "build\Release\shutokou_battle_x.exe" set "OUT_EXE=build\Release\shutokou_battle_x.exe"
if not defined OUT_EXE if exist "build\shutokou_battle_x.exe" set "OUT_EXE=build\shutokou_battle_x.exe"

if defined OUT_EXE (
    echo Executable / 可执行文件: %CD%\!OUT_EXE!

    REM Auto-deploy to D:\ShutokouBattleX if directory exists
    if exist "D:\ShutokouBattleX" (
        echo Syncing updated binary and DLLs to D:\ShutokouBattleX\...
        copy /y "!OUT_EXE!" "D:\ShutokouBattleX\" >nul 2>nul
        if exist "out\win-amd64\Release\rexruntime.dll" copy /y "out\win-amd64\Release\rexruntime.dll" "D:\ShutokouBattleX\" >nul 2>nul
        if exist "out\win-amd64\Release\rexgpu-xenos.dll" copy /y "out\win-amd64\Release\rexgpu-xenos.dll" "D:\ShutokouBattleX\" >nul 2>nul
        if exist "out\win-amd64\Release\rexglue.exe" copy /y "out\win-amd64\Release\rexglue.exe" "D:\ShutokouBattleX\" >nul 2>nul
        if exist "out\win-amd64\Release\*.dll" copy /y "out\win-amd64\Release\*.dll" "D:\ShutokouBattleX\" >nul 2>nul
        if exist "out\win-amd64\Release\Launcher.exe" copy /y "out\win-amd64\Release\Launcher.exe" "D:\ShutokouBattleX\Launcher.exe" >nul 2>nul
        echo @echo off > "D:\ShutokouBattleX\launch-game.bat"
        echo cd /d "%%~dp0" >> "D:\ShutokouBattleX\launch-game.bat"
        echo start "" "%%~dp0shutokou_battle_x.exe" >> "D:\ShutokouBattleX\launch-game.bat"
        echo [OK] Updated shutokou_battle_x.exe, Launcher.exe, rexruntime.dll, rexgpu-xenos.dll in D:\ShutokouBattleX\
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
echo Log file / 日志文件: %LOG_FILE%
echo ==============================================================================

:script_exit
echo.
set /p "_EXIT_WAIT=Press Enter to close this window / 请按 Enter 键关闭窗口..."
