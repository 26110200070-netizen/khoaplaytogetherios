#pragma once

namespace Menu {
    enum class Tab {
        Main = 0,
        Fishing,
        MiningFarm,
        BossCombat,
        Minigame,
        ESP,
        Map,
        Debug
    };

    void Initialize();
    void Render(bool* p_open = nullptr);
    bool IsOpen();
    void SetOpen(bool open);
    void ToggleOpen();
}
