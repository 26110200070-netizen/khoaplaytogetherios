#pragma once
#include <cstdint>

namespace PlayerFeatures {
    struct Config {
        bool speedHack;
        float speedMultiplier; // 1.0f to 10.0f
        bool highJump;
        bool walkOnAir;
        bool noClip;
        bool autoSchool;
        bool autoMinigameGoal;
    };

    void Initialize();
    void EnsureHooksInstalled();
    Config& GetConfig();
    void SetSpeedMultiplier(float speed);
    void TriggerMinigameGoal();
}
