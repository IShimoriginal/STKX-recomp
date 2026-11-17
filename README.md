# 首都高バトルX (Shutokou Battle X) - Windows Native Recompilation

[![Platform](https://img.shields.io/badge/Platform-Windows%20x64%20(DirectX%2012%20%2F%20Vulkan)-blue.svg)]()
[![Recompiler](https://img.shields.io/badge/Recompiler-ReXGlue%20%2F%20ShiftGlue-emerald.svg)]()
[![Title ID](https://img.shields.io/badge/Title%20ID-474507D1-orange.svg)]()
[![Target](https://img.shields.io/badge/Target-C%2B%2B23%20Native%20MSVC%20%2F%20Clang-green.svg)]()

A native static recompilation project for the Xbox 360 title **Shutokou Battle X** (首都高バトルX, Title ID: `474507D1`) developed by Genki Co., Ltd.

> **Note:** Only the Japanese release (**Shutokou Battle X**, Title ID `474507D1`) has been tested. Other regional releases have **not** been tested.

Based on the [ReXGlue](https://github.com/rexglue/rexglue-sdk) ahead-of-time (AOT) static recompilation SDK, with [MCLA-recomp](https://github.com/arcanite24/MCLA-recomp) and [pinyon-shift](https://github.com/arcanite24/pinyon-shift) as reference projects.

---

## 快速上手 (Quick Start)

### 环境要求
- **操作系统**：Windows 10 / 11 (x64)
- **编译工具链**：Git、CMake (3.25+)、Ninja、LLVM/Clang (`clang` / `clang++`)

### 1. 放置游戏文件并检测环境
将您从正版 Xbox 360《首都高バトルX》（Title ID: `474507D1`）光盘中提取的文件放置于 `game_root/` 目录：
- `game_root/default.xex`
- `game_root/DATA/`

然后运行环境与资源检测脚本（会自动检查 `game_root/` 与编译工具链）：
```cmd
scripts\setup-game-assets.bat
```

### 2. 下载第三方依赖
拉取 `thirdparty/` 所需的第三方库（后续 `run-codegen.bat` 也会自动检测并补全）：
```cmd
scripts\download-dependencies.bat
```

### 3. 运行代码生成 (AOT Codegen)
```cmd
scripts\run-codegen.bat
```
*(使用 `rexglue.exe` 根据 `manifest.toml` 将 PowerPC 机器码静态翻译为 C++ 代码，输出至 `src/generated/entrypoint/`)*

### 4. 编译 Windows 原生程序
```cmd
scripts\build-windows.bat
```
编译完成后，最终可执行文件与运行库位于：
- `out\win-amd64\Release\shutokou_battle_x.exe`

*(可选：若上一级目录存在 `..\ShutokouBattleX\`，构建脚本会自动将 `shutokou_battle_x.exe`、所需 `.dll` 及 `rexglue.exe` 同步到该目录并生成 `launch-game.bat`；若该目录下尚无 `game_root\`，也会自动复制过去。)*

---

## 项目特性与当前进度 (Features & Status)

### 已实现并实测通过
- **高帧率与物理帧率解耦**：解除原版 Xbox 360 30 FPS 限制，支持高帧率原生运行。
- **核心流程与计时同步**：开场 Logo、非车库菜单动画、比赛 `3-2-1-GO` 倒计时及 4 秒等待、Time Attack 计时器与油门加速速度均已正常。
- **菜单光标连发限速**：修复了高帧率下按住方向键时菜单光标连发过快的问题。
- **车库车辆转盘速度修复**：修复了车库车辆展示转盘在高帧率下旋转过快的问题。
- **战斗 SP 扣血速度修复**：修复了战斗中敌我双方 SP 值扣减随帧率加速的问题。
- **Direct3D 12 原生渲染**：基于 ReXGlue Xenos GPU 后端在 Windows 上通过 Direct3D 12 原生渲染。

### 仍未实现 / 待解决问题
- **战斗开始即时演算运镜速度（高优先级）**：触发战斗到正式开跑的 4 秒等待时间已正常，但运镜动画本身仍存在加速现象。
- **路边空气墙指示牌箭头滚动速度（低优先级）**：赛道空气墙指示牌滚动动画仍受高帧率影响加速。
- **车库 UI 底部滚动 Tips 速度（低优先级）**：车库底部 2D UI 滚动提示条仍存在加速现象。
- **非整数内部分辨率与超分管线**：ReXGlue 后端仅支持整数倍内部分辨率缩放（不支持 `1.25x`/`1.5x` 或热切换），且当前未内置 FSR1/FSR2/CAS 超分后处理管线。
- **偶发帧时间窄尖峰（待观察）**：车库等场景在高帧率下偶发帧时间窄尖峰。

---

## 目录结构 (Directory Structure)

```text
├── CMakeLists.txt                # CMake 构建配置文件
├── CMakePresets.json             # Visual Studio 2022 / Ninja 预设
├── manifest.toml                 # ReXGlue 静态重编译配置清单
├── cmake/
│   └── rexglue.cmake             # ReXGlue / ShiftGlue SDK 链接辅助模块
├── include/
│   └── shutokou_battle_x_app.h   # 首都高赛车X 宿主应用程序定义 (ReXApp)
├── src/
│   ├── main.cpp                  # 程序入口点 (REX_DEFINE_APP)
│   └── patches/
│       ├── framerate_patch.h/.cpp # 60FPS 帧率与物理步长补丁
│       └── wheel_input.h/.cpp     # 方向盘力反馈与模拟线性输入
├── scripts/
│   ├── build-windows.bat         # 一键编译 Windows 客户端脚本
│   ├── run-codegen.bat           # 一键运行 AOT 代码生成脚本
│   └── setup-game-assets.bat     # 资源目录向导脚本
└── docs/
    └── BUILD_WINDOWS.md          # 详细中文编译指南与常见问题
```

---

## 致谢 (Acknowledgements)

- **[ReXGlue](https://github.com/rexglue/rexglue-sdk)** — 提供 Xbox 360 静态重编译 SDK、运行时与 Xenos GPU 后端。
- **[MCLA-recomp](https://github.com/arcanite24/MCLA-recomp)** — 提供 Xbox 360 赛车游戏静态重编译与高帧率适配参考。
- **[pinyon-shift](https://github.com/arcanite24/pinyon-shift)** — 提供静态重编译工程结构与实现思路参考。

---

## 声明 (Disclaimer)

本项目是独立的开源研究与静态重编译工程，**不包含**任何受版权保护的游戏专有资源（如原始可执行文件、3D 模型、音效、贴图等）。用户必须合法拥有 Xbox 360 版《首都高バトルX》（Title ID: `474507D1`）正版光盘并在本地自行提取数据。本项目仅针对日版《首都高バトルX》进行开发与实测，未对其他地区版本进行过测试。
