/**
 * @file        shutokou_battle_x_app.h
 * @brief       Custom ReXApp host implementation for 首都高バトルX (Shutokou Battle X)
 * 
 * @copyright   Copyright (c) 2026 ReXGlue / Shutokou Battle X Recomp Project
 * @license     MIT / BSD-3-Clause
 */

#pragma once

#include <memory>
#include <string>
#include <string_view>
#include <iostream>
#include <algorithm>
#include <filesystem>

#include <rex/rex_app.h>
#include <rex/cvar.h>
#include <rex/system/flags.h>
#include <rex/ui/keybinds.h>
#include <rex/ui/windowed_app.h>

#if __has_include("shutokou_battle_x_init.h")
#include "shutokou_battle_x_init.h"
#elif __has_include("generated/entrypoint/shutokou_battle_x_init.h")
#include "generated/entrypoint/shutokou_battle_x_init.h"
#else
extern const rex::PPCImageInfo PPCImageConfig;
#endif

#include "patches/framerate_menu.h"
#include "patches/framerate_patch.h"
#include "patches/wheel_input.h"

class ShutokouBattleXApp : public rex::ReXApp {
public:
    using rex::ReXApp::ReXApp;

    static std::unique_ptr<rex::ui::WindowedApp> Create(rex::ui::WindowedAppContext& ctx) {
        return std::unique_ptr<ShutokouBattleXApp>(
            new ShutokouBattleXApp(ctx, "shutokou_battle_x", PPCImageConfig)
        );
    }

    /**
     * @brief Called before kernel and graphics subsystem initialization
     */
    void OnPreSetup(rex::RuntimeConfig& config) override {
        std::cout << "[SBX] Initializing 首都高バトルX Native Windows Host Runtime..." << std::endl;
        std::cout << "[SBX] Title ID: 474507D1 (Genki Co., Ltd.)" << std::endl;
        
        // 激活 Xenos GPU 硬件模拟驱动插件 (Direct3D 12 渲染引擎)
        if (config.gpu_plugin.empty()) {
            config.gpu_plugin = "xenos";
        }

        // 允许零页 (0x00000000 - 0x00010000) 读写，防止空指针与未初始化结构体解引用引发 Access Violation 闪退
        REXCVAR_SET(protect_zero, false);

        // Vulkan 后端默认关闭异步着色器编译，防止车库等场景因占位管线导致黑屏
        if (rex::cvar::Query<std::string>("gpu_backend") == "vulkan" &&
            rex::cvar::GetFlagSource("async_shader_compilation") == rex::cvar::Source::kDefault) {
            rex::cvar::SetFlagByName("async_shader_compilation", "false");
        }
    }

    /**
     * @brief Configure virtual filesystem paths
     */
    void OnConfigurePaths(rex::PathConfig& paths) override {
        namespace fs = std::filesystem;
        auto exe_dir = rex::filesystem::GetExecutableFolder();

        // 智能探测游戏资源目录候选路径:
        // 1. 同级目录 exe_dir/game_root (用户将游戏打包装进 Release 目录或独立发布包)
        // 2. 同级目录 exe_dir (用户把 DATA, default.xex 直接放在 exe 同目录)
        // 3. 上上级工程根目录 exe_dir/../../../game_root (从 out/win-amd64/Release/ 向上回溯到 STKX-recomp/game_root)
        // 4. 当前运行目录 cwd/game_root
        std::vector<fs::path> candidates = {
            exe_dir / "game_root",
            exe_dir,
            exe_dir / ".." / ".." / ".." / "game_root",
            fs::current_path() / "game_root",
            fs::current_path()
        };

        bool found = false;
        for (const auto& candidate : candidates) {
            std::error_code ec;
            if (fs::exists(candidate / "default.xex", ec) || fs::exists(candidate / "DATA", ec)) {
                paths.game_data_root = fs::absolute(candidate);
                found = true;
                std::cout << "[SBX] 成功定位游戏资源根目录: " << paths.game_data_root.string() << std::endl;
                break;
            }
        }

        if (!found) {
            // 回退到默认相对路径，并输出清晰指引
            paths.game_data_root = fs::exists("game_root") ? fs::absolute("game_root") : (exe_dir / "game_root");
        }

        paths.user_data_root = exe_dir / "saves";
        std::error_code ec;
        fs::create_directories(paths.user_data_root, ec);
    }

    /**
     * @brief Called after kernel and subsystems are up
     */
    void OnPostSetup() override {
        // Default to vsync=false unless overridden by CLI or shutokou_battle_x.toml
        if (rex::cvar::GetFlagSource("vsync") == rex::cvar::Source::kDefault) {
            rex::cvar::SetFlagByName("vsync", "false");
        }
        const int32_t target_fps = rex::cvar::Query<int32_t>("target_fps");
        sbx::patches::InitializeFrameratePatch(
            target_fps > 0 ? static_cast<uint32_t>(target_fps) : 0u);
        if (runtime() && runtime()->graphics_system()) {
            runtime()->graphics_system()->SetSwapCallback(
                [](uint64_t dt_us, uint64_t /*swap_count*/) {
                    sbx::patches::OnGuestSwapFrame(dt_us);
                });
        }
        sbx::patches::InitializeSteeringWheelSupport();
        std::cout << "[SBX] Host framerate pacer ready (target_fps=" << target_fps
                  << ", vsync=" << (rex::cvar::Query<bool>("vsync") ? "true" : "false")
                  << ", F1 menu enabled)." << std::endl;
    }

    /**
     * @brief In-game ImGui Overlay dialogs (F1 menu)
     */
    void OnCreateDialogs(rex::ui::ImGuiDrawer* drawer) override {
        (void)drawer;
        ui_alive_ = std::make_shared<bool>(true);
        rex::ui::RegisterBind("bind_framerate_menu", "F1", "Toggle framerate menu", [this]() {
            if (framerate_menu_) {
                framerate_menu_.reset();
            } else if (imgui_drawer()) {
                auto alive = std::weak_ptr<bool>(ui_alive_);
                auto stats_fn = [this]() -> rex::ui::FrameStats {
                    const auto& provider = frame_stats_provider();
                    return provider ? provider() : rex::ui::FrameStats{};
                };
                auto close_fn = [this, alive]() {
                    app_context().CallInUIThreadDeferred([this, alive]() {
                        if (!alive.expired()) {
                            framerate_menu_.reset();
                        }
                    });
                };
                framerate_menu_ = std::make_unique<sbx::ui::FramerateMenuDialog>(
                    imgui_drawer(), config_path(), std::move(stats_fn), std::move(close_fn));
            }
        });
    }

    void OnShutdown() override {
        std::cout << "[SBX] Shutting down 首都高バトルX..." << std::endl;
        if (runtime() && runtime()->graphics_system()) {
            runtime()->graphics_system()->SetSwapCallback(nullptr);
        }
        ui_alive_.reset();
        rex::ui::UnregisterBind("bind_framerate_menu");
        framerate_menu_.reset();
        sbx::patches::ShutdownFrameratePatch();
    }

private:
    std::shared_ptr<bool> ui_alive_;
    std::unique_ptr<sbx::ui::FramerateMenuDialog> framerate_menu_;
};
