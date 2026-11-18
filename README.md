# 首都高バトルX (Shutokou Battle X) - Windows Native Recompilation

[![Platform](https://img.shields.io/badge/Platform-Windows%20x64%20(DirectX%2012%20%2F%20Vulkan)-blue.svg)]()
[![Recompiler](https://img.shields.io/badge/Recompiler-ReXGlue%20%2F%20ShiftGlue-emerald.svg)]()
[![Title ID](https://img.shields.io/badge/Title%20ID-474507D1-orange.svg)]()
[![Target](https://img.shields.io/badge/Target-C%2B%2B23%20Native%20MSVC%20%2F%20Clang-green.svg)]()

A native static recompilation project for the Xbox 360 title **Shutokou Battle X** (首都高バトルX, Title ID: `474507D1`) developed by Genki Co., Ltd.

> **Note:** Only the Japanese release (**Shutokou Battle X**, Title ID `474507D1`) has been tested. Other regional releases have **not** been tested.

Based on the [ReXGlue](https://github.com/rexglue/rexglue-sdk) ahead-of-time (AOT) static recompilation SDK, with [MCLA-recomp](https://github.com/arcanite24/MCLA-recomp) and [pinyon-shift](https://github.com/arcanite24/pinyon-shift) as reference projects.

**Language / 语言**: [简体中文](#简体中文) | [English](#english)

---

## 简体中文

### 前言

本项目构思及维护均由一人完成，95% 以上代码依赖 AI 生成，仅作个人学习研究使用，不确保后续更新进度及时。本人不鼓励、不支持非法下载及盗版，请从您拥有的合法正版游戏副本提取游戏本体档案！

<p align="center">
  <img src="https://github.com/user-attachments/assets/37ac4718-fbd9-4f28-be9f-46086c7b8f78" width="48%" alt="Copy" />
  <img src="https://github.com/user-attachments/assets/20acf720-86ca-4939-9b2f-3814e0a70dce" width="48%" alt="Disc" />
</p>

> **格式说明**：本项目**仅支持已解包的 XEX 格式游戏副本**（需包含 `default.xex` 与 `DATA/` 目录），**不支持 `.iso` 光盘镜像格式**。

---
<p align="center">
  <img src="https://github.com/user-attachments/assets/e18e4109-238d-4ed9-a37c-5bfe6298b5a0" width="32%" alt="Screenshot 1" />
  <img src="https://github.com/user-attachments/assets/939820f0-b8fd-422e-94c8-211b631e6bb2" width="32%" alt="Screenshot 2" />
  <img src="https://github.com/user-attachments/assets/962a4e8b-aa9f-4053-8e7d-2b5ee366c0f6" width="32%" alt="Screenshot 3" />
</p>

---

### 快速上手

#### 环境要求
- **操作系统**：Windows 10 / 11 (x64)
- **磁盘空间**：安装与编译过程中约需 **9 GB** 可用空间（编译完成后的独立游戏目录约 **3 GB**）
- **预计用时**：完整下载依赖与编译总用时约 **20–60 分钟**（视网络状况与 CPU 性能而定）
- **编译工具链**：Git、CMake (3.25+)、Ninja、LLVM/Clang (`clang` / `clang++`)、VS2022 / MSVC Build Tools（可由下方安装向导自动检测并补齐）

> **安装方式说明**：放置好下方的 `game_root/` 游戏文件后，您既可以直接双击根目录的 **`Setup.bat`** 一键按流程引导完成全部安装与编译（每步完成后按 Enter 进入下一步），也可以手动依序运行 `scripts\` 下的 3 个脚本（`setup-game-assets.bat` → `run-codegen.bat` → `build-windows.bat`）。

#### 0. 准备正版游戏文件
请自行搜索相关教程，将您合法持有的 Xbox 360 正版《首都高バトルX》（Title ID: `474507D1`）光盘通过 Redump 等合法方式提取到电脑本地，并解包为 XEX 格式文件（包含 `default.xex` 与 `DATA/` 文件夹；不接受 `.iso` 镜像）。

#### 1. 放置游戏文件并检测环境
> **目录规划建议**：建议先将本项目解压/放置在一个磁盘空间充足的目录（如 `D:\STKX-recomp\`），并在其**同级目录**提前新建一个名为 **`ShutokouBattleX`** 的空文件夹（即 `..\ShutokouBattleX\`，例如 `D:\ShutokouBattleX\`）。后续编译完成时，脚本会自动将可独立运行的成品游戏与资源同步到该目录中，方便直接启动或整包迁移。

将提取并解包后的游戏文件放置于 `game_root/` 目录：
- `game_root/default.xex`
- `game_root/DATA/`

然后直接双击根目录的 **`Setup.bat`**（向导会自动调用第 1–3 步），或手动运行环境与资源检测脚本：
```cmd
scripts\setup-game-assets.bat
```
脚本采用**统一 `downloads\` 目录校验安装流程**：
1. **自动扫描 `downloads\` 并校验安装**：脚本启动时会先扫描 `downloads\` 目录并自动校验、安装/解压所有已放入的有效安装包（含 `vs_BuildTools.exe` 自动静默勾选 C++ 构建工具链，无需依赖 `winget`）。
2. **自动输出精确单文件直链（`downloads\DOWNLOAD_LINKS.txt`）**：若仍有未安装的组件（包括 `Git-2.48.1-64-bit.exe`、`cmake-3.31.5-windows-x86_64.msi`、`ninja-win.zip`、`LLVM-19.1.7-win64.exe`、`vs_BuildTools.exe` 以及 20 个 `thirdparty/` 源码 `.zip` 包），脚本会直接输出**精确到单个安装包的下载直链**并保存至 `downloads\DOWNLOAD_LINKS.txt`。
3. **统一存放于 `downloads\` 校验安装**：
   - **选项 `[1]`（脚本自动下载）**：由脚本自动将缺失安装包下载至 `downloads\` 目录，随后统一校验并安装。
   - **选项 `[2]`（弱网/手动下载补全）**：您可根据 `downloads\DOWNLOAD_LINKS.txt` 中的直链，使用浏览器或下载工具自行下载缺失文件，**保持原文件名且无需手动解压**，全部放入项目根目录下的 **`downloads\`** 文件夹，然后选择 `[2]`（或重新运行脚本），脚本会自动校验 `downloads\` 中已有的安装包，完好的包直接安装/解压，仍有缺失则继续提示补全。

#### 2. 运行代码生成 (AOT Codegen)
*(若使用 `Setup.bat`，在第 1 步完成后按 Enter 键会自动进入本步骤)*
```cmd
scripts\run-codegen.bat
```
*(使用 `rexglue.exe` 根据 `manifest.toml` 将 PowerPC 机器码静态翻译为 C++ 代码，输出至 `src/generated/entrypoint/`)*

#### 3. 编译 Windows 原生程序
*(若使用 `Setup.bat`，在第 2 步完成后按 Enter 键会自动进入本步骤)*
```cmd
scripts\build-windows.bat
```
编译完成后，可执行文件、启动器与运行库位于：
- `out\win-amd64\Release\shutokou_battle_x.exe`
- `out\win-amd64\Release\Launcher.exe`

**启动与迁移说明**：
- 如果您已按第 1 步在同级目录提前新建了 `..\ShutokouBattleX\` 文件夹，构建脚本在编译完成后已自动将 `shutokou_battle_x.exe`、`Launcher.exe`、全部运行所需的 `.dll`、`launch-game.bat` 以及 `game_root\`（若目标目录尚无该文件夹）同步过去。您**可以直接在 `..\ShutokouBattleX\` 中运行 `Launcher.exe`（或 `shutokou_battle_x.exe`）启动游戏**，也可以随时将整个 `ShutokouBattleX` 文件夹作为绿色独立游戏目录自由移动或迁移到其他路径/电脑。

---

### 项目特性与当前进度

#### 基本特性
- **DX12、Vulkan API 支持（Vulkan 仍在适配中，不推荐）**
- **1X（720P）、2X（1440P）及 3X（2160P）运行分辨率支持**
- **30、40、60、120FPS 支持**
- **支持垂直同步开关**
- **原生 XInput 手柄支持**
- **存档**
- **其余 ReXGlue 原生支持的功能**

#### 已实现并实测通过
- **高帧率与物理帧率解耦**：解除原版 Xbox 360 30 FPS 限制，支持高帧率原生运行。
- **核心流程与计时同步**：开场 Logo、非车库菜单动画、比赛 `3-2-1-GO` 倒计时及 4 秒等待、Time Attack 计时器与油门加速速度均已正常。
- **菜单光标连发限速**：修复了高帧率下按住方向键时菜单光标连发过快的问题。
- **车库车辆转盘速度修复**：修复了车库车辆展示转盘在高帧率下旋转过快的问题。
- **战斗 SP 扣血速度修复**：修复了战斗中敌我双方 SP 值扣减随帧率加速的问题。
- **Direct3D 12 原生渲染**：基于 ReXGlue Xenos GPU 后端在 Windows 上通过 Direct3D 12 原生渲染。

#### 仍未实现 / 待解决问题
- **部分运镜脚本在高帧率下会加速**：高帧率下运镜动画本身仍存在加速现象。
- **路边空气墙指示牌箭头滚动加速**：赛道空气墙指示牌滚动动画受高帧率影响加速。
- **车库 UI 底部滚动的 Tips 加速**：车库底部 2D UI 滚动提示条存在加速现象。
- **Vulkan 支持测试中**：使用 Vulkan API 时有可能遇到随机黑屏，待后续优化。

> *未完整测试流程，不确保能完全通关，请随时保存。如游戏中遇到黑屏情况，请把游戏目录下的 `/logs` 目录中的对应日志与黑屏出现的场合发送到邮箱：`ishimoriginal@proton.me`*

---

### 目录结构

```text
├── Setup.bat                     # 一键安装与编译引导向导（推荐入口）
├── CMakeLists.txt                # CMake 构建配置文件
├── CMakePresets.json             # Visual Studio 2022 / Ninja 预设
├── manifest.toml                 # ReXGlue 静态重编译配置清单
├── game_root/                    # ★ 游戏本体存放目录（需自行放入正版解包文件）
│   ├── default.xex               #   Xbox 360 主程序文件
│   └── DATA/                     #   游戏模型、贴图、音频与着色器资源
├── downloads/                    # 依赖安装包统一存放与校验目录（含 DOWNLOAD_LINKS.txt）
├── cmake/
│   └── rexglue.cmake             # ReXGlue / ShiftGlue SDK 链接辅助模块
├── include/
│   └── shutokou_battle_x_app.h   # 首都高赛车X 宿主应用程序定义 (ReXApp)
├── src/
│   ├── main.cpp                  # 程序入口点 (REX_DEFINE_APP)
│   ├── launcher/
│   │   └── main.cpp              # 原生 Win32 GUI 启动器 (Launcher.exe)
│   └── patches/
│       ├── framerate_patch.h/.cpp # 帧率与物理步长补丁
│       └── wheel_input.h/.cpp     # 方向盘力反馈与模拟线性输入
├── scripts/
│   ├── build-windows.bat         # 编译 Windows 客户端与启动器脚本
│   ├── run-codegen.bat           # 运行 AOT 代码生成脚本
│   ├── setup-game-assets.bat     # 资源目录、工具链与依赖检测向导脚本
│   └── setup_helper.ps1          # 依赖直链导出、下载与归档校验辅助脚本
└── docs/
    └── BUILD_WINDOWS.md          # 详细中文编译指南与常见问题
```

---

### 致谢

- **[ReXGlue](https://github.com/rexglue/rexglue-sdk)** — 提供 Xbox 360 静态重编译 SDK、运行时与 Xenos GPU 后端。
- **[MCLA-recomp](https://github.com/arcanite24/MCLA-recomp)** — 提供 Xbox 360 赛车游戏静态重编译与高帧率适配参考。
- **[pinyon-shift](https://github.com/arcanite24/pinyon-shift)** — 提供静态重编译工程结构与实现思路参考。
- **[Google Gemini](https://gemini.google.com/) (Google DeepMind)** — 协助撰写代码及 Debug。

---

### 声明

本项目是独立的开源研究与静态重编译工程，**不包含**任何受版权保护的游戏专有资源（如原始可执行文件、3D 模型、音效、贴图等）。用户必须合法拥有 Xbox 360 版《首都高バトルX》（Title ID: `474507D1`）正版光盘并在本地自行提取数据。本项目仅针对日版《首都高バトルX》进行开发与实测，未对其他地区版本进行过测试。

---

## ☕ 支持我的爱好（或单纯想要请我喝一杯咖啡）
本项目使用完全免费，如你在任何收费渠道下载本项目副本即表示你已受骗！
<p align="center">
  <img src="https://github.com/user-attachments/assets/74ca58b2-0ab7-4d2d-8f5f-a8392d72e519" width="48%" alt="Code" />
</p>

---

## English

### Preface

This project is conceived and maintained by a single developer, with over 95% of the code generated with AI assistance. It is intended solely for personal learning and research, and timely future updates are not guaranteed. Illegal downloading and piracy are neither encouraged nor supported—please extract the game files only from a legal copy that you legitimately own!

> **Format Notice:** Only **unpacked XEX-format game copies** (containing `default.xex` and the `DATA/` directory) are supported. **`.iso` disc image files are NOT supported.**

---

### Quick Start

#### Requirements
- **OS**: Windows 10 / 11 (x64)
- **Disk Space**: ~**9 GB** of free space required during installation and compilation (final standalone game folder is ~**3 GB**)
- **Estimated Time**: ~**20–60 minutes** in total (depending on network speed and CPU performance)
- **Toolchain**: Git, CMake (3.25+), Ninja, LLVM/Clang (`clang` / `clang++`), VS2022 / MSVC Build Tools (auto-checked and installed via the setup wizard below)

> **Installation Options:** After placing your game files in `game_root/`, you can either double-click **`Setup.bat`** in the project root to run the entire setup and build pipeline step-by-step (pressing Enter between stages), or manually run the three scripts inside `scripts\` in order (`setup-game-assets.bat` → `run-codegen.bat` → `build-windows.bat`).

#### 0. Prepare Legal Game Files
Please search online for guides on how to dump (e.g., via Redump) your legally owned Xbox 360 disc of **Shutokou Battle X** (Title ID: `474507D1`) to your PC and unpack it into XEX format (containing `default.xex` and the `DATA/` directory; `.iso` images are not supported).

#### 1. Place Game Assets & Check Environment
> **Folder Layout Tip:** We recommend placing this project folder in a drive/directory with sufficient disk space (e.g., `D:\STKX-recomp\`), and creating an empty sibling folder named **`ShutokouBattleX`** alongside it in the parent directory (i.e., `..\ShutokouBattleX\`, such as `D:\ShutokouBattleX\`) in advance. Once compilation finishes, the build script will automatically deploy a clean, standalone copy of the game and assets there for easy launching or portability.

Place the extracted XEX game files into the `game_root/` directory:
- `game_root/default.xex`
- `game_root/DATA/`

Then double-click **`Setup.bat`** in the project root (recommended), or manually run the environment and asset verification wizard:
```cmd
scripts\setup-game-assets.bat
```
The script uses a **unified `downloads\` verification and installation workflow**:
1. **Auto-Scan & Unified Installer Handling**: On startup, the script scans `downloads\` and automatically verifies and installs/extracts any valid packages already placed there (including `vs_BuildTools.exe`, which automatically installs MSVC C++ Build Tools & Windows SDK without needing `winget`).
2. **Exact Direct Single-File Links (`downloads\DOWNLOAD_LINKS.txt`)**: If any components are still missing (including `Git-2.48.1-64-bit.exe`, `cmake-3.31.5-windows-x86_64.msi`, `ninja-win.zip`, `LLVM-19.1.7-win64.exe`, `vs_BuildTools.exe`, and the 20 `thirdparty/` `.zip` archives), the script immediately exports **exact direct single-file download URLs** to `downloads\DOWNLOAD_LINKS.txt`.
3. **Unified Verification & Installation in `downloads\`**:
   - **Option `[1]` (Script Auto-Download)**: The script automatically downloads missing packages into `downloads\`, then verifies and installs them.
   - **Option `[2]` (Slow Network / Manual Download)**: Download the missing files yourself using the direct URLs in `downloads\DOWNLOAD_LINKS.txt` and place them directly into the **`downloads\`** folder in the project root (**keep original filenames, do NOT extract manually**). Then select `[2]` (or re-run the script): it will verify all packages in `downloads\`, install/extract valid ones, and prompt you for any remaining missing packages.

#### 2. Run AOT Codegen
*(If using `Setup.bat`, pressing Enter after Stage 1 automatically launches this step)*
```cmd
scripts\run-codegen.bat
```
*(Translates PowerPC machine code into C++ via `rexglue.exe` using `manifest.toml`, outputting to `src/generated/entrypoint/`)*

#### 3. Build the Windows Native Executable
*(If using `Setup.bat`, pressing Enter after Stage 2 automatically launches this step)*
```cmd
scripts\build-windows.bat
```
Once built, the executable, native launcher, and runtime DLLs are located at:
- `out\win-amd64\Release\shutokou_battle_x.exe`
- `out\win-amd64\Release\Launcher.exe`

**Launching & Portability:**
- If you created the sibling `..\ShutokouBattleX\` folder in Step 1, the build script has already automatically copied `shutokou_battle_x.exe`, `Launcher.exe`, all required runtime `.dll` files, `launch-game.bat`, and `game_root\` (if not yet present) into `..\ShutokouBattleX\`. You can **launch the game directly from `..\ShutokouBattleX\`** (via `Launcher.exe` or `shutokou_battle_x.exe`), or freely move/migrate the entire `ShutokouBattleX` folder anywhere as a self-contained game directory.

---

### Features & Status

#### Basic Features
- **DirectX 12 & Vulkan API support (Vulkan is still being adapted, not recommended)**
- **1x (720p), 2x (1440p), and 3x (2160p) internal resolution support**
- **30, 40, 60, and 120 FPS support**
- **VSync toggle support**
- **Native XInput controller support**
- **Save data support**
- **Other native ReXGlue features**

#### Implemented & Verified
- **High-FPS & Physics Decoupling**: Removes the original Xbox 360 30 FPS cap for native high-framerate gameplay.
- **Core Flow & Timer Sync**: Opening logos, non-garage menu animations, race `3-2-1-GO` countdown and 4-second wait, Time Attack timer, and throttle acceleration all run at normal speed.
- **Menu Cursor Repeat Rate Limit**: Fixed overly fast directional key repeat in menus at high framerates.
- **Garage Turntable Speed Fix**: Fixed the vehicle turntable in the garage spinning too fast at high framerates.
- **Battle SP Drain Speed Fix**: Fixed opponent/player SP drain speeding up with framerate during battles.
- **Native Direct3D 12 Rendering**: Renders natively on Windows via the ReXGlue Xenos GPU D3D12 backend.

#### Unimplemented / Known Issues
- **Some Camera Scripts Speed Up at High FPS**: Certain real-time camera animations still play faster at high framerates.
- **Trackside Barrier Arrow Scroll Speed**: Barrier indicator scrolling animations on the course are still sped up by high framerates.
- **Garage Bottom Scrolling Tips Speed**: The 2D scrolling tips bar at the bottom of the garage UI is still sped up.
- **Vulkan Support Under Testing**: Random black screens may occur when using the Vulkan API; further optimization is pending.

> *Full playthrough has not been tested; completion from start to finish is not guaranteed—please save frequently. If you encounter a black screen during gameplay, please send the corresponding log file from the `/logs` directory in your game folder along with a description of when the black screen occurred to: `ishimoriginal@proton.me`*

---

### Directory Structure

```text
├── Setup.bat                     # One-click setup & build wizard (recommended)
├── CMakeLists.txt                # CMake build configuration
├── CMakePresets.json             # Visual Studio 2022 / Ninja presets
├── manifest.toml                 # ReXGlue static recompilation manifest
├── game_root/                    # ★ Game assets folder (place your unpacked copy here)
│   ├── default.xex               #   Xbox 360 main executable
│   └── DATA/                     #   Game models, textures, audio & shader assets
├── downloads/                    # Unified package cache & verification folder (incl. DOWNLOAD_LINKS.txt)
├── cmake/
│   └── rexglue.cmake             # ReXGlue / ShiftGlue SDK helper module
├── include/
│   └── shutokou_battle_x_app.h   # Host application definition (ReXApp)
├── src/
│   ├── main.cpp                  # Entry point (REX_DEFINE_APP)
│   ├── launcher/
│   │   └── main.cpp              # Native Win32 GUI launcher (Launcher.exe)
│   └── patches/
│       ├── framerate_patch.h/.cpp # Framerate & physics delta-time patches
│       └── wheel_input.h/.cpp     # Force-feedback wheel & analog input
├── scripts/
│   ├── build-windows.bat         # Windows client & launcher build script
│   ├── run-codegen.bat           # AOT codegen script
│   ├── setup-game-assets.bat     # Asset, toolchain & dependency setup wizard
│   └── setup_helper.ps1          # Helper for direct links, downloads & archive verification
└── docs/
    └── BUILD_WINDOWS.md          # Detailed build guide & FAQ
```

---

### Acknowledgements

- **[ReXGlue](https://github.com/rexglue/rexglue-sdk)** — Xbox 360 static recompilation SDK, runtime, and Xenos GPU backend.
- **[MCLA-recomp](https://github.com/arcanite24/MCLA-recomp)** — Reference for Xbox 360 racing game static recompilation and high-FPS adaptation.
- **[pinyon-shift](https://github.com/arcanite24/pinyon-shift)** — Reference for static recompilation project structure and implementation.
- **[Google Gemini](https://gemini.google.com/) (Google DeepMind)** — Assisted with code generation and debugging.

---

### Disclaimer

This project is an independent open-source research and static recompilation effort. It **does not** include any copyrighted game assets (such as original executables, 3D models, audio, or textures). Users must legally own an Xbox 360 copy of **Shutokou Battle X** (Title ID: `474507D1`) and extract the data locally. Only the Japanese release has been developed and tested; other regional releases have not been tested.

## ☕ Support

This project is completely free and open-source. If you enjoy playing *Shutokou Battle X* on PC and would like to support my reverse-engineering work (entirely optional):

[![Ko-fi](https://img.shields.io/badge/Ko--fi-Buy%20me%20a%20coffee-FF5E5B?style=flat&logo=ko-fi&logoColor=white)](https://ko-fi.com/ishimoriginal)
