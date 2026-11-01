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
    static Tab s_currentTab = Tab::FishingInsects;

    // Boss & Event state flags
    static bool s_bossAttack = false;
    static bool s_autoAim = false;
    static bool s_rapidFire = false;
    static bool s_noRecoil = false;
    static bool s_plinko = false;
    static bool s_plinkoAlwaysMax = false;

    // Minigame flags
    static bool s_glassBridge = false;
    static bool s_woodBridge = false;
    static bool s_autoHammer = false;

    // ESP state flags
    static bool s_espFishing = false;
    static bool s_espRocks = false;
    static bool s_espInsects = false;
    static bool s_espTreasure = false;
    static bool s_espAllItems = false;
    static bool s_espBoss = false;
    static bool s_espBossLine = false;
    static bool s_espBossHP = false;

    void Initialize() {
        ImGuiStyle& style = ImGui::GetStyle();
        style.WindowRounding = 8.0f;
        style.FrameRounding = 5.0f;
        style.GrabRounding = 5.0f;
        style.ItemSpacing = ImVec2(8, 6);
        style.FramePadding = ImVec2(8, 4);
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
    // TAB 0: CÂU CÁ & BỌ
    // --------------------------------------------------------------------------
    static void RenderTabFishingInsects() {
        auto& fcfg = FishingFeatures::GetConfig();
        auto& mcfg = MainFeatures::GetConfig();
        auto& icfg = InsectFeatures::GetConfig();

        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "TIỆN ÍCH CHUNG CÂU & BỌ");
        ImGui::Separator();
        ImGui::Checkbox("Auto Bảo Quản", &mcfg.autoPreserveFish);
        ImGui::SliderFloat("Delay Bảo Quản (s)", &mcfg.autoPreserveDelay, 0.1f, 1.0f, "%.2f s");
        ImGui::Checkbox("Tự Động Đóng Hộp Quà", &mcfg.autoCloseGift);
        ImGui::Checkbox("Tự Động Đóng Hộp Thẻ", &mcfg.autoCloseCardBox);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "CÂU CÁ (FISHING)");
        ImGui::Separator();
        ImGui::Checkbox("Auto Câu Cá", &fcfg.autoFishingEnabled);
        if (fcfg.autoFishingEnabled) {
            ImGui::Checkbox("Tự Động Quăng Cần", &fcfg.autoCastRod);
            ImGui::SliderFloat("Delay Quăng Lại (s)", &fcfg.castDelay, 0.5f, 3.0f, "%.2f s");
            ImGui::Checkbox("Tự Động Giật Cần", &fcfg.autoHitBite);
            ImGui::SliderFloat("Tốc Độ Phản Xạ Giật (s)", &fcfg.hitReactionDelay, 0.01f, 0.3f, "%.2f s");
            ImGui::Checkbox("Không Bán Cá Bóng 6, 7", &fcfg.keepFishShadow67);
            ImGui::Checkbox("Cá Cắn Nhanh (Fast Catch)", &fcfg.fastCatch);
        }

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "LỌC BÓNG CÁ");
        ImGui::Separator();
        ImGui::Checkbox("Lọc Bóng 1", &fcfg.filterShadow[1]); ImGui::SameLine();
        ImGui::Checkbox("Lọc Bóng 2", &fcfg.filterShadow[2]); ImGui::SameLine();
        ImGui::Checkbox("Lọc Bóng 3", &fcfg.filterShadow[3]);
        ImGui::Checkbox("Lọc Bóng 4", &fcfg.filterShadow[4]); ImGui::SameLine();
        ImGui::Checkbox("Lọc Bóng 5", &fcfg.filterShadow[5]); ImGui::SameLine();
        ImGui::Checkbox("Lọc Bóng 6", &fcfg.filterShadow[6]);
        ImGui::Checkbox("Lọc Bóng 7", &fcfg.filterShadow[7]);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "BẮT BỌ & CÔN TRÙNG (INSECTS)");
        ImGui::Separator();
        ImGui::Checkbox("Tự Bắt Bọ", &icfg.autoCatchInsect);
        ImGui::Checkbox("Gom Côn Trùng", &icfg.gatherInsects);
        ImGui::Checkbox("Đóng Băng Côn Trùng", &icfg.freezeInsects);
        ImGui::Checkbox("Côn Trùng Không Sợ", &icfg.insectNoScared);
    }

    // --------------------------------------------------------------------------
    // TAB 1: KHAI KHOÁNG
    // --------------------------------------------------------------------------
    static void RenderTabMiningFarm() {
        auto& mcfg = MiningFeatures::GetConfig();
        auto& fcfg = FarmFeatures::GetConfig();

        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "ĐẬP ĐÁ & KHAI KHOÁNG");
        ImGui::Separator();
        ImGui::Checkbox("Auto Đập Đá", &mcfg.autoMineRocks);
        ImGui::Checkbox("Auto Đổi Map Đập Đá", &mcfg.autoChangeMapMine);
        ImGui::Checkbox("Auto Nhặt Vật Phẩm", &mcfg.autoPickupItems);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "CỔ VẬT / KHAI QUẬT (EXCAVATION)");
        ImGui::Separator();
        ImGui::Checkbox("Auto Khai Quật (Đào Từ Xa)", &mcfg.autoExcavate);
        ImGui::SliderFloat("Delay Đào (s)", &mcfg.excavateDelay, 0.1f, 1.0f, "%.2f s");

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "NÔNG TRẠI (FARM)");
        ImGui::Separator();
        ImGui::Checkbox("Tự Động Mua Hạt Giống", &fcfg.autoBuySeeds);
        ImGui::Checkbox("Tự Động Mua Công Cụ", &fcfg.autoBuyTools);
        ImGui::Checkbox("Tự Động Thu & Bán", &fcfg.autoHarvest);
        ImGui::Checkbox("Giữ Biến Thể", &fcfg.keepVariants);
    }

    // --------------------------------------------------------------------------
    // TAB 2: SỰ KIỆN & BOSS
    // --------------------------------------------------------------------------
    static void RenderTabBossCombat() {
        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "BOSS RỒNG & CHIẾN ĐẤU (COMBAT VIP)");
        ImGui::Separator();
        ImGui::Checkbox("Tự Động Tấn Công Boss Rồng", &s_bossAttack);
        ImGui::Checkbox("Tự Động Bắn Quái & Khóa Mục Tiêu", &s_autoAim);
        ImGui::Checkbox("Bắn Liên Thanh Siêu Tốc (Rapid Fire)", &s_rapidFire);
        ImGui::Checkbox("Không Giật Súng (No Recoil)", &s_noRecoil);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "SỰ KIỆN MINIGAME & THẢ XU");
        ImGui::Separator();
        ImGui::Checkbox("Sự Kiện Thả Xu Plinko", &s_plinko);
        ImGui::Checkbox("Luôn Luôn Trúng Ô To Nhất", &s_plinkoAlwaysMax);
    }

    // --------------------------------------------------------------------------
    // TAB 3: MINIGAME
    // --------------------------------------------------------------------------
    static void RenderTabMinigame() {
        auto& pcfg = PlayerFeatures::GetConfig();

        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "PLAYER MODIFIERS (DI CHUYỂN)");
        ImGui::Separator();
        ImGui::Checkbox("Chạy Nhanh (SpeedHack)", &pcfg.speedHack);
        if (pcfg.speedHack) {
            ImGui::SliderFloat("Tốc Độ Chạy", &pcfg.speedMultiplier, 1.0f, 10.0f, "%.1fx");
        }
        ImGui::Checkbox("Nhảy Cao", &pcfg.highJump);
        ImGui::Checkbox("Đi Trên Không", &pcfg.walkOnAir);
        ImGui::Checkbox("NoClip (Xuyên Vật Thể)", &pcfg.noClip);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "MINIGAME & THÁP");
        ImGui::Separator();
        ImGui::Checkbox("Auto Về Đích Tất Cả Map", &pcfg.autoMinigameGoal);
        ImGui::Checkbox("Tự Dò Cầu Kính", &s_glassBridge);
        ImGui::Checkbox("Tự Dò Ván Gỗ", &s_woodBridge);
        ImGui::Checkbox("Auto School", &pcfg.autoSchool);
        ImGui::Checkbox("Auto Đập Búa", &s_autoHammer);
    }

    // --------------------------------------------------------------------------
    // TAB 4: HIỂN THỊ ESP
    // --------------------------------------------------------------------------
    static void RenderTabESP() {
        auto& espCfg = ESPFeatures::GetConfig();

        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "ESP SỰ KIỆN BOSS RỒNG & QUÁI");
        ImGui::Separator();
        ImGui::Checkbox("Bật Tổng ESP Boss / Quái", &espCfg.espBossMonster);
        ImGui::Checkbox("Line Chỉ Đường Boss / Quái", &espCfg.espBossLine);
        ImGui::Checkbox("Vòng Tròn Chân Raycast / Box", &espCfg.espBossBox);
        ImGui::Checkbox("Tên Quái & Thanh Máu (HP Bar)", &espCfg.espBossHP);
        ImGui::Checkbox("ESP Boss Rồng Đặc Biệt", &espCfg.espSpecialDragon);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "ESP THU THẬP & THẾ GIỚI");
        ImGui::Separator();
        ImGui::Checkbox("ESP Vùng Câu Cá", &espCfg.espFishingZone);
        ImGui::Checkbox("Hiện Nút Tele Vùng Câu", &espCfg.showTeleFishingZone);
        ImGui::Checkbox("ESP Đá", &espCfg.espRocks);
        ImGui::Checkbox("ESP Côn Trùng", &espCfg.espInsects);
        ImGui::Checkbox("ESP Khai Quật", &espCfg.espExcavation);
        ImGui::Checkbox("ESP Kho Báu", &espCfg.espTreasure);
        ImGui::Checkbox("ESP Tất Cả Vật Phẩm", &espCfg.espAllItems);
        ImGui::Checkbox("Hiện Nút Tele Tất Cả Vật Phẩm", &espCfg.showTeleAllItems);
        ImGui::Checkbox("ESP Vật Phẩm Sự Kiện", &espCfg.espEventItems);
        ImGui::Checkbox("Hiện Nút Tele Sự Kiện", &espCfg.showTeleEventItems);
        ImGui::Checkbox("ESP Nhiệm Vụ NPC", &espCfg.espNPCQuest);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "ESP MINIGAME & KHÁC");
        ImGui::Separator();
        ImGui::Checkbox("ESP Zombie Virus", &espCfg.espZombieVirus);
        ImGui::Checkbox("Hiện Nút Tele Zombie Virus", &espCfg.showTeleZombieVirus);
        ImGui::Checkbox("ESP Auto Move / Path", &espCfg.espAutoPath);
    }

    // --------------------------------------------------------------------------
    // TAB 5: TIỆN ÍCH
    // --------------------------------------------------------------------------
    static void RenderTabUtilities() {
        auto& ucfg = UtilityFeatures::GetConfig();

        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "BỎ QUA QUẢNG CÁO (SKIP ADS)");
        ImGui::Separator();
        ImGui::Checkbox("Skip Ads 0s (AppLovin SDK)", &ucfg.skipAds);
        ImGui::Checkbox("Skip Ads Bằng Proxy Callback", &ucfg.skipAdsProxy);
        ImGui::Checkbox("Chặn Kết Nối Quảng Cáo HTTP", &ucfg.blockHttpAds);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "TIỆN ÍCH HỆ THỐNG");
        ImGui::Separator();
        ImGui::Checkbox("Stream Mode (Ẩn Menu Khi Quay/Chụp)", &ucfg.streamMode);
        ImGui::Checkbox("Nhân Vật Không Ngủ", &ucfg.noSleep);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "DỊCH CHUYỂN BẢN ĐỒ");
        ImGui::Separator();

        const auto& locations = MapFeatures::GetLocations();
        for (size_t i = 0; i < locations.size(); i++) {
            const auto& loc = locations[i];
            if (ImGui::Button(loc.nameVi, ImVec2(180, 26))) {
                MapFeatures::TeleportToLocation(loc);
            }
            if ((i % 2 == 0) && (i + 1 < locations.size())) {
                ImGui::SameLine();
            }
        }
    }

    // --------------------------------------------------------------------------
    // Main UI Render Function
    // --------------------------------------------------------------------------
    void Render(bool* p_open) {
        if (p_open && !*p_open) return;
        if (!s_isOpen) return;

        ImGui::SetNextWindowSize(ImVec2(620, 420), ImGuiCond_FirstUseEver);
        if (!ImGui::Begin("CATE  /  PLAY TOGETHER###Play Together VNG", p_open ? p_open : &s_isOpen,
                          ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize)) {
            ImGui::End();
            return;
        }

        // Left Navigation Bar (##category)
        ImGui::BeginChild("##category", ImVec2(150, 0), true);

        auto RenderTabButton = [](const char* label, Tab tab) {
            bool selected = (s_currentTab == tab);
            if (selected) {
                ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.26f, 0.70f, 0.98f, 1.0f));
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 1.0f, 1.0f, 1.0f));
            } else {
                ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.14f, 0.16f, 0.22f, 1.0f));
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.75f, 0.75f, 0.75f, 1.0f));
            }

            if (ImGui::Button(label, ImVec2(-1, 38))) {
                s_currentTab = tab;
            }

            ImGui::PopStyleColor(2);
        };

        RenderTabButton("CÂU CÁ & BỌ", Tab::FishingInsects);
        RenderTabButton("KHAI KHOÁNG", Tab::MiningFarm);
        RenderTabButton("SỰ KIỆN & BOSS", Tab::BossCombat);
        RenderTabButton("MINIGAME", Tab::Minigame);
        RenderTabButton("HIỂN THỊ ESP", Tab::ESP);
        RenderTabButton("TIỆN ÍCH", Tab::Utilities);

        ImGui::EndChild();

        ImGui::SameLine();

        // Right Content Area (##MainContentPanel)
        ImGui::BeginChild("##MainContentPanel", ImVec2(0, 0), true);

        switch (s_currentTab) {
            case Tab::FishingInsects: RenderTabFishingInsects(); break;
            case Tab::MiningFarm:      RenderTabMiningFarm(); break;
            case Tab::BossCombat:      RenderTabBossCombat(); break;
            case Tab::Minigame:        RenderTabMinigame(); break;
            case Tab::ESP:             RenderTabESP(); break;
            case Tab::Utilities:       RenderTabUtilities(); break;
        }

        ImGui::EndChild();
        ImGui::End();
    }
}
