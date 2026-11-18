@chcp 65001 >nul
@echo off
setlocal enabledelayedexpansion
title Shutokou Battle X - One-Click Setup Wizard

cd /d "%~dp0"

echo ==============================================================================
echo   Shutokou Battle X - One-Click Setup ^& Build Wizard
call :PRINT_CN "  \u9996\u90FD\u9AD8\u8D5B\u8F66X - \u4E00\u952E\u5B89\u88C5\u4E0E\u7F16\u8BD1\u5411\u5BFC"
echo   Root: %CD%
echo ==============================================================================
echo.

REM Offer to create sibling ..\ShutokouBattleX folder if not present
if not exist "..\ShutokouBattleX\" (
    call :PRINT_CN "[\u63D0\u793A] \u540C\u7EA7\u76EE\u5F55\u4E0B\u5C1A\u672A\u521B\u5EFA ..\\ShutokouBattleX\\ \u6587\u4EF6\u5939\u3002\u521B\u5EFA\u540E\uFF0C\u7F16\u8BD1\u5B8C\u6210\u5C06\u81EA\u52A8\u540C\u6B65\u72EC\u7ACB\u6E38\u620F\u7A0B\u5E8F\u4E0E\u8D44\u6E90\u5230\u8BE5\u76EE\u5F55\u3002"
    set "MK_DEPLOY="
    set /p "MK_DEPLOY=Create ..\ShutokouBattleX\ folder now? [Y/N] (Default Y): "
    if /i not "!MK_DEPLOY!"=="N" (
        mkdir "..\ShutokouBattleX" 2>nul
        if exist "..\ShutokouBattleX\" (
            echo [OK] Created ..\ShutokouBattleX\
        )
    )
    echo.
)

REM ------------------------------------------------------------------------------
REM Stage 1/3: Environment, Game Assets & Dependencies
REM ------------------------------------------------------------------------------
call :PRINT_CN "=== [Stage 1/3] Environment, Assets ^& Dependencies / \u7B2C 1 \u6B65\uFF1A\u68C0\u6D4B\u73AF\u5883\u4E0E\u4F9D\u8D56 ==="
call "scripts\setup-game-assets.bat" --check-only
if !ERRORLEVEL! neq 0 (
    echo.
    call :PRINT_CN "[\u63D0\u793A] \u68C0\u6D4B\u5230\u7F3A\u5931\u7EC4\u4EF6\uFF0C\u6B63\u5728\u62C9\u8D77\u5B89\u88C5\u5411\u5BFC scripts\\setup-game-assets.bat..."
    call "scripts\setup-game-assets.bat"
    echo.
    call "scripts\setup-game-assets.bat" --check-only
    if !ERRORLEVEL! neq 0 (
        call :PRINT_CN "[\u672A\u5B8C\u6210] \u73AF\u5883\u6216\u4F9D\u8D56\u4ECD\u672A\u5168\u90E8\u5C31\u7EEA\uFF0C\u8BF7\u8865\u9F50\u540E\u91CD\u65B0\u8FD0\u884C Setup.bat\u3002"
        goto :setup_exit
    )
)

if not exist "game_root\default.xex" (
    call :PRINT_CN "[\u9519\u8BEF] \u7F3A\u5C11 game_root\\default.xex\uFF0C\u8BF7\u5C06\u6B63\u7248\u89E3\u5305\u7684 XEX \u6E38\u620F\u6587\u4EF6\u653E\u5165 game_root\\ \u540E\u91CD\u8BD5\u3002"
    goto :setup_exit
)
if not exist "game_root\DATA\" (
    call :PRINT_CN "[\u9519\u8BEF] \u7F3A\u5C11 game_root\\DATA\\ \u76EE\u5F55\uFF0C\u8BF7\u5C06\u6B63\u7248\u89E3\u5305\u7684 XEX \u6E38\u620F\u6587\u4EF6\u653E\u5165 game_root\\ \u540E\u91CD\u8BD5\u3002"
    goto :setup_exit
)

echo.
call :PRINT_CN "[\u7B2C 1 \u6B65\u5B8C\u6210] \u8BF7\u6309 Enter \u952E\u8FDB\u5165\u7B2C 2 \u6B65\uFF08AOT \u4EE3\u7801\u751F\u6210\uFF09..."
set /p "_WAIT_S1=Stage 1/3 complete. Press Enter to run Stage 2 (AOT Codegen)..."

REM ------------------------------------------------------------------------------
REM Stage 2/3: AOT Codegen
REM ------------------------------------------------------------------------------
echo.
call :PRINT_CN "=== [Stage 2/3] Running AOT Codegen / \u7B2C 2 \u6B65\uFF1A\u6267\u884C AOT \u9759\u6001\u4EE3\u7801\u751F\u6210 ==="
call "scripts\run-codegen.bat" --no-pause
if !ERRORLEVEL! neq 0 (
    call :PRINT_CN "[\u9519\u8BEF] AOT \u4EE3\u7801\u751F\u6210\u5931\u8D25\uFF0C\u8BF7\u67E5\u770B logs\\codegen_latest.log\u3002"
    goto :setup_exit
)

echo.
call :PRINT_CN "[\u7B2C 2 \u6B65\u5B8C\u6210] \u8BF7\u6309 Enter \u952E\u8FDB\u5165\u7B2C 3 \u6B65\uFF08\u7F16\u8BD1 Windows \u539F\u751F\u7A0B\u5E8F\uFF09..."
set /p "_WAIT_S2=Stage 2/3 complete. Press Enter to run Stage 3 (Build Windows Native)..."

REM ------------------------------------------------------------------------------
REM Stage 3/3: Native Windows Build
REM ------------------------------------------------------------------------------
echo.
call :PRINT_CN "=== [Stage 3/3] Building Windows Native Executable ^& Launcher / \u7B2C 3 \u6B65\uFF1A\u7F16\u8BD1\u539F\u751F\u6E38\u620F\u4E0E\u542F\u52A8\u5668 ==="
call "scripts\build-windows.bat" --no-pause
if !ERRORLEVEL! neq 0 (
    call :PRINT_CN "[\u9519\u8BEF] \u7F16\u8BD1\u5931\u8D25\uFF0C\u8BF7\u67E5\u770B logs\\build_latest.log\u3002"
    goto :setup_exit
)
if not exist "out\win-amd64\Release\shutokou_battle_x.exe" (
    call :PRINT_CN "[\u9519\u8BEF] \u7F16\u8BD1\u672A\u751F\u6210 shutokou_battle_x.exe\uFF0C\u8BF7\u67E5\u770B logs\\build_latest.log\u3002"
    goto :setup_exit
)

echo.
echo ==============================================================================
call :PRINT_CN "[\u5168\u90E8\u5B8C\u6210] Shutokou Battle X \u5DF2\u5B89\u88C5\u5E76\u7F16\u8BD1\u5C31\u7EEA\uFF01"
set "LAUNCHER_TARGET="
if exist "..\ShutokouBattleX\Launcher.exe" (
    set "LAUNCHER_TARGET=..\ShutokouBattleX\Launcher.exe"
    echo Game Directory: %CD%\..\ShutokouBattleX\
) else if exist "out\win-amd64\Release\Launcher.exe" (
    set "LAUNCHER_TARGET=out\win-amd64\Release\Launcher.exe"
    echo Output Directory: %CD%\out\win-amd64\Release\
)
echo ==============================================================================

if defined LAUNCHER_TARGET (
    set "RUN_NOW="
    set /p "RUN_NOW=Launch Launcher.exe now? [Y/N] (Default Y): "
    if /i not "!RUN_NOW!"=="N" (
        start "" "!LAUNCHER_TARGET!"
    )
)

:setup_exit
echo.
call :PRINT_CN "\u8BF7\u6309 Enter \u952E\u5173\u95ED\u7A97\u53E3..."
set /p "_EXIT_WAIT=Press Enter to close this window..."
exit /b 0

:PRINT_CN
powershell -NoProfile -Command "Write-Host ([regex]::Unescape('%~1'))"
exit /b 0
