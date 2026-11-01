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

    void Initialize() {
        ImGuiStyle& style = ImGui::GetStyle();
        style.WindowRounding = 8.0f;
        style.FrameRounding = 5.0f;
        style.GrabRounding = 5.0f;
        style.ItemSpacing = ImVec2(7, 5);
        style.FramePadding = ImVec2(7, 4);
        style.WindowPadding = ImVec2(8, 8);

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
    // TAB 1: MAIN (HỆ THỐNG, SỬA CÔNG CỤ, MỞ QUÀ & TELE HƯỚNG DẪN)
    // --------------------------------------------------------------------------
    static void RenderTabMain() {
        auto& mcfg = MainFeatures::GetConfig();
        auto mstats = MainFeatures::GetStats();

        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "TRANG CHỦ - HỆ THỐNG & TỰ ĐỘNG");
        ImGui::Separator();

        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[1] Tự Động Bảo Quản & Bấm OK:");
        ImGui::Checkbox("Bật Auto Bảo Quản Cá", &mcfg.autoPreserveFish);
        ImGui::Checkbox("Tự Động Bấm OK Khi Nhận Thưởng", &mcfg.autoClickOK);
        ImGui::SliderFloat("Delay Bảo Quản (s)", &mcfg.autoPreserveDelay, 0.1f, 1.0f, "%.2f s");
        ImGui::TextColored(ImVec4(0.20f, 0.90f, 0.30f, 1.0f), "Đã bảo quản: %u con", mstats.fishPreservedCount);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[2] Sửa Công Cụ (Auto Repair Tool):");
        ImGui::Checkbox("Tự Động Sửa Công Cụ (Cần câu, cuốc đá, vợt bọ)", &mcfg.autoRepairTools);
        if (ImGui::Button("Sửa Công Cụ Ngay", ImVec2(180, 26))) {
            MainFeatures::TriggerRepairNow();
        }
        ImGui::SameLine();
        ImGui::TextColored(ImVec4(0.20f, 0.90f, 0.30f, 1.0f), "Đã sửa: %u lần", mstats.toolsRepairedCount);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[3] Quà Thư & Hộp Quà:");
        ImGui::Checkbox("Tự Động Nhận Quà Thư & Tự Đóng (MailBox)", &mcfg.autoOpenMailGift);
        if (ImGui::Button("Nhận Hết Quà Thư Ngay", ImVec2(180, 26))) {
            MainFeatures::TriggerReceiveAllMailNow();
        }
        ImGui::SameLine();
        ImGui::TextColored(ImVec4(0.20f, 0.90f, 0.30f, 1.0f), "Đã nhận: %u lần", mstats.mailGiftsReceivedCount);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[4] Tự Động Đóng Giao Diện:");
        ImGui::Checkbox("Tự Động Đóng Hộp Quà (DialogRewardPopup)", &mcfg.autoCloseGift);
        ImGui::Checkbox("Tự Động Đóng Hộp Thẻ (DialogResultGetItemView)", &mcfg.autoCloseCardBox);
        ImGui::SliderFloat("Delay Đóng (s)", &mcfg.autoCloseDelay, 0.1f, 1.0f, "%.2f s");

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[5] Tele Hướng Dẫn:");
        ImGui::Checkbox("Auto Tele Hướng Dẫn (Mũi Tên Chỉ Đường)", &mcfg.teleGuideArrow);
        if (ImGui::Button("Tele Ngay Tới Hướng Dẫn", ImVec2(200, 26))) {
            MainFeatures::TriggerTeleGuide();
        }
    }

    // --------------------------------------------------------------------------
    // TAB 2: CÂU CÁ (FISHING) - TÍCH HỢP LỌC BÓNG & LỌC ID
    // --------------------------------------------------------------------------
    static void RenderTabFishing() {
        auto& fcfg = FishingFeatures::GetConfig();
        auto fstatus = FishingFeatures::GetStatus();

        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "TỰ ĐỘNG CÂU CÁ & LỌC CÁ");
        ImGui::Separator();

        ImGui::Checkbox("Bật Auto Câu Cá", &fcfg.autoFishingEnabled);
        ImGui::SameLine();
        ImGui::TextColored(ImVec4(0.20f, 0.90f, 0.30f, 1.0f), "Trạng thái: %s", fstatus.lastStateName.c_str());
        ImGui::TextColored(ImVec4(0.20f, 0.90f, 0.30f, 1.0f), "Đã câu: %u | Khổng lồ: %u", fstatus.totalFishCaught, fstatus.bigFishCompleted);

        if (ImGui::Button("Thử Quăng Cần", ImVec2(120, 26))) {
            FishingFeatures::TriggerCast();
        }
        ImGui::SameLine();
        if (ImGui::Button("Thử Giật Cần", ImVec2(120, 26))) {
            FishingFeatures::TriggerReel();
        }

        if (fcfg.autoFishingEnabled) {
            ImGui::Checkbox("Tự Động Quăng Cần", &fcfg.autoCastRod);
            ImGui::SliderFloat("Delay Quăng (s)", &fcfg.castDelay, 0.5f, 3.0f, "%.2f s");
            ImGui::Checkbox("Tự Động Giật Cần", &fcfg.autoHitBite);
            ImGui::SliderFloat("Tốc Độ Giật (s)", &fcfg.hitReactionDelay, 0.01f, 0.3f, "%.2f s");
            ImGui::Checkbox("Không Bán Cá Bóng 6, 7", &fcfg.keepFishShadow67);
            ImGui::Checkbox("Cá Cắn Nhanh (Fast Catch)", &fcfg.fastCatch);
        }

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[1] Lọc Nhanh Theo Bóng Cá:");
        ImGui::Checkbox("Bóng 1", &fcfg.filterShadow[1]); ImGui::SameLine();
        ImGui::Checkbox("Bóng 2", &fcfg.filterShadow[2]); ImGui::SameLine();
        ImGui::Checkbox("Bóng 3", &fcfg.filterShadow[3]);
        ImGui::Checkbox("Bóng 4", &fcfg.filterShadow[4]); ImGui::SameLine();
        ImGui::Checkbox("Bóng 5", &fcfg.filterShadow[5]); ImGui::SameLine();
        ImGui::Checkbox("Bóng 6", &fcfg.filterShadow[6]);
        ImGui::Checkbox("Bóng 7", &fcfg.filterShadow[7]);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[2] Lọc Chi Tiết Theo ID Loài Cá:");
        ImGui::Checkbox("Bật Lọc Chi Tiết Theo ID", &fcfg.enableIdFilter);

        if (ImGui::Button("Sao Chép ID Đã Lọc", ImVec2(150, 26))) {
            FishingFeatures::CopySelectedFishIdsToClipboard();
        }
        ImGui::SameLine();
        if (ImGui::Button("Chọn Tất Cả", ImVec2(90, 26))) {
            FishingFeatures::SelectAllFishIds(true);
        }
        ImGui::SameLine();
        if (ImGui::Button("Bỏ Chọn Hết", ImVec2(90, 26))) {
            FishingFeatures::SelectAllFishIds(false);
        }

        ImGui::TextColored(ImVec4(0.6f, 0.8f, 1.0f, 1.0f), "Mẹo: Click trực tiếp vào cột ID để copy nhanh từng mã.");

        // Bảng lọc ID cá cuộn mượt
        if (ImGui::BeginChild("##FishIdTableArea", ImVec2(0, 180), true)) {
            if (ImGui::BeginTable("##FishFilterTable", 3, ImGuiTableFlags_RowBg | ImGuiTableFlags_BordersOuter | ImGuiTableFlags_ScrollY)) {
                ImGui::TableSetupColumn("Chọn", ImGuiTableColumnFlags_WidthFixed, 40.0f);
                ImGui::TableSetupColumn("ID Cá", ImGuiTableColumnFlags_WidthFixed, 60.0f);
                ImGui::TableSetupColumn("Bóng & Loài Cá", ImGuiTableColumnFlags_WidthStretch);
                ImGui::TableHeadersRow();

                for (size_t i = 0; i < FishingFeatures::k_fishTableCount; i++) {
                    const auto& entry = FishingFeatures::k_fishTable[i];
                    uint32_t fid = entry.id;
                    if (fid >= 25000) continue;

                    ImGui::TableNextRow();

                    // Cột 1: Checkbox
                    ImGui::TableSetColumnIndex(0);
                    ImGui::PushID((int)fid);
                    ImGui::Checkbox("##chk", &fcfg.filterFishIds[fid]);
                    ImGui::PopID();

                    // Cột 2: Nút ID bấm để copy
                    ImGui::TableSetColumnIndex(1);
                    char idBtnLabel[32];
                    snprintf(idBtnLabel, sizeof(idBtnLabel), "%u##id", fid);
                    if (ImGui::SmallButton(idBtnLabel)) {
                        FishingFeatures::CopySingleFishIdToClipboard(fid);
                    }

                    // Cột 3: Tên bóng & tóm tắt loài cá
                    ImGui::TableSetColumnIndex(2);
                    ImGui::Text("B%u - %s", entry.shadow, entry.speciesSummary);
                }
                ImGui::EndTable();
            }
            ImGui::EndChild();
        }
    }

    // --------------------------------------------------------------------------
    // TAB 3: BẮT BỌ (INSECTS - TAB RIÊNG)
    // --------------------------------------------------------------------------
    static void RenderTabInsect() {
        auto& icfg = InsectFeatures::GetConfig();
        auto istats = InsectFeatures::GetStats();

        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "TỰ ĐỘNG BẮT BỌ");
        ImGui::Separator();

        ImGui::Checkbox("Bật Auto Bắt Bọ (Tele Dưới Đất -> Chờ 2s -> Vợt)", &icfg.autoCatchInsect);
        ImGui::Checkbox("Côn Trùng Không Sợ (Đứng Yên, Không Bay Mất)", &icfg.insectsNoFear);
        ImGui::Checkbox("Tăng Tầm Vợt Siêu Rộng (30m)", &icfg.superCatchRadius);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "Tự Động Đổi Map Khi Hết Bọ:");
        ImGui::Checkbox("Bật Auto Đổi Map Bắt Bọ", &icfg.autoChangeMap);
        ImGui::TextColored(ImVec4(0.75f, 0.75f, 0.75f, 1.0f), "Chọn các map xoay vòng:");
        ImGui::Checkbox("Quảng Trường (Plaza)", &icfg.cycleMapPlaza); ImGui::SameLine();
        ImGui::Checkbox("Khu Cắm Trại", &icfg.cycleMapCamping);
        ImGui::Checkbox("Khu Nghỉ Dưỡng", &icfg.cycleMapResort); ImGui::SameLine();
        ImGui::Checkbox("Downtown", &icfg.cycleMapDowntown);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "Bảng Thông Tin:");
        ImGui::Checkbox("Hiện Popup Thông Tin Trên Màn Hình", &icfg.showInfoPopup);
        ImGui::TextColored(ImVec4(0.20f, 0.90f, 0.30f, 1.0f), "Số bọ trong map: %u con", istats.insectsInMap);
        ImGui::TextColored(ImVec4(0.20f, 0.90f, 0.30f, 1.0f), "Đã bắt được: %u con", istats.insectsCaught);
        ImGui::TextColored(ImVec4(0.20f, 0.90f, 0.30f, 1.0f), "Balo hiện tại: %d con", istats.backpackCount);
    }

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "Tự Động Đổi Map Khi Hết Bọ:");
        ImGui::Checkbox("Bật Auto Đổi Map Bắt Bọ", &icfg.autoChangeMap);
        ImGui::TextColored(ImVec4(0.75f, 0.75f, 0.75f, 1.0f), "Chọn các map xoay vòng:");
        ImGui::Checkbox("Quảng Trường (Plaza)", &icfg.cycleMapPlaza); ImGui::SameLine();
        ImGui::Checkbox("Khu Cắm Trại", &icfg.cycleMapCamping);
        ImGui::Checkbox("Khu Nghỉ Dưỡng", &icfg.cycleMapResort); ImGui::SameLine();
        ImGui::Checkbox("Downtown", &icfg.cycleMapDowntown);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "Bảng Thông Tin:");
        ImGui::Checkbox("Hiện Popup Thông Tin Trên Màn Hình", &icfg.showInfoPopup);
        ImGui::TextColored(ImVec4(0.20f, 0.90f, 0.30f, 1.0f), "Số bọ trong map: %u con", istats.insectsInMap);
        ImGui::TextColored(ImVec4(0.20f, 0.90f, 0.30f, 1.0f), "Đã bắt được: %u con", istats.insectsCaught);
        ImGui::TextColored(ImVec4(0.20f, 0.90f, 0.30f, 1.0f), "Balo hiện tại: %d con", istats.backpackCount);
    }

    // --------------------------------------------------------------------------
    // TAB 4: ĐẬP ĐÁ (MINING - TAB RIÊNG)
    // --------------------------------------------------------------------------
    static void RenderTabMining() {
        auto& mcfg = MiningFeatures::GetConfig();
        auto mstats = MiningFeatures::GetStats();

        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "TỰ ĐỘNG ĐẬP ĐÁ");
        ImGui::Separator();

        ImGui::Checkbox("Bật Auto Đập Đá (Tele Đến Đá -> Đập)", &mcfg.autoMineRocks);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "Tự Động Đổi Map Khi Hết Đá:");
        ImGui::Checkbox("Bật Auto Đổi Map Đập Đá", &mcfg.autoChangeMap);
        ImGui::TextColored(ImVec4(0.75f, 0.75f, 0.75f, 1.0f), "Chọn các map xoay vòng:");
        ImGui::Checkbox("Quảng Trường", &mcfg.cycleMapPlaza); ImGui::SameLine();
        ImGui::Checkbox("Khu Cắm Trại", &mcfg.cycleMapCamping);
        ImGui::Checkbox("Khu Nghỉ Dưỡng", &mcfg.cycleMapResort); ImGui::SameLine();
        ImGui::Checkbox("Downtown", &mcfg.cycleMapDowntown);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "Bộ Lọc Đá:");
        ImGui::Checkbox("Tele Tất Cả Đá", &mcfg.teleAllStones);
        ImGui::Checkbox("Tele Đá Nhỏ", &mcfg.teleSmallStones); ImGui::SameLine();
        ImGui::Checkbox("Tele Đá Vừa", &mcfg.teleMediumStones); ImGui::SameLine();
        ImGui::Checkbox("Tele Đá To", &mcfg.teleLargeStones);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.20f, 0.90f, 0.30f, 1.0f), "Số đá trong map: %u", mstats.rocksInMap);
        ImGui::TextColored(ImVec4(0.20f, 0.90f, 0.30f, 1.0f), "Đã đập được: %u viên đá", mstats.rocksMined);
    }

    // --------------------------------------------------------------------------
    // TAB 5: KHAI QUẬT & NÔNG TRẠI
    // --------------------------------------------------------------------------
    static void RenderTabExcavate() {
        auto& mcfg = MiningFeatures::GetConfig();
        auto& fcfg = FarmFeatures::GetConfig();

        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "KHAI QUẬT & NÔNG TRẠI");
        ImGui::Separator();

        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[1] Khai Quật / Đào Kho Báu:");
        ImGui::Checkbox("Auto Khai Quật (Đào Từ Xa)", &mcfg.autoExcavate);
        ImGui::SliderFloat("Delay Đào (s)", &mcfg.excavateDelay, 0.1f, 1.0f, "%.2f s");

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[2] Nông Trại:");
        ImGui::Checkbox("Tự Động Thu Hoạch", &fcfg.autoHarvest);
        ImGui::Checkbox("Tự Thu Hoạch (VIP)", &fcfg.autoHarvestSellVIP);
        ImGui::Checkbox("Giữ Biến Thể", &fcfg.keepVariants);
    }

    // --------------------------------------------------------------------------
    // TAB 6: HIỂN THỊ ESP
    // --------------------------------------------------------------------------
    static void RenderTabESP() {
        auto& ecfg = ESPFeatures::GetConfig();

        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "HIỂN THỊ ESP");
        ImGui::Separator();

        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[1] ESP Thu Thập:");
        ImGui::Checkbox("ESP Quặng Đá", &ecfg.espRocks);
        ImGui::Checkbox("ESP Côn Trùng & Bọ", &ecfg.espInsects);
        ImGui::Checkbox("ESP Khai Quật / Kho Báu", &ecfg.espExcavation);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[2] ESP Boss Rồng & Quái:");
        ImGui::Checkbox("Bật Tổng ESP Boss / Quái", &ecfg.espBossMonster);
        ImGui::Checkbox("Line Chỉ Đường", &ecfg.espBossLine);
        ImGui::Checkbox("Box / Vòng Tròn Chân", &ecfg.espBossBox);
        ImGui::Checkbox("Tên & Thanh Máu (HP Bar)", &ecfg.espBossHP);
    }

    // --------------------------------------------------------------------------
    // TAB 7: DỊCH CHUYỂN BẢN ĐỒ
    // --------------------------------------------------------------------------
    static void RenderTabMap() {
        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "DỊCH CHUYỂN BẢN ĐỒ");
        ImGui::Separator();

        const auto& locations = MapFeatures::GetLocations();
        for (size_t i = 0; i < locations.size(); i++) {
            const auto& loc = locations[i];
            if (ImGui::Button(loc.nameVi, ImVec2(150, 26))) {
                MapFeatures::TeleportToLocation(loc);
            }
            if ((i % 2 == 0) && (i + 1 < locations.size())) {
                ImGui::SameLine();
            }
        }
    }

    // --------------------------------------------------------------------------
    // TAB 8: DI CHUYỂN & TIỆN ÍCH
    // --------------------------------------------------------------------------
    static void RenderTabPlayerUtil() {
        auto& pcfg = PlayerFeatures::GetConfig();
        auto& ucfg = UtilityFeatures::GetConfig();

        ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "DI CHUYỂN & TIỆN ÍCH");
        ImGui::Separator();

        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[1] Di Chuyển Nhân Vật:");
        ImGui::Checkbox("Bật Hack Tốc Độ", &pcfg.speedHack);
        ImGui::SliderFloat("Tốc Độ Chạy", &pcfg.speedMultiplier, 1.0f, 10.0f, "%.1fx");
        ImGui::Checkbox("Nhảy Cao", &pcfg.highJump);
        ImGui::Checkbox("Đi Trên Không (Fly)", &pcfg.walkOnAir);
        ImGui::Checkbox("NoClip (Xuyên Vật Thể)", &pcfg.noClip);

        ImGui::Spacing();
        ImGui::TextColored(ImVec4(0.95f, 0.80f, 0.20f, 1.0f), "[2] Tiện Ích:");
        ImGui::Checkbox("Bỏ Qua Video Ads 0s", &ucfg.skipAds);
        ImGui::Checkbox("Giữ Sáng Màn Hình (No Sleep)", &ucfg.noSleep);
    }

    // --------------------------------------------------------------------------
    // Main UI Render Function
    // --------------------------------------------------------------------------
    void Render(bool* p_open) {
        // Floating HUD for Insect Info
        auto& icfg = InsectFeatures::GetConfig();
        if (icfg.showInfoPopup) {
            auto istats = InsectFeatures::GetStats();
            ImGui::SetNextWindowPos(ImVec2(10, 10), ImGuiCond_FirstUseEver);
            ImGui::Begin("##InsectHUD", nullptr, ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoSavedSettings | ImGuiWindowFlags_NoFocusOnAppearing);
            ImGui::TextColored(ImVec4(0.26f, 0.70f, 0.98f, 1.0f), "[Bắt Bọ]");
            ImGui::SameLine();
            ImGui::TextColored(ImVec4(1.0f, 1.0f, 1.0f, 1.0f), "Trong map: %u | Đã bắt: %u | Balo: %d", istats.insectsInMap, istats.insectsCaught, istats.backpackCount);
            ImGui::End();
        }

        if (p_open && !*p_open) return;
        if (!s_isOpen) return;

        // Kích thước nhỏ gọn 530 x 370
        ImGui::SetNextWindowSize(ImVec2(530, 370), ImGuiCond_FirstUseEver);
        if (!ImGui::Begin("KHOA PLAYTOGETHER - IMGUI iOS [Non-Jailbreak]###Play Together VNG", p_open ? p_open : &s_isOpen,
                          ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize)) {
            ImGui::End();
            return;
        }

        // Left Navigation Bar (##category) - Kéo cuộn cảm ứng tự do
        ImGui::BeginChild("##category", ImVec2(130, 0), true, ImGuiWindowFlags_AlwaysVerticalScrollbar);

        auto RenderTabButton = [](const char* label, Tab tab) {
            bool selected = (s_currentTab == tab);
            if (selected) {
                ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.26f, 0.70f, 0.98f, 1.0f));
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 1.0f, 1.0f, 1.0f));
            } else {
                ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.14f, 0.16f, 0.22f, 1.0f));
                ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.75f, 0.75f, 0.75f, 1.0f));
            }

            if (ImGui::Button(label, ImVec2(-1, 32))) {
                s_currentTab = tab;
            }

            ImGui::PopStyleColor(2);
        };

        RenderTabButton("Main", Tab::Main);
        RenderTabButton("Câu Cá", Tab::Fishing);
        RenderTabButton("Bắt Bọ", Tab::Insect);
        RenderTabButton("Đập Đá", Tab::Mining);
        RenderTabButton("Khai Quật", Tab::Excavate);
        RenderTabButton("ESP", Tab::ESP);
        RenderTabButton("Bản Đồ", Tab::Map);
        RenderTabButton("Tiện Ích", Tab::PlayerUtil);

        ImGui::EndChild();

        ImGui::SameLine();

        // Right Content Area (##MainContentPanel) - Kéo cuộn cảm ứng tự do
        ImGui::BeginChild("##MainContentPanel", ImVec2(0, 0), true, ImGuiWindowFlags_AlwaysVerticalScrollbar);

        switch (s_currentTab) {
            case Tab::Main:       RenderTabMain(); break;
            case Tab::Fishing:    RenderTabFishing(); break;
            case Tab::Insect:     RenderTabInsect(); break;
            case Tab::Mining:     RenderTabMining(); break;
            case Tab::Excavate:   RenderTabExcavate(); break;
            case Tab::ESP:        RenderTabESP(); break;
            case Tab::Map:        RenderTabMap(); break;
            case Tab::PlayerUtil: RenderTabPlayerUtil(); break;
        }

        ImGui::EndChild();
        ImGui::End();
    }
}
