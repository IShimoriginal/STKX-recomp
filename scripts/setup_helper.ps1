param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('verify', 'links', 'download')]
    [string]$Action,

    [string]$DownloadDir = (Join-Path $PWD 'downloads'),
    [string]$LinksFile = (Join-Path $PWD 'downloads\DOWNLOAD_LINKS.txt'),
    [int]$MissGit = 0,
    [int]$MissCmake = 0,
    [int]$MissNinja = 0,
    [int]$MissClang = 0,
    [int]$MissMsvc = 0
)

$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

$LibItems = @(
    @{ name = 'cli11';                   file = 'cli11.zip';                           sentinel = 'thirdparty\cli11\include\CLI\CLI.hpp';                     target = 'thirdparty\cli11';                   url = 'https://github.com/CLIUtils/CLI11/archive/HEAD.zip';                                                 patterns = @('*cli11*.zip', '*CLI11*.zip') },
    @{ name = 'tomlplusplus';            file = 'tomlplusplus.zip';                    sentinel = 'thirdparty\tomlplusplus\include\toml++\toml.hpp';            target = 'thirdparty\tomlplusplus';            url = 'https://github.com/marzer/tomlplusplus/archive/HEAD.zip';                                            patterns = @('*toml*.zip') },
    @{ name = 'simde';                   file = 'simde.zip';                           sentinel = 'thirdparty\simde\simde\simde-common.h';                    target = 'thirdparty\simde';                   url = 'https://github.com/simd-everywhere/simde/archive/HEAD.zip';                                          patterns = @('*simde*.zip') },
    @{ name = 'xxHash';                  file = 'xxHash-v0.8.3.zip';                   sentinel = 'thirdparty\xxHash\xxhash.c';                               target = 'thirdparty\xxHash';                  url = 'https://github.com/Cyan4973/xxHash/archive/refs/tags/v0.8.3.zip';                                    patterns = @('*xxhash*.zip', '*xxHash*.zip') },
    @{ name = 'spdlog';                  file = 'spdlog.zip';                          sentinel = 'thirdparty\spdlog\include\spdlog\spdlog.h';                target = 'thirdparty\spdlog';                  url = 'https://github.com/gabime/spdlog/archive/HEAD.zip';                                                  patterns = @('*spdlog*.zip') },
    @{ name = 'fmt';                     file = 'fmt.zip';                             sentinel = 'thirdparty\fmt\include\fmt\format.h';                      target = 'thirdparty\fmt';                     url = 'https://github.com/fmtlib/fmt/archive/HEAD.zip';                                                     patterns = @('*fmt*.zip') },
    @{ name = 'utfcpp';                  file = 'utfcpp.zip';                          sentinel = 'thirdparty\utfcpp\source\utf8.h';                          target = 'thirdparty\utfcpp';                  url = 'https://github.com/nemtrif/utfcpp/archive/HEAD.zip';                                                 patterns = @('*utfcpp*.zip') },
    @{ name = 'sdl3';                    file = 'SDL-release-3.4.x.zip';               sentinel = 'thirdparty\sdl3\cmake\macros.cmake';                       target = 'thirdparty\sdl3';                    url = 'https://github.com/libsdl-org/SDL/archive/refs/heads/release-3.4.x.zip';                             patterns = @('*sdl*.zip', '*SDL*.zip') },
    @{ name = 'imgui';                   file = 'imgui.zip';                           sentinel = 'thirdparty\imgui\imgui.cpp';                               target = 'thirdparty\imgui';                   url = 'https://github.com/ocornut/imgui/archive/HEAD.zip';                                                  patterns = @('*imgui*.zip') },
    @{ name = 'inja';                    file = 'inja.zip';                            sentinel = 'thirdparty\inja\include\inja\inja.hpp';                    target = 'thirdparty\inja';                    url = 'https://github.com/pantor/inja/archive/HEAD.zip';                                                    patterns = @('*inja*.zip') },
    @{ name = 'libmspack';               file = 'libmspack.zip';                       sentinel = 'thirdparty\libmspack\cabextract\mspack\lzxd.c';            target = 'thirdparty\libmspack';               url = 'https://github.com/kyz/libmspack/archive/HEAD.zip';                                                  patterns = @('*libmspack*.zip') },
    @{ name = 'o1heap';                  file = 'o1heap.zip';                          sentinel = 'thirdparty\o1heap\o1heap\o1heap.c';                        target = 'thirdparty\o1heap';                  url = 'https://github.com/pavel-kirienko/o1heap/archive/HEAD.zip';                                          patterns = @('*o1heap*.zip') },
    @{ name = 'FFmpeg';                  file = 'FFmpeg-xenia-ffmpeg-canary-full.zip'; sentinel = 'thirdparty\FFmpeg\libavutil\adler32.c';                    target = 'thirdparty\FFmpeg';                  url = 'https://github.com/wmarti/FFmpeg/archive/refs/heads/xenia-ffmpeg-canary-full.zip';                   patterns = @('*ffmpeg*.zip', '*FFmpeg*.zip') },
    @{ name = 'vulkan-headers';          file = 'vulkan-headers.zip';                  sentinel = 'thirdparty\vulkan-headers\include\vulkan\vulkan.h';        target = 'thirdparty\vulkan-headers';          url = 'https://github.com/KhronosGroup/Vulkan-Headers/archive/HEAD.zip';                                    patterns = @('*vulkan-headers*.zip', '*Vulkan-Headers*.zip') },
    @{ name = 'vulkan-memory-allocator'; file = 'vulkan-memory-allocator.zip';         sentinel = 'thirdparty\vulkan-memory-allocator\include\vk_mem_alloc.h'; target = 'thirdparty\vulkan-memory-allocator'; url = 'https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator/archive/HEAD.zip';                   patterns = @('*vulkan-memory-allocator*.zip', '*VulkanMemoryAllocator*.zip') },
    @{ name = 'spirv-headers';           file = 'spirv-headers.zip';                   sentinel = 'thirdparty\spirv-headers\include\spirv\unified1\spirv.h';  target = 'thirdparty\spirv-headers';           url = 'https://github.com/KhronosGroup/SPIRV-Headers/archive/HEAD.zip';                                     patterns = @('*spirv-headers*.zip', '*SPIRV-Headers*.zip') },
    @{ name = 'spirv-tools';             file = 'spirv-tools.zip';                     sentinel = 'thirdparty\spirv-tools\include\spirv-tools\libspirv.h';    target = 'thirdparty\spirv-tools';             url = 'https://github.com/KhronosGroup/SPIRV-Tools/archive/HEAD.zip';                                       patterns = @('*spirv-tools*.zip', '*SPIRV-Tools*.zip') },
    @{ name = 'glslang';                 file = 'glslang-11.13.0.zip';                 sentinel = 'thirdparty\glslang\SPIRV\SpvBuilder.h';                    target = 'thirdparty\glslang';                 url = 'https://github.com/KhronosGroup/glslang/archive/refs/tags/11.13.0.zip';                              patterns = @('*glslang*.zip') }
)

$ToolItems = @(
    @{ name = 'Git';          miss = ($MissGit -eq 1);   minSize = 10000000; file = 'Git-2.48.1-64-bit.exe';           url = 'https://github.com/git-for-windows/git/releases/download/v2.48.1.windows.1/Git-2.48.1-64-bit.exe' },
    @{ name = 'CMake';        miss = ($MissCmake -eq 1); minSize = 10000000; file = 'cmake-3.31.5-windows-x86_64.msi'; url = 'https://github.com/Kitware/CMake/releases/download/v3.31.5/cmake-3.31.5-windows-x86_64.msi' },
    @{ name = 'Ninja';        miss = ($MissNinja -eq 1); minSize = 50000;    file = 'ninja-win.zip';                   url = 'https://github.com/ninja-build/ninja/releases/download/v1.12.1/ninja-win.zip' },
    @{ name = 'LLVM';         miss = ($MissClang -eq 1); minSize = 50000000; file = 'LLVM-19.1.7-win64.exe';           url = 'https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.7/LLVM-19.1.7-win64.exe' },
    @{ name = 'VSBuildTools'; miss = ($MissMsvc -eq 1);  minSize = 1000000;  file = 'vs_BuildTools.exe';               url = 'https://aka.ms/vs/17/release/vs_BuildTools.exe' }
)

function Test-ValidZip([string]$Path) {
    try {
        $z = [System.IO.Compression.ZipFile]::OpenRead($Path)
        $c = $z.Entries.Count
        $z.Dispose()
        return ($c -gt 0)
    } catch {
        return $false
    }
}

if ($Action -eq 'links') {
    if (-not (Test-Path $DownloadDir)) { New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null }
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('==============================================================================')
    $lines.Add('Shutokou Battle X - Exact Direct Download Links / 缺失组件精确单文件下载清单')
    $lines.Add("Target Folder / 统一存放目录: $DownloadDir\")
    $lines.Add('Instructions  / 使用说明:')
    $lines.Add('  All links below are direct single-file downloads. Place downloaded files')
    $lines.Add("  directly into $DownloadDir\ (keep original filenames, DO NOT extract).")
    $lines.Add("  以下链接均为精确单文件直链，下载后无需解压或重命名，请直接放入 $DownloadDir\ 目录。")
    $lines.Add('==============================================================================')
    $lines.Add('')

    foreach ($t in $ToolItems) {
        if ($t.miss) {
            $lines.Add(('  [Toolchain] {0,-35} : {1}' -f $t.file, $t.url))
        }
    }
    foreach ($it in $LibItems) {
        if (-not (Test-Path $it.sentinel)) {
            $lines.Add(('  [Library]   {0,-35} : {1}' -f $it.file, $it.url))
        }
    }

    [System.IO.File]::WriteAllLines($LinksFile, $lines, [System.Text.UTF8Encoding]::new($false))
    exit 0
}

if ($Action -eq 'download') {
    if (-not (Test-Path $DownloadDir)) { New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null }
    foreach ($t in $ToolItems) {
        if (-not $t.miss) { continue }
        $out = Join-Path $DownloadDir $t.file
        if ((Test-Path $out) -and ((Get-Item $out).Length -gt $t.minSize)) {
            Write-Host ("  [Cached]   " + $t.file)
            continue
        }
        Write-Host ("  [Download] " + $t.name + " -> " + $out)
        try {
            Invoke-WebRequest -Uri $t.url -OutFile $out -UseBasicParsing
        } catch {
            Write-Host ("  [ERROR] Failed to download " + $t.name + ": " + $_.Exception.Message)
        }
    }
    foreach ($it in $LibItems) {
        if (Test-Path $it.sentinel) { continue }
        $out = Join-Path $DownloadDir $it.file
        if ((Test-Path $out) -and ((Get-Item $out).Length -gt 1024)) {
            Write-Host ("  [Cached]   " + $it.file)
            continue
        }
        Write-Host ("  [Download] " + $it.name + " -> " + $out)
        try {
            Invoke-WebRequest -Uri $it.url -OutFile $out -UseBasicParsing
        } catch {
            Write-Host ("  [ERROR] Failed to download " + $it.name + ": " + $_.Exception.Message)
        }
    }
    exit 0
}

if ($Action -eq 'verify') {
    if (-not (Test-Path $DownloadDir)) { exit 0 }
    $files = Get-ChildItem -Path $DownloadDir -File -ErrorAction SilentlyContinue
    if (-not $files) { exit 0 }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        $gitPkg = $files | Where-Object { $_.Name -like 'Git-*.exe' } | Select-Object -First 1
        if ($gitPkg -and $gitPkg.Length -gt 10000000) {
            Write-Host ("  [Verify OK] Installing " + $gitPkg.Name + "...")
            Start-Process -FilePath $gitPkg.FullName -ArgumentList '/VERYSILENT', '/NORESTART' -Wait
        } elseif ($gitPkg) {
            Write-Host ("  [CORRUPT] " + $gitPkg.Name + " is incomplete, please re-download.")
        }
    }

    if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
        $cmakePkg = $files | Where-Object { $_.Name -like 'cmake-*.msi' -or $_.Name -like 'cmake-*.exe' } | Select-Object -First 1
        if ($cmakePkg -and $cmakePkg.Length -gt 10000000) {
            Write-Host ("  [Verify OK] Installing " + $cmakePkg.Name + "...")
            if ($cmakePkg.Extension -eq '.msi') {
                $msiArg = '/i "' + $cmakePkg.FullName + '" ADD_CMAKE_TO_PATH=System /passive /norestart'
                Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArg -Wait
            } else {
                Start-Process -FilePath $cmakePkg.FullName -ArgumentList '/S' -Wait
            }
        } elseif ($cmakePkg) {
            Write-Host ("  [CORRUPT] " + $cmakePkg.Name + " is incomplete, please re-download.")
        }
    }

    if (-not (Get-Command ninja -ErrorAction SilentlyContinue)) {
        $ninjaPkg = $files | Where-Object { $_.Name -like '*ninja*.zip' } | Select-Object -First 1
        if ($ninjaPkg -and (Test-ValidZip $ninjaPkg.FullName)) {
            Write-Host ("  [Verify OK] Extracting " + $ninjaPkg.Name + " -> tools\binutils\ninja.exe")
            New-Item -ItemType Directory -Path 'tools\binutils' -Force | Out-Null
            Expand-Archive -Path $ninjaPkg.FullName -DestinationPath 'tools\binutils' -Force
        } elseif ($ninjaPkg) {
            Write-Host ("  [CORRUPT] " + $ninjaPkg.Name + " is not a valid zip archive, please re-download.")
        }
    }

    if (-not (Get-Command clang -ErrorAction SilentlyContinue)) {
        $llvmPkg = $files | Where-Object { $_.Name -like 'LLVM-*.exe' } | Select-Object -First 1
        if ($llvmPkg -and $llvmPkg.Length -gt 50000000) {
            Write-Host ("  [Verify OK] Installing " + $llvmPkg.Name + "...")
            Start-Process -FilePath $llvmPkg.FullName -ArgumentList '/S' -Wait
        } elseif ($llvmPkg) {
            Write-Host ("  [CORRUPT] " + $llvmPkg.Name + " is incomplete, please re-download.")
        }
    }

    $hasMsvc = [bool](Get-Command cl -ErrorAction SilentlyContinue)
    $vsw = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if ((-not $hasMsvc) -and (Test-Path $vsw)) {
        $vsPath = & $vsw -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
        if ($vsPath) { $hasMsvc = $true }
    }
    if (-not $hasMsvc) {
        $vsPkg = $files | Where-Object { $_.Name -like 'vs_BuildTools*.exe' } | Select-Object -First 1
        if ($vsPkg -and $vsPkg.Length -gt 1000000) {
            Write-Host ("  [Verify OK] Installing " + $vsPkg.Name + " (MSVC C++ Build Tools & Windows SDK)...")
            Start-Process -FilePath $vsPkg.FullName -ArgumentList '--wait', '--passive', '--norestart', '--add', 'Microsoft.VisualStudio.Workload.VCTools', '--includeRecommended' -Wait
        } elseif ($vsPkg) {
            Write-Host ("  [CORRUPT] " + $vsPkg.Name + " is incomplete, please re-download.")
        }
    }

    $zips = $files | Where-Object { $_.Extension -eq '.zip' -and $_.Name -notlike '*ninja*' }
    foreach ($it in $LibItems) {
        if (Test-Path $it.sentinel) { continue }
        $match = $null
        foreach ($pat in $it.patterns) {
            $match = $zips | Where-Object { $_.Name -like $pat } | Select-Object -First 1
            if ($match) { break }
        }
        if (-not $match) { continue }
        if (-not (Test-ValidZip $match.FullName)) {
            Write-Host ("  [CORRUPT] " + $match.Name + " is corrupted/incomplete, please re-download.")
            continue
        }
        Write-Host ("  [Verify OK] Extracting " + $match.Name + " -> " + $it.target)
        $tmp = Join-Path $DownloadDir ('_tmp_' + $it.name)
        if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
        Expand-Archive -Path $match.FullName -DestinationPath $tmp -Force
        if (Test-Path $it.target) { Remove-Item -Recurse -Force $it.target }
        $dirs = Get-ChildItem -Path $tmp -Directory
        $topFiles = Get-ChildItem -Path $tmp -File
        if ($dirs.Count -eq 1 -and $topFiles.Count -eq 0) {
            Move-Item -Path $dirs[0].FullName -Destination $it.target
        } else {
            New-Item -ItemType Directory -Path $it.target -Force | Out-Null
            Get-ChildItem -Path $tmp | Move-Item -Destination $it.target
        }
        if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
        if (Test-Path $it.sentinel) {
            Write-Host ("  [Installed] " + $it.name)
        } else {
            Write-Host ("  [WARN] " + $it.name + " extracted, but missing expected file: " + $it.sentinel)
        }
    }
    exit 0
}
