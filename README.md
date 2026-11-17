# 首都高バトルX (Shutokou Battle X / Import Tuner Challenge) - Windows Native Recompilation

[![Platform](https://img.shields.io/badge/Platform-Windows%20x64%20(DirectX%2012%20%2F%20Vulkan)-blue.svg)]()
[![Recompiler](https://img.shields.io/badge/Recompiler-ReXGlue%20%2F%20ShiftGlue-emerald.svg)]()
[![Title ID](https://img.shields.io/badge/Title%20ID-474507D1%20%2F%20555307EE-orange.svg)]()
[![Target](https://img.shields.io/badge/Target-C%2B%2B23%20Native%20MSVC%20%2F%20Clang-green.svg)]()

A native static recompilation project for the Xbox 360 title **Shutokou Battle X** (首都高バトルX, released internationally as **Import Tuner Challenge**) developed by Genki Co., Ltd.

Based on the [ReXGlue](https://github.com/rexglue/rexglue-sdk) & [ShiftGlue](https://github.com/arcanite24/shiftglue-sdk) ahead-of-time (AOT) static recompilation architecture (similar to [pinyon-shift](https://github.com/arcanite24/pinyon-shift)).

---

## 快速上手 (Quick Start)

完整的中文与英文编译步骤详见 [docs/BUILD_WINDOWS.md](docs/BUILD_WINDOWS.md)。

### 1. 放置游戏文件
将您从正版 Xbox 360 光盘中提取的文件放置于 `game_root/` 目录：
- `game_root/default.xex`
- `game_root/MEDIA/`

### 2. 运行代码生成 (AOT Codegen)
```cmd
scripts\run-codegen.bat
```
*(使用 ReXGlue 工具链将 PowerPC 大端机器码静态翻译为高度优化的 C++23 代码)*

### 3. 编译 Windows 原生游戏程序
```cmd
scripts\build-windows.bat
```
生成的可执行文件位于：
`build\windows-msvc-release\Release\shutokou_battle_x.exe`

---

## 项目特性 (Features)

- **60 FPS / 120 FPS 高帧率物理修复**: 解除原始 Xbox 360 30 FPS 限制，物理步长自适应计算。
- **超宽屏与 4K 支持**: 支持 21:9、32:9 超宽分辨率与 AMD FidelityFX Super Resolution (FSR)。
- **力反馈方向盘集成**: 针对首都高高速公路漂移调校的 DirectInput / XInput 转向回正力矩。
- **现代化图形后端**: 支持 Windows Direct3D 12 与跨平台 Vulkan 1.3。

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

## 声明 (Disclaimer)

本项目是独立的开源研究与静态重编译工程，**不包含**任何受版权保护的游戏专有资源（如原始可执行文件、3D 模型、音效、贴图等）。用户必须合法拥有 Xbox 360 版《首都高バトルX》（或《Import Tuner Challenge》）正版光盘并在本地自行提取数据。
