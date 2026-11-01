#pragma once
#include <cstdint>
#include <string>
#include "Game/GameTypes.h"

namespace FishingFeatures {

    struct Config {
        bool autoFishingEnabled;       // Auto Câu Cá (Tích hợp bóng 1-7 & Minigame)
        bool autoCastRod;              // Tự động quăng cần
        float castDelay;               // Delay quăng cần (s)
        bool autoHitBite;              // Tự động giật cần
        float hitReactionDelay;        // Tốc độ phản xạ giật (s)
        
        // Minigame cá khổng lồ
        bool bigFishMinigameEnabled;   // Tự giải minigame cá khổng lồ
        float stunTapInterval;         // Tốc độ kéo (s)
        
        // Bảo vệ & Lọc bóng cá
        bool keepFishShadow67;         // Không bán cá bóng 6, 7
        bool fastCatch;                // Cá cắn nhanh
        bool filterShadow[8];          // Lọc bóng 1 -> 7 (true = giữ/câu, false = bỏ qua)
    };

    struct Status {
        GameTypes::FloatState currentFloatState;
        GameTypes::eFishingState currentPlayerState;
        void* activeFloatController;
        void* activePlayerController;
        uint32_t totalFishCaught;
        uint32_t bigFishCompleted;
        bool isFishingActive;
        bool isInMinigame;
        std::string lastStateName;
    };

    void Initialize();
    void InstallHooks();
    void Update();
    void* GetLocalPlayerControl();
    Config& GetConfig();
    Status GetStatus();
    void ResetStats();

    void TriggerCast();
    void TriggerReel();
}
