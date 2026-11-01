#pragma once

namespace Menu {
    enum class Tab {
        FishingInsects = 0,
        MiningFarm,
        BossCombat,
        Minigame,
        ESP,
        Utilities
    };

    void Initialize();
    void Render(bool* p_open = nullptr);
    bool IsOpen();
    void SetOpen(bool open);
    void ToggleOpen();
}
