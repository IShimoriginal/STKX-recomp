@chcp 65001 >nul
@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0.."

echo ==============================================================================
echo   Shutokou Battle X [首都高赛车X] - 依赖组件完整性检测与下载工具
echo   当前目录: %CD%
echo ==============================================================================

where git >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] 未找到 git 命令！如果需要自动联网下载依赖，请安装 Git for Windows。
    if /i not "%~1"=="--no-pause" pause
    exit /b 1
)

echo 正在检测第三方依赖组件源文件...

REM 1. cli11
if not exist "thirdparty\cli11\include\CLI\CLI.hpp" (
    echo [下载] 正在获取 cli11...
    if exist "thirdparty\cli11" rmdir /s /q "thirdparty\cli11" >nul 2>nul
    git clone --depth 1 https://github.com/CLIUtils/CLI11.git thirdparty\cli11
)

REM 2. tomlplusplus
if not exist "thirdparty\tomlplusplus\include\toml++\toml.hpp" (
    echo [下载] 正在获取 tomlplusplus...
    if exist "thirdparty\tomlplusplus" rmdir /s /q "thirdparty\tomlplusplus" >nul 2>nul
    git clone --depth 1 https://github.com/marzer/tomlplusplus.git thirdparty\tomlplusplus
)

REM 3. simde
if not exist "thirdparty\simde\simde\simde-common.h" (
    echo [下载] 正在获取 simde...
    if exist "thirdparty\simde" rmdir /s /q "thirdparty\simde" >nul 2>nul
    git clone --depth 1 https://github.com/simd-everywhere/simde.git thirdparty\simde
)

REM 4. xxHash
if not exist "thirdparty\xxHash\xxhash.c" (
    echo [下载] 正在获取 xxHash [分支 v0.8.3]...
    if exist "thirdparty\xxHash" rmdir /s /q "thirdparty\xxHash" >nul 2>nul
    git clone --depth 1 --branch v0.8.3 https://github.com/Cyan4973/xxHash.git thirdparty\xxHash
)

REM 5. spdlog
if not exist "thirdparty\spdlog\include\spdlog\spdlog.h" (
    echo [下载] 正在获取 spdlog...
    if exist "thirdparty\spdlog" rmdir /s /q "thirdparty\spdlog" >nul 2>nul
    git clone --depth 1 https://github.com/gabime/spdlog.git thirdparty\spdlog
)

REM 6. fmt
if not exist "thirdparty\fmt\include\fmt\format.h" (
    echo [下载] 正在获取 fmt...
    if exist "thirdparty\fmt" rmdir /s /q "thirdparty\fmt" >nul 2>nul
    git clone --depth 1 https://github.com/fmtlib/fmt.git thirdparty\fmt
)

REM 7. utfcpp
if not exist "thirdparty\utfcpp\source\utf8.h" (
    echo [下载] 正在获取 utfcpp...
    if exist "thirdparty\utfcpp" rmdir /s /q "thirdparty\utfcpp" >nul 2>nul
    git clone --depth 1 https://github.com/nemtrif/utfcpp.git thirdparty\utfcpp
)

REM 8. sdl3
if not exist "thirdparty\sdl3\cmake\macros.cmake" (
    echo [下载] 正在获取 sdl3 [分支 release-3.4.x]...
    if exist "thirdparty\sdl3" rmdir /s /q "thirdparty\sdl3" >nul 2>nul
    git clone --depth 1 --branch release-3.4.x https://github.com/libsdl-org/SDL.git thirdparty\sdl3
)

REM 9. imgui
if not exist "thirdparty\imgui\imgui.cpp" (
    echo [下载] 正在获取 imgui...
    if exist "thirdparty\imgui" rmdir /s /q "thirdparty\imgui" >nul 2>nul
    git clone --depth 1 https://github.com/ocornut/imgui.git thirdparty\imgui
)

REM 10. inja
if not exist "thirdparty\inja\include\inja\inja.hpp" (
    echo [下载] 正在获取 inja...
    if exist "thirdparty\inja" rmdir /s /q "thirdparty\inja" >nul 2>nul
    git clone --depth 1 https://github.com/pantor/inja.git thirdparty\inja
)

REM 11. libmspack
if not exist "thirdparty\libmspack\cabextract\mspack\lzxd.c" (
    echo [下载] 正在获取 libmspack...
    if exist "thirdparty\libmspack" rmdir /s /q "thirdparty\libmspack" >nul 2>nul
    git clone --depth 1 https://github.com/kyz/libmspack.git thirdparty\libmspack
)

REM 12. o1heap
if not exist "thirdparty\o1heap\o1heap\o1heap.c" (
    echo [下载] 正在获取 o1heap...
    if exist "thirdparty\o1heap" rmdir /s /q "thirdparty\o1heap" >nul 2>nul
    git clone --depth 1 https://github.com/pavel-kirienko/o1heap.git thirdparty\o1heap
)

REM 13. FFmpeg
if not exist "thirdparty\FFmpeg\libavutil\adler32.c" (
    echo [下载] 正在获取 FFmpeg [分支 xenia-ffmpeg-canary-full]...
    if exist "thirdparty\FFmpeg" rmdir /s /q "thirdparty\FFmpeg" >nul 2>nul
    git clone --depth 1 --branch xenia-ffmpeg-canary-full https://github.com/wmarti/FFmpeg.git thirdparty\FFmpeg
)

echo.
echo ==============================================================================
echo [SUCCESS] 所有依赖库检测与同步完成！
echo ==============================================================================

if /i not "%~1"=="--no-pause" pause
