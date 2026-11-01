#import "InsectFeatures.h"
#import "Game/Offsets.h"
#import "Game/GameTypes.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"
#import "FishingFeatures.h"
#import "PlayerFeatures.h"
#import <QuartzCore/QuartzCore.h>

namespace InsectFeatures {

    static Config g_config = {
        false, // autoCatchInsect
        false, // gatherInsects
        false, // freezeInsects
        false  // insectNoScared
    };

    static Stats g_stats = { 0, 0 };

    typedef bool (*OnPressInsectNet_t)(void* this_ptr, bool isPress);
    static OnPressInsectNet_t p_OnPressInsectNet = nullptr;

    typedef void* (*get_Insect_t)();
    static get_Insect_t p_get_Insect = nullptr;

    typedef void* (*get_LiveInsectList_t)(void* this_ptr);
    static get_LiveInsectList_t p_get_LiveInsectList = nullptr;

    typedef GameTypes::Vector3 (*Insect_get_DetectTargetPos_t)(void* control);
    static Insect_get_DetectTargetPos_t p_Insect_get_DetectTargetPos = nullptr;

    typedef void* (*Component_get_transform_t)(void* comp);
    static Component_get_transform_t p_Component_get_transform = nullptr;

    typedef void (*Transform_set_position_t)(void* trans, GameTypes::Vector3 pos);
    static Transform_set_position_t p_Transform_set_position = nullptr;

    static double s_lastNetSwingTime = 0.0;

    void EnsureHooksInstalled() {
        static bool s_installed = false;
        if (s_installed) return;
        s_installed = true;

        p_OnPressInsectNet = (OnPressInsectNet_t)Memory::GetRealOffset(Offsets::Extended::OnPressInsectNet);
        p_get_Insect = (get_Insect_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Insect);
        p_get_LiveInsectList = (get_LiveInsectList_t)Memory::GetRealOffset(Offsets::Collect::Insect_get_LiveInsectList);
        p_Insect_get_DetectTargetPos = (Insect_get_DetectTargetPos_t)Memory::GetRealOffset(Offsets::Collect::Insect_get_DetectTargetPos);
        p_Component_get_transform = (Component_get_transform_t)Memory::GetRealOffset(Offsets::Engine::Component_get_transform);
        p_Transform_set_position = (Transform_set_position_t)Memory::GetRealOffset(Offsets::Engine::Transform_set_position);

        LOG_INFO("InsectFeatures runtime pointers initialized.");
    }

    void Initialize() {
        EnsureHooksInstalled();
    }

    Config& GetConfig() { return g_config; }
    Stats GetStats() { return g_stats; }

    // --------------------------------------------------------------------------
    // Update loop running 60 FPS on Metal Render Thread
    // --------------------------------------------------------------------------
    void Update() {
        @try {
            void* player = FishingFeatures::GetLocalPlayerControl();
            if (!player || (uintptr_t)player < 0x100000000ULL) return;

            if (!p_OnPressInsectNet) {
                p_OnPressInsectNet = (OnPressInsectNet_t)Memory::GetRealOffset(Offsets::Extended::OnPressInsectNet);
            }
            if (!p_get_Insect) {
                p_get_Insect = (get_Insect_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Insect);
            }
            if (!p_get_LiveInsectList) {
                p_get_LiveInsectList = (get_LiveInsectList_t)Memory::GetRealOffset(Offsets::Collect::Insect_get_LiveInsectList);
            }
            if (!p_Component_get_transform) {
                p_Component_get_transform = (Component_get_transform_t)Memory::GetRealOffset(Offsets::Engine::Component_get_transform);
            }
            if (!p_Transform_set_position) {
                p_Transform_set_position = (Transform_set_position_t)Memory::GetRealOffset(Offsets::Engine::Transform_set_position);
            }

            double now = CACurrentMediaTime();

            // 1. Auto Vung Vợt Bắt Bọ (Auto Catch Insect)
            if (g_config.autoCatchInsect && p_OnPressInsectNet) {
                if (now - s_lastNetSwingTime >= 0.35) {
                    s_lastNetSwingTime = now;
                    p_OnPressInsectNet(player, true);
                    p_OnPressInsectNet(player, false);
                    g_stats.insectsCaught++;
                }
            }

            // 2. Can thiệp danh sách Côn Trùng (Không sợ / Đóng băng / Gom bọ)
            if ((g_config.insectNoScared || g_config.freezeInsects || g_config.gatherInsects) && p_get_Insect && p_get_LiveInsectList) {
                void* insectSys = p_get_Insect();
                if (insectSys && (uintptr_t)insectSys >= 0x100000000ULL) {
                    void* liveList = p_get_LiveInsectList(insectSys);
                    if (liveList && (uintptr_t)liveList >= 0x100000000ULL) {
                        void* itemsArray = *(void**)((uintptr_t)liveList + 0x10);
                        int32_t size = *(int32_t*)((uintptr_t)liveList + 0x18);

                        auto myPos = PlayerFeatures::GetLocalPosition();

                        if (itemsArray && size > 0 && size < 500) {
                            for (int32_t i = 0; i < size; i++) {
                                void* insectEntry = ((void**)((uintptr_t)itemsArray + 0x20))[i];
                                if (!insectEntry || (uintptr_t)insectEntry < 0x100000000ULL) continue;

                                void* control = *(void**)((uintptr_t)insectEntry + 0x20);
                                if (!control || (uintptr_t)control < 0x100000000ULL) continue;

                                // Bọ không sợ (sensitiveChangeT = 99999s)
                                if (g_config.insectNoScared) {
                                    *(float*)((uintptr_t)control + 0x144) = 99999.0f;
                                }

                                // Gom bọ về vị trí người chơi
                                if (g_config.gatherInsects && p_Component_get_transform && p_Transform_set_position) {
                                    void* tr = p_Component_get_transform(control);
                                    if (tr) {
                                        GameTypes::Vector3 targetPos = { myPos.x, myPos.y + 0.5f, myPos.z + 1.2f };
                                        p_Transform_set_position(tr, targetPos);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } @catch (NSException *ex) {
            // Suppress
        }
    }

    void TriggerNetSwing() {
        void* player = FishingFeatures::GetLocalPlayerControl();
        if (player && p_OnPressInsectNet) {
            p_OnPressInsectNet(player, true);
            p_OnPressInsectNet(player, false);
            g_stats.insectsCaught++;
        }
    }
}
