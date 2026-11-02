#import "MiningFeatures.h"
#import "Game/Offsets.h"
#import "Game/GameTypes.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"
#import "FishingFeatures.h"
#import "PlayerFeatures.h"
#import "MapFeatures.h"
#import <QuartzCore/QuartzCore.h>
#import <vector>
#import <cmath>

namespace MiningFeatures {

    static Config g_config = {
        false, // autoMineRocks
        false, // autoChangeMap
        true,  // cycleMapPlaza
        true,  // cycleMapCamping
        true,  // cycleMapResort
        true,  // cycleMapDowntown
        true,  // teleAllStones
        false, // teleSmallStones
        false, // teleMediumStones
        false, // teleLargeStones
        false, // autoExcavate
        0.3f   // excavateDelay
    };

    static Stats g_stats = { 0, 0 };

    typedef bool (*OnClickPickax_t)(void* this_ptr);
    static OnClickPickax_t p_OnClickPickax = nullptr;

    typedef bool (*OnClickExcavate_t)(void* this_ptr);
    static OnClickExcavate_t p_OnClickExcavate = nullptr;

    typedef void* (*get_Collect_t)();
    static get_Collect_t p_get_Collect = nullptr;

    typedef GameTypes::Vector3 (*MapObject_get_DetectTargetPos_t)(void* obj);
    static MapObject_get_DetectTargetPos_t p_MapObject_get_DetectTargetPos = nullptr;

    typedef void (*RequestToMapObjectAction_t)(void* this_ptr, uint32_t objectID);
    static RequestToMapObjectAction_t p_RequestToMapObjectAction = nullptr;

    typedef int64_t (*UpdateClosestExcavationObjectId_t)(void* this_ptr, GameTypes::Vector3 position, float detectRange);
    static UpdateClosestExcavationObjectId_t p_UpdateClosestExcavationObjectId = nullptr;

    typedef void* (*GetExcavationObjectManager_t)(void* this_ptr, int64_t objectUid);
    static GetExcavationObjectManager_t p_GetExcavationObjectManager = nullptr;

    typedef void (*RequestExcavationHit_t)(void* this_ptr, bool isSuccess, GameTypes::Vector3 hitPos);
    static RequestExcavationHit_t p_RequestExcavationHit = nullptr;

    typedef void (*RequestExcvationReward_t)(void* this_ptr, int64_t uid);
    static RequestExcvationReward_t p_RequestExcvationReward = nullptr;

    typedef void (*ExcavationObject_OnClickReward_t)(void* this_ptr);
    static ExcavationObject_OnClickReward_t p_ExcavationObject_OnClickReward = nullptr;

    typedef void* (*Component_get_transform_t)(void* comp);
    static Component_get_transform_t p_Component_get_transform = nullptr;

    typedef GameTypes::Vector3 (*Transform_get_position_t)(void* trans);
    static Transform_get_position_t p_Transform_get_position = nullptr;

    static double s_lastMineHitTime = 0.0;
    static double s_lastExcavateTime = 0.0;
    static double s_lastMapChangeTime = 0.0;
    static size_t s_currentCycleIndex = 0;
    static void* s_currentTargetRock = nullptr;

    void EnsureHooksInstalled() {
        static bool s_installed = false;
        if (s_installed) return;
        s_installed = true;

        p_OnClickPickax = (OnClickPickax_t)Memory::GetRealOffset(Offsets::Extended::OnClickPickax);
        p_OnClickExcavate = (OnClickExcavate_t)Memory::GetRealOffset(Offsets::Extended::OnClickExcavate);
        p_get_Collect = (get_Collect_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Collect);
        p_MapObject_get_DetectTargetPos = (MapObject_get_DetectTargetPos_t)Memory::GetRealOffset(Offsets::Collect::MapObject_get_DetectTargetPos);

        p_RequestToMapObjectAction = (RequestToMapObjectAction_t)Memory::GetRealOffset(Offsets::Collect::RequestToMapObjectAction);
        p_UpdateClosestExcavationObjectId = (UpdateClosestExcavationObjectId_t)Memory::GetRealOffset(0x3970A50);
        p_GetExcavationObjectManager = (GetExcavationObjectManager_t)Memory::GetRealOffset(0x396DDF0);
        p_RequestExcavationHit = (RequestExcavationHit_t)Memory::GetRealOffset(Offsets::Collect::RequestExcavationHit);
        p_RequestExcvationReward = (RequestExcvationReward_t)Memory::GetRealOffset(Offsets::Collect::RequestExcvationReward);
        p_ExcavationObject_OnClickReward = (ExcavationObject_OnClickReward_t)Memory::GetRealOffset(Offsets::Collect::ExcavationObject_OnClickReward);

        p_Component_get_transform = (Component_get_transform_t)Memory::GetRealOffset(Offsets::Engine::Component_get_transform);
        p_Transform_get_position = (Transform_get_position_t)Memory::GetRealOffset(Offsets::Engine::Transform_get_position);

        LOG_INFO("MiningFeatures initialized with native CollectSystem actions.");
    }

    void Initialize() {
        EnsureHooksInstalled();
    }

    Config& GetConfig() { return g_config; }
    Stats GetStats() { return g_stats; }

    static std::vector<uint32_t> GetEnabledMapList() {
        std::vector<uint32_t> maps;
        if (g_config.cycleMapPlaza) maps.push_back(1001);
        if (g_config.cycleMapCamping) maps.push_back(1201);
        if (g_config.cycleMapResort) maps.push_back(1301);
        if (g_config.cycleMapDowntown) maps.push_back(1502);
        return maps;
    }

    // --------------------------------------------------------------------------
    // Update loop running 60 FPS on Metal Render Thread
    // --------------------------------------------------------------------------
    void Update() {
        @try {
            void* player = FishingFeatures::GetLocalPlayerControl();
            if (!player || (uintptr_t)player < 0x100000000ULL) return;

            if (!p_OnClickPickax) p_OnClickPickax = (OnClickPickax_t)Memory::GetRealOffset(Offsets::Extended::OnClickPickax);
            if (!p_OnClickExcavate) p_OnClickExcavate = (OnClickExcavate_t)Memory::GetRealOffset(Offsets::Extended::OnClickExcavate);
            if (!p_get_Collect) p_get_Collect = (get_Collect_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Collect);
            if (!p_MapObject_get_DetectTargetPos) p_MapObject_get_DetectTargetPos = (MapObject_get_DetectTargetPos_t)Memory::GetRealOffset(Offsets::Collect::MapObject_get_DetectTargetPos);
            if (!p_RequestToMapObjectAction) p_RequestToMapObjectAction = (RequestToMapObjectAction_t)Memory::GetRealOffset(Offsets::Collect::RequestToMapObjectAction);

            if (!p_get_Collect) return;
            void* collectSys = p_get_Collect();
            if (!collectSys || (uintptr_t)collectSys < 0x100000000ULL) return;

            // Mở rộng bán kính gõ cuốc của CollectSystem lên 50m
            float* p_rad = (float*)((uintptr_t)collectSys + 0x1B8);
            if (*p_rad < 50.0f) *p_rad = 50.0f;

            // 1. Quét danh sách quặng đá hợp lệ
            void* mapObjList = *(void**)((uintptr_t)collectSys + 0x180);
            std::vector<void*> validRocks;
            if (mapObjList && (uintptr_t)mapObjList >= 0x100000000ULL) {
                void* itemsArray = *(void**)((uintptr_t)mapObjList + 0x10);
                int32_t size = *(int32_t*)((uintptr_t)mapObjList + 0x18);
                if (itemsArray && size > 0 && size < 500) {
                    for (int32_t i = 0; i < size; i++) {
                        void* rockObj = ((void**)((uintptr_t)itemsArray + 0x20))[i];
                        if (!rockObj || (uintptr_t)rockObj < 0x100000000ULL) continue;

                        int32_t state = *(int32_t*)((uintptr_t)rockObj + 0x18);
                        if (state == 2) continue; // Đã vỡ

                        validRocks.push_back(rockObj);
                    }
                }
            }
            g_stats.rocksInMap = (uint32_t)validRocks.size();

            double now = CACurrentMediaTime();

            // 2. Tự Động Đổi Map Khi Hết Đá
            if (g_config.autoChangeMap && validRocks.empty()) {
                if (now - s_lastMapChangeTime >= 4.0) {
                    s_lastMapChangeTime = now;
                    std::vector<uint32_t> cycle = GetEnabledMapList();
                    if (!cycle.empty()) {
                        s_currentCycleIndex = (s_currentCycleIndex + 1) % cycle.size();
                        uint32_t nextMap = cycle[s_currentCycleIndex];
                        MapFeatures::TeleportToMap(nextMap);
                        s_currentTargetRock = nullptr;
                    }
                }
                return;
            }

            // 3. Logic Auto Đập Đá Chuẩn Cate:
            // Teleport đứng cách quặng đá 0.9m (không trùng va chạm), đăng ký Target ObjectID trong CollectSystem và gõ cuốc
            if (g_config.autoMineRocks && !validRocks.empty() && p_OnClickPickax) {
                bool targetValid = false;
                if (s_currentTargetRock) {
                    int32_t targetState = *(int32_t*)((uintptr_t)s_currentTargetRock + 0x18);
                    if (targetState != 2) {
                        for (void* r : validRocks) {
                            if (r == s_currentTargetRock) {
                                targetValid = true;
                                break;
                            }
                        }
                    }
                }

                if (!targetValid) {
                    if (s_currentTargetRock) {
                        g_stats.rocksMined++;
                    }
                    s_currentTargetRock = validRocks[0];
                    if (s_currentTargetRock && p_MapObject_get_DetectTargetPos) {
                        GameTypes::Vector3 rpos = p_MapObject_get_DetectTargetPos(s_currentTargetRock);
                        if (fabsf(rpos.x) > 0.01f || fabsf(rpos.z) > 0.01f) {
                            // Đứng cách tâm đá 0.9m để không bị kẹt collider đá
                            PlayerFeatures::Teleport(rpos.x + 0.85f, rpos.y + 0.05f, rpos.z + 0.85f);
                        }
                    }
                }

                if (s_currentTargetRock) {
                    // Đọc ObjectID từ NetworkMapObject ở offset 0x10
                    void* netObj = *(void**)((uintptr_t)s_currentTargetRock + 0x10);
                    uint32_t rockId = 0;
                    if (netObj && (uintptr_t)netObj >= 0x100000000ULL) {
                        rockId = *(uint32_t*)((uintptr_t)netObj + 0x10);
                    }

                    // Đăng ký mục tiêu đá vào CollectSystem để game không báo "không có gì ở đây"
                    if (rockId > 0) {
                        *(uint32_t*)((uintptr_t)collectSys + 0x1C4) = rockId; // _curTargetObjID
                        *(uint32_t*)((uintptr_t)collectSys + 0x150) = rockId; // _collectTargetMapObjectID
                    }

                    // Gõ cuốc liên tục
                    if (now - s_lastMineHitTime >= 0.35) {
                        s_lastMineHitTime = now;
                        p_OnClickPickax(player);
                        if (p_RequestToMapObjectAction && rockId > 0) {
                            p_RequestToMapObjectAction(collectSys, rockId);
                        }
                    }
                }
            }

            // 4. Auto Khai Quật / Đào Kho Báu Chuẩn Cate:
            // Tự tìm cổ vật gần nhất trong map -> Tự động Teleport đến cổ vật -> Đào -> Nhận thưởng
            if (g_config.autoExcavate) {
                if (!p_UpdateClosestExcavationObjectId) p_UpdateClosestExcavationObjectId = (UpdateClosestExcavationObjectId_t)Memory::GetRealOffset(0x3970A50);
                if (!p_GetExcavationObjectManager) p_GetExcavationObjectManager = (GetExcavationObjectManager_t)Memory::GetRealOffset(0x396DDF0);
                if (!p_Component_get_transform) p_Component_get_transform = (Component_get_transform_t)Memory::GetRealOffset(Offsets::Engine::Component_get_transform);
                if (!p_Transform_get_position) p_Transform_get_position = (Transform_get_position_t)Memory::GetRealOffset(Offsets::Engine::Transform_get_position);

                GameTypes::Vector3 myPos = PlayerFeatures::GetLocalPosition();
                int64_t closestUid = 0;
                if (p_UpdateClosestExcavationObjectId) {
                    closestUid = p_UpdateClosestExcavationObjectId(collectSys, myPos, 9999.0f);
                } else {
                    closestUid = *(int64_t*)((uintptr_t)collectSys + 0x120); // _closestExcavationObjId
                }

                if (closestUid != 0 && p_GetExcavationObjectManager) {
                    void* manager = p_GetExcavationObjectManager(collectSys, closestUid);
                    if (manager && (uintptr_t)manager >= 0x100000000ULL) {
                        int32_t curHp = *(int32_t*)((uintptr_t)manager + 0x30); // CurrentHP
                        int32_t state = *(int32_t*)((uintptr_t)manager + 0x28); // State

                        if (p_Component_get_transform && p_Transform_get_position) {
                            void* trans = p_Component_get_transform(manager);
                            if (trans && (uintptr_t)trans >= 0x100000000ULL) {
                                GameTypes::Vector3 tpos = p_Transform_get_position(trans);
                                float dx = tpos.x - myPos.x;
                                float dz = tpos.z - myPos.z;
                                float dist = sqrtf(dx*dx + dz*dz);

                                // Teleport trực tiếp đến vị trí hòm cổ vật
                                if (dist > 1.2f && (fabsf(tpos.x) > 0.1f || fabsf(tpos.z) > 0.1f)) {
                                    PlayerFeatures::Teleport(tpos.x, tpos.y + 0.1f, tpos.z);
                                }
                            }
                        }

                        // Nếu cổ vật đã đào xong hoặc hết máu, lập tức nhận thưởng
                        if (curHp <= 0 || state == 2 || state == 3) {
                            if (p_ExcavationObject_OnClickReward) {
                                p_ExcavationObject_OnClickReward(manager);
                            }
                            if (p_RequestExcvationReward) {
                                p_RequestExcvationReward(collectSys, closestUid);
                            }
                        } else {
                            // Đang đào: Gọi OnClickExcavate theo nhịp cấu hình
                            double delay = g_config.excavateDelay > 0.1f ? (double)g_config.excavateDelay : 0.3;
                            if (now - s_lastExcavateTime >= delay) {
                                s_lastExcavateTime = now;
                                if (p_OnClickExcavate) {
                                    p_OnClickExcavate(player);
                                }
                                if (p_RequestExcavationHit) {
                                    p_RequestExcavationHit(collectSys, true, myPos);
                                }
                            }
                        }
                    }
                } else if (p_OnClickExcavate) {
                    // Fallback đào tại chỗ nếu chưa phát hiện cổ vật
                    double delay = g_config.excavateDelay > 0.1f ? (double)g_config.excavateDelay : 0.3;
                    if (now - s_lastExcavateTime >= delay) {
                        s_lastExcavateTime = now;
                        p_OnClickExcavate(player);
                    }
                }
            }
        } @catch (NSException *ex) {
            // Suppress
        }
    }

    void TriggerPickaxHit() {
        void* player = FishingFeatures::GetLocalPlayerControl();
        if (player && p_OnClickPickax) {
            p_OnClickPickax(player);
            g_stats.rocksMined++;
        }
    }

    void TriggerExcavate() {
        void* player = FishingFeatures::GetLocalPlayerControl();
        if (player && p_OnClickExcavate) {
            p_OnClickExcavate(player);
        }
    }
}
