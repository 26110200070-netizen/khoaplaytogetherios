#pragma once

namespace Menu {
    enum class Tab {
        Main = 0,
        Fishing,
        Insect,
        Mining,
        Excavate,
        ESP,
        Map,
        PlayerUtil
    };

    void Initialize();
    void Render(bool* p_open = nullptr);
    bool IsOpen();
    void SetOpen(bool open);
    void ToggleOpen();
}
