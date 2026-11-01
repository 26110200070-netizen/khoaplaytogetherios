#pragma once
#include <cstdint>
#include <string>
#include <vector>
#include "Game/GameTypes.h"

namespace MapFeatures {

    enum class VerificationStatus {
        Verified,
        Unverified,
        Unknown
    };

    struct MapLocation {
        const char* nameVi;
        const char* nameEn;
        uint32_t mapId;
        GameTypes::MapKind kind;
        VerificationStatus status;
        const char* description;
    };

    void Initialize();
    const std::vector<MapLocation>& GetLocations();
    bool TeleportToMap(uint32_t mapId);
    bool TeleportToLocation(const MapLocation& loc);
    const char* GetStatusString(VerificationStatus status);
}
