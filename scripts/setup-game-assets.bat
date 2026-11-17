@chcp 65001 >nul
@echo off
setlocal enabledelayedexpansion
title Shutokou Battle X - Environment ^& Asset Setup Wizard / 环境与游戏资源检测向导

cd /d "%~dp0.."
set "CHECK_ONLY=0"
if /i "%~1"=="--check-only" set "CHECK_ONLY=1"

set "DOWNLOAD_DIR=%CD%\downloads"
set "LINKS_FILE=%DOWNLOAD_DIR%\DOWNLOAD_LINKS.txt"

:RUN_CHECK
cls >nul 2>nul
echo ==============================================================================
echo   Shutokou Battle X [首都高赛车X]
echo   Environment ^& Asset Setup Wizard / 环境与游戏资源全量检测向导
echo   Working Directory / 当前工作目录: %CD%
echo ==============================================================================

if not exist "game_root" (
    mkdir "game_root"
    echo [OK] Created directory / 已创建目录: %CD%\game_root\
)

if not exist "saves" (
    mkdir "saves"
    echo [OK] Created directory / 已创建目录: %CD%\saves\
)

REM ------------------------------------------------------------------------------
REM 1. Game Assets Check
REM ------------------------------------------------------------------------------
echo.
echo [1/3] Checking game assets [game_root]... / 检测游戏资源 [game_root]...
set "ASSETS_OK=1"

if exist "game_root\default.xex" (
    echo   [OK]      default.xex
) else (
    echo   [MISSING] Missing file / 缺少文件: %CD%\game_root\default.xex
    set "ASSETS_OK=0"
)

if exist "game_root\DATA" (
    echo   [OK]      DATA\
    if exist "game_root\DATA\TXR"     echo             - TXR     [Models, Textures ^& Physics]
    if exist "game_root\DATA\SHADERS" echo             - SHADERS [GPU Microcode Shaders]
    if exist "game_root\DATA\AUDIO"   echo             - AUDIO   [Engine Audio ^& BGM]
    if exist "game_root\DATA\FONT"    echo             - FONT    [Game Fonts]
) else (
    echo   [MISSING] Missing directory / 缺少目录: %CD%\game_root\DATA\
    set "ASSETS_OK=0"
)

REM ------------------------------------------------------------------------------
REM 2. Build Toolchain Check
REM ------------------------------------------------------------------------------
echo.
echo [2/3] Checking build toolchain... / 检测后续编译所需工具链...
set "TOOLS_OK=1"
set "MISS_GIT=0"
set "MISS_CMAKE=0"
set "MISS_NINJA=0"
set "MISS_CLANG=0"
set "MISS_MSVC=0"

where git >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo   [OK]      Git
) else (
    echo   [MISSING] Git        ^(Required for fetching source dependencies / 用于拉取源码依赖^)
    set "MISS_GIT=1"
    set "TOOLS_OK=0"
)

where cmake >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo   [OK]      CMake
) else (
    echo   [MISSING] CMake      ^(Requires 3.25+ / 需 3.25+, 用于项目配置与构建^)
    set "MISS_CMAKE=1"
    set "TOOLS_OK=0"
)

where ninja >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo   [OK]      Ninja
) else (
    echo   [MISSING] Ninja      ^(Used by CMakePresets Ninja Multi-Config^)
    set "MISS_NINJA=1"
    set "TOOLS_OK=0"
)

set "HAS_CLANG=1"
where clang >nul 2>nul
if %ERRORLEVEL% neq 0 set "HAS_CLANG=0"
where clang++ >nul 2>nul
if %ERRORLEVEL% neq 0 set "HAS_CLANG=0"
if !HAS_CLANG! equ 1 (
    echo   [OK]      LLVM/Clang ^(clang / clang++^)
) else (
    echo   [MISSING] LLVM/Clang ^(CMakePresets requires clang / clang++^)
    set "MISS_CLANG=1"
    set "TOOLS_OK=0"
)

set "HAS_MSVC=0"
where cl >nul 2>nul
if %ERRORLEVEL% equ 0 set "HAS_MSVC=1"
set "PF86=%ProgramFiles(x86)%"
set "VSWHERE=!PF86!\Microsoft Visual Studio\Installer\vswhere.exe"
if !HAS_MSVC! equ 0 if exist "!VSWHERE!" (
    for /f "usebackq delims=" %%I in (`"!VSWHERE!" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2^>nul`) do (
        if not "%%I"=="" set "HAS_MSVC=1"
    )
)
if !HAS_MSVC! equ 1 (
    echo   [OK]      VS2022 / MSVC Build Tools ^& Windows SDK
) else (
    echo   [MISSING] VS2022 / MSVC Build Tools [Required for linking Windows targets / Clang 链接必需]
    set "MISS_MSVC=1"
    set "TOOLS_OK=0"
)

REM ------------------------------------------------------------------------------
REM 3. Third-Party Source Dependencies Check (thirdparty\)
REM ------------------------------------------------------------------------------
echo.
echo [3/3] Checking third-party libraries [thirdparty\]... / 检测第三方源码依赖 [thirdparty\]...
set "LIBS_OK=1"
set "MISS_LIB_COUNT=0"

call :CHECK_LIB "cli11"        "thirdparty\cli11\include\CLI\CLI.hpp"
call :CHECK_LIB "tomlplusplus" "thirdparty\tomlplusplus\include\toml++\toml.hpp"
call :CHECK_LIB "simde"        "thirdparty\simde\simde\simde-common.h"
call :CHECK_LIB "xxHash"       "thirdparty\xxHash\xxhash.c"
call :CHECK_LIB "spdlog"       "thirdparty\spdlog\include\spdlog\spdlog.h"
call :CHECK_LIB "fmt"          "thirdparty\fmt\include\fmt\format.h"
call :CHECK_LIB "utfcpp"       "thirdparty\utfcpp\source\utf8.h"
call :CHECK_LIB "sdl3"         "thirdparty\sdl3\cmake\macros.cmake"
call :CHECK_LIB "imgui"        "thirdparty\imgui\imgui.cpp"
call :CHECK_LIB "inja"         "thirdparty\inja\include\inja\inja.hpp"
call :CHECK_LIB "libmspack"    "thirdparty\libmspack\cabextract\mspack\lzxd.c"
call :CHECK_LIB "o1heap"       "thirdparty\o1heap\o1heap\o1heap.c"
call :CHECK_LIB "FFmpeg"       "thirdparty\FFmpeg\libavutil\adler32.c"
call :CHECK_LIB "vulkan-headers"          "thirdparty\vulkan-headers\include\vulkan\vulkan.h"
call :CHECK_LIB "vulkan-memory-allocator" "thirdparty\vulkan-memory-allocator\include\vk_mem_alloc.h"
call :CHECK_LIB "spirv-headers"           "thirdparty\spirv-headers\include\spirv\unified1\spirv.h"
call :CHECK_LIB "spirv-tools"             "thirdparty\spirv-tools\include\spirv-tools\libspirv.h"
call :CHECK_LIB "glslang"                 "thirdparty\glslang\SPIRV\SpvBuilder.h"

echo.
echo ==============================================================================
if !ASSETS_OK! equ 1 if !TOOLS_OK! equ 1 if !LIBS_OK! equ 1 (
    echo [ALL READY / 状态良好] Game assets, toolchain, and third-party libraries are all ready.
    echo                        游戏资源、编译工具链与第三方依赖全部就绪！
    echo.
    echo Next steps / 接下来请按顺序执行:
    echo   1. scripts\run-codegen.bat   [Run AOT static codegen / 执行 AOT 静态代码生成]
    echo   2. scripts\build-windows.bat [Build Windows native executable / 编译 Windows 原生游戏程序]
    echo ==============================================================================
    goto :SCRIPT_EXIT
)

if !ASSETS_OK! equ 0 (
    echo [ASSETS NOT READY / 游戏资源未就绪]
    echo Please place your extracted Xbox 360 game files into / 请将正版提取的 Xbox 360 游戏文件放入:
    echo   %CD%\game_root\default.xex
    echo   %CD%\game_root\DATA\
    echo.
)

if !TOOLS_OK! equ 1 if !LIBS_OK! equ 1 (
    echo [STATUS / 组件状态] Toolchain and third-party libraries are ready. Only game_root assets are needed.
    echo                     编译工具链与第三方依赖已全部就绪，仅需补齐上方 game_root 资源即可。
    echo ==============================================================================
    goto :SCRIPT_EXIT
)

echo [MISSING COMPONENTS / 发现缺失组件] Please select an installation method / 请选择安装方式:
echo   [1] One-click online download ^& install (Requires Internet / 一键联网下载并安装缺失组件)
echo   [2] Export download links for manual/offline download (导出缺失组件下载链接，适合弱网/离线)
echo   [3] Extract ^& install downloaded .zip archives from %DOWNLOAD_DIR% (从指定目录统一解压安装压缩包)
echo   [0] Exit without installing (暂不安装，退出检测)
echo ==============================================================================

if "!CHECK_ONLY!"=="1" exit /b 1

set "USER_CHOICE="
set /p "USER_CHOICE=Select option / 请输入选项 [1/2/3/0]: "

if "!USER_CHOICE!"=="1" goto :ONE_CLICK_INSTALL
if "!USER_CHOICE!"=="2" goto :SHOW_MANUAL_LINKS
if "!USER_CHOICE!"=="3" goto :EXTRACT_ARCHIVE_DIR
if "!USER_CHOICE!"=="0" goto :SCRIPT_EXIT
echo Invalid option, please try again. / 无效选项，请重试。
goto :RUN_CHECK

REM ==============================================================================
REM Option 1: One-click online download and install
REM ==============================================================================
:ONE_CLICK_INSTALL
echo.
echo [One-Click Install / 一键安装] Processing missing components...

if !TOOLS_OK! equ 0 (
    where winget >nul 2>nul
    if %ERRORLEVEL% equ 0 (
        echo Detected winget, installing missing build tools...
        if !MISS_GIT! equ 1   winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
        if !MISS_CMAKE! equ 1 winget install --id Kitware.CMake -e --accept-source-agreements --accept-package-agreements
        if !MISS_NINJA! equ 1 winget install --id Ninja-build.Ninja -e --accept-source-agreements --accept-package-agreements
        if !MISS_CLANG! equ 1 winget install --id LLVM.LLVM -e --accept-source-agreements --accept-package-agreements
        if !MISS_MSVC! equ 1 (
            echo Launching Visual Studio 2022 Build Tools installer ^(Please select "Desktop development with C++"^)...
            echo 正在启动 Visual Studio 2022 Build Tools 安装器 ^(请勾选 "使用 C++ 的桌面开发"^)...
            winget install --id Microsoft.VisualStudio.2022.BuildTools -e --accept-source-agreements --accept-package-agreements
        )
        REM Refresh current session PATH
        for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command "[Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')"`) do set "PATH=%%P"
    ) else (
        echo [WARN] winget not found. Please use Option [2] to get installer download links.
        echo [警告] 当前系统未检测到 winget，请使用选项 [2] 获取安装包下载链接。
    )
)

if !LIBS_OK! equ 0 (
    where git >nul 2>nul
    if %ERRORLEVEL% equ 0 (
        echo.
        echo Fetching missing third-party source libraries via Git...
        call "%~dp0download-dependencies.bat" --no-pause
    ) else (
        echo.
        echo [INFO] Git not found; downloading .zip archives via PowerShell and extracting...
        if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"
        call :PS_DOWNLOAD_MISSING_ZIPS
        call :PS_EXTRACT_ALL_ZIPS
    )
)

echo.
echo [DONE / 完成] One-click processing finished. Press Enter to re-check...
set /p "_RECHECK_WAIT=Press Enter to continue / 请按 Enter 键重新检测..."
goto :RUN_CHECK

REM ==============================================================================
REM Option 2: Export missing component download links + target folder
REM ==============================================================================
:SHOW_MANUAL_LINKS
if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"

> "%LINKS_FILE%" (
    echo ==============================================================================
    echo Shutokou Battle X - Missing Components Manual Download List / 缺失组件手动下载清单
    echo Generated / 生成时间: %DATE% %TIME%
    echo ==============================================================================
    echo.
    if !TOOLS_OK! equ 0 (
        echo [1. Build Toolchain Installers - Run installer after download / 编译工具链安装包 - 下载后直接双击安装]
        if !MISS_GIT! equ 1   echo   - Git for Windows: https://git-scm.com/download/win
        if !MISS_CMAKE! equ 1 echo   - CMake ^(Windows x64^): https://cmake.org/download/
        if !MISS_NINJA! equ 1 echo   - Ninja ^(Windows zip^): https://github.com/ninja-build/ninja/releases/latest
        if !MISS_CLANG! equ 1 echo   - LLVM/Clang ^(win64.exe^): https://github.com/llvm/llvm-project/releases/latest
        if !MISS_MSVC! equ 1  echo   - VS2022 Build Tools: https://visualstudio.microsoft.com/zh-hans/visual-cpp-build-tools/
        echo.
    )
    if !LIBS_OK! equ 0 (
        echo [2. Third-Party Source Archives - Place .zip files directly in folder below ^(DO NOT extract manually^)]
        echo [二、第三方源码依赖包 - 请下载为 .zip 压缩包并直接放入以下目录（保持原文件名，无需手动解压）:]
        echo Target Directory / 存放目录: %DOWNLOAD_DIR%
        echo.
        if not exist "thirdparty\cli11\include\CLI\CLI.hpp"          echo   - cli11        : https://github.com/CLIUtils/CLI11/archive/HEAD.zip
        if not exist "thirdparty\tomlplusplus\include\toml++\toml.hpp" echo   - tomlplusplus : https://github.com/marzer/tomlplusplus/archive/HEAD.zip
        if not exist "thirdparty\simde\simde\simde-common.h"         echo   - simde        : https://github.com/simd-everywhere/simde/archive/HEAD.zip
        if not exist "thirdparty\xxHash\xxhash.c"                    echo   - xxHash       : https://github.com/Cyan4973/xxHash/archive/refs/tags/v0.8.3.zip
        if not exist "thirdparty\spdlog\include\spdlog\spdlog.h"     echo   - spdlog       : https://github.com/gabime/spdlog/archive/HEAD.zip
        if not exist "thirdparty\fmt\include\fmt\format.h"           echo   - fmt          : https://github.com/fmtlib/fmt/archive/HEAD.zip
        if not exist "thirdparty\utfcpp\source\utf8.h"               echo   - utfcpp       : https://github.com/nemtrif/utfcpp/archive/HEAD.zip
        if not exist "thirdparty\sdl3\cmake\macros.cmake"            echo   - sdl3         : https://github.com/libsdl-org/SDL/archive/refs/heads/release-3.4.x.zip
        if not exist "thirdparty\imgui\imgui.cpp"                    echo   - imgui        : https://github.com/ocornut/imgui/archive/HEAD.zip
        if not exist "thirdparty\inja\include\inja\inja.hpp"         echo   - inja         : https://github.com/pantor/inja/archive/HEAD.zip
        if not exist "thirdparty\libmspack\cabextract\mspack\lzxd.c" echo   - libmspack    : https://github.com/kyz/libmspack/archive/HEAD.zip
        if not exist "thirdparty\o1heap\o1heap\o1heap.c"             echo   - o1heap       : https://github.com/pavel-kirienko/o1heap/archive/HEAD.zip
        if not exist "thirdparty\FFmpeg\libavutil\adler32.c"         echo   - FFmpeg       : https://github.com/wmarti/FFmpeg/archive/refs/heads/xenia-ffmpeg-canary-full.zip
        if not exist "thirdparty\vulkan-headers\include\vulkan\vulkan.h"            echo   - vulkan-headers          : https://github.com/KhronosGroup/Vulkan-Headers/archive/HEAD.zip
        if not exist "thirdparty\vulkan-memory-allocator\include\vk_mem_alloc.h"    echo   - vulkan-memory-allocator : https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator/archive/HEAD.zip
        if not exist "thirdparty\spirv-headers\include\spirv\unified1\spirv.h"      echo   - spirv-headers           : https://github.com/KhronosGroup/SPIRV-Headers/archive/HEAD.zip
        if not exist "thirdparty\spirv-tools\include\spirv-tools\libspirv.h"        echo   - spirv-tools             : https://github.com/KhronosGroup/SPIRV-Tools/archive/HEAD.zip
        if not exist "thirdparty\glslang\SPIRV\SpvBuilder.h"                        echo   - glslang                 : https://github.com/KhronosGroup/glslang/archive/refs/tags/11.13.0.zip
    )
)

echo.
type "%LINKS_FILE%"
echo.
echo [INFO / 提示] The download list above has been saved to / 以上清单已同步保存至:
echo   %LINKS_FILE%
echo.
echo Please place all downloaded .zip archives ^(keep original filenames, DO NOT extract manually^) into:
echo 请将下载好的所有 .zip 压缩包（保持原文件名，无需手动解压）放入:
echo   %DOWNLOAD_DIR%\
echo.
set "NEXT_ACTION="
set /p "NEXT_ACTION=Enter [Y] to extract & install now, or [M] to return to menu / 放好后输入 [Y] 立即统一解压安装，或输入 [M] 返回主菜单: "
if /i "!NEXT_ACTION!"=="Y" goto :EXTRACT_ARCHIVE_DIR
goto :RUN_CHECK

REM ==============================================================================
REM Option 3: Extract & install all archives from downloads\
REM ==============================================================================
:EXTRACT_ARCHIVE_DIR
echo.
if not exist "%DOWNLOAD_DIR%" (
    mkdir "%DOWNLOAD_DIR%"
    echo [INFO / 提示] Created directory / 已创建存放目录: %DOWNLOAD_DIR%
    echo Please place the downloaded .zip archives into this directory first.
    echo 请先将下载好的 .zip 压缩包放入该目录，然后再执行本步骤。
    set /p "_WAIT_DIR=Press Enter to return to menu / 请按 Enter 键返回主菜单..."
    goto :RUN_CHECK
)

echo Scanning and extracting archives from %DOWNLOAD_DIR%...
call :PS_EXTRACT_ALL_ZIPS

echo.
echo [DONE / 完成] Archive extraction finished. / 统一解压安装结束。
set /p "_WAIT_EXT=Press Enter to re-check / 请按 Enter 键重新检测..."
goto :RUN_CHECK

:SCRIPT_EXIT
if "!CHECK_ONLY!"=="0" (
    echo.
    set /p "_EXIT_WAIT=Press Enter to close this window / 请按 Enter 键关闭窗口..."
)
exit /b 0

REM ==============================================================================
REM Helper Subroutines
REM ==============================================================================
:CHECK_LIB
set "LIB_NAME=%~1"
set "LIB_SENTINEL=%~2"
if exist "%LIB_SENTINEL%" (
    echo   [OK]      !LIB_NAME!
) else (
    echo   [MISSING] !LIB_NAME!
    set "LIBS_OK=0"
    set /a MISS_LIB_COUNT+=1
)
exit /b 0

:PS_DOWNLOAD_MISSING_ZIPS
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Continue';" ^
  "$dl = '%DOWNLOAD_DIR%';" ^
  "$items = @(" ^
  "  @{ name='cli11';        sentinel='thirdparty\cli11\include\CLI\CLI.hpp';          url='https://github.com/CLIUtils/CLI11/archive/HEAD.zip'; file='cli11.zip' }," ^
  "  @{ name='tomlplusplus'; sentinel='thirdparty\tomlplusplus\include\toml++\toml.hpp'; url='https://github.com/marzer/tomlplusplus/archive/HEAD.zip'; file='tomlplusplus.zip' }," ^
  "  @{ name='simde';        sentinel='thirdparty\simde\simde\simde-common.h';         url='https://github.com/simd-everywhere/simde/archive/HEAD.zip'; file='simde.zip' }," ^
  "  @{ name='xxHash';       sentinel='thirdparty\xxHash\xxhash.c';                    url='https://github.com/Cyan4973/xxHash/archive/refs/tags/v0.8.3.zip'; file='xxHash-v0.8.3.zip' }," ^
  "  @{ name='spdlog';       sentinel='thirdparty\spdlog\include\spdlog\spdlog.h';     url='https://github.com/gabime/spdlog/archive/HEAD.zip'; file='spdlog.zip' }," ^
  "  @{ name='fmt';          sentinel='thirdparty\fmt\include\fmt\format.h';           url='https://github.com/fmtlib/fmt/archive/HEAD.zip'; file='fmt.zip' }," ^
  "  @{ name='utfcpp';       sentinel='thirdparty\utfcpp\source\utf8.h';               url='https://github.com/nemtrif/utfcpp/archive/HEAD.zip'; file='utfcpp.zip' }," ^
  "  @{ name='sdl3';         sentinel='thirdparty\sdl3\cmake\macros.cmake';            url='https://github.com/libsdl-org/SDL/archive/refs/heads/release-3.4.x.zip'; file='SDL-release-3.4.x.zip' }," ^
  "  @{ name='imgui';        sentinel='thirdparty\imgui\imgui.cpp';                    url='https://github.com/ocornut/imgui/archive/HEAD.zip'; file='imgui.zip' }," ^
  "  @{ name='inja';         sentinel='thirdparty\inja\include\inja\inja.hpp';         url='https://github.com/pantor/inja/archive/HEAD.zip'; file='inja.zip' }," ^
  "  @{ name='libmspack';    sentinel='thirdparty\libmspack\cabextract\mspack\lzxd.c'; url='https://github.com/kyz/libmspack/archive/HEAD.zip'; file='libmspack.zip' }," ^
  "  @{ name='o1heap';       sentinel='thirdparty\o1heap\o1heap\o1heap.c';             url='https://github.com/pavel-kirienko/o1heap/archive/HEAD.zip'; file='o1heap.zip' }," ^
  "  @{ name='FFmpeg';       sentinel='thirdparty\FFmpeg\libavutil\adler32.c';         url='https://github.com/wmarti/FFmpeg/archive/refs/heads/xenia-ffmpeg-canary-full.zip'; file='FFmpeg-xenia-ffmpeg-canary-full.zip' }," ^
  "  @{ name='vulkan-headers';          sentinel='thirdparty\vulkan-headers\include\vulkan\vulkan.h';         url='https://github.com/KhronosGroup/Vulkan-Headers/archive/HEAD.zip'; file='vulkan-headers.zip' }," ^
  "  @{ name='vulkan-memory-allocator'; sentinel='thirdparty\vulkan-memory-allocator\include\vk_mem_alloc.h'; url='https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator/archive/HEAD.zip'; file='vulkan-memory-allocator.zip' }," ^
  "  @{ name='spirv-headers';           sentinel='thirdparty\spirv-headers\include\spirv\unified1\spirv.h';   url='https://github.com/KhronosGroup/SPIRV-Headers/archive/HEAD.zip'; file='spirv-headers.zip' }," ^
  "  @{ name='spirv-tools';             sentinel='thirdparty\spirv-tools\include\spirv-tools\libspirv.h';     url='https://github.com/KhronosGroup/SPIRV-Tools/archive/HEAD.zip'; file='spirv-tools.zip' }," ^
  "  @{ name='glslang';                 sentinel='thirdparty\glslang\SPIRV\SpvBuilder.h';                     url='https://github.com/KhronosGroup/glslang/archive/refs/tags/11.13.0.zip'; file='glslang-11.13.0.zip' }" ^
  ");" ^
  "foreach ($it in $items) {" ^
  "  if (Test-Path $it.sentinel) { continue }" ^
  "  $out = Join-Path $dl $it.file;" ^
  "  Write-Host ('[Download] ' + $it.name + ' -> ' + $out);" ^
  "  try { Invoke-WebRequest -Uri $it.url -OutFile $out -UseBasicParsing } catch { Write-Host ('[ERROR] Download failed: ' + $it.name + ' - ' + $_.Exception.Message) }" ^
  "}"
exit /b 0

:PS_EXTRACT_ALL_ZIPS
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$dl = '%DOWNLOAD_DIR%';" ^
  "$items = @(" ^
  "  @{ name='cli11';        sentinel='thirdparty\cli11\include\CLI\CLI.hpp';          target='thirdparty\cli11';        patterns=@('*cli11*.zip') }," ^
  "  @{ name='tomlplusplus'; sentinel='thirdparty\tomlplusplus\include\toml++\toml.hpp'; target='thirdparty\tomlplusplus'; patterns=@('*toml*.zip') }," ^
  "  @{ name='simde';        sentinel='thirdparty\simde\simde\simde-common.h';         target='thirdparty\simde';        patterns=@('*simde*.zip') }," ^
  "  @{ name='xxHash';       sentinel='thirdparty\xxHash\xxhash.c';                    target='thirdparty\xxHash';       patterns=@('*xxhash*.zip') }," ^
  "  @{ name='spdlog';       sentinel='thirdparty\spdlog\include\spdlog\spdlog.h';     target='thirdparty\spdlog';       patterns=@('*spdlog*.zip') }," ^
  "  @{ name='fmt';          sentinel='thirdparty\fmt\include\fmt\format.h';           target='thirdparty\fmt';          patterns=@('*fmt*.zip') }," ^
  "  @{ name='utfcpp';       sentinel='thirdparty\utfcpp\source\utf8.h';               target='thirdparty\utfcpp';       patterns=@('*utfcpp*.zip') }," ^
  "  @{ name='sdl3';         sentinel='thirdparty\sdl3\cmake\macros.cmake';            target='thirdparty\sdl3';         patterns=@('*sdl*.zip') }," ^
  "  @{ name='imgui';        sentinel='thirdparty\imgui\imgui.cpp';                    target='thirdparty\imgui';        patterns=@('*imgui*.zip') }," ^
  "  @{ name='inja';         sentinel='thirdparty\inja\include\inja\inja.hpp';         target='thirdparty\inja';         patterns=@('*inja*.zip') }," ^
  "  @{ name='libmspack';    sentinel='thirdparty\libmspack\cabextract\mspack\lzxd.c'; target='thirdparty\libmspack';    patterns=@('*libmspack*.zip') }," ^
  "  @{ name='o1heap';       sentinel='thirdparty\o1heap\o1heap\o1heap.c';             target='thirdparty\o1heap';       patterns=@('*o1heap*.zip') }," ^
  "  @{ name='FFmpeg';       sentinel='thirdparty\FFmpeg\libavutil\adler32.c';         target='thirdparty\FFmpeg';       patterns=@('*ffmpeg*.zip') }," ^
  "  @{ name='vulkan-headers';          sentinel='thirdparty\vulkan-headers\include\vulkan\vulkan.h';         target='thirdparty\vulkan-headers';          patterns=@('*vulkan-headers*.zip','*Vulkan-Headers*.zip') }," ^
  "  @{ name='vulkan-memory-allocator'; sentinel='thirdparty\vulkan-memory-allocator\include\vk_mem_alloc.h'; target='thirdparty\vulkan-memory-allocator'; patterns=@('*vulkan-memory-allocator*.zip','*VulkanMemoryAllocator*.zip') }," ^
  "  @{ name='spirv-headers';           sentinel='thirdparty\spirv-headers\include\spirv\unified1\spirv.h';   target='thirdparty\spirv-headers';           patterns=@('*spirv-headers*.zip','*SPIRV-Headers*.zip') }," ^
  "  @{ name='spirv-tools';             sentinel='thirdparty\spirv-tools\include\spirv-tools\libspirv.h';     target='thirdparty\spirv-tools';             patterns=@('*spirv-tools*.zip','*SPIRV-Tools*.zip') }," ^
  "  @{ name='glslang';                 sentinel='thirdparty\glslang\SPIRV\SpvBuilder.h';                     target='thirdparty\glslang';                 patterns=@('*glslang*.zip') }" ^
  ");" ^
  "$zips = Get-ChildItem -Path $dl -Filter '*.zip' -File -ErrorAction SilentlyContinue;" ^
  "foreach ($it in $items) {" ^
  "  if (Test-Path $it.sentinel) { continue }" ^
  "  $match = $null;" ^
  "  foreach ($pat in $it.patterns) {" ^
  "    $match = $zips | Where-Object { $_.Name -like $pat } | Select-Object -First 1;" ^
  "    if ($match) { break }" ^
  "  }" ^
  "  if (-not $match) { Write-Host ('  [SKIP] Archive not found for ' + $it.name); continue }" ^
  "  Write-Host ('  [Extract] ' + $match.Name + ' -> ' + $it.target);" ^
  "  $tmp = Join-Path $dl ('_tmp_' + $it.name);" ^
  "  if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }" ^
  "  Expand-Archive -Path $match.FullName -DestinationPath $tmp -Force;" ^
  "  if (Test-Path $it.target) { Remove-Item -Recurse -Force $it.target }" ^
  "  $dirs = Get-ChildItem -Path $tmp -Directory;" ^
  "  $files = Get-ChildItem -Path $tmp -File;" ^
  "  if ($dirs.Count -eq 1 -and $files.Count -eq 0) {" ^
  "    Move-Item -Path $dirs[0].FullName -Destination $it.target;" ^
  "  } else {" ^
  "    New-Item -ItemType Directory -Path $it.target -Force | Out-Null;" ^
  "    Get-ChildItem -Path $tmp | Move-Item -Destination $it.target;" ^
  "  }" ^
  "  if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }" ^
  "  if (Test-Path $it.sentinel) { Write-Host ('  [OK]      ' + $it.name + ' installed') } else { Write-Host ('  [WARN]    ' + $it.name + ' extracted, but missing sentinel: ' + $it.sentinel) }" ^
  "}"
exit /b 0
