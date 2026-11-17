@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

cd /d "%~dp0"

echo ==============================================================================
echo   首都高赛车X (Shutokou Battle X) - Windows 原生客户端启动器
echo ==============================================================================
echo.

set "TARGET_EXE="
if exist "dist\shutokou_battle_x.exe" (
    set "TARGET_EXE=dist\shutokou_battle_x.exe"
) else if exist "out\win-amd64\Release\shutokou_battle_x.exe" (
    set "TARGET_EXE=out\win-amd64\Release\shutokou_battle_x.exe"
) else if exist "build\Release\shutokou_battle_x.exe" (
    set "TARGET_EXE=build\Release\shutokou_battle_x.exe"
)

if not defined TARGET_EXE (
    echo [ERROR] 未找到编译完成的 shutokou_battle_x.exe！
    echo 请先运行 scripts\build-windows.bat 完成编译构建。
    echo.
    pause
    exit /b 1
)

REM 校验游戏资源目录
if not exist "game_root\default.xex" if not exist "dist\game_root\default.xex" (
    echo [WARNING] 未在 game_root\ 检测到 default.xex。
    echo 请确保 Xbox 360 游戏原盘提取文件位于 game_root\ 目录中。
    echo.
)

echo [启动中] 正在启动原生 Windows 版《首都高赛车X》...
echo 游戏程序: !TARGET_EXE!
echo 渲染管线: Direct3D 12 (原生高帧率 / 60FPS-120FPS 物理同步)
echo.

start "" "!TARGET_EXE!"
