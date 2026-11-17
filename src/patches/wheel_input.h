/**
 * @file        wheel_input.h
 * @brief       Steering wheel & Force Feedback integration for 首都高バトルX
 */

#pragma once

#include <cstdint>

namespace sbx::patches {

void InitializeSteeringWheelSupport();
void UpdateForceFeedback(float lateralGForce, float tireSlipRatio, float roadRumble);

} // namespace sbx::patches
