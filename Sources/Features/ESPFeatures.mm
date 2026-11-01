#import "ESPFeatures.h"
#import "Game/Offsets.h"
#import "Game/GameTypes.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"
#import "FishingFeatures.h"
#import "../Includes/IMGUI/imgui.h"
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

    struct UnityVector3 {
        float x, y, z;
    };

    typedef void* (*Camera_get_main_t)();
    static Camera_get_main_t p_Camera_get_main = nullptr;

    typedef UnityVector3 (*Camera_WorldToScreenPoint_t)(void* camera, UnityVector3 pos);
    static Camera_WorldToScreenPoint_t p_Camera_WorldToScreenPoint = nullptr;

    typedef UnityVector3 (*Transform_get_position_t)(void* transform);
    static Transform_get_position_t p_Transform_get_position = nullptr;

    // Cache of discovered ESP targets
    static std::vector<ESPItem> s_cachedItems;

    void EnsureHooksInstalled() {
        static bool s_installed = false;
        if (s_installed) return;
        s_installed = true;

        p_Camera_get_main = (Camera_get_main_t)Memory::GetRealOffset(Offsets::Engine::Camera_get_main);
        p_Camera_WorldToScreenPoint = (Camera_WorldToScreenPoint_t)Memory::GetRealOffset(Offsets::Engine::Camera_WorldToScreenPoint);
        p_Transform_get_position = (Transform_get_position_t)Memory::GetRealOffset(Offsets::Engine::Transform_get_position);

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
    // 3D-to-2D Viewport Transformation
    // --------------------------------------------------------------------------
    static bool WorldToScreen(const UnityVector3& worldPos, ImVec2& screenPos) {
        if (!p_Camera_get_main || !p_Camera_WorldToScreenPoint) return false;
        void* mainCam = p_Camera_get_main();
        if (!mainCam) return false;

        UnityVector3 scr = p_Camera_WorldToScreenPoint(mainCam, worldPos);
        if (scr.z <= 0.05f) return false; // Target behind camera

        ImGuiIO& io = ImGui::GetIO();
        screenPos.x = scr.x;
        screenPos.y = io.DisplaySize.y - scr.y; // Invert Unity Y to ImGui coordinate space
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

        // 1. ESP Boss Rồng & Quái Vật
        if (g_config.espBossMonster) {
            for (const auto& item : s_cachedItems) {
                if (item.type != 0) continue;

                UnityVector3 wpos = { item.x, item.y, item.z };
                ImVec2 scr;
                if (!WorldToScreen(wpos, scr)) continue;

                // Snap line
                if (g_config.espBossLine) {
                    drawList->AddLine(screenCenterBottom, scr, IM_COL32(255, 60, 60, 200), 1.5f);
                }

                // Bounding Box / Raycast Circle
                if (g_config.espBossBox) {
                    drawList->AddCircle(scr, 24.0f, IM_COL32(255, 80, 80, 240), 24, 2.0f);
                }

                // Name & Distance text
                char label[128];
                snprintf(label, sizeof(label), "%s [%.1fm]", item.name.c_str(), item.distance);
                drawList->AddText(ImVec2(scr.x - 30, scr.y - 35), IM_COL32(255, 255, 255, 255), label);

                // Health Bar (HP Bar)
                if (g_config.espBossHP && item.maxHp > 0) {
                    float barWidth = 60.0f;
                    float barHeight = 6.0f;
                    float hpPercent = (float)item.hp / (float)item.maxHp;
                    if (hpPercent > 1.0f) hpPercent = 1.0f;
                    if (hpPercent < 0.0f) hpPercent = 0.0f;

                    ImVec2 barPos(scr.x - barWidth * 0.5f, scr.y - 18);
                    // Background (dark red)
                    drawList->AddRectFilled(barPos, ImVec2(barPos.x + barWidth, barPos.y + barHeight), IM_COL32(80, 0, 0, 220));
                    // Active HP (green/lime)
                    drawList->AddRectFilled(barPos, ImVec2(barPos.x + barWidth * hpPercent, barPos.y + barHeight), IM_COL32(50, 220, 50, 255));
                    // Border
                    drawList->AddRect(barPos, ImVec2(barPos.x + barWidth, barPos.y + barHeight), IM_COL32(0, 0, 0, 255));
                }
            }
        }

        // 2. ESP Vùng Câu Cá (Fishing Zones)
        if (g_config.espFishingZone) {
            for (const auto& item : s_cachedItems) {
                if (item.type != 1) continue;

                UnityVector3 wpos = { item.x, item.y, item.z };
                ImVec2 scr;
                if (!WorldToScreen(wpos, scr)) continue;

                drawList->AddCircleFilled(scr, 6.0f, IM_COL32(66, 178, 250, 220));
                drawList->AddCircle(scr, 18.0f, IM_COL32(66, 178, 250, 180), 16, 1.5f);

                char label[64];
                snprintf(label, sizeof(label), "Vùng Câu #%s [%.1fm]", item.name.c_str(), item.distance);
                drawList->AddText(ImVec2(scr.x - 30, scr.y - 25), IM_COL32(66, 178, 250, 255), label);
            }
        }

        // 3. ESP Đá & Khoáng Sản
        if (g_config.espRocks) {
            for (const auto& item : s_cachedItems) {
                if (item.type != 2) continue;

                UnityVector3 wpos = { item.x, item.y, item.z };
                ImVec2 scr;
                if (!WorldToScreen(wpos, scr)) continue;

                drawList->AddCircle(scr, 14.0f, IM_COL32(255, 215, 0, 220), 16, 2.0f);
                char label[64];
                snprintf(label, sizeof(label), "Đá: %s [%.1fm]", item.name.c_str(), item.distance);
                drawList->AddText(ImVec2(scr.x - 20, scr.y - 22), IM_COL32(255, 215, 0, 255), label);
            }
        }

        // 4. ESP Côn Trùng & Bọ
        if (g_config.espInsects) {
            for (const auto& item : s_cachedItems) {
                if (item.type != 3) continue;

                UnityVector3 wpos = { item.x, item.y, item.z };
                ImVec2 scr;
                if (!WorldToScreen(wpos, scr)) continue;

                drawList->AddCircle(scr, 12.0f, IM_COL32(144, 238, 144, 220), 16, 1.5f);
                char label[64];
                snprintf(label, sizeof(label), "Bọ: %s [%.1fm]", item.name.c_str(), item.distance);
                drawList->AddText(ImVec2(scr.x - 20, scr.y - 20), IM_COL32(144, 238, 144, 255), label);
            }
        }

        // 5. ESP Khai Quật / Kho Báu
        if (g_config.espExcavation || g_config.espTreasure) {
            for (const auto& item : s_cachedItems) {
                if (item.type != 4) continue;

                UnityVector3 wpos = { item.x, item.y, item.z };
                ImVec2 scr;
                if (!WorldToScreen(wpos, scr)) continue;

                drawList->AddRect(ImVec2(scr.x - 12, scr.y - 12), ImVec2(scr.x + 12, scr.y + 12), IM_COL32(255, 165, 0, 240), 2.0f, 0, 1.5f);
                char label[64];
                snprintf(label, sizeof(label), "Kho Báu [%.1fm]", item.distance);
                drawList->AddText(ImVec2(scr.x - 25, scr.y - 24), IM_COL32(255, 165, 0, 255), label);
            }
        }

        // 6. ESP Vật Phẩm & Rác
        if (g_config.espAllItems || g_config.espEventItems) {
            for (const auto& item : s_cachedItems) {
                if (item.type != 5) continue;

                UnityVector3 wpos = { item.x, item.y, item.z };
                ImVec2 scr;
                if (!WorldToScreen(wpos, scr)) continue;

                drawList->AddCircleFilled(scr, 5.0f, IM_COL32(200, 200, 255, 220));
                char label[64];
                snprintf(label, sizeof(label), "%s [%.1fm]", item.name.c_str(), item.distance);
                drawList->AddText(ImVec2(scr.x - 20, scr.y - 18), IM_COL32(200, 200, 255, 255), label);
            }
        }

        // 7. ESP Zombie Virus
        if (g_config.espZombieVirus) {
            for (const auto& item : s_cachedItems) {
                if (item.type != 7) continue;

                UnityVector3 wpos = { item.x, item.y, item.z };
                ImVec2 scr;
                if (!WorldToScreen(wpos, scr)) continue;

                drawList->AddCircle(scr, 16.0f, IM_COL32(180, 50, 230, 240), 20, 2.0f);
                char label[64];
                snprintf(label, sizeof(label), "Zombie Virus [%.1fm]", item.distance);
                drawList->AddText(ImVec2(scr.x - 30, scr.y - 25), IM_COL32(200, 100, 255, 255), label);
            }
        }
    }
}
