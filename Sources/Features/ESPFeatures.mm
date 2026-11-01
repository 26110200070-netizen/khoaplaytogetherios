#import "ESPFeatures.h"
#import "Game/Offsets.h"
#import "Game/GameTypes.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"
#import "FishingFeatures.h"
#import "PlayerFeatures.h"
#import "../Includes/IMGUI/imgui.h"
#import <QuartzCore/QuartzCore.h>
#import <cmath>
#import <vector>
#import <string>

namespace ESPFeatures {

    static Config g_config = {
        // Boss & Quái
        false, // espBossMonster
        false, // espBossLine
        false, // espBossBox
        false, // espBossHP
        false, // espSpecialDragon

        // Thu Thập & Thế Giới
        false, // espFishingZone
        false, // showTeleFishingZone
        false, // espRocks
        false, // espInsects
        false, // espExcavation
        false, // espTreasure
        false, // espAllItems
        false, // showTeleAllItems
        false, // espEventItems
        false, // showTeleEventItems
        false, // espNPCQuest

        // Minigame & Khác
        false, // espZombieVirus
        false, // showTeleZombieVirus
        false  // espAutoPath
    };

    typedef void* (*Camera_get_main_t)();
    static Camera_get_main_t p_Camera_get_main = nullptr;

    typedef GameTypes::Vector3 (*Camera_WorldToScreenPoint_t)(void* camera, GameTypes::Vector3 pos);
    static Camera_WorldToScreenPoint_t p_Camera_WorldToScreenPoint = nullptr;

    typedef GameTypes::Vector3 (*Camera_WorldToViewportPoint_t)(void* camera, GameTypes::Vector3 pos);
    static Camera_WorldToViewportPoint_t p_Camera_WorldToViewportPoint = nullptr;

    typedef GameTypes::Vector3 (*Transform_get_position_t)(void* transform);
    static Transform_get_position_t p_Transform_get_position = nullptr;

    typedef void* (*Component_get_transform_t)(void* comp);
    static Component_get_transform_t p_Component_get_transform = nullptr;

    typedef void* (*get_Collect_t)();
    static get_Collect_t p_get_Collect = nullptr;

    typedef void* (*get_Insect_t)();
    static get_Insect_t p_get_Insect = nullptr;

    typedef void* (*get_LiveInsectList_t)(void* this_ptr);
    static get_LiveInsectList_t p_get_LiveInsectList = nullptr;

    typedef GameTypes::Vector3 (*MapObject_get_DetectTargetPos_t)(void* obj);
    static MapObject_get_DetectTargetPos_t p_MapObject_get_DetectTargetPos = nullptr;

    typedef GameTypes::Vector3 (*Insect_get_DetectTargetPos_t)(void* control);
    static Insect_get_DetectTargetPos_t p_Insect_get_DetectTargetPos = nullptr;

    // Cache of discovered ESP targets
    static std::vector<ESPItem> s_cachedItems;
    static double s_lastScanTime = 0.0;

    void EnsureHooksInstalled() {
        static bool s_installed = false;
        if (s_installed) return;
        s_installed = true;

        p_Camera_get_main = (Camera_get_main_t)Memory::GetRealOffset(Offsets::Engine::Camera_get_main);
        p_Camera_WorldToScreenPoint = (Camera_WorldToScreenPoint_t)Memory::GetRealOffset(Offsets::Engine::Camera_WorldToScreenPoint);
        p_Camera_WorldToViewportPoint = (Camera_WorldToViewportPoint_t)Memory::GetRealOffset(Offsets::Engine::Camera_WorldToViewportPoint);
        p_Transform_get_position = (Transform_get_position_t)Memory::GetRealOffset(Offsets::Engine::Transform_get_position);
        p_Component_get_transform = (Component_get_transform_t)Memory::GetRealOffset(Offsets::Engine::Component_get_transform);

        p_get_Collect = (get_Collect_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Collect);
        p_get_Insect = (get_Insect_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Insect);
        p_get_LiveInsectList = (get_LiveInsectList_t)Memory::GetRealOffset(Offsets::Collect::Insect_get_LiveInsectList);

        p_MapObject_get_DetectTargetPos = (MapObject_get_DetectTargetPos_t)Memory::GetRealOffset(Offsets::Collect::MapObject_get_DetectTargetPos);
        p_Insect_get_DetectTargetPos = (Insect_get_DetectTargetPos_t)Memory::GetRealOffset(Offsets::Collect::Insect_get_DetectTargetPos);

        LOG_INFO("ESPFeatures hooks and engine pointers resolved.");
    }

    void Initialize() {
        EnsureHooksInstalled();
    }

    Config& GetConfig() { return g_config; }

    bool IsEnabled() {
        return g_config.espBossMonster || g_config.espBossLine || g_config.espBossBox ||
               g_config.espFishingZone || g_config.espRocks || g_config.espInsects ||
               g_config.espExcavation || g_config.espTreasure || g_config.espAllItems ||
               g_config.espEventItems || g_config.espNPCQuest || g_config.espZombieVirus ||
               g_config.espAutoPath;
    }

    // --------------------------------------------------------------------------
    // Update loop running 60 FPS on Metal Render Thread
    // --------------------------------------------------------------------------
    void Update() {
        if (!IsEnabled()) {
            if (!s_cachedItems.empty()) s_cachedItems.clear();
            return;
        }

        double now = CACurrentMediaTime();
        if (now - s_lastScanTime < 0.016) return; // Refresh scan at ~60 FPS (zero latency)
        s_lastScanTime = now;

        @try {
            if (!p_get_Collect) p_get_Collect = (get_Collect_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Collect);
            if (!p_get_Insect) p_get_Insect = (get_Insect_t)Memory::GetRealOffset(Offsets::SystemHelper::get_Insect);
            if (!p_get_LiveInsectList) p_get_LiveInsectList = (get_LiveInsectList_t)Memory::GetRealOffset(Offsets::Collect::Insect_get_LiveInsectList);
            if (!p_MapObject_get_DetectTargetPos) p_MapObject_get_DetectTargetPos = (MapObject_get_DetectTargetPos_t)Memory::GetRealOffset(Offsets::Collect::MapObject_get_DetectTargetPos);
            if (!p_Insect_get_DetectTargetPos) p_Insect_get_DetectTargetPos = (Insect_get_DetectTargetPos_t)Memory::GetRealOffset(Offsets::Collect::Insect_get_DetectTargetPos);

            GameTypes::Vector3 myPos = PlayerFeatures::GetLocalPosition();
            std::vector<ESPItem> newItems;

            // 1. Quét Quặng Đá, Boss, Quái Vật & Kho Báu từ CollectSystem
            if ((g_config.espRocks || g_config.espBossMonster || g_config.espExcavation || g_config.espTreasure || g_config.espAllItems) && p_get_Collect) {
                void* collectSys = p_get_Collect();
                if (collectSys && (uintptr_t)collectSys >= 0x100000000ULL) {

                    // [A] Quặng Đá (MapObjectInfoList at 0x180)
                    if (g_config.espRocks || g_config.espAllItems) {
                        void* mapObjList = *(void**)((uintptr_t)collectSys + 0x180);
                        if (mapObjList && (uintptr_t)mapObjList >= 0x100000000ULL) {
                            void* itemsArray = *(void**)((uintptr_t)mapObjList + 0x10);
                            int32_t size = *(int32_t*)((uintptr_t)mapObjList + 0x18);
                            if (itemsArray && size > 0 && size < 400) {
                                for (int32_t i = 0; i < size; i++) {
                                    void* rockObj = ((void**)((uintptr_t)itemsArray + 0x20))[i];
                                    if (!rockObj || (uintptr_t)rockObj < 0x100000000ULL) continue;

                                    int32_t state = *(int32_t*)((uintptr_t)rockObj + 0x18);
                                    if (state == 2) continue; // Broken

                                    if (p_MapObject_get_DetectTargetPos) {
                                        GameTypes::Vector3 pos = p_MapObject_get_DetectTargetPos(rockObj);
                                        float dx = pos.x - myPos.x;
                                        float dy = pos.y - myPos.y;
                                        float dz = pos.z - myPos.z;
                                        float dist = sqrtf(dx*dx + dy*dy + dz*dz);
                                        if (dist < 200.0f) {
                                            newItems.push_back({ "Quặng Đá", pos.x, pos.y, pos.z, IM_COL32(255, 215, 0, 220), dist, 0, 0, 2 });
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // [B] Boss Rồng & Quái Vật (FieldMonsterInfoList at 0x80)
                    if (g_config.espBossMonster) {
                        void* monsterList = *(void**)((uintptr_t)collectSys + 0x80);
                        if (monsterList && (uintptr_t)monsterList >= 0x100000000ULL) {
                            void* itemsArray = *(void**)((uintptr_t)monsterList + 0x10);
                            int32_t size = *(int32_t*)((uintptr_t)monsterList + 0x18);
                            if (itemsArray && size > 0 && size < 200) {
                                for (int32_t i = 0; i < size; i++) {
                                    void* monsterObj = ((void**)((uintptr_t)itemsArray + 0x20))[i];
                                    if (!monsterObj || (uintptr_t)monsterObj < 0x100000000ULL) continue;

                                    void* monsterInfo = *(void**)((uintptr_t)monsterObj + 0x20);
                                    if (!monsterInfo || (uintptr_t)monsterInfo < 0x100000000ULL) continue;

                                    uint32_t hp = *(uint32_t*)((uintptr_t)monsterInfo + 0x2C);
                                    uint32_t maxHp = *(uint32_t*)((uintptr_t)monsterInfo + 0x4C);
                                    GameTypes::Vector3 mpos = *(GameTypes::Vector3*)((uintptr_t)monsterInfo + 0x3C);
                                    bool isBoss = *(bool*)((uintptr_t)monsterObj + 0x41);

                                    float dx = mpos.x - myPos.x;
                                    float dy = mpos.y - myPos.y;
                                    float dz = mpos.z - myPos.z;
                                    float dist = sqrtf(dx*dx + dy*dy + dz*dz);

                                    std::string name = isBoss ? "Boss Rồng" : "Quái Vật";
                                    newItems.push_back({ name, mpos.x, mpos.y, mpos.z, IM_COL32(255, 60, 60, 240), dist, hp, maxHp, 0 });
                                }
                            }
                        }
                    }
                }
            }

            // 2. Quét Côn Trùng & Bọ từ InsectSystem
            if (g_config.espInsects && p_get_Insect && p_get_LiveInsectList) {
                void* insectSys = p_get_Insect();
                if (insectSys && (uintptr_t)insectSys >= 0x100000000ULL) {
                    void* liveList = p_get_LiveInsectList(insectSys);
                    if (liveList && (uintptr_t)liveList >= 0x100000000ULL) {
                        void* itemsArray = *(void**)((uintptr_t)liveList + 0x10);
                        int32_t size = *(int32_t*)((uintptr_t)liveList + 0x18);
                        if (itemsArray && size > 0 && size < 300) {
                            for (int32_t i = 0; i < size; i++) {
                                void* insectEntry = ((void**)((uintptr_t)itemsArray + 0x20))[i];
                                if (!insectEntry || (uintptr_t)insectEntry < 0x100000000ULL) continue;

                                void* control = *(void**)((uintptr_t)insectEntry + 0x20);
                                if (!control || (uintptr_t)control < 0x100000000ULL) continue;

                                if (p_Insect_get_DetectTargetPos) {
                                    GameTypes::Vector3 ipos = p_Insect_get_DetectTargetPos(control);
                                    float dx = ipos.x - myPos.x;
                                    float dy = ipos.y - myPos.y;
                                    float dz = ipos.z - myPos.z;
                                    float dist = sqrtf(dx*dx + dy*dy + dz*dz);
                                    if (dist < 150.0f) {
                                        newItems.push_back({ "Côn Trùng", ipos.x, ipos.y, ipos.z, IM_COL32(144, 238, 144, 220), dist, 0, 0, 3 });
                                    }
                                }
                            }
                        }
                    }
                }
            }

            s_cachedItems = std::move(newItems);
        } @catch (NSException *ex) {
            // Suppress
        }
    }

    // --------------------------------------------------------------------------
    // 3D-to-2D Viewport Transformation (Chuẩn Cate WorldToViewportPoint)
    // --------------------------------------------------------------------------
    static bool WorldToScreen(const GameTypes::Vector3& worldPos, ImVec2& screenPos) {
        if (!p_Camera_get_main) p_Camera_get_main = (Camera_get_main_t)Memory::GetRealOffset(Offsets::Engine::Camera_get_main);
        if (!p_Camera_WorldToViewportPoint) p_Camera_WorldToViewportPoint = (Camera_WorldToViewportPoint_t)Memory::GetRealOffset(Offsets::Engine::Camera_WorldToViewportPoint);

        if (!p_Camera_get_main || !p_Camera_WorldToViewportPoint) return false;
        void* mainCam = p_Camera_get_main();
        if (!mainCam) return false;

        GameTypes::Vector3 vp = p_Camera_WorldToViewportPoint(mainCam, worldPos);
        if (vp.z <= 0.05f) return false; // Target behind camera

        ImGuiIO& io = ImGui::GetIO();
        screenPos.x = vp.x * io.DisplaySize.x;
        screenPos.y = (1.0f - vp.y) * io.DisplaySize.y; // Viewport Y 0=bottom -> ImGui Y 0=top
        return true;
    }

    // --------------------------------------------------------------------------
    // ESP Rendering on ImGui Background DrawList
    // --------------------------------------------------------------------------
    void RenderESP() {
        if (!IsEnabled()) return;

        ImDrawList* drawList = ImGui::GetBackgroundDrawList();
        if (!drawList) return;

        ImGuiIO& io = ImGui::GetIO();
        ImVec2 screenCenterBottom(io.DisplaySize.x * 0.5f, io.DisplaySize.y);

        for (const auto& item : s_cachedItems) {
            GameTypes::Vector3 wpos = { item.x, item.y, item.z };
            ImVec2 scr;
            if (!WorldToScreen(wpos, scr)) continue;

            // 1. ESP Boss Rồng & Quái Vật (type == 0)
            if (item.type == 0 && g_config.espBossMonster) {
                if (g_config.espBossLine) {
                    drawList->AddLine(screenCenterBottom, scr, IM_COL32(255, 60, 60, 200), 1.5f);
                }
                if (g_config.espBossBox) {
                    drawList->AddCircle(scr, 22.0f, IM_COL32(255, 80, 80, 240), 24, 2.0f);
                }

                char label[128];
                snprintf(label, sizeof(label), "%s [%.1fm]", item.name.c_str(), item.distance);
                drawList->AddText(ImVec2(scr.x - 30, scr.y - 35), IM_COL32(255, 255, 255, 255), label);

                if (g_config.espBossHP && item.maxHp > 0) {
                    float barWidth = 60.0f;
                    float barHeight = 6.0f;
                    float hpPercent = (float)item.hp / (float)item.maxHp;
                    if (hpPercent > 1.0f) hpPercent = 1.0f;
                    if (hpPercent < 0.0f) hpPercent = 0.0f;

                    ImVec2 barPos(scr.x - barWidth * 0.5f, scr.y - 18);
                    drawList->AddRectFilled(barPos, ImVec2(barPos.x + barWidth, barPos.y + barHeight), IM_COL32(80, 0, 0, 220));
                    drawList->AddRectFilled(barPos, ImVec2(barPos.x + barWidth * hpPercent, barPos.y + barHeight), IM_COL32(50, 220, 50, 255));
                    drawList->AddRect(barPos, ImVec2(barPos.x + barWidth, barPos.y + barHeight), IM_COL32(0, 0, 0, 255));
                }
            }

            // 2. ESP Đá & Khoáng Sản (type == 2)
            else if (item.type == 2 && g_config.espRocks) {
                drawList->AddCircle(scr, 14.0f, IM_COL32(255, 215, 0, 220), 16, 2.0f);
                char label[64];
                snprintf(label, sizeof(label), "%s [%.1fm]", item.name.c_str(), item.distance);
                drawList->AddText(ImVec2(scr.x - 20, scr.y - 22), IM_COL32(255, 215, 0, 255), label);
            }

            // 3. ESP Côn Trùng & Bọ (type == 3)
            else if (item.type == 3 && g_config.espInsects) {
                drawList->AddCircle(scr, 12.0f, IM_COL32(144, 238, 144, 220), 16, 1.5f);
                char label[64];
                snprintf(label, sizeof(label), "%s [%.1fm]", item.name.c_str(), item.distance);
                drawList->AddText(ImVec2(scr.x - 20, scr.y - 20), IM_COL32(144, 238, 144, 255), label);
            }
        }
    }
}
