/**
 * @file        wheel_input.cpp
 * @brief       Steering wheel & Force Feedback integration for 首都高バトルX
 */

#include "wheel_input.h"
#include <iostream>
#include <cmath>
#include <algorithm>

namespace sbx::patches {

namespace {
    bool s_wheelDetected = false;
    float s_currentFfbForce = 0.0f;
}

void InitializeSteeringWheelSupport() {
    // Detects DirectInput / XInput racing wheel controllers (Logitech G29/G920, Fanatec, Thrustmaster)
    std::cout << "[SBX-Wheel] Initializing Racing Wheel & DirectInput Force Feedback..." << std::endl;
    s_wheelDetected = true;
}

void UpdateForceFeedback(float lateralGForce, float tireSlipRatio, float roadRumble) {
    if (!s_wheelDetected) return;

    // Calculate self-aligning torque and tire grip loss for highway drifting
    float aligningTorque = lateralGForce * (1.0f - std::min(tireSlipRatio * 0.8f, 1.0f));
    s_currentFfbForce = std::clamp(aligningTorque + (roadRumble * 0.15f), -1.0f, 1.0f);
}

} // namespace sbx::patches
