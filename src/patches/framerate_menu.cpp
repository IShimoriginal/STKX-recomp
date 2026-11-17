/**
 * @file        framerate_menu.cpp
 * @brief       In-game ImGui framerate & timing control menu (F1) for 首都高バトルX
 */

#include "framerate_menu.h"

#include "framerate_patch.h"

#include <rex/chrono/clock.h>
#include <rex/cvar.h>

#include <imgui.h>

#include <algorithm>
#include <array>
#include <string>

namespace sbx::ui {

namespace {

struct FpsPreset {
  const char* label;
  int32_t fps;
};

constexpr std::array<FpsPreset, 5> kPresets = {{
    {"30 FPS", 30},
    {"40 FPS", 40},
    {"60 FPS", 60},
    {"120 FPS", 120},
    {"Unlimited", 0},
}};

}  // namespace

FramerateMenuDialog::FramerateMenuDialog(
    rex::ui::ImGuiDrawer* imgui_drawer,
    std::filesystem::path config_path,
    rex::ui::DebugOverlayDialog::FrameStatsProvider stats_provider,
    std::function<void()> on_close_requested)
    : rex::ui::ImGuiDialog(imgui_drawer),
      config_path_(std::move(config_path)),
      stats_provider_(std::move(stats_provider)),
      on_close_requested_(std::move(on_close_requested)) {}

FramerateMenuDialog::~FramerateMenuDialog() = default;

void FramerateMenuDialog::ApplyPreset(int32_t target_fps) {
  rex::cvar::SetFlagByName("vsync", "false");
  rex::cvar::SetFlagByName("target_fps", std::to_string(target_fps));
  sbx::patches::SetTargetFps(target_fps > 0 ? static_cast<uint32_t>(target_fps) : 0u);
}

void FramerateMenuDialog::RequestClose() {
  if (close_dispatched_) {
    return;
  }
  close_dispatched_ = true;
  if (on_close_requested_) {
    on_close_requested_();
  }
}

void FramerateMenuDialog::OnDraw(ImGuiIO& /*io*/) {
  ImGui::SetNextWindowPos(ImVec2(24.0f, 24.0f), ImGuiCond_FirstUseEver);
  ImGui::SetNextWindowBgAlpha(0.88f);

  bool window_open = true;
  if (ImGui::Begin("Framerate & Timing (F1)##sbx_fps", &window_open,
                   ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoCollapse)) {
    const bool vsync_enabled = rex::cvar::Query<bool>("vsync");
    const int32_t target_fps = rex::cvar::Query<int32_t>("target_fps");
    const bool decouple_active = sbx::patches::IsSpeedDecoupleHookActive();

    if (stats_provider_) {
      const auto stats = stats_provider_();
      if (stats.frame_count > 0) {
        ImGui::Text("Current Guest: %.1f FPS (%.2f ms)", stats.fps, stats.frame_time_ms);
      } else {
        ImGui::TextDisabled("Current Guest: waiting for swap...");
      }
    }

    if (vsync_enabled) {
      ImGui::Text("Active Cap: VSync ON (Guest 60Hz VBlank)");
    } else if (target_fps > 0) {
      ImGui::Text("Active Cap: %d FPS (%.2f ms target)", target_fps,
                  1000.0 / static_cast<double>(target_fps));
    } else {
      ImGui::Text("Active Cap: Unlimited (VSync OFF)");
    }

    if (decouple_active) {
      ImGui::TextColored(ImVec4(0.35f, 0.90f, 0.45f, 1.0f),
                         "Speed Decouple: Active (real_dt %.2f ms, %.2fx vs 30fps)",
                         sbx::patches::GetRealDeltaTime() * 1000.0f,
                         sbx::patches::GetSpeedScaleFactor());
    } else {
      ImGui::TextColored(ImVec4(0.95f, 0.78f, 0.30f, 1.0f),
                         "Speed Decouple: Host pacer active (waiting for guest swap...)");
    }

    ImGui::Separator();
    ImGui::TextUnformatted("Framerate Presets:");

    for (size_t i = 0; i < kPresets.size(); ++i) {
      if (i > 0) {
        ImGui::SameLine();
      }
      const bool selected = (!vsync_enabled && target_fps == kPresets[i].fps);
      if (selected) {
        ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.18f, 0.55f, 0.28f, 1.0f));
        ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.24f, 0.65f, 0.35f, 1.0f));
      }
      if (ImGui::Button(kPresets[i].label)) {
        ApplyPreset(kPresets[i].fps);
      }
      if (selected) {
        ImGui::PopStyleColor(2);
      }
    }

    ImGui::Spacing();

    int32_t custom_fps = target_fps;
    ImGui::SetNextItemWidth(120.0f);
    if (ImGui::InputInt("Custom Target FPS (0 = Unlimited)", &custom_fps, 1, 10)) {
      custom_fps = std::clamp(custom_fps, 0, 1000);
      ApplyPreset(custom_fps);
    }

    bool vsync_checkbox = vsync_enabled;
    if (ImGui::Checkbox("Enable VSync (overrides target FPS cap)", &vsync_checkbox)) {
      rex::cvar::SetFlagByName("vsync", vsync_checkbox ? "true" : "false");
    }

    ImGui::Separator();

    if (ImGui::Button("Save Config")) {
      if (!config_path_.empty()) {
        rex::cvar::SaveConfig(config_path_);
        const uint64_t now = rex::chrono::Clock::QueryHostTickCount();
        const uint64_t freq = rex::chrono::Clock::QueryHostTickFrequency();
        save_feedback_until_tick_ = (freq > 0) ? (now + freq * 3ULL) : 0ULL;
        save_feedback_text_ = "Saved: " + config_path_.filename().string();
      } else {
        save_feedback_text_ = "No config path configured";
      }
    }

    ImGui::SameLine();
    if (ImGui::Button("Close (F1)")) {
      RequestClose();
    }

    if (!save_feedback_text_.empty()) {
      const uint64_t now = rex::chrono::Clock::QueryHostTickCount();
      if (save_feedback_until_tick_ == 0 || now <= save_feedback_until_tick_) {
        ImGui::SameLine();
        ImGui::TextColored(ImVec4(0.45f, 0.85f, 1.0f, 1.0f), "%s", save_feedback_text_.c_str());
      } else {
        save_feedback_text_.clear();
      }
    }
  }
  ImGui::End();

  if (!window_open) {
    RequestClose();
  }
}

}  // namespace sbx::ui
