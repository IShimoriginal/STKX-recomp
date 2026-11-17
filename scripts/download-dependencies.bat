@chcp 65001 >nul
@echo off
setlocal enabledelayedexpansion
title Shutokou Battle X - Third-Party Dependency Downloader / 第三方依赖检测与下载工具

cd /d "%~dp0.."

echo ==============================================================================
echo   Shutokou Battle X [首都高赛车X]
echo   Third-Party Dependency Downloader / 依赖组件完整性检测与下载工具
echo   Root / 当前目录: %CD%
echo ==============================================================================

where git >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Git command not found. Please install Git for Windows to download dependencies automatically.
    echo [错误]  未找到 git 命令！如需自动联网下载依赖，请先安装 Git for Windows。
    if /i not "%~1"=="--no-pause" (
        echo.
        set /p "_EXIT_WAIT=Press Enter to close this window / 请按 Enter 键关闭窗口..."
    )
    exit /b 1
)

echo Checking third-party source dependencies...

REM 1. cli11
if not exist "thirdparty\cli11\include\CLI\CLI.hpp" (
    echo [Download] Fetching cli11...
    if exist "thirdparty\cli11" rmdir /s /q "thirdparty\cli11" >nul 2>nul
    git clone --depth 1 https://github.com/CLIUtils/CLI11.git thirdparty\cli11
)

REM 2. tomlplusplus
if not exist "thirdparty\tomlplusplus\include\toml++\toml.hpp" (
    echo [Download] Fetching tomlplusplus...
    if exist "thirdparty\tomlplusplus" rmdir /s /q "thirdparty\tomlplusplus" >nul 2>nul
    git clone --depth 1 https://github.com/marzer/tomlplusplus.git thirdparty\tomlplusplus
)

REM 3. simde
if not exist "thirdparty\simde\simde\simde-common.h" (
    echo [Download] Fetching simde...
    if exist "thirdparty\simde" rmdir /s /q "thirdparty\simde" >nul 2>nul
    git clone --depth 1 https://github.com/simd-everywhere/simde.git thirdparty\simde
)

REM 4. xxHash
if not exist "thirdparty\xxHash\xxhash.c" (
    echo [Download] Fetching xxHash [branch v0.8.3]...
    if exist "thirdparty\xxHash" rmdir /s /q "thirdparty\xxHash" >nul 2>nul
    git clone --depth 1 --branch v0.8.3 https://github.com/Cyan4973/xxHash.git thirdparty\xxHash
)

REM 5. spdlog
if not exist "thirdparty\spdlog\include\spdlog\spdlog.h" (
    echo [Download] Fetching spdlog...
    if exist "thirdparty\spdlog" rmdir /s /q "thirdparty\spdlog" >nul 2>nul
    git clone --depth 1 https://github.com/gabime/spdlog.git thirdparty\spdlog
)

REM 6. fmt
if not exist "thirdparty\fmt\include\fmt\format.h" (
    echo [Download] Fetching fmt...
    if exist "thirdparty\fmt" rmdir /s /q "thirdparty\fmt" >nul 2>nul
    git clone --depth 1 https://github.com/fmtlib/fmt.git thirdparty\fmt
)

REM 7. utfcpp
if not exist "thirdparty\utfcpp\source\utf8.h" (
    echo [Download] Fetching utfcpp...
    if exist "thirdparty\utfcpp" rmdir /s /q "thirdparty\utfcpp" >nul 2>nul
    git clone --depth 1 https://github.com/nemtrif/utfcpp.git thirdparty\utfcpp
)

REM 8. sdl3
if not exist "thirdparty\sdl3\cmake\macros.cmake" (
    echo [Download] Fetching sdl3 [branch release-3.4.x]...
    if exist "thirdparty\sdl3" rmdir /s /q "thirdparty\sdl3" >nul 2>nul
    git clone --depth 1 --branch release-3.4.x https://github.com/libsdl-org/SDL.git thirdparty\sdl3
)

REM 9. imgui
if not exist "thirdparty\imgui\imgui.cpp" (
    echo [Download] Fetching imgui...
    if exist "thirdparty\imgui" rmdir /s /q "thirdparty\imgui" >nul 2>nul
    git clone --depth 1 https://github.com/ocornut/imgui.git thirdparty\imgui
)

REM 10. inja
if not exist "thirdparty\inja\include\inja\inja.hpp" (
    echo [Download] Fetching inja...
    if exist "thirdparty\inja" rmdir /s /q "thirdparty\inja" >nul 2>nul
    git clone --depth 1 https://github.com/pantor/inja.git thirdparty\inja
)

REM 11. libmspack
if not exist "thirdparty\libmspack\cabextract\mspack\lzxd.c" (
    echo [Download] Fetching libmspack...
    if exist "thirdparty\libmspack" rmdir /s /q "thirdparty\libmspack" >nul 2>nul
    git clone --depth 1 https://github.com/kyz/libmspack.git thirdparty\libmspack
)

REM 12. o1heap
if not exist "thirdparty\o1heap\o1heap\o1heap.c" (
    echo [Download] Fetching o1heap...
    if exist "thirdparty\o1heap" rmdir /s /q "thirdparty\o1heap" >nul 2>nul
    git clone --depth 1 https://github.com/pavel-kirienko/o1heap.git thirdparty\o1heap
)

REM 13. FFmpeg
if not exist "thirdparty\FFmpeg\libavutil\adler32.c" (
    echo [Download] Fetching FFmpeg [branch xenia-ffmpeg-canary-full]...
    if exist "thirdparty\FFmpeg" rmdir /s /q "thirdparty\FFmpeg" >nul 2>nul
    git clone --depth 1 --branch xenia-ffmpeg-canary-full https://github.com/wmarti/FFmpeg.git thirdparty\FFmpeg
)

REM 14. vulkan-headers
if not exist "thirdparty\vulkan-headers\include\vulkan\vulkan.h" (
    echo [Download] Fetching vulkan-headers...
    if exist "thirdparty\vulkan-headers" rmdir /s /q "thirdparty\vulkan-headers" >nul 2>nul
    git clone --depth 1 https://github.com/KhronosGroup/Vulkan-Headers.git thirdparty\vulkan-headers
)

REM 15. vulkan-memory-allocator
if not exist "thirdparty\vulkan-memory-allocator\include\vk_mem_alloc.h" (
    echo [Download] Fetching vulkan-memory-allocator...
    if exist "thirdparty\vulkan-memory-allocator" rmdir /s /q "thirdparty\vulkan-memory-allocator" >nul 2>nul
    git clone --depth 1 https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator.git thirdparty\vulkan-memory-allocator
)

REM 16. spirv-headers
if not exist "thirdparty\spirv-headers\include\spirv\unified1\spirv.h" (
    echo [Download] Fetching spirv-headers...
    if exist "thirdparty\spirv-headers" rmdir /s /q "thirdparty\spirv-headers" >nul 2>nul
    git clone --depth 1 https://github.com/KhronosGroup/SPIRV-Headers.git thirdparty\spirv-headers
)

REM 17. spirv-tools
if not exist "thirdparty\spirv-tools\include\spirv-tools\libspirv.h" (
    echo [Download] Fetching spirv-tools...
    if exist "thirdparty\spirv-tools" rmdir /s /q "thirdparty\spirv-tools" >nul 2>nul
    git clone --depth 1 https://github.com/KhronosGroup/SPIRV-Tools.git thirdparty\spirv-tools
)

REM 18. glslang (11.13.0)
if not exist "thirdparty\glslang\SPIRV\SpvBuilder.h" (
    echo [Download] Fetching glslang [branch 11.13.0]...
    if exist "thirdparty\glslang" rmdir /s /q "thirdparty\glslang" >nul 2>nul
    git clone --depth 1 --branch 11.13.0 https://github.com/KhronosGroup/glslang.git thirdparty\glslang
)

echo.
echo ==============================================================================
echo [SUCCESS] All third-party dependencies verified and synchronized.
echo [完成]    所有第三方依赖库检测与同步完成！
echo ==============================================================================

if /i not "%~1"=="--no-pause" (
    echo.
    set /p "_EXIT_WAIT=Press Enter to close this window / 请按 Enter 键关闭窗口..."
)
