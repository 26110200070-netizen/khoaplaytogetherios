#pragma once
#include <cstdint>
#include <string>

namespace AntiBan {
    struct AntiBanStats {
        uint32_t blockedReports;
        uint32_t blockedSpeedChecks;
        uint32_t blockedIntegrityChecks;
        uint32_t blockedJailbreakProbes;
        bool active;
    };

    void Initialize();
    void EnsureHooksInstalled();
    void SetEnabled(bool enabled);
    bool IsEnabled();
    AntiBanStats GetStats();
    void ResetStats();
}
