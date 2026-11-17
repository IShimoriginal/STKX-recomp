/**
 * @file        framerate_menu.h
 * @brief       In-game ImGui framerate & timing control menu (F1) for 首都高バトルX
 */

#pragma once

#include <rex/ui/imgui_dialog.h>
#include <rex/ui/overlay/debug_overlay.h>

#include <cstdint>
#include <filesystem>
#include <functional>

namespace sbx::ui {

class FramerateMenuDialog final : public rex::ui::ImGuiDialog {
 public:
  FramerateMenuDialog(rex::ui::ImGuiDrawer* imgui_drawer,
                      std::filesystem::path config_path,
                      rex::ui::DebugOverlayDialog::FrameStatsProvider stats_provider,
                      std::function<void()> on_close_requested = {});
  ~FramerateMenuDialog() override;

 protected:
  void OnDraw(ImGuiIO& io) override;

 private:
  void ApplyPreset(int32_t target_fps);
  void RequestClose();

  std::filesystem::path config_path_;
  rex::ui::DebugOverlayDialog::FrameStatsProvider stats_provider_;
  std::function<void()> on_close_requested_;
  bool close_dispatched_ = false;
  uint64_t save_feedback_until_tick_ = 0;
  std::string save_feedback_text_;
};

}  // namespace sbx::ui
