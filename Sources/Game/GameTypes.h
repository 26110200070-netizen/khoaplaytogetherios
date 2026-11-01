#pragma once
#include <cstdint>

// ==============================================================================
// PLAYTOGETHER 2.33.0 - GAME ENUMS & STRUCTS
// Verified from Il2CppDumper dump.cs
// ==============================================================================

namespace GameTypes {

    // --------------------------------------------------------------------------
    // Fishing Float States (FishingFloatController.FloatState)
    // --------------------------------------------------------------------------
    enum class FloatState : int32_t {
        None                  = 0,
        Begin                 = 1,
        Casting               = 2,
        OnWater               = 3,
        Idle                  = 4,
        Touch                 = 5,
        Hit                   = 6,  // Dấu chấm than (!) - Cá cắn câu!
        Fight                 = 7,
        SuccessLift           = 8,  // Kéo lên thành công
        FailLift              = 9,
        Fail                  = 10,
        MissLift              = 11,
        BigFish_Begin         = 12,
        BigFish_Pumpin        = 13,
        BigFish_DragReady     = 14,
        BigFish_Drag          = 15, // Cá quái vật bơi / giãy kéo dây
        BigFish_Tug           = 16,
        BigFish_TugMiss       = 17,
        BigFish_StunBegin     = 18,
        BigFish_Stun          = 19, // Cá choáng (Stun) -> giật cần liên tục
        BigFish_StunRecovery  = 20,
        BigFish_Fight         = 21,
        BigFish_Appear        = 22,
        BigFish_Catch         = 23,
        BigFish_RaidFight     = 24,
        BigFish_RaidFight_Sync= 25
    };

    // --------------------------------------------------------------------------
    // Player Fishing States (ActorDefaultControl.eFishingState)
    // --------------------------------------------------------------------------
    enum class eFishingState : int32_t {
        None                  = 0,
        Casting               = 1,
        Search                = 2,
        SearchResult          = 3,
        Idle                  = 4,
        Hit                   = 5,  // Cá cắn câu -> giật
        Fighting              = 6,
        Catch                 = 7,  // Bắt được
        Fail                  = 8,
        Boast                 = 9,
        Finish                = 10,
        CastingFail           = 11,
        Miss                  = 12,
        BigFish_RaidEnter     = 13,
        BigFish_RaidSync      = 14,
        BigFish_Begin         = 15,
        BigFish_Pumpin        = 16,
        BigFish_Drag          = 17, // Minigame drag
        BigFish_Tug           = 18,
        BigFish_Fighting      = 19,
        BigFish_Catch         = 20,
        BigFish_Miss          = 21,
        BigFish_RaidFighting  = 22,
        BigFish_StunBegin     = 23,
        BigFish_Stun          = 24, // Minigame stun
        BigFish_StunRecovery  = 25
    };

    // --------------------------------------------------------------------------
    // Map IDs (PlayTogether.Table.Map_Kind)
    // --------------------------------------------------------------------------
    enum class MapKind : uint32_t {
        None                  = 0,
        Myhome                = 200,
        Showroom              = 300,
        Square                = 1001, // Plaza
        CostumeShop           = 1101,
        CarShop               = 1102,
        InteriorShop          = 1103,
        PetShop               = 1104,
        Mart                  = 1105,
        SevenEleven           = 1106,
        Baby                  = 1107,
        CampingZone           = 1201, // Cắm trại
        ResortIsland          = 1301, // Khu nghỉ dưỡng
        Sewer                 = 1401, // Cống ngầm
        DownTown              = 1502, // Down town
        ConcertHall           = 1503,
        School                = 1601,
        HorrorSchool          = 1602,
        BigMart               = 1701,
        Cinema                = 1702,
        Bank                  = 1703,
        PoliceOffice          = 1704,
        CityHall              = 1705,
        Hospital              = 1706,
        Hotel                 = 1707
    };

    // --------------------------------------------------------------------------
    // Where From Type for Zone Transition
    // --------------------------------------------------------------------------
    enum class eWhereFromType : int32_t {
        None                  = 0,
        QuickMove             = 10
    };

    // --------------------------------------------------------------------------
    // Anti-Cheat Detection Codes (AntiCheatListener.HType)
    // --------------------------------------------------------------------------
    enum class HType : int32_t {
        Spd                   = 1,
        Time                  = 2,
        Mem                   = 3,
        Tb                    = 4,
        App                   = 5,
        Fishing1              = 6,
        Fishing2              = 7,
        Fishing3              = 8,
        Fishing4              = 9,
        Fishing5              = 10,
        TimeScale             = 20,
        CostumeDataCheat      = 21,
        AnimationSpdCheat     = 22,
        DefaultCharacterCheat = 23,
        NameChange            = 24,
        AnimationClipSpdCheat = 25,
        OutOfMove             = 26,
        Teleport              = 27,
        Teleport2             = 28,
        CameraCheat           = 29,
        FishingZoneCheat      = 30,
        TreasureHunt1         = 31,
        FishingLevelCheat     = 32,
        InsectPosCheat        = 33,
        InsectPosCheat2       = 34,
        InsectCatchCehat      = 35,
        BoardMiniGameCheat    = 36,
        GPrestoSpd            = 37,
        InsectPosCheat_Far    = 38,
        MineTeleport          = 39,
        InsectTeleport        = 40,
        InvalidNickname       = 41,
        CustomCheat           = 99,
        TOHRespawn            = 100001,
        TOHJump               = 100002,
        InvalidSyncPosition   = 100003,
        TowerOfHellClearTime  = 300001,
        ObbyClearTime         = 300002,
        FishingCatchTime      = 300003,
        FishingCastingTime    = 300004
    };

    // --------------------------------------------------------------------------
    // Vector3 Representation
    // --------------------------------------------------------------------------
    struct Vector3 {
        float x;
        float y;
        float z;
    };
}
