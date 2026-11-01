#import "PlayerFeatures.h"
#import "Game/Offsets.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"
#import "FishingFeatures.h"

namespace PlayerFeatures {

    static Config g_config = {
        false, // speedHack
        2.0f,  // speedMultiplier
        false, // highJump
        false, // walkOnAir
        false, // noClip
        false  // autoMinigameGoal
    };

    static float s_baseMoveSpd = -1.0f;
    static float s_baseJumpSpd = -1.0f;

    typedef void (*Motor_SetPosition_t)(void* motor, GameTypes::Vector3 pos, bool bypassInterpolation);
    static Motor_SetPosition_t p_Motor_SetPosition = nullptr;

    typedef void (*Motor_SetCapsuleCollisionsActivation_t)(void* motor, bool collisionsActive);
    static Motor_SetCapsuleCollisionsActivation_t p_Motor_SetCapsuleCollisionsActivation = nullptr;

    typedef void (*Motor_SetMovementCollisionsSolvingActivation_t)(void* motor, bool collisionsActive);
    static Motor_SetMovementCollisionsSolvingActivation_t p_Motor_SetMovementCollisionsSolvingActivation = nullptr;

    typedef void (*Motor_set_CheatDetect_t)(void* motor, bool value);
    static Motor_set_CheatDetect_t p_Motor_set_CheatDetect = nullptr;

    typedef GameTypes::Vector3 (*Motor_get_TransientPosition_t)(void* motor);
    static Motor_get_TransientPosition_t p_Motor_get_TransientPosition = nullptr;

    void EnsureHooksInstalled() {
        static bool s_installed = false;
        if (s_installed) return;
        s_installed = true;

        p_Motor_SetPosition = (Motor_SetPosition_t)Memory::GetRealOffset(Offsets::Kinematic::Motor_SetPosition);
        p_Motor_SetCapsuleCollisionsActivation = (Motor_SetCapsuleCollisionsActivation_t)Memory::GetRealOffset(Offsets::Kinematic::Motor_SetCapsuleCollisionsActivation);
        p_Motor_SetMovementCollisionsSolvingActivation = (Motor_SetMovementCollisionsSolvingActivation_t)Memory::GetRealOffset(Offsets::Kinematic::Motor_SetMovementCollisionsSolvingActivation);
        p_Motor_set_CheatDetect = (Motor_set_CheatDetect_t)Memory::GetRealOffset(Offsets::Kinematic::Motor_set_CheatDetect);
        p_Motor_get_TransientPosition = (Motor_get_TransientPosition_t)Memory::GetRealOffset(Offsets::Kinematic::Motor_get_TransientPosition);

        LOG_INFO("PlayerFeatures runtime motor pointers initialized.");
    }

    void Initialize() {
        EnsureHooksInstalled();
    }

    Config& GetConfig() { return g_config; }

    void SetSpeedMultiplier(float speed) {
        g_config.speedMultiplier = speed;
    }

    static void* GetMotor() {
        void* player = FishingFeatures::GetLocalPlayerControl();
        if (!player || (uintptr_t)player < 0x100000000ULL) return nullptr;

        void* kmc = *(void**)((uintptr_t)player + 0x4F8);
        if (!kmc || (uintptr_t)kmc < 0x100000000ULL) return nullptr;

        void* motor = *(void**)((uintptr_t)kmc + 0x20);
        if (!motor || (uintptr_t)motor < 0x100000000ULL) return nullptr;

        return motor;
    }

    // --------------------------------------------------------------------------
    // Update loop running 60 FPS on Metal Render Thread
    // --------------------------------------------------------------------------
    void Update() {
        @try {
            void* player = FishingFeatures::GetLocalPlayerControl();
            if (!player || (uintptr_t)player < 0x100000000ULL) return;

            void* kmc = *(void**)((uintptr_t)player + 0x4F8);
            if (!kmc || (uintptr_t)kmc < 0x100000000ULL) return;

            void* motor = *(void**)((uintptr_t)kmc + 0x20);

            // 1. Tốc Độ Chạy (Speed Hack)
            float* p_spd = (float*)((uintptr_t)kmc + 0x48);
            if (s_baseMoveSpd <= 0.0f && *p_spd > 0.0f && *p_spd < 50.0f) {
                s_baseMoveSpd = *p_spd;
            }
            if (s_baseMoveSpd > 0.0f) {
                if (g_config.speedHack) {
                    *p_spd = s_baseMoveSpd * g_config.speedMultiplier;
                } else {
                    *p_spd = s_baseMoveSpd;
                }
            }

            // 2. Nhảy Cao (High Jump)
            float* p_jump = (float*)((uintptr_t)kmc + 0x9C);
            if (s_baseJumpSpd <= 0.0f && *p_jump > 0.0f && *p_jump < 50.0f) {
                s_baseJumpSpd = *p_jump;
            }
            if (s_baseJumpSpd > 0.0f) {
                if (g_config.highJump) {
                    *p_jump = 18.0f;
                } else {
                    *p_jump = s_baseJumpSpd;
                }
            }

            // 3. Đi Trên Không (Walk On Air / Fly)
            float* p_gravityY = (float*)((uintptr_t)kmc + 0xC4);
            if (g_config.walkOnAir) {
                *p_gravityY = 0.0f; // Vô hiệu hóa trọng lực
            }

            // 4. NoClip (Xuyên Vật Thể)
            static bool s_lastNoClip = false;
            if (g_config.noClip != s_lastNoClip) {
                s_lastNoClip = g_config.noClip;
                if (motor) {
                    if (!p_Motor_SetCapsuleCollisionsActivation) {
                        p_Motor_SetCapsuleCollisionsActivation = (Motor_SetCapsuleCollisionsActivation_t)Memory::GetRealOffset(Offsets::Kinematic::Motor_SetCapsuleCollisionsActivation);
                    }
                    if (!p_Motor_SetMovementCollisionsSolvingActivation) {
                        p_Motor_SetMovementCollisionsSolvingActivation = (Motor_SetMovementCollisionsSolvingActivation_t)Memory::GetRealOffset(Offsets::Kinematic::Motor_SetMovementCollisionsSolvingActivation);
                    }
                    if (p_Motor_SetCapsuleCollisionsActivation) {
                        p_Motor_SetCapsuleCollisionsActivation(motor, !g_config.noClip);
                    }
                    if (p_Motor_SetMovementCollisionsSolvingActivation) {
                        p_Motor_SetMovementCollisionsSolvingActivation(motor, !g_config.noClip);
                    }
                }
            }

            // 5. Anti-Cheat bypass in Physics Motor
            if (motor) {
                if (!p_Motor_set_CheatDetect) {
                    p_Motor_set_CheatDetect = (Motor_set_CheatDetect_t)Memory::GetRealOffset(Offsets::Kinematic::Motor_set_CheatDetect);
                }
                if (p_Motor_set_CheatDetect) {
                    p_Motor_set_CheatDetect(motor, false);
                }
            }
        } @catch (NSException *ex) {
            // Suppress
        }
    }

    void Teleport(float x, float y, float z) {
        @try {
            void* motor = GetMotor();
            if (!motor) return;

            if (!p_Motor_SetPosition) {
                p_Motor_SetPosition = (Motor_SetPosition_t)Memory::GetRealOffset(Offsets::Kinematic::Motor_SetPosition);
            }

            if (p_Motor_SetPosition) {
                GameTypes::Vector3 target = { x, y, z };
                p_Motor_SetPosition(motor, target, true);
            }
        } @catch (NSException *ex) {
            // Suppress
        }
    }

    GameTypes::Vector3 GetLocalPosition() {
        @try {
            void* motor = GetMotor();
            if (motor) {
                if (!p_Motor_get_TransientPosition) {
                    p_Motor_get_TransientPosition = (Motor_get_TransientPosition_t)Memory::GetRealOffset(Offsets::Kinematic::Motor_get_TransientPosition);
                }
                if (p_Motor_get_TransientPosition) {
                    return p_Motor_get_TransientPosition(motor);
                }
                // Fallback: direct struct field at 0x100
                return *(GameTypes::Vector3*)((uintptr_t)motor + 0x100);
            }
        } @catch (NSException *ex) {
            // Suppress
        }
        return { 0.0f, 0.0f, 0.0f };
    }

    void TriggerMinigameGoal() {
        // Obby checkpoint finish logic
    }
}
