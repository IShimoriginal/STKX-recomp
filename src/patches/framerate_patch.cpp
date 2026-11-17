/**
 * @file        framerate_patch.cpp
 * @brief       Framerate control & MCLA-style real_dt speed decoupling for 首都高バトルX
 */

#include "framerate_patch.h"

#include <rex/chrono/clock.h>

#include <algorithm>
#include <atomic>
#include <iostream>
#include <mutex>

namespace sbx::patches {

namespace {

constexpr float kBaseFps = 30.0f;
constexpr float kBaseDeltaTime = 1.0f / kBaseFps;
constexpr float kMinRealDeltaTime = 1.0f / 1000.0f;
constexpr float kMaxRealDeltaTime = 1.0f / 15.0f;

std::atomic<uint32_t> s_targetFps{60};
std::atomic<float> s_realDeltaTime{1.0f / 60.0f};
std::atomic<float> s_speedScaleFactor{0.5f};
std::atomic<uint32_t> s_frameTicks30Hz{1};
std::atomic<uint64_t> s_lastTick{0};
std::atomic<bool> s_enabled{false};
std::atomic<bool> s_hookActive{false};
std::mutex s_accumMutex;
double s_accum30Hz = 0.0;

void AdvanceFrameAccumulator30Hz(float scale) {
  std::lock_guard<std::mutex> lock(s_accumMutex);
  s_accum30Hz += static_cast<double>(scale);
  const uint32_t ticks = static_cast<uint32_t>(s_accum30Hz);
  s_accum30Hz -= static_cast<double>(ticks);
  s_frameTicks30Hz.store(ticks, std::memory_order_release);
}

float ComputeStaticScale(uint32_t targetFps) {
  if (targetFps == 0) {
    return s_realDeltaTime.load(std::memory_order_relaxed) * kBaseFps;
  }
  return kBaseFps / static_cast<float>(targetFps);
}

}  // namespace

void InitializeFrameratePatch(uint32_t targetFps) {
  s_targetFps.store(targetFps, std::memory_order_relaxed);
  const float initialDt = (targetFps > 0)
                              ? std::clamp(1.0f / static_cast<float>(targetFps),
                                           kMinRealDeltaTime, kMaxRealDeltaTime)
                              : (1.0f / 60.0f);
  s_realDeltaTime.store(initialDt, std::memory_order_relaxed);
  s_speedScaleFactor.store(ComputeStaticScale(targetFps), std::memory_order_relaxed);
  {
    std::lock_guard<std::mutex> lock(s_accumMutex);
    s_accum30Hz = 0.0;
  }
  s_frameTicks30Hz.store(1, std::memory_order_release);
  s_lastTick.store(rex::chrono::Clock::QueryHostTickCount(), std::memory_order_relaxed);
  s_enabled.store(true, std::memory_order_release);

  std::cout << "[SBX-Patch] Framerate patch initialized (target_fps=" << targetFps
            << ", base_scale=" << s_speedScaleFactor.load(std::memory_order_relaxed) << "x)"
            << std::endl;
}

void ShutdownFrameratePatch() {
  s_enabled.store(false, std::memory_order_release);
  s_hookActive.store(false, std::memory_order_release);
  {
    std::lock_guard<std::mutex> lock(s_accumMutex);
    s_accum30Hz = 0.0;
  }
  s_frameTicks30Hz.store(1, std::memory_order_release);
  s_lastTick.store(0, std::memory_order_relaxed);
}

void SetTargetFps(uint32_t targetFps) {
  s_targetFps.store(targetFps, std::memory_order_relaxed);
  if (!s_hookActive.load(std::memory_order_acquire)) {
    const float dt = (targetFps > 0)
                         ? std::clamp(1.0f / static_cast<float>(targetFps),
                                      kMinRealDeltaTime, kMaxRealDeltaTime)
                         : kMinRealDeltaTime;
    s_realDeltaTime.store(dt, std::memory_order_relaxed);
    s_speedScaleFactor.store(ComputeStaticScale(targetFps), std::memory_order_relaxed);
  }
}

uint32_t GetTargetFps() {
  return s_targetFps.load(std::memory_order_relaxed);
}

void OnGuestSwapFrame(uint64_t dt_us) {
  if (!s_enabled.load(std::memory_order_acquire) || dt_us == 0) {
    return;
  }
  const double rawDt = static_cast<double>(dt_us) * 1.0e-6;
  const float clampedDt =
      std::clamp(static_cast<float>(rawDt), kMinRealDeltaTime, kMaxRealDeltaTime);
  const float scale = clampedDt / kBaseDeltaTime;
  s_realDeltaTime.store(clampedDt, std::memory_order_relaxed);
  s_speedScaleFactor.store(scale, std::memory_order_relaxed);
  AdvanceFrameAccumulator30Hz(scale);
  s_hookActive.store(true, std::memory_order_release);
}

void BeginFrameTick() {
  const uint64_t now = rex::chrono::Clock::QueryHostTickCount();
  const uint64_t freq = rex::chrono::Clock::QueryHostTickFrequency();
  const uint64_t prev = s_lastTick.exchange(now, std::memory_order_relaxed);

  if (prev == 0 || freq == 0 || now <= prev) {
    return;
  }

  const double rawDt = static_cast<double>(now - prev) / static_cast<double>(freq);
  const float clampedDt =
      std::clamp(static_cast<float>(rawDt), kMinRealDeltaTime, kMaxRealDeltaTime);
  const float scale = clampedDt / kBaseDeltaTime;
  s_realDeltaTime.store(clampedDt, std::memory_order_relaxed);
  s_speedScaleFactor.store(scale, std::memory_order_relaxed);
  AdvanceFrameAccumulator30Hz(scale);
}

float GetRealDeltaTime() {
  return s_realDeltaTime.load(std::memory_order_relaxed);
}

float GetSpeedScaleFactor() {
  return s_speedScaleFactor.load(std::memory_order_relaxed);
}

float GetScaledDeltaTime(float originalDt) {
  if (!s_enabled.load(std::memory_order_acquire)) {
    return originalDt;
  }
  return originalDt * s_speedScaleFactor.load(std::memory_order_relaxed);
}

uint32_t GetFrameTicks30Hz() {
  if (!s_enabled.load(std::memory_order_acquire)) {
    return 1;
  }
  return s_frameTicks30Hz.load(std::memory_order_acquire);
}

bool IsSpeedDecoupleHookActive() {
  return s_hookActive.load(std::memory_order_acquire);
}

void MarkSpeedDecoupleHookActive() {
  s_hookActive.store(true, std::memory_order_release);
}

}  // namespace sbx::patches
