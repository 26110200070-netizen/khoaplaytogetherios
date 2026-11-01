#pragma once
#include <cstdint>
#include <string>
#include <vector>

namespace ESPFeatures {

    struct Config {
        // 1. ESP Sự Kiện Boss Rồng & Quái
        bool espBossMonster;           // Bật Tổng ESP Boss / Quái
        bool espBossLine;              // Line Chỉ Đường Boss / Quái
        bool espBossBox;               // Vòng Tròn Chân Raycast / Box
        bool espBossHP;                // Tên Quái & Thanh Máu (HP Bar)
        bool espSpecialDragon;         // ESP Boss Rồng Đặc Biệt

        // 2. ESP Thu Thập & Thế Giới
        bool espFishingZone;           // ESP Vùng Câu Cá
        bool showTeleFishingZone;      // Hiện Nút Tele Vùng Câu
        bool espRocks;                 // ESP Đá & Khoáng Sản
        bool espInsects;               // ESP Côn Trùng
        bool espExcavation;            // ESP Khai Quật
        bool espTreasure;              // ESP Kho Báu
        bool espAllItems;              // ESP Tất Cả Vật Phẩm
        bool showTeleAllItems;         // Hiện Nút Tele Tất Cả Vật Phẩm
        bool espEventItems;            // ESP Vật Phẩm Sự Kiện
        bool showTeleEventItems;       // Hiện Nút Tele Sự Kiện
        bool espNPCQuest;              // ESP Nhiệm Vụ NPC

        // 3. ESP Minigame & Khác
        bool espZombieVirus;           // ESP Zombie Virus
        bool showTeleZombieVirus;      // Hiện Nút Tele Zombie Virus
        bool espAutoPath;              // ESP Auto Move / Path
    };

    struct ESPItem {
        std::string name;
        float x, y, z;
        uint32_t color; // ImU32 RGBA
        float distance;
        uint32_t hp;
        uint32_t maxHp;
        int type; // 0: Monster, 1: Fishing, 2: Rock, 3: Insect, 4: Treasure, 5: Item, 6: NPC, 7: Zombie
    };

    void Initialize();
    void EnsureHooksInstalled();
    Config& GetConfig();
    bool IsEnabled();

    // Renders ESP overlays onto ImGui background draw list
    void RenderESP();
}
