#pragma once
#include <cstdint>
#include "Game/GameTypes.h"

namespace PlayerFeatures {

    struct Config {
        bool speedHack;
        float speedMultiplier;
        bool highJump;
        bool walkOnAir;
        bool noClip;
        bool autoMinigameGoal;
    };

    void Initialize();
    void EnsureHooksInstalled();
    void Update();
    Config& GetConfig();
    void SetSpeedMultiplier(float speed);
    void TriggerMinigameGoal();
    void Teleport(float x, float y, float z);
    GameTypes::Vector3 GetLocalPosition();
}
