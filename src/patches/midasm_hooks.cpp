/**
 * @file        patches/midasm_hooks.cpp
 * @brief       Mid-ASM hook implementations for 首都高バトルX (474507D1)
 */

#include "patches/midasm_hooks.h"
#include "patches/framerate_patch.h"

#include <rex/cvar.h>
#include <rex/logging.h>

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <mutex>
#include <string>

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <Windows.h>

namespace {

struct PadJustPressedEntry {
  uint32_t padAddr = 0;
  uint32_t mask = 0;
};

std::mutex s_padStateMutex;
std::array<PadJustPressedEntry, 8> s_padJustPressed{};

void SetPadButtonJustPressed(uint32_t padAddr, uint32_t btnIdx, bool justPressed) {
  if (btnIdx >= 32u) {
    return;
  }
  const uint32_t bit = 1u << btnIdx;
  std::lock_guard<std::mutex> lock(s_padStateMutex);
  PadJustPressedEntry* emptySlot = nullptr;
  for (auto& entry : s_padJustPressed) {
    if (entry.padAddr == padAddr) {
      if (justPressed) {
        entry.mask |= bit;
      } else {
        entry.mask &= ~bit;
      }
      return;
    }
    if (entry.padAddr == 0 && emptySlot == nullptr) {
      emptySlot = &entry;
    }
  }
  if (justPressed) {
    PadJustPressedEntry* slot = emptySlot ? emptySlot : &s_padJustPressed.back();
    slot->padAddr = padAddr;
    slot->mask = bit;
  }
}

bool IsPadButtonJustPressed(uint32_t padAddr, uint32_t btnIdx) {
  if (btnIdx >= 32u) {
    return false;
  }
  const uint32_t bit = 1u << btnIdx;
  std::lock_guard<std::mutex> lock(s_padStateMutex);
  for (const auto& entry : s_padJustPressed) {
    if (entry.padAddr == padAddr) {
      return (entry.mask & bit) != 0u;
    }
  }
  return false;
}

inline void ScaleDtRegister(PPCRegister& reg) {
  const float dt = static_cast<float>(reg.f64);
  if (!std::isfinite(dt) || dt <= 0.0f) {
    return;
  }
  const float scaled = sbx::patches::GetScaledDeltaTime(dt);
  reg.f64 = static_cast<double>(scaled);
}

// Adjusts a register right after `addi reg, reg, 1` to add `ticks` instead of 1.
inline void AdjustTickAdd1(PPCRegister& reg, uint32_t ticks) {
  const uint32_t oldVal = reg.u32 - 1u;
  reg.u64 = static_cast<uint64_t>(oldVal + ticks);
}

// Adjusts `addic. reg, reg, step` before `stw` and refreshes cr0 for subsequent `bge`.
inline void AdjustTickAddStepCr0(PPCRegister& reg,
                                 PPCCRRegister& cr0,
                                 PPCXERRegister& xer,
                                 int32_t originalStep,
                                 uint32_t ticks) {
  const int32_t oldVal = reg.s32 - originalStep;
  const int32_t nextVal = oldVal + originalStep * static_cast<int32_t>(ticks);
  reg.s64 = nextVal;
  cr0.compare<int32_t>(nextVal, 0, xer);
}

// Adjusts countdown `addic. reg, reg, -1` before `stw`, clamping >0 transitions at 0.
inline void AdjustTickSub1Cr0(PPCRegister& reg,
                              PPCCRRegister& cr0,
                              PPCXERRegister& xer,
                              uint32_t ticks) {
  const int32_t oldVal = reg.s32 + 1;
  int32_t nextVal = oldVal - static_cast<int32_t>(ticks);
  if (oldVal > 0 && nextVal < 0) {
    nextVal = 0;
  }
  reg.s64 = nextVal;
  cr0.compare<int32_t>(nextVal, 0, xer);
}

// Adjusts a signed/unsigned register right after `addi reg, reg, -1`.
inline void AdjustTickSub1(PPCRegister& reg, uint32_t ticks) {
  const int32_t oldVal = reg.s32 + 1;
  reg.s64 = oldVal - static_cast<int32_t>(ticks);
}

}  // namespace

REXCVAR_DEFINE_UINT32(
    post_race_wait_cycles, 15, "Patches",
    "Cycle threshold replacing 60 at 0x8218C30C to prevent post-race black screen")
    .range(1, 60);

void sbx_post_race_wait_patch(PPCRegister& r11,
                              PPCCRRegister& cr6,
                              PPCXERRegister& xer) {
  const uint32_t threshold = REXCVAR_GET(post_race_wait_cycles);
  cr6.compare<uint32_t>(r11.u32, threshold, xer);

  if (r11.u32 >= threshold) {
    REXLOG_INFO("[SBX][Patch] 0x8218C30C wait gate cleared at r11={} (threshold={})",
                r11.u32, threshold);
  }
}

void sbx_scale_dt_f0(PPCRegister& f0) {
  ScaleDtRegister(f0);
}

void sbx_scale_dt_f1(PPCRegister& f1) {
  ScaleDtRegister(f1);
}

void sbx_scale_dt_f6(PPCRegister& f6) {
  ScaleDtRegister(f6);
}

void sbx_scale_dt_f9(PPCRegister& f9) {
  ScaleDtRegister(f9);
}

void sbx_scale_dt_f10(PPCRegister& f10) {
  ScaleDtRegister(f10);
}

void sbx_scale_dt_f11(PPCRegister& f11) {
  ScaleDtRegister(f11);
}

void sbx_scale_dt_f13(PPCRegister& f13) {
  ScaleDtRegister(f13);
}

void sbx_scale_dt_f29(PPCRegister& f29) {
  ScaleDtRegister(f29);
}

void sbx_scale_dt_f30(PPCRegister& f30) {
  ScaleDtRegister(f30);
}

void sbx_scale_dt_f31(PPCRegister& f31) {
  ScaleDtRegister(f31);
}

void sbx_pad_hold_tick(PPCRegister& r31, PPCRegister& r7, PPCRegister& r10) {
  const uint32_t oldVal = r10.u32 - 1u;
  if (oldVal == 0u) {
    SetPadButtonJustPressed(r31.u32, r7.u32, true);
    r10.u64 = 1u;
    return;
  }
  SetPadButtonJustPressed(r31.u32, r7.u32, false);
  const uint32_t step = std::min(sbx::patches::GetFrameTicks30Hz(), 1u);
  r10.u64 = static_cast<uint64_t>(oldVal + step);
}

std::atomic<uint32_t> s_padRepEq1{0};
std::atomic<uint32_t> s_padRepGt1{0};
std::atomic<uint32_t> s_padRepSuppressed{0};

void sbx_pad_repeat_check(PPCRegister& r3, PPCRegister& r4, PPCRegister& r11) {
  if (r11.u32 == 1u) {
    s_padRepEq1.fetch_add(1u, std::memory_order_relaxed);
  } else if (r11.s32 > 1) {
    s_padRepGt1.fetch_add(1u, std::memory_order_relaxed);
  }
  const uint32_t ticks = sbx::patches::GetFrameTicks30Hz();
  if (ticks > 0u) {
    return;
  }
  const uint32_t btnIdx = (r4.u32 >= 284u) ? ((r4.u32 - 284u) >> 2) : 32u;
  if (r11.u32 == 1u && IsPadButtonJustPressed(r3.u32, btnIdx)) {
    return;
  }
  // Suppress held-key initial repeat/duplicate trigger on zero-tick subframes.
  s_padRepSuppressed.fetch_add(1u, std::memory_order_relaxed);
  r11.s64 = -1;
}

namespace {
void PollRecorderHotkey(uint64_t nowMs);
inline uint64_t NowMs();
}  // namespace

bool sbx_menu_repeat_gate(PPCRegister& r4) {
  PollRecorderHotkey(NowMs());
  return (r4.u32 != 0u) && (sbx::patches::GetFrameTicks30Hz() == 0u);
}

void sbx_tick_add1_r10(PPCRegister& r10) {
  AdjustTickAdd1(r10, sbx::patches::GetFrameTicks30Hz());
}

void sbx_tick_add1_r11(PPCRegister& r11) {
  AdjustTickAdd1(r11, sbx::patches::GetFrameTicks30Hz());
}

void sbx_tick_add1_cap120_r11(PPCRegister& r11) {
  const uint32_t ticks = sbx::patches::GetFrameTicks30Hz();
  const uint32_t oldVal = r11.u32 - 1u;
  const uint32_t nextVal = oldVal + ticks;
  r11.u64 = (oldVal <= 120u && nextVal > 120u) ? 120u : nextVal;
}

void sbx_tick_sub1_r10(PPCRegister& r10) {
  AdjustTickSub1(r10, sbx::patches::GetFrameTicks30Hz());
}

void sbx_tick_sub1_r11(PPCRegister& r11) {
  AdjustTickSub1(r11, sbx::patches::GetFrameTicks30Hz());
}

void sbx_tick_sub1_clamp0_r3(PPCRegister& r3) {
  const uint32_t ticks = sbx::patches::GetFrameTicks30Hz();
  const int32_t oldVal = r3.s32 + 1;
  int32_t nextVal = oldVal - static_cast<int32_t>(ticks);
  if (oldVal > 0 && nextVal < 0) {
    nextVal = 0;
  }
  r3.s64 = nextVal;
}

void sbx_tick_add1_cr0_r10(PPCRegister& r10,
                           PPCCRRegister& cr0,
                           PPCXERRegister& xer) {
  const uint32_t step = std::min(sbx::patches::GetFrameTicks30Hz(), 1u);
  AdjustTickAddStepCr0(r10, cr0, xer, 1, step);
}

void sbx_tick_add1_cr0_r11(PPCRegister& r11,
                           PPCCRRegister& cr0,
                           PPCXERRegister& xer) {
  const uint32_t step = std::min(sbx::patches::GetFrameTicks30Hz(), 1u);
  AdjustTickAddStepCr0(r11, cr0, xer, 1, step);
}

void sbx_tick_add8_cr0_r11(PPCRegister& r11,
                           PPCCRRegister& cr0,
                           PPCXERRegister& xer) {
  AdjustTickAddStepCr0(r11, cr0, xer, 8, sbx::patches::GetFrameTicks30Hz());
}

void sbx_tick_sub1_cr0_r9(PPCRegister& r9,
                           PPCCRRegister& cr0,
                           PPCXERRegister& xer) {
  AdjustTickSub1Cr0(r9, cr0, xer, sbx::patches::GetFrameTicks30Hz());
}

void sbx_tick_sub1_cr0_r10(PPCRegister& r10,
                           PPCCRRegister& cr0,
                           PPCXERRegister& xer) {
  AdjustTickSub1Cr0(r10, cr0, xer, sbx::patches::GetFrameTicks30Hz());
}

void sbx_tick_sub1_cr0_r11(PPCRegister& r11,
                           PPCCRRegister& cr0,
                           PPCXERRegister& xer) {
  AdjustTickSub1Cr0(r11, cr0, xer, sbx::patches::GetFrameTicks30Hz());
}

namespace {

constexpr size_t kNumProbes = 21;
constexpr const char* kProbeNames[kNumProbes] = {
    "82165338", "82190508", "82262B00", "8226ED80", "8228F2D0", "8218E400",
    "8217DD48", "8211D4B8", "unused08", "unused09", "unused10", "unused11",
    "unused12", "unused13", "unused14", "unused15", "unused16", "unused17",
    "unused18", "unused19", "unused20",
};

struct CtrSlot {
  std::atomic<uint32_t> addr{0};
  std::atomic<uint32_t> count{0};
};
std::array<CtrSlot, 16> s_ctrUpd{};
std::array<CtrSlot, 16> s_ctrDrw{};
std::array<std::atomic<uint32_t>, kNumProbes> s_probeHits{};
std::array<uint64_t, kNumProbes> s_recTotals{};
std::atomic<bool> s_recording{false};

inline void RecordCtr(std::array<CtrSlot, 16>& slots, uint32_t target) {
  if (!s_recording.load(std::memory_order_acquire)) {
    return;
  }
  for (auto& s : slots) {
    uint32_t a = s.addr.load(std::memory_order_relaxed);
    if (a == target) {
      s.count.fetch_add(1u, std::memory_order_relaxed);
      return;
    }
    if (a == 0u) {
      uint32_t expected = 0u;
      if (s.addr.compare_exchange_strong(expected, target, std::memory_order_relaxed) ||
          expected == target) {
        s.count.fetch_add(1u, std::memory_order_relaxed);
        return;
      }
    }
  }
}

std::atomic<uint64_t> s_lastPollMs{0};
std::atomic<uint64_t> s_lastProbeLogMs{0};
uint64_t s_recStartMs = 0;
bool s_f9WasDown = false;
std::mutex s_probeLogMutex;

inline uint64_t NowMs() {
  return static_cast<uint64_t>(
      std::chrono::duration_cast<std::chrono::milliseconds>(
          std::chrono::steady_clock::now().time_since_epoch())
          .count());
}

void PollRecorderHotkey(uint64_t nowMs) {
  uint64_t prevPoll = s_lastPollMs.load(std::memory_order_relaxed);
  if (nowMs - prevPoll < 40ull) {
    return;
  }
  std::lock_guard<std::mutex> lock(s_probeLogMutex);
  prevPoll = s_lastPollMs.load(std::memory_order_relaxed);
  if (nowMs - prevPoll < 40ull) {
    return;
  }
  s_lastPollMs.store(nowMs, std::memory_order_relaxed);

  const bool isDown = (GetAsyncKeyState(VK_F9) & 0x8000) != 0;
  const bool pressed = isDown && !s_f9WasDown;
  s_f9WasDown = isDown;

  if (pressed) {
    if (!s_recording.load(std::memory_order_relaxed)) {
      for (size_t i = 0; i < kNumProbes; ++i) {
        s_probeHits[i].store(0u, std::memory_order_relaxed);
        s_recTotals[i] = 0u;
      }
      for (auto& s : s_ctrUpd) {
        s.addr.store(0u, std::memory_order_relaxed);
        s.count.store(0u, std::memory_order_relaxed);
      }
      for (auto& s : s_ctrDrw) {
        s.addr.store(0u, std::memory_order_relaxed);
        s.count.store(0u, std::memory_order_relaxed);
      }
      s_recStartMs = nowMs;
      s_lastProbeLogMs.store(nowMs, std::memory_order_relaxed);
      s_recording.store(true, std::memory_order_release);
      REXLOG_INFO("[RECORDER] === START (F9) ===");
    } else {
      s_recording.store(false, std::memory_order_release);
      std::string msg;
      msg.reserve(512);
      for (size_t i = 0; i < kNumProbes; ++i) {
        s_recTotals[i] += s_probeHits[i].exchange(0u, std::memory_order_relaxed);
        if (s_recTotals[i] > 0u) {
          if (!msg.empty()) msg += ' ';
          msg += kProbeNames[i];
          msg += '=';
          msg += std::to_string(s_recTotals[i]);
        }
      }
      auto appendCtr = [&](const char* tag, std::array<CtrSlot, 16>& slots) {
        for (auto& s : slots) {
          const uint32_t a = s.addr.load(std::memory_order_relaxed);
          const uint32_t c = s.count.exchange(0u, std::memory_order_relaxed);
          if (a != 0u && c > 0u) {
            char buf[32];
            std::snprintf(buf, sizeof(buf), " %s:%08X=%u", tag, a, c);
            msg += buf;
          }
        }
      };
      appendCtr("UPD", s_ctrUpd);
      appendCtr("DRW", s_ctrDrw);
      const double durSec = static_cast<double>(nowMs - s_recStartMs) / 1000.0;
      REXLOG_INFO("[RECORDER] === STOP ({:.2f}s) TOTALS: {} ===",
                  durSec, msg.empty() ? "none" : msg);
    }
    return;
  }

  if (!s_recording.load(std::memory_order_relaxed)) {
    return;
  }

  const uint64_t prevLog = s_lastProbeLogMs.load(std::memory_order_relaxed);
  if (nowMs - prevLog < 1000ull) {
    return;
  }
  s_lastProbeLogMs.store(nowMs, std::memory_order_relaxed);

  std::string msg;
  msg.reserve(256);
  for (size_t i = 0; i < kNumProbes; ++i) {
    const uint32_t c = s_probeHits[i].exchange(0u, std::memory_order_relaxed);
    s_recTotals[i] += c;
    if (c > 0u) {
      if (!msg.empty()) msg += ' ';
      msg += kProbeNames[i];
      msg += '=';
      msg += std::to_string(c);
    }
  }
  if (!msg.empty()) {
    REXLOG_INFO("[RECORDER 1s] {}", msg);
  }
}

inline void RecordProbeHit(size_t idx) {
  if (s_recording.load(std::memory_order_acquire)) {
    s_probeHits[idx].fetch_add(1u, std::memory_order_relaxed);
  }
  PollRecorderHotkey(NowMs());
}

}  // namespace

void sbx_probe_00() { RecordProbeHit(0); }
void sbx_probe_01() { RecordProbeHit(1); }
void sbx_probe_02() { RecordProbeHit(2); }
void sbx_probe_03() { RecordProbeHit(3); }
void sbx_probe_04() { RecordProbeHit(4); }
void sbx_probe_05() { RecordProbeHit(5); }
void sbx_probe_06() { RecordProbeHit(6); }
void sbx_probe_07() { RecordProbeHit(7); }
void sbx_probe_08() { RecordProbeHit(8); }
void sbx_probe_09() { RecordProbeHit(9); }
void sbx_probe_10() { RecordProbeHit(10); }
void sbx_probe_11() { RecordProbeHit(11); }
void sbx_probe_12() { RecordProbeHit(12); }
void sbx_probe_13() { RecordProbeHit(13); }
void sbx_probe_14() { RecordProbeHit(14); }
void sbx_probe_15() { RecordProbeHit(15); }
void sbx_probe_16() { RecordProbeHit(16); }
void sbx_probe_17() { RecordProbeHit(17); }
void sbx_probe_18() { RecordProbeHit(18); }
void sbx_probe_19() { RecordProbeHit(19); }
void sbx_probe_20() { RecordProbeHit(20); }
void sbx_probe_ctr_upd(PPCRegister& ctr) {
  RecordCtr(s_ctrUpd, ctr.u32);
  PollRecorderHotkey(NowMs());
}
void sbx_probe_ctr_drw(PPCRegister& ctr) {
  RecordCtr(s_ctrDrw, ctr.u32);
  PollRecorderHotkey(NowMs());
}

void sbx_scale_sp_dmg_r11(PPCRegister& r11, PPCRegister& r26) {
  if (r11.u32 == 0u) {
    return;
  }
  PPCRegister tmp{};
  tmp.f64 = static_cast<double>(r11.u32);
  ScaleDtRegister(tmp);
  double scaled = tmp.f64;
  if (scaled < 0.0) {
    scaled = 0.0;
  }

  static std::mutex s_spMutex;
  static std::array<std::pair<uint32_t, double>, 8> s_spAcc{};
  std::lock_guard<std::mutex> lock(s_spMutex);
  double* remPtr = nullptr;
  for (auto& slot : s_spAcc) {
    if (slot.first == r26.u32) {
      remPtr = &slot.second;
      break;
    }
    if (slot.first == 0u && !remPtr) {
      slot.first = r26.u32;
      remPtr = &slot.second;
    }
  }
  const double total = scaled + (remPtr ? *remPtr : 0.0);
  const uint32_t intDmg = static_cast<uint32_t>(total);
  if (remPtr) {
    *remPtr = total - static_cast<double>(intDmg);
  }
  r11.u64 = intDmg;
}

void sbx_scale_sub_f0_f30(PPCRegister& f0, PPCRegister& f30) {
  // Runs after `fsubs f0, f0, f30`; reconstruct original f0 and apply scaled step
  // without mutating f30 (which is also used later as 1.0f).
  const double origF0 = f0.f64 + f30.f64;
  PPCRegister step{};
  step.f64 = f30.f64;
  ScaleDtRegister(step);
  f0.f64 = double(float(origF0 - step.f64));
}
