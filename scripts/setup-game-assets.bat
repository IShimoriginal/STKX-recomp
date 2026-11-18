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
call :CHECK_LIB "tracy"                   "thirdparty\tracy\CMakeLists.txt"
call :CHECK_LIB "fidelityfx"              "thirdparty\fidelityfx\CMakeLists.txt"

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
powershell -NoProfile -Command "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false); [Console]::WriteLine([regex]::Unescape('%~1'))"
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
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_helper.ps1" -Action links -DownloadDir "%DOWNLOAD_DIR%" -LinksFile "%LINKS_FILE%" -MissGit !MISS_GIT! -MissCmake !MISS_CMAKE! -MissNinja !MISS_NINJA! -MissClang !MISS_CLANG! -MissMsvc !MISS_MSVC!
exit /b 0

:PS_DOWNLOAD_MISSING_PACKAGES
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_helper.ps1" -Action download -DownloadDir "%DOWNLOAD_DIR%" -MissGit !MISS_GIT! -MissCmake !MISS_CMAKE! -MissNinja !MISS_NINJA! -MissClang !MISS_CLANG! -MissMsvc !MISS_MSVC!
exit /b 0

:VERIFY_AND_INSTALL_DOWNLOADS
if "!CHECK_ONLY!"=="1" exit /b 0
if not exist "%DOWNLOAD_DIR%" exit /b 0

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_helper.ps1" -Action verify -DownloadDir "%DOWNLOAD_DIR%"

REM Refresh session PATH after any toolchain package installation
if exist "%CD%\tools\binutils" set "PATH=%CD%\tools\binutils;!PATH!"
if exist "C:\Program Files\Git\cmd" set "PATH=!PATH!;C:\Program Files\Git\cmd"
if exist "C:\Program Files\CMake\bin" set "PATH=!PATH!;C:\Program Files\CMake\bin"
if exist "C:\Program Files\LLVM\bin" set "PATH=!PATH!;C:\Program Files\LLVM\bin"
exit /b 0
