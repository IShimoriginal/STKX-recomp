/**
 * @file        framerate_patch.h
 * @brief       Framerate control & MCLA-style real_dt speed decoupling for 首都高バトルX
 */

#pragma once

#include <cstdint>

namespace sbx::patches {

void InitializeFrameratePatch(uint32_t targetFps);
void ShutdownFrameratePatch();

void SetTargetFps(uint32_t targetFps);
uint32_t GetTargetFps();

// Advances wall-clock real_dt measurement from host XE_SWAP delta (microseconds).
// Invoked on each actual guest frame swap via CommandProcessor::SetSwapCallback.
void OnGuestSwapFrame(uint64_t dt_us);
void BeginFrameTick();

// Returns clamped wall-clock delta time in seconds ([1/1000s, 1/15s]).
float GetRealDeltaTime();

// Returns physics time scale relative to the Xbox 360 30 FPS baseline
// (1.0f at 30 FPS, 0.5f at 60 FPS, 0.25f at 120 FPS).
float GetSpeedScaleFactor();

// Scales a fixed 30 FPS guest delta time using real_dt / (1/30).
float GetScaledDeltaTime(float originalDt);

// Returns how many 30 FPS baseline ticks occurred during the current host frame
// (e.g. alternates 0/1 at 60 FPS, 0/0/0/1 at 120 FPS, always 1 at 30 FPS).
uint32_t GetFrameTicks30Hz();

// Tracks whether a guest entrypoint midasm hook is actively feeding simulation ticks.
bool IsSpeedDecoupleHookActive();
void MarkSpeedDecoupleHookActive();

}  // namespace sbx::patches
