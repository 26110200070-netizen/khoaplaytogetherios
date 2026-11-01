#import "PlayerFeatures.h"
#import "Game/Offsets.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"

namespace PlayerFeatures {

    static Config g_config = {
        false, // speedHack
        2.5f,  // speedMultiplier
        false, // highJump
        false, // walkOnAir
        false, // noClip
        false, // autoSchool
        false  // autoMinigameGoal
    };

    typedef void (*AnimancerState_set_Speed_t)(void* this_ptr, float speed);
    static AnimancerState_set_Speed_t p_AnimancerState_set_Speed = nullptr;

    typedef void (*SendToKMGFinishGoal_t)(void* protocol, int miniGameType, int goalIndex);
    static SendToKMGFinishGoal_t p_SendToKMGFinishGoal = nullptr;

    void EnsureHooksInstalled() {
        static bool s_installed = false;
        if (s_installed) return;
        s_installed = true;

        p_AnimancerState_set_Speed = (AnimancerState_set_Speed_t)Memory::GetRealOffset(Offsets::Extended::AnimancerState_set_Speed);
        p_SendToKMGFinishGoal = (SendToKMGFinishGoal_t)Memory::GetRealOffset(Offsets::Extended::SendToKMGFinishGoal);
        LOG_INFO("PlayerFeatures hooks initialized.");
    }

    void Initialize() {
        EnsureHooksInstalled();
    }

    Config& GetConfig() { return g_config; }

    void SetSpeedMultiplier(float speed) {
        g_config.speedMultiplier = speed;
    }

    void TriggerMinigameGoal() {
        EnsureHooksInstalled();
    }
}
