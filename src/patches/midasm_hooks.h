/**
 * @file        patches/midasm_hooks.h
 * @brief       Mid-ASM hooks injected into recompiled PPC instructions via manifest.toml
 */

#pragma once

#include <rex/ppc/context.h>

/**
 * @brief Overrides the 60-cycle post-race wait threshold at 0x8218C30C (sub_8218C240)
 *        after `cmplwi cr6, r11, 60` executes, preventing the post-race black screen softlock.
 */
void sbx_post_race_wait_patch(PPCRegister& r11,
                              PPCCRRegister& cr6,
                              PPCXERRegister& xer);

/**
 * @brief Scales guest fixed 30 FPS delta time loaded via `lfs` into an FPR
 *        by real_dt / (1/30s) so simulation and steering speed match 1:1 at any FPS.
 */
void sbx_scale_dt_f0(PPCRegister& f0);
void sbx_scale_dt_f1(PPCRegister& f1);
void sbx_scale_dt_f6(PPCRegister& f6);
void sbx_scale_dt_f9(PPCRegister& f9);
void sbx_scale_dt_f10(PPCRegister& f10);
void sbx_scale_dt_f11(PPCRegister& f11);
void sbx_scale_dt_f13(PPCRegister& f13);
void sbx_scale_dt_f29(PPCRegister& f29);
void sbx_scale_dt_f30(PPCRegister& f30);
void sbx_scale_dt_f31(PPCRegister& f31);

/**
 * @brief Decouples menu/pad button hold duration & auto-repeat timing (sub_82577A08 /
 *        sub_82577DA0) from host FPS while keeping initial presses 1-frame responsive.
 */
void sbx_pad_hold_tick(PPCRegister& r31, PPCRegister& r7, PPCRegister& r10);
void sbx_pad_repeat_check(PPCRegister& r3, PPCRegister& r4, PPCRegister& r11);
bool sbx_menu_repeat_gate(PPCRegister& r4);

/**
 * @brief Decouples fixed 30 FPS integer frame/timer/animation counters using the
 *        per-frame shared 30 Hz accumulator (`GetFrameTicks30Hz()`).
 */
void sbx_tick_add1_r10(PPCRegister& r10);
void sbx_tick_add1_r11(PPCRegister& r11);
void sbx_tick_add1_cap120_r11(PPCRegister& r11);
void sbx_tick_sub1_r10(PPCRegister& r10);
void sbx_tick_sub1_r11(PPCRegister& r11);
void sbx_tick_sub1_clamp0_r3(PPCRegister& r3);

void sbx_tick_add1_cr0_r10(PPCRegister& r10,
                           PPCCRRegister& cr0,
                           PPCXERRegister& xer);
void sbx_tick_add1_cr0_r11(PPCRegister& r11,
                           PPCCRRegister& cr0,
                           PPCXERRegister& xer);
void sbx_tick_add8_cr0_r11(PPCRegister& r11,
                           PPCCRRegister& cr0,
                           PPCXERRegister& xer);

void sbx_tick_sub1_cr0_r9(PPCRegister& r9,
                           PPCCRRegister& cr0,
                           PPCXERRegister& xer);
void sbx_tick_sub1_cr0_r10(PPCRegister& r10,
                           PPCCRRegister& cr0,
                           PPCXERRegister& xer);
void sbx_tick_sub1_cr0_r11(PPCRegister& r11,
                           PPCCRRegister& cr0,
                           PPCXERRegister& xer);

void sbx_scale_sp_dmg_r11(PPCRegister& r11, PPCRegister& r26);
void sbx_scale_sub_f0_f30(PPCRegister& f0, PPCRegister& f30);

// Temporary runtime hit-count probes (1s periodic log)
void sbx_probe_00();
void sbx_probe_01();
void sbx_probe_02();
void sbx_probe_03();
void sbx_probe_04();
void sbx_probe_05();
void sbx_probe_06();
void sbx_probe_07();
void sbx_probe_08();
void sbx_probe_09();
void sbx_probe_10();
void sbx_probe_11();
void sbx_probe_12();
void sbx_probe_13();
void sbx_probe_14();
void sbx_probe_15();
void sbx_probe_16();
void sbx_probe_17();
void sbx_probe_18();
void sbx_probe_19();
void sbx_probe_20();
void sbx_probe_ctr_upd(PPCRegister& ctr);
void sbx_probe_ctr_drw(PPCRegister& ctr);
