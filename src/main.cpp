/**
 * @file        main.cpp
 * @brief       Entry point for 首都高バトルX (Shutokou Battle X) Windows Native Recompilation
 * 
 * @copyright   Copyright (c) 2026 STKX-recomp / ReXGlue Project
 * @license     BSD-3-Clause
 */

#include "shutokou_battle_x_app.h"

#if __has_include("shutokou_battle_x_init.h")
#include "shutokou_battle_x_init.h"
REX_DEFINE_APP(shutokou_battle_x, ShutokouBattleXApp::Create)
#elif __has_include("generated/entrypoint/shutokou_battle_x_init.h")
#include "generated/entrypoint/shutokou_battle_x_init.h"
REX_DEFINE_APP(shutokou_battle_x, ShutokouBattleXApp::Create)
#else
REX_DEFINE_APP(shutokou_battle_x, ShutokouBattleXApp::Create)
#endif
