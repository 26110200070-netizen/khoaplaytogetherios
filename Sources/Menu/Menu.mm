#import "Menu.h"
#import "../Includes/IMGUI/imgui.h"
#import "Features/FishingFeatures.h"
#import "Features/MainFeatures.h"
#import "Features/MiningFeatures.h"
#import "Features/InsectFeatures.h"
#import "Features/FarmFeatures.h"
#import "Features/PlayerFeatures.h"
#import "Features/UtilityFeatures.h"
#import "Features/MapFeatures.h"
#import "Features/ESPFeatures.h"
#import <UIKit/UIKit.h>

namespace Menu {

    static bool s_isOpen = true;
    static Tab s_currentTab = Tab::Main;

    // Boss & Event state flags
    static bool s_bossAttack = false;
    static bool s_noRecoil = false;
    static float s_bossDistance = 15.0f;
    static bool s_plinko = false;

    // Minigame flags
    static bool s_glassBridge = false;
    static bool s_autoHammer = false;

    // Stone tele filters
    static bool s_teleAllStones = false;
    static bool s_teleSmallStones = false;
    static bool s_teleMediumStones = false;
    static bool s_teleLargeStones = false;
    static bool s_autoBuyShovel = false;

    void Initialize() {
        ImGuiStyle& style = ImGui::GetStyle();
        style.WindowRounding = 8.0f;
        style.FrameRounding = 5.0f;
        style.GrabRounding = 5.0f;
        style.ItemSpacing = ImVec2(8, 6);
        style.FramePadding = ImVec2(8, 5);
        style.WindowPadding = ImVec2(10, 10);

        ImVec4* colors = style.Colors;
        colors[ImGuiCol_WindowBg]             = ImVec4(0.08f, 0.09f, 0.12f, 0.96f);
        colors[ImGuiCol_Border]               = ImVec4(0.20f, 0.25f, 0.35f, 0.60f);
        colors[ImGuiCol_FrameBg]              = ImVec4(0.14f, 0.16f, 0.22f, 1.00f);
        colors[ImGuiCol_FrameBgHovered]       = ImVec4(0.20f, 0.24f, 0.32f, 1.00f);
        colors[ImGuiCol_FrameBgActive]        = ImVec4(0.26f, 0.32f, 0.44f, 1.00f);
        colors[ImGuiCol_TitleBg]              = ImVec4(0.10f, 0.12f, 0.16f, 1.00f);
        colors[ImGuiCol_TitleBgActive]        = ImVec4(0.14f, 0.18f, 0.24f, 1.00f);
        colors[ImGuiCol_CheckMark]            = ImVec4(0.26f, 0.70f, 0.98f, 1.00f);
        colors[ImGuiCol_SliderGrab]           = ImVec4(0.26f, 0.70f, 0.98f, 1.00f);
        colors[ImGuiCol_SliderGrabActive]     = ImVec4(0.40f, 0.80f, 1.00f, 1.00f);
        colors[ImGuiCol_Button]               = ImVec4(0.16f, 0.20f, 0.28f, 1.00f);
        colors[ImGuiCol_ButtonHovered]        = ImVec4(0.26f, 0.70f, 0.98f, 0.80f);
        colors[ImGuiCol_ButtonActive]         = ImVec4(0.20f, 0.60f, 0.90f, 1.00f);
        colors[ImGuiCol_Header]               = ImVec4(0.26f, 0.70f, 0.98f, 0.30f);
        colors[ImGuiCol_HeaderHovered]        = ImVec4(0.26f, 0.70f, 0.98f, 0.60f);
        colors[ImGuiCol_HeaderActive]         = ImVec4(0.26f, 0.70f, 0.98f, 0.80f);
    }

    bool IsOpen() { return s_isOpen; }
    void SetOpen(bool open) { s_isOpen = open; }
    void ToggleOpen() { s_isOpen = !s_isOpen; }

    // --------------------------------------------------------------------------
    // TAB 1: MAIN (HỆ THỐNG & BẢO QUẢN)
    // --------------------------------------------------------------------------
    static void RenderTabMain() {
        auto& mcfg = MainFeatures::GetConfig();
        auto mstats = MainFeatures::GetStats();

        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "CHỨC NĂNG HỆ THỐNG & TỰ ĐỘNG");
        ImGui::Separator();

        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[1] Tự Động Bảo Quản (Auto Keep Fish):");
        ImGui::Checkbox("Bật Auto Bảo Quản", &mcfg.autoPreserveFish);
        ImGui::SliderFloat("Delay Bảo Quản (s)", &mcfg.autoPreserveDelay, 0.1f, 1.0f, "%.2f s");
        ImGui::TextColored(ImVec4(0.20f, 0.90f, 0.30f, 1.0f), "Đã bảo quản: %u con", mstats.fishPreservedCount);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[2] Tự Động Đóng Giao Diện:");
        ImGui::Checkbox("Tự Động Đóng Hộp Quà", &mcfg.autoCloseGift);
        ImGui::Checkbox("Tự Động Đóng Hộp Thẻ", &mcfg.autoCloseCardBox);
        ImGui::SliderFloat("Delay Đóng Giao Diện (s)", &mcfg.autoCloseDelay, 0.1f, 1.0f, "%.2f s");
    }

    // --------------------------------------------------------------------------
    // TAB 2: CÂU CÁ (FISHING - TÍCH HỢP BÓNG THƯỜNG & KHỔNG LỒ)
    // --------------------------------------------------------------------------
    static void RenderTabFishing() {
        auto& fcfg = FishingFeatures::GetConfig();
        auto fstatus = FishingFeatures::GetStatus();
        auto& icfg = InsectFeatures::GetConfig();

        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "CÂU CÁ & BẮT BỌ");
        ImGui::Separator();

        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[1] Auto Câu Cá:");
        ImGui::Checkbox("Bật Auto Câu Cá", &fcfg.autoFishingEnabled);
        ImGui::SameLine();
        ImGui::TextColored(ImVec4(0.20f, 0.90f, 0.30f, 1.0f), "Trạng thái: %s", fstatus.lastStateName.c_str());
        ImGui::TextColored(ImVec4(0.20f, 0.90f, 0.30f, 1.0f), "Đã câu: %u con | Khổng lồ: %u", fstatus.totalFishCaught, fstatus.bigFishCompleted);

        if (ImGui::Button("Thử Quăng Cần", ImVec2(130, 28))) {
            FishingFeatures::TriggerCast();
        }
        ImGui::SameLine();
        if (ImGui::Button("Thử Giật Cần", ImVec2(130, 28))) {
            FishingFeatures::TriggerReel();
        }

        if (fcfg.autoFishingEnabled) {
            ImGui::Checkbox("Tự Động Quăng Cần", &fcfg.autoCastRod);
            ImGui::SliderFloat("Delay Quăng Lại (s)", &fcfg.castDelay, 0.5f, 3.0f, "%.2f s");
            ImGui::Checkbox("Tự Động Giật Cần", &fcfg.autoHitBite);
            ImGui::SliderFloat("Tốc Độ Phản Xạ Giật (s)", &fcfg.hitReactionDelay, 0.01f, 0.3f, "%.2f s");
            ImGui::Checkbox("Không Bán Cá Bóng 6, 7", &fcfg.keepFishShadow67);
            ImGui::Checkbox("Cá Cắn Nhanh (Fast Catch)", &fcfg.fastCatch);
        }

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[2] Lọc Bóng Cá:");
        ImGui::Checkbox("Lọc Bóng 1", &fcfg.filterShadow[1]); ImGui::SameLine();
        ImGui::Checkbox("Lọc Bóng 2", &fcfg.filterShadow[2]); ImGui::SameLine();
        ImGui::Checkbox("Lọc Bóng 3", &fcfg.filterShadow[3]);
        ImGui::Checkbox("Lọc Bóng 4", &fcfg.filterShadow[4]); ImGui::SameLine();
        ImGui::Checkbox("Lọc Bóng 5", &fcfg.filterShadow[5]); ImGui::SameLine();
        ImGui::Checkbox("Lọc Bóng 6", &fcfg.filterShadow[6]);
        ImGui::Checkbox("Lọc Bóng 7", &fcfg.filterShadow[7]);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[3] Bắt Bọ & Côn Trùng:");
        ImGui::Checkbox("Tự Bắt Bọ", &icfg.autoCatchInsect);
        ImGui::Checkbox("Gom Côn Trùng", &icfg.gatherInsects);
        ImGui::Checkbox("Đóng Băng Côn Trùng", &icfg.freezeInsects);
        ImGui::Checkbox("Côn Trùng Không Sợ", &icfg.insectNoScared);
    }

    // --------------------------------------------------------------------------
    // TAB 3: KHAI KHOÁNG & NÔNG TRẠI
    // --------------------------------------------------------------------------
    static void RenderTabMiningFarm() {
        auto& mcfg = MiningFeatures::GetConfig();
        auto& fcfg = FarmFeatures::GetConfig();

        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "KHAI KHOÁNG, KHAI QUẬT & NÔNG TRẠI");
        ImGui::Separator();

        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[1] Đập Đá & Khai Khoáng:");
        ImGui::Checkbox("Auto Đập Đá", &mcfg.autoMineRocks);
        ImGui::Checkbox("Auto Đổi Map Đập Đá", &mcfg.autoChangeMapMine);
        ImGui::Checkbox("Auto Nhặt Vật Phẩm", &mcfg.autoPickupItems);
        ImGui::Checkbox("Tele Tất Cả Đá", &s_teleAllStones);
        ImGui::Checkbox("Tele Đá Nhỏ", &s_teleSmallStones); ImGui::SameLine();
        ImGui::Checkbox("Tele Đá Vừa", &s_teleMediumStones); ImGui::SameLine();
        ImGui::Checkbox("Tele Đá To", &s_teleLargeStones);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[2] Khai Quật:");
        ImGui::Checkbox("Auto Khai Quật", &mcfg.autoExcavate);
        ImGui::Checkbox("Auto Mua Dụng Cụ Đào", &s_autoBuyShovel);
        ImGui::SliderFloat("Delay Đào (s)", &mcfg.excavateDelay, 0.1f, 1.0f, "%.2f s");

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[3] Nông Trại:");
        ImGui::Checkbox("Tự Động Thu & Bán", &fcfg.autoHarvest);
        ImGui::Checkbox("Tự Thu & Bán (VIP)", &fcfg.autoHarvestSellVIP);
        ImGui::Checkbox("Giữ Biến Thể", &fcfg.keepVariants);
    }

    // --------------------------------------------------------------------------
    // TAB 4: SỰ KIỆN & BOSS
    // --------------------------------------------------------------------------
    static void RenderTabBossCombat() {
        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "SỰ KIỆN & BOSS RỒNG");
        ImGui::Separator();

        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[1] Boss Rồng & Chiến Đấu:");
        ImGui::Checkbox("Tự Động Tấn Công Boss Rồng", &s_bossAttack);
        ImGui::Checkbox("Không Giật Súng (No Recoil)", &s_noRecoil);
        ImGui::SliderFloat("Khoảng Cách Trên Đầu Boss (m)", &s_bossDistance, 5.0f, 30.0f, "%.1f m");

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[2] Sự Kiện Minigame:");
        ImGui::Checkbox("Sự Kiện Thả Xu Plinko", &s_plinko);
    }

    // --------------------------------------------------------------------------
    // TAB 5: MINIGAME & DI CHUYỂN
    // --------------------------------------------------------------------------
    static void RenderTabMinigame() {
        auto& pcfg = PlayerFeatures::GetConfig();

        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "MINIGAME & DI CHUYỂN NHÂN VẬT");
        ImGui::Separator();

        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[1] Minigame Party & Về Đích:");
        ImGui::Checkbox("Auto Về Đích", &pcfg.autoMinigameGoal);
        ImGui::Checkbox("Auto Đập Búa", &s_autoHammer);
        ImGui::Checkbox("Cầu Kính An Toàn", &s_glassBridge);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[2] Di Chuyển Nhân Vật:");
        ImGui::Checkbox("Bật Hack Tốc Độ", &pcfg.speedHack);
        ImGui::SliderFloat("Tốc Độ Chạy", &pcfg.speedMultiplier, 1.0f, 10.0f, "%.1fx");
        ImGui::Checkbox("Nhảy Cao", &pcfg.highJump);
        ImGui::Checkbox("Đi Trên Không", &pcfg.walkOnAir);
        ImGui::Checkbox("NoClip (Xuyên Vật Thể)", &pcfg.noClip);
    }

    // --------------------------------------------------------------------------
    // TAB 6: HIỂN THỊ ESP
    // --------------------------------------------------------------------------
    static void RenderTabESP() {
        auto& ecfg = ESPFeatures::GetConfig();

        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "HỆ THỐNG HIỂN THỊ ESP");
        ImGui::Separator();

        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[1] ESP Sự Kiện Boss Rồng & Quái:");
        ImGui::Checkbox("Bật Tổng ESP Boss / Quái", &ecfg.espBossMonster);
        ImGui::Checkbox("Line Chỉ Đường", &ecfg.espBossLine);
        ImGui::Checkbox("Vòng Tròn Chân / Box", &ecfg.espBossBox);
        ImGui::Checkbox("ESP Tên & Máu (HP Bar)", &ecfg.espBossHP);
        ImGui::Checkbox("ESP Boss Rồng Đặc Biệt", &ecfg.espSpecialDragon);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[2] ESP Thu Thập & Thế Giới:");
        ImGui::Checkbox("ESP Vùng Câu Cá", &ecfg.espFishingZone);
        ImGui::Checkbox("Hiện Nút Tele Vùng Câu", &ecfg.showTeleFishingZone);
        ImGui::Checkbox("ESP Đá", &ecfg.espRocks);
        ImGui::Checkbox("ESP Côn Trùng", &ecfg.espInsects);
        ImGui::Checkbox("ESP Khai Quật", &ecfg.espExcavation);
        ImGui::Checkbox("ESP Kho Báu", &ecfg.espTreasure);
        ImGui::Checkbox("ESP Tất Cả Vật Phẩm", &ecfg.espAllItems);
        ImGui::Checkbox("ESP Zombie Virus", &ecfg.espZombieVirus);
    }

    // --------------------------------------------------------------------------
    // TAB 7: DỊCH CHUYỂN BẢN ĐỒ
    // --------------------------------------------------------------------------
    static void RenderTabMap() {
        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "DỊCH CHUYỂN TỨC THỜI BẢN ĐỒ");
        ImGui::Separator();

        const auto& locations = MapFeatures::GetLocations();
        for (size_t i = 0; i < locations.size(); i++) {
            const auto& loc = locations[i];
            if (ImGui::Button(loc.nameVi, ImVec2(180, 28))) {
                MapFeatures::TeleportToLocation(loc);
            }
            if ((i % 2 == 0) && (i + 1 < locations.size())) {
                ImGui::SameLine();
            }
        }
    }

    // --------------------------------------------------------------------------
    // TAB 8: TIỆN ÍCH & DEBUG
    // --------------------------------------------------------------------------
    static void RenderTabDebug() {
        auto& ucfg = UtilityFeatures::GetConfig();

        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "TIỆN ÍCH HỆ THỐNG & DEBUG");
        ImGui::Separator();

        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[1] Tiện Ích:");
        ImGui::Checkbox("Bỏ Qua Video Ads 0s (Skip Ads SDK)", &ucfg.skipAds);
        ImGui::Checkbox("Bỏ Qua Ads Bằng Proxy", &ucfg.skipAdsProxy);
        ImGui::Checkbox("Chặn Kết Nối Ads HTTP", &ucfg.blockHttpAds);
        ImGui::Checkbox("Stream Mode (Ẩn Menu Khi Quay Màn Hình)", &ucfg.streamMode);
        ImGui::Checkbox("Giữ Sáng Màn Hình (No Sleep)", &ucfg.noSleep);
        ImGui::Checkbox("Auto Spam Chat", &ucfg.autoSpamChat);
    }

    // --------------------------------------------------------------------------
    // Main UI Render Function
    // --------------------------------------------------------------------------
    void Render(bool* p_open) {
        if (p_open && !*p_open) return;
        if (!s_isOpen) return;

        ImGui::SetNextWindowSize(ImVec2(620, 420), ImGuiCond_FirstUseEver);
        if (!ImGui::Begin("KHOA PLAYTOGETHER - IMGUI iOS [Non-Jailbreak]###Play Together VNG", p_open ? p_open : &s_isOpen,
                          ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize)) {
            ImGui::End();
            return;
        }

        // Left Navigation Bar (##category) - Kéo lên xuống bằng tay mượt mà
        ImGui::BeginChild("##category", ImVec2(145, 0), true, ImGuiWindowFlags_AlwaysVerticalScrollbar);

        auto RenderTabButton = [](const char* label, Tab tab) {
            bool selected = (s_currentTab == tab);
            if (selected) {
                ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.26f, 0.70f, 0.98f, 1.0f));
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 1.0f, 1.0f, 1.0f));
            } else {
                ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.14f, 0.16f, 0.22f, 1.0f));
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.75f, 0.75f, 0.75f, 1.0f));
            }

            if (ImGui::Button(label, ImVec2(-1, 36))) {
                s_currentTab = tab;
            }

            ImGui::PopStyleColor(2);
        };

        RenderTabButton("Main", Tab::Main);
        RenderTabButton("Câu Cá", Tab::Fishing);
        RenderTabButton("Khai Khoáng", Tab::MiningFarm);
        RenderTabButton("Sự Kiện & Boss", Tab::BossCombat);
        RenderTabButton("Minigame", Tab::Minigame);
        RenderTabButton("ESP", Tab::ESP);
        RenderTabButton("Bản Đồ", Tab::Map);
        RenderTabButton("Debug", Tab::Debug);

        ImGui::EndChild();

        ImGui::SameLine();

        // Right Content Area (##MainContentPanel) - Kéo cuộn cảm ứng tự do
        ImGui::BeginChild("##MainContentPanel", ImVec2(0, 0), true, ImGuiWindowFlags_AlwaysVerticalScrollbar);

        switch (s_currentTab) {
            case Tab::Main:       RenderTabMain(); break;
            case Tab::Fishing:    RenderTabFishing(); break;
            case Tab::MiningFarm: RenderTabMiningFarm(); break;
            case Tab::BossCombat: RenderTabBossCombat(); break;
            case Tab::Minigame:   RenderTabMinigame(); break;
            case Tab::ESP:        RenderTabESP(); break;
            case Tab::Map:        RenderTabMap(); break;
            case Tab::Debug:      RenderTabDebug(); break;
        }

        ImGui::EndChild();
        ImGui::End();
    }
}
