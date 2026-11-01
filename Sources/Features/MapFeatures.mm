#import "MapFeatures.h"
#import "Game/Offsets.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"

namespace MapFeatures {

    // Verified locations matching prompt exact requirements
    static const std::vector<MapLocation> s_locations = {
        {
            "Khu nghỉ dưỡng",
            "Resort Island",
            1301,
            GameTypes::MapKind::ResortIsland,
            VerificationStatus::Verified,
            "Đảo nghỉ dưỡng nhiệt đới, bãi biển câu cá cao cấp"
        },
        {
            "Cắm trại",
            "Camping Zone",
            1201,
            GameTypes::MapKind::CampingZone,
            VerificationStatus::Verified,
            "Khu cắm trại dã ngoại, suối thác, hồ câu cá tự nhiên"
        },
        {
            "Plaza",
            "Square (Plaza)",
            1001,
            GameTypes::MapKind::Square,
            VerificationStatus::Verified,
            "Quảng trường trung tâm đảo Kaia, hồ Plaza"
        },
        {
            "Cống ngầm",
            "Sewer Area",
            1401,
            GameTypes::MapKind::Sewer,
            VerificationStatus::Verified,
            "Khu vực cống ngầm bí mật ngầm dưới thành phố"
        },
        {
            "Down town",
            "Downtown District",
            1502,
            GameTypes::MapKind::DownTown,
            VerificationStatus::Verified,
            "Khu phố sầm uất trung tâm, trung tâm mua sắm và rạp chiếu"
        }
    };

    // SystemHelper.get_Layer
    typedef void* (*SystemHelper_get_Layer_t)();
    static SystemHelper_get_Layer_t p_SystemHelper_get_Layer = nullptr;

    // LayerSystem.ConnectToZoneMove
    typedef void (*LayerSystem_ConnectToZoneMove_t)(void* this_ptr, uint32_t targetMapId, int fromType, void* serverName, bool useIris, bool useAdabt);
    static LayerSystem_ConnectToZoneMove_t p_LayerSystem_ConnectToZoneMove = nullptr;

    void Initialize() {
        LOG_INFO("Initializing MapFeatures subsystem...");
        p_SystemHelper_get_Layer = (SystemHelper_get_Layer_t)Memory::GetRealOffset(Offsets::Map::SystemHelper_get_Layer);
        p_LayerSystem_ConnectToZoneMove = (LayerSystem_ConnectToZoneMove_t)Memory::GetRealOffset(Offsets::Map::LayerSystem_ConnectToZoneMove);
        LOG_SUCCESS("MapFeatures: 5 Verified map destinations ready.");
    }

    const std::vector<MapLocation>& GetLocations() {
        return s_locations;
    }

    const char* GetStatusString(VerificationStatus status) {
        switch (status) {
            case VerificationStatus::Verified: return "VERIFIED";
            case VerificationStatus::Unverified: return "UNVERIFIED";
            default: return "UNKNOWN";
        }
    }

    bool TeleportToMap(uint32_t mapId) {
        if (!p_SystemHelper_get_Layer) {
            p_SystemHelper_get_Layer = (SystemHelper_get_Layer_t)Memory::GetRealOffset(Offsets::Map::SystemHelper_get_Layer);
        }
        if (!p_LayerSystem_ConnectToZoneMove) {
            p_LayerSystem_ConnectToZoneMove = (LayerSystem_ConnectToZoneMove_t)Memory::GetRealOffset(Offsets::Map::LayerSystem_ConnectToZoneMove);
        }

        if (!p_SystemHelper_get_Layer || !p_LayerSystem_ConnectToZoneMove) {
            LOG_ERROR("Teleport failed: Function pointers not resolved");
            return false;
        }

        void* layerSys = p_SystemHelper_get_Layer();
        if (!layerSys) {
            LOG_ERROR("Teleport failed: LayerSystem is NULL (Game still initializing?)");
            return false;
        }

        LOG_INFO("Teleporting to Map ID: " + std::to_string(mapId) + " via LayerSystem...");
        // eWhereFromType.QuickMove = 10, serverName = null, useIris = true, useAdabt = false
        p_LayerSystem_ConnectToZoneMove(layerSys, mapId, 10, nullptr, true, false);
        LOG_SUCCESS("Teleport command dispatched to game network layer!");
        return true;
    }

    bool TeleportToLocation(const MapLocation& loc) {
        LOG_INFO(std::string("Requesting teleport to [") + loc.nameVi + "] (ID: " + std::to_string(loc.mapId) + ")");
        return TeleportToMap(loc.mapId);
    }
}
