@chcp 65001 >nul
@echo off
setlocal enabledelayedexpansion
title Shutokou Battle X - Environment and Asset Setup Wizard

cd /d "%~dp0.."
set "CHECK_ONLY=0"
if /i "%~1"=="--check-only" set "CHECK_ONLY=1"

set "DOWNLOAD_DIR=%CD%\downloads"
set "LINKS_FILE=%DOWNLOAD_DIR%\DOWNLOAD_LINKS.txt"

:RUN_CHECK
cls >nul 2>nul
echo ==============================================================================
echo   Shutokou Battle X - Environment ^& Asset Setup Wizard
call :PRINT_CN "  \u9996\u90FD\u9AD8\u8D5B\u8F66X - \u73AF\u5883\u4E0E\u6E38\u620F\u8D44\u6E90\u5168\u91CF\u68C0\u6D4B\u5411\u5BFC"
echo   Working Directory: %CD%
echo ==============================================================================

if not exist "game_root" (
    mkdir "game_root"
    echo [OK] Created directory: %CD%\game_root\
)

if not exist "saves" (
    mkdir "saves"
    echo [OK] Created directory: %CD%\saves\
)

if not exist "%DOWNLOAD_DIR%" (
    mkdir "%DOWNLOAD_DIR%"
)

REM Auto-include common default installation paths into session PATH
if exist "%CD%\tools\binutils" set "PATH=%CD%\tools\binutils;!PATH!"
if exist "C:\Program Files\Git\cmd" set "PATH=!PATH!;C:\Program Files\Git\cmd"
if exist "C:\Program Files\CMake\bin" set "PATH=!PATH!;C:\Program Files\CMake\bin"
if exist "C:\Program Files\LLVM\bin" set "PATH=!PATH!;C:\Program Files\LLVM\bin"

REM ------------------------------------------------------------------------------
REM Step 1: First verify & install any valid packages already placed in downloads\
REM ------------------------------------------------------------------------------
call :VERIFY_AND_INSTALL_DOWNLOADS

REM ------------------------------------------------------------------------------
REM Step 2: Check Game Assets (game_root\)
REM ------------------------------------------------------------------------------
echo.
call :PRINT_CN "[1/3] Checking game assets [game_root]... / \u68C0\u6D4B\u6E38\u620F\u8D44\u6E90 [game_root]..."
set "ASSETS_OK=1"

if exist "game_root\default.xex" (
    echo   [OK]      default.xex
) else (
    echo   [MISSING] Missing file: %CD%\game_root\default.xex
    set "ASSETS_OK=0"
)

if exist "game_root\DATA" (
    echo   [OK]      DATA\
    if exist "game_root\DATA\TXR"     echo             - TXR     [Models, Textures ^& Physics]
    if exist "game_root\DATA\SHADERS" echo             - SHADERS [GPU Microcode Shaders]
    if exist "game_root\DATA\AUDIO"   echo             - AUDIO   [Engine Audio ^& BGM]
    if exist "game_root\DATA\FONT"    echo             - FONT    [Game Fonts]
) else (
    echo   [MISSING] Missing directory: %CD%\game_root\DATA\
    set "ASSETS_OK=0"
)

REM ------------------------------------------------------------------------------
REM Step 3: Check Build Toolchain
REM ------------------------------------------------------------------------------
echo.
call :PRINT_CN "[2/3] Checking build toolchain... / \u68C0\u6D4B\u540E\u7EED\u7F16\u8BD1\u6240\u9700\u5DE5\u5177\u94FE..."
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
    echo   [MISSING] Git        ^(Git-2.48.1-64-bit.exe^)
    set "MISS_GIT=1"
    set "TOOLS_OK=0"
)

where cmake >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo   [OK]      CMake
) else (
    echo   [MISSING] CMake      ^(cmake-3.31.5-windows-x86_64.msi^)
    set "MISS_CMAKE=1"
    set "TOOLS_OK=0"
)

where ninja >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo   [OK]      Ninja
) else (
    echo   [MISSING] Ninja      ^(ninja-win.zip^)
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
    echo   [MISSING] LLVM/Clang ^(LLVM-19.1.7-win64.exe^)
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
    echo   [MISSING] VS2022 / MSVC Build Tools ^(vs_BuildTools.exe^)
    set "MISS_MSVC=1"
    set "TOOLS_OK=0"
)

REM ------------------------------------------------------------------------------
REM Step 4: Check Third-Party Source Dependencies (thirdparty\)
REM ------------------------------------------------------------------------------
echo.
call :PRINT_CN "[3/3] Checking third-party libraries [thirdparty]... / \u68C0\u6D4B\u7B2C\u4E09\u65B9\u6E90\u7801\u4F9D\u8D56 [thirdparty]..."
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
    echo [ALL READY] Game assets, toolchain, and third-party libraries are all ready.
    call :PRINT_CN "[\u72B6\u6001\u826F\u597D] \u6E38\u620F\u8D44\u6E90\u3001\u7F16\u8BD1\u5DE5\u5177\u94FE\u4E0E\u7B2C\u4E09\u65B9\u4F9D\u8D56\u5168\u90E8\u5C31\u7EEA\uFF01"
    echo.
    echo Next steps:
    echo   1. scripts\run-codegen.bat   [Run AOT static codegen]
    echo   2. scripts\build-windows.bat [Build Windows native executable]
    call :PRINT_CN "\u63A5\u4E0B\u6765\u8BF7\u6309\u987A\u5E8F\u6267\u884C: 1. scripts\\run-codegen.bat   2. scripts\\build-windows.bat"
    echo ==============================================================================
    goto :SCRIPT_EXIT
)

if !ASSETS_OK! equ 0 (
    echo [ASSETS NOT READY] Please place your extracted Xbox 360 XEX game files into:
    echo   %CD%\game_root\default.xex
    echo   %CD%\game_root\DATA\
    call :PRINT_CN "[\u6E38\u620F\u8D44\u6E90\u672A\u5C31\u7EEA] \u8BF7\u5C06\u6B63\u7248\u89E3\u5305\u7684 XEX \u6E38\u620F\u6587\u4EF6\u653E\u5165 game_root\\default.xex \u4E0E game_root\\DATA\\"
    echo.
)

if !TOOLS_OK! equ 1 if !LIBS_OK! equ 1 (
    echo [STATUS] Toolchain and third-party libraries are ready. Only game_root assets are needed.
    call :PRINT_CN "[\u7EC4\u4EF6\u72B6\u6001] \u7F16\u8BD1\u5DE5\u5177\u94FE\u4E0E\u7B2C\u4E09\u65B9\u4F9D\u8D56\u5DF2\u5168\u90E8\u5C31\u7EEA\uFF0C\u4EC5\u9700\u8865\u9F50 game_root \u8D44\u6E90\u5373\u53EF\u3002"
    echo ==============================================================================
    goto :SCRIPT_EXIT
)

REM ------------------------------------------------------------------------------
REM Step 5: Generate exact direct download links into DOWNLOAD_LINKS.txt
REM ------------------------------------------------------------------------------
call :WRITE_DOWNLOAD_LINKS

echo [MISSING PACKAGES] Exact single-file download links have been exported to:
echo   %LINKS_FILE%
echo.
type "%LINKS_FILE%"
echo.
echo ==============================================================================
echo Unified Package Directory: %DOWNLOAD_DIR%\
echo.
call :PRINT_CN "[\u53D1\u73B0\u672A\u5B89\u88C5\u7684\u4F9D\u8D56\u5305] \u8BF7\u9009\u62E9\u8865\u5168\u65B9\u5F0F:\n  [1] \u7531\u811A\u672C\u81EA\u52A8\u4E0B\u8F7D\u7F3A\u5931\u5305\u81F3 downloads\\ \u76EE\u5F55\u5E76\u7EDF\u4E00\u6821\u9A8C\u5B89\u88C5 (\u9700\u8054\u7F51)\n  [2] \u6211\u5DF2\u6839\u636E DOWNLOAD_LINKS.txt \u81EA\u884C\u4E0B\u8F7D\u5E76\u653E\u5165 downloads\\\uFF0C\u7ACB\u5373\u91CD\u65B0\u6821\u9A8C\u5E76\u5B89\u88C5\n  [0] \u6682\u4E0D\u5B89\u88C5\uFF0C\u9000\u51FA\u68C0\u6D4B"
echo.
echo   [1] Auto-download missing packages into downloads\ ^& verify/install (Requires Internet)
echo   [2] I have placed downloaded files into downloads\ manually; verify ^& install now
echo   [0] Exit without installing
echo ==============================================================================

if "!CHECK_ONLY!"=="1" exit /b 1

set "USER_CHOICE="
set /p "USER_CHOICE=Select option [1/2/0]: "

if "!USER_CHOICE!"=="1" (
    echo.
    call :PRINT_CN "[\u81EA\u52A8\u4E0B\u8F7D] \u6B63\u5728\u4E0B\u8F7D\u7F3A\u5931\u5B89\u88C5\u5305\u81F3 downloads\\..."
    call :PS_DOWNLOAD_MISSING_PACKAGES
    echo.
    call :PRINT_CN "[\u6821\u9A8C\u5E76\u5B89\u88C5] \u6B63\u5728\u91CD\u65B0\u626B\u63CF downloads\\ \u5E76\u5B89\u88C5\u6821\u9A8C\u901A\u8FC7\u7684\u5305..."
    goto :RUN_CHECK
)
if "!USER_CHOICE!"=="2" (
    goto :RUN_CHECK
)
if "!USER_CHOICE!"=="0" goto :SCRIPT_EXIT

call :PRINT_CN "\u65E0\u6548\u9009\u9879\uFF0C\u8BF7\u91CD\u8BD5\u3002"
goto :RUN_CHECK

:SCRIPT_EXIT
if "!CHECK_ONLY!"=="0" (
    echo.
    call :PRINT_CN "\u8BF7\u6309 Enter \u952E\u5173\u95ED\u7A97\u53E3..."
    set /p "_EXIT_WAIT=Press Enter to close this window..."
)
exit /b 0

REM ==============================================================================
REM Helper Subroutines
REM ==============================================================================
:PRINT_CN
powershell -NoProfile -Command "Write-Host ([regex]::Unescape('%~1'))"
exit /b 0

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

:WRITE_DOWNLOAD_LINKS
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$dl = '%DOWNLOAD_DIR%';" ^
  "$out = '%LINKS_FILE%';" ^
  "$lines = [System.Collections.Generic.List[string]]::new();" ^
  "$lines.Add('==============================================================================');" ^
  "$lines.Add([regex]::Unescape('Shutokou Battle X - Exact Direct Download Links / \u7F3A\u5931\u7EC4\u4EF6\u7CBE\u786E\u5355\u6587\u4EF6\u4E0B\u8F7D\u6E05\u5355'));" ^
  "$lines.Add([regex]::Unescape('Target Folder / \u7EDF\u4E00\u5B58\u653E\u76EE\u5F55: ') + $dl + '\');" ^
  "$lines.Add([regex]::Unescape('Instructions  / \u4F7F\u7528\u8BF4\u660E:'));" ^
  "$lines.Add('  All links below are direct single-file downloads. Place downloaded files');" ^
  "$lines.Add('  directly into ' + $dl + '\ (keep original filenames, DO NOT extract).');" ^
  "$lines.Add([regex]::Unescape('  \u4EE5\u4E0B\u94FE\u63A5\u5747\u4E3A\u7CBE\u786E\u5355\u6587\u4EF6\u76F4\u94FE\uFF0C\u4E0B\u8F7D\u540E\u65E0\u9700\u89E3\u538B\u6216\u91CD\u547D\u540D\uFF0C\u8BF7\u76F4\u63A5\u653E\u5165 ') + $dl + [regex]::Unescape('\ \u76EE\u5F55\u3002'));" ^
  "$lines.Add('==============================================================================');" ^
  "$lines.Add('');" ^
  "if ('!MISS_GIT!' -eq '1')   { $lines.Add('  [Toolchain] Git-2.48.1-64-bit.exe               : https://github.com/git-for-windows/git/releases/download/v2.48.1.windows.1/Git-2.48.1-64-bit.exe') }" ^
  "if ('!MISS_CMAKE!' -eq '1') { $lines.Add('  [Toolchain] cmake-3.31.5-windows-x86_64.msi     : https://github.com/Kitware/CMake/releases/download/v3.31.5/cmake-3.31.5-windows-x86_64.msi') }" ^
  "if ('!MISS_NINJA!' -eq '1') { $lines.Add('  [Toolchain] ninja-win.zip                       : https://github.com/ninja-build/ninja/releases/download/v1.12.1/ninja-win.zip') }" ^
  "if ('!MISS_CLANG!' -eq '1') { $lines.Add('  [Toolchain] LLVM-19.1.7-win64.exe               : https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.7/LLVM-19.1.7-win64.exe') }" ^
  "if ('!MISS_MSVC!' -eq '1')  { $lines.Add('  [Toolchain] vs_BuildTools.exe                   : https://aka.ms/vs/17/release/vs_BuildTools.exe') }" ^
  "$items = @(" ^
  "  @{ file='cli11.zip';                           sentinel='thirdparty\cli11\include\CLI\CLI.hpp';          url='https://github.com/CLIUtils/CLI11/archive/HEAD.zip' }," ^
  "  @{ file='tomlplusplus.zip';                    sentinel='thirdparty\tomlplusplus\include\toml++\toml.hpp'; url='https://github.com/marzer/tomlplusplus/archive/HEAD.zip' }," ^
  "  @{ file='simde.zip';                           sentinel='thirdparty\simde\simde\simde-common.h';         url='https://github.com/simd-everywhere/simde/archive/HEAD.zip' }," ^
  "  @{ file='xxHash-v0.8.3.zip';                   sentinel='thirdparty\xxHash\xxhash.c';                    url='https://github.com/Cyan4973/xxHash/archive/refs/tags/v0.8.3.zip' }," ^
  "  @{ file='spdlog.zip';                          sentinel='thirdparty\spdlog\include\spdlog\spdlog.h';     url='https://github.com/gabime/spdlog/archive/HEAD.zip' }," ^
  "  @{ file='fmt.zip';                             sentinel='thirdparty\fmt\include\fmt\format.h';           url='https://github.com/fmtlib/fmt/archive/HEAD.zip' }," ^
  "  @{ file='utfcpp.zip';                          sentinel='thirdparty\utfcpp\source\utf8.h';               url='https://github.com/nemtrif/utfcpp/archive/HEAD.zip' }," ^
  "  @{ file='SDL-release-3.4.x.zip';               sentinel='thirdparty\sdl3\cmake\macros.cmake';            url='https://github.com/libsdl-org/SDL/archive/refs/heads/release-3.4.x.zip' }," ^
  "  @{ file='imgui.zip';                           sentinel='thirdparty\imgui\imgui.cpp';                    url='https://github.com/ocornut/imgui/archive/HEAD.zip' }," ^
  "  @{ file='inja.zip';                            sentinel='thirdparty\inja\include\inja\inja.hpp';         url='https://github.com/pantor/inja/archive/HEAD.zip' }," ^
  "  @{ file='libmspack.zip';                       sentinel='thirdparty\libmspack\cabextract\mspack\lzxd.c'; url='https://github.com/kyz/libmspack/archive/HEAD.zip' }," ^
  "  @{ file='o1heap.zip';                          sentinel='thirdparty\o1heap\o1heap\o1heap.c';             url='https://github.com/pavel-kirienko/o1heap/archive/HEAD.zip' }," ^
  "  @{ file='FFmpeg-xenia-ffmpeg-canary-full.zip'; sentinel='thirdparty\FFmpeg\libavutil\adler32.c';         url='https://github.com/wmarti/FFmpeg/archive/refs/heads/xenia-ffmpeg-canary-full.zip' }," ^
  "  @{ file='vulkan-headers.zip';                  sentinel='thirdparty\vulkan-headers\include\vulkan\vulkan.h';         url='https://github.com/KhronosGroup/Vulkan-Headers/archive/HEAD.zip' }," ^
  "  @{ file='vulkan-memory-allocator.zip';         sentinel='thirdparty\vulkan-memory-allocator\include\vk_mem_alloc.h'; url='https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator/archive/HEAD.zip' }," ^
  "  @{ file='spirv-headers.zip';                   sentinel='thirdparty\spirv-headers\include\spirv\unified1\spirv.h';   url='https://github.com/KhronosGroup/SPIRV-Headers/archive/HEAD.zip' }," ^
  "  @{ file='spirv-tools.zip';                     sentinel='thirdparty\spirv-tools\include\spirv-tools\libspirv.h';     url='https://github.com/KhronosGroup/SPIRV-Tools/archive/HEAD.zip' }," ^
  "  @{ file='glslang-11.13.0.zip';                 sentinel='thirdparty\glslang\SPIRV\SpvBuilder.h';                     url='https://github.com/KhronosGroup/glslang/archive/refs/tags/11.13.0.zip' }" ^
  ");" ^
  "foreach ($it in $items) {" ^
  "  if (-not (Test-Path $it.sentinel)) {" ^
  "    $lines.Add(('  [Library]   {0,-35} : {1}' -f $it.file, $it.url));" ^
  "  }" ^
  "}" ^
  "[System.IO.File]::WriteAllLines($out, $lines, [System.Text.UTF8Encoding]::new($false));"
exit /b 0

:PS_DOWNLOAD_MISSING_PACKAGES
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Continue';" ^
  "$dl = '%DOWNLOAD_DIR%';" ^
  "$tools = @(" ^
  "  @{ name='Git';          miss=('!MISS_GIT!'   -eq '1'); minSize=10000000; url='https://github.com/git-for-windows/git/releases/download/v2.48.1.windows.1/Git-2.48.1-64-bit.exe'; file='Git-2.48.1-64-bit.exe' }," ^
  "  @{ name='CMake';        miss=('!MISS_CMAKE!' -eq '1'); minSize=10000000; url='https://github.com/Kitware/CMake/releases/download/v3.31.5/cmake-3.31.5-windows-x86_64.msi'; file='cmake-3.31.5-windows-x86_64.msi' }," ^
  "  @{ name='Ninja';        miss=('!MISS_NINJA!' -eq '1'); minSize=50000;    url='https://github.com/ninja-build/ninja/releases/download/v1.12.1/ninja-win.zip'; file='ninja-win.zip' }," ^
  "  @{ name='LLVM';         miss=('!MISS_CLANG!' -eq '1'); minSize=50000000; url='https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.7/LLVM-19.1.7-win64.exe'; file='LLVM-19.1.7-win64.exe' }," ^
  "  @{ name='VSBuildTools'; miss=('!MISS_MSVC!'  -eq '1'); minSize=1000000;  url='https://aka.ms/vs/17/release/vs_BuildTools.exe'; file='vs_BuildTools.exe' }" ^
  ");" ^
  "foreach ($t in $tools) {" ^
  "  if (-not $t.miss) { continue }" ^
  "  $out = Join-Path $dl $t.file;" ^
  "  if ((Test-Path $out) -and ((Get-Item $out).Length -gt $t.minSize)) { Write-Host ('  [Cached]   ' + $t.file); continue }" ^
  "  Write-Host ('  [Download] ' + $t.name + ' -> ' + $out);" ^
  "  try { Invoke-WebRequest -Uri $t.url -OutFile $out -UseBasicParsing } catch { Write-Host ('  [ERROR] Failed to download ' + $t.name + ': ' + $_.Exception.Message) }" ^
  "}" ^
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
  "  if ((Test-Path $out) -and ((Get-Item $out).Length -gt 1024)) { Write-Host ('  [Cached]   ' + $it.file); continue }" ^
  "  Write-Host ('  [Download] ' + $it.name + ' -> ' + $out);" ^
  "  try { Invoke-WebRequest -Uri $it.url -OutFile $out -UseBasicParsing } catch { Write-Host ('  [ERROR] Failed to download ' + $it.name + ': ' + $_.Exception.Message) }" ^
  "}"
exit /b 0

:VERIFY_AND_INSTALL_DOWNLOADS
if "!CHECK_ONLY!"=="1" exit /b 0
if not exist "%DOWNLOAD_DIR%" exit /b 0

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Continue';" ^
  "Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue;" ^
  "$dl = '%DOWNLOAD_DIR%';" ^
  "$files = Get-ChildItem -Path $dl -File -ErrorAction SilentlyContinue;" ^
  "if (-not $files) { exit 0 }" ^
  "function Test-ValidZip($path) {" ^
  "  try { $z = [System.IO.Compression.ZipFile]::OpenRead($path); $c = $z.Entries.Count; $z.Dispose(); return ($c -gt 0) } catch { return $false }" ^
  "}" ^
  "if (-not (Get-Command git -ErrorAction SilentlyContinue)) {" ^
  "  $gitPkg = $files | Where-Object { $_.Name -like 'Git-*.exe' } | Select-Object -First 1;" ^
  "  if ($gitPkg -and $gitPkg.Length -gt 10000000) {" ^
  "    Write-Host ('  [Verify OK] Installing ' + $gitPkg.Name + '...');" ^
  "    Start-Process -FilePath $gitPkg.FullName -ArgumentList '/VERYSILENT','/NORESTART' -Wait;" ^
  "  } elseif ($gitPkg) { Write-Host ('  [CORRUPT] ' + $gitPkg.Name + ' is incomplete, please re-download.') }" ^
  "}" ^
  "if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {" ^
  "  $cmakePkg = $files | Where-Object { $_.Name -like 'cmake-*.msi' -or $_.Name -like 'cmake-*.exe' } | Select-Object -First 1;" ^
  "  if ($cmakePkg -and $cmakePkg.Length -gt 10000000) {" ^
  "    Write-Host ('  [Verify OK] Installing ' + $cmakePkg.Name + '...');" ^
  "    if ($cmakePkg.Extension -eq '.msi') { Start-Process -FilePath 'msiexec.exe' -ArgumentList '/i', ('\"' + $cmakePkg.FullName + '\"'), 'ADD_CMAKE_TO_PATH=System', '/passive', '/norestart' -Wait }" ^
  "    else { Start-Process -FilePath $cmakePkg.FullName -ArgumentList '/S' -Wait }" ^
  "  } elseif ($cmakePkg) { Write-Host ('  [CORRUPT] ' + $cmakePkg.Name + ' is incomplete, please re-download.') }" ^
  "}" ^
  "if (-not (Get-Command ninja -ErrorAction SilentlyContinue)) {" ^
  "  $ninjaPkg = $files | Where-Object { $_.Name -like '*ninja*.zip' } | Select-Object -First 1;" ^
  "  if ($ninjaPkg -and (Test-ValidZip $ninjaPkg.FullName)) {" ^
  "    Write-Host ('  [Verify OK] Extracting ' + $ninjaPkg.Name + ' -> tools\binutils\ninja.exe');" ^
  "    New-Item -ItemType Directory -Path 'tools\binutils' -Force | Out-Null;" ^
  "    Expand-Archive -Path $ninjaPkg.FullName -DestinationPath 'tools\binutils' -Force;" ^
  "  } elseif ($ninjaPkg) { Write-Host ('  [CORRUPT] ' + $ninjaPkg.Name + ' is not a valid zip archive, please re-download.') }" ^
  "}" ^
  "if (-not (Get-Command clang -ErrorAction SilentlyContinue)) {" ^
  "  $llvmPkg = $files | Where-Object { $_.Name -like 'LLVM-*.exe' } | Select-Object -First 1;" ^
  "  if ($llvmPkg -and $llvmPkg.Length -gt 50000000) {" ^
  "    Write-Host ('  [Verify OK] Installing ' + $llvmPkg.Name + '...');" ^
  "    Start-Process -FilePath $llvmPkg.FullName -ArgumentList '/S' -Wait;" ^
  "  } elseif ($llvmPkg) { Write-Host ('  [CORRUPT] ' + $llvmPkg.Name + ' is incomplete, please re-download.') }" ^
  "}" ^
  "$hasMsvc = [bool](Get-Command cl -ErrorAction SilentlyContinue);" ^
  "$vsw = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe';" ^
  "if ((-not $hasMsvc) -and (Test-Path $vsw)) {" ^
  "  $vsPath = & $vsw -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null;" ^
  "  if ($vsPath) { $hasMsvc = $true }" ^
  "}" ^
  "if (-not $hasMsvc) {" ^
  "  $vsPkg = $files | Where-Object { $_.Name -like 'vs_BuildTools*.exe' } | Select-Object -First 1;" ^
  "  if ($vsPkg -and $vsPkg.Length -gt 1000000) {" ^
  "    Write-Host ('  [Verify OK] Installing ' + $vsPkg.Name + ' (MSVC C++ Build Tools & Windows SDK)...');" ^
  "    Start-Process -FilePath $vsPkg.FullName -ArgumentList '--wait','--passive','--norestart','--add','Microsoft.VisualStudio.Workload.VCTools','--includeRecommended' -Wait;" ^
  "  } elseif ($vsPkg) { Write-Host ('  [CORRUPT] ' + $vsPkg.Name + ' is incomplete, please re-download.') }" ^
  "}" ^
  "$items = @(" ^
  "  @{ name='cli11';        sentinel='thirdparty\cli11\include\CLI\CLI.hpp';          target='thirdparty\cli11';        patterns=@('*cli11*.zip','*CLI11*.zip') }," ^
  "  @{ name='tomlplusplus'; sentinel='thirdparty\tomlplusplus\include\toml++\toml.hpp'; target='thirdparty\tomlplusplus'; patterns=@('*toml*.zip') }," ^
  "  @{ name='simde';        sentinel='thirdparty\simde\simde\simde-common.h';         target='thirdparty\simde';        patterns=@('*simde*.zip') }," ^
  "  @{ name='xxHash';       sentinel='thirdparty\xxHash\xxhash.c';                    target='thirdparty\xxHash';       patterns=@('*xxhash*.zip','*xxHash*.zip') }," ^
  "  @{ name='spdlog';       sentinel='thirdparty\spdlog\include\spdlog\spdlog.h';     target='thirdparty\spdlog';       patterns=@('*spdlog*.zip') }," ^
  "  @{ name='fmt';          sentinel='thirdparty\fmt\include\fmt\format.h';           target='thirdparty\fmt';          patterns=@('*fmt*.zip') }," ^
  "  @{ name='utfcpp';       sentinel='thirdparty\utfcpp\source\utf8.h';               target='thirdparty\utfcpp';       patterns=@('*utfcpp*.zip') }," ^
  "  @{ name='sdl3';         sentinel='thirdparty\sdl3\cmake\macros.cmake';            target='thirdparty\sdl3';         patterns=@('*sdl*.zip','*SDL*.zip') }," ^
  "  @{ name='imgui';        sentinel='thirdparty\imgui\imgui.cpp';                    target='thirdparty\imgui';        patterns=@('*imgui*.zip') }," ^
  "  @{ name='inja';         sentinel='thirdparty\inja\include\inja\inja.hpp';         target='thirdparty\inja';         patterns=@('*inja*.zip') }," ^
  "  @{ name='libmspack';    sentinel='thirdparty\libmspack\cabextract\mspack\lzxd.c'; target='thirdparty\libmspack';    patterns=@('*libmspack*.zip') }," ^
  "  @{ name='o1heap';       sentinel='thirdparty\o1heap\o1heap\o1heap.c';             target='thirdparty\o1heap';       patterns=@('*o1heap*.zip') }," ^
  "  @{ name='FFmpeg';       sentinel='thirdparty\FFmpeg\libavutil\adler32.c';         target='thirdparty\FFmpeg';       patterns=@('*ffmpeg*.zip','*FFmpeg*.zip') }," ^
  "  @{ name='vulkan-headers';          sentinel='thirdparty\vulkan-headers\include\vulkan\vulkan.h';         target='thirdparty\vulkan-headers';          patterns=@('*vulkan-headers*.zip','*Vulkan-Headers*.zip') }," ^
  "  @{ name='vulkan-memory-allocator'; sentinel='thirdparty\vulkan-memory-allocator\include\vk_mem_alloc.h'; target='thirdparty\vulkan-memory-allocator'; patterns=@('*vulkan-memory-allocator*.zip','*VulkanMemoryAllocator*.zip') }," ^
  "  @{ name='spirv-headers';           sentinel='thirdparty\spirv-headers\include\spirv\unified1\spirv.h';   target='thirdparty\spirv-headers';           patterns=@('*spirv-headers*.zip','*SPIRV-Headers*.zip') }," ^
  "  @{ name='spirv-tools';             sentinel='thirdparty\spirv-tools\include\spirv-tools\libspirv.h';     target='thirdparty\spirv-tools';             patterns=@('*spirv-tools*.zip','*SPIRV-Tools*.zip') }," ^
  "  @{ name='glslang';                 sentinel='thirdparty\glslang\SPIRV\SpvBuilder.h';                     target='thirdparty\glslang';                 patterns=@('*glslang*.zip') }" ^
  ");" ^
  "$zips = $files | Where-Object { $_.Extension -eq '.zip' -and $_.Name -notlike '*ninja*' };" ^
  "foreach ($it in $items) {" ^
  "  if (Test-Path $it.sentinel) { continue }" ^
  "  $match = $null;" ^
  "  foreach ($pat in $it.patterns) {" ^
  "    $match = $zips | Where-Object { $_.Name -like $pat } | Select-Object -First 1;" ^
  "    if ($match) { break }" ^
  "  }" ^
  "  if (-not $match) { continue }" ^
  "  if (-not (Test-ValidZip $match.FullName)) {" ^
  "    Write-Host ('  [CORRUPT] ' + $match.Name + ' is corrupted/incomplete, please re-download.');" ^
  "    continue;" ^
  "  }" ^
  "  Write-Host ('  [Verify OK] Extracting ' + $match.Name + ' -> ' + $it.target);" ^
  "  $tmp = Join-Path $dl ('_tmp_' + $it.name);" ^
  "  if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }" ^
  "  Expand-Archive -Path $match.FullName -DestinationPath $tmp -Force;" ^
  "  if (Test-Path $it.target) { Remove-Item -Recurse -Force $it.target }" ^
  "  $dirs = Get-ChildItem -Path $tmp -Directory;" ^
  "  $topFiles = Get-ChildItem -Path $tmp -File;" ^
  "  if ($dirs.Count -eq 1 -and $topFiles.Count -eq 0) {" ^
  "    Move-Item -Path $dirs[0].FullName -Destination $it.target;" ^
  "  } else {" ^
  "    New-Item -ItemType Directory -Path $it.target -Force | Out-Null;" ^
  "    Get-ChildItem -Path $tmp | Move-Item -Destination $it.target;" ^
  "  }" ^
  "  if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }" ^
  "  if (Test-Path $it.sentinel) { Write-Host ('  [Installed] ' + $it.name) } else { Write-Host ('  [WARN] ' + $it.name + ' extracted, but missing expected file: ' + $it.sentinel) }" ^
  "}"

REM Refresh session PATH after any toolchain package installation
if exist "%CD%\tools\binutils" set "PATH=%CD%\tools\binutils;!PATH!"
if exist "C:\Program Files\Git\cmd" set "PATH=!PATH!;C:\Program Files\Git\cmd"
if exist "C:\Program Files\CMake\bin" set "PATH=!PATH!;C:\Program Files\CMake\bin"
if exist "C:\Program Files\LLVM\bin" set "PATH=!PATH!;C:\Program Files\LLVM\bin"
exit /b 0
