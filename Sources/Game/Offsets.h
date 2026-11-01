#pragma once
#include <cstdint>

// ==============================================================================
// PLAYTOGETHER 2.33.0 (iOS arm64) - VERIFIED OFFSETS
// Extracted and verified from Il2CppDumper dump.cs and script.json
// Binary: UnityFramework
// ==============================================================================

namespace Offsets {
    // --------------------------------------------------------------------------
    // 0. SystemHelper (Global Unity System Access)
    // --------------------------------------------------------------------------
    namespace SystemHelper {
        constexpr uintptr_t get_Account   = 0x3421108; // public static AccountSystem get_Account()
        constexpr uintptr_t get_Dialog    = 0x341EA50; // public static DialogSystem get_Dialog()
        constexpr uintptr_t get_Table     = 0x3415C50; // public static TableSystem get_Table()
        constexpr uintptr_t get_Map       = 0x341F9E4; // public static MapSystem get_Map()
        constexpr uintptr_t get_Actor     = 0x3421558; // public static ActorSystem get_Actor()
        constexpr uintptr_t get_Fishing   = 0x3422020; // public static FishingSystem get_Fishing()
        constexpr uintptr_t get_Chat      = 0x342235C; // public static ChatSystem get_Chat()

        // DialogSystem methods
        constexpr uintptr_t DialogSystem_FindTypeFirst = 0x2C72714; // public DialogUnit FindTypeFirst(eDialogType findtype)
        constexpr uintptr_t DialogSystem_GetRewardPopup = 0x2C74650; // public DialogRewardPopup get_GetRewardPopup()
    }

    // --------------------------------------------------------------------------
    // 1. Fishing Subsystem
    // --------------------------------------------------------------------------
    namespace Fishing {
        // ActorDefaultControlPlayer
        constexpr uintptr_t OnLateUpdate          = 0x3762F64; // public override void OnLateUpdate()
        constexpr uintptr_t get_FishingState      = 0x372D15C; // public ActorDefaultControl.eFishingState get_FishingState()
        constexpr uintptr_t get_HasFishingPole    = 0x372D208; // public bool get_HasFishingPole()
        constexpr uintptr_t get_IsFishing         = 0x376AF00; // public override bool get_IsFishing()
        constexpr uintptr_t OnClickFishing        = 0x376B0E0; // public override void OnClickFishing()
        constexpr uintptr_t FishingCancel         = 0x376AE98; // public void FishingCancel()
        constexpr uintptr_t StartFishing          = 0x376B824; // public bool StartFishing()
        constexpr uintptr_t UpdateFishingState    = 0x376C860; // public override bool UpdateFishingState(ActorDefaultControl.eFishingState fishingState)
        constexpr uintptr_t HitResult             = 0x3770764; // private void HitResult(FishingSystem.eHitState hitState)
        constexpr uintptr_t CatchResult           = 0x3770928; // private void CatchResult(bool success, uint rewardItemId, int size, FishExtraData options)
        constexpr uintptr_t ReceiveFishingBegin   = 0x376FAF0; // private void ReceiveFishingBegin(...)

        // FishingFloatController
        constexpr uintptr_t ChangeState           = 0x2D275C4; // public void ChangeState(FishingFloatController.FloatState state)
        constexpr uintptr_t BigFishStunHit        = 0x2D2BAF8; // public void BigFishStunHit()
        constexpr uintptr_t PlayPumpinEfx         = 0x2D2C87C; // private void PlayPumpinEfx()
        constexpr uintptr_t StopPumpinEfx         = 0x2D2C4A0; // private void StopPumpinEfx(bool destroy)

        // FishingSystem
        constexpr uintptr_t FishingSystem_get_Self = 0x2D31E08; // public static FishingSystem get_Self()
        constexpr uintptr_t RequestFishingBegin    = 0x2D34ECC; // public void RequestFishingBegin(Vector3 point, ...)
        constexpr uintptr_t RequestFishingHit      = 0x2D35860; // public void RequestFishingHit(...)
        constexpr uintptr_t RequestFishingTug      = 0x2D359E4; // public void RequestFishingTug(...)
        constexpr uintptr_t RequestFishingCatch    = 0x2D36270; // public void RequestFishingCatch(...)
    }

    // --------------------------------------------------------------------------
    // 2. Dialog & UI Subsystem (Auto Bảo quản, Đóng quà / Hộp thẻ)
    // --------------------------------------------------------------------------
    namespace Dialogs {
        // DialogFishingGetItem (Fish reward / Keep dialog)
        constexpr uintptr_t DialogFishingGetItem_DialogShow        = 0x3E521D0; // public override void DialogShow()
        constexpr uintptr_t DialogFishingGetItem_OnClick_Close     = 0x3E521EC; // private void OnClick_ButtonClose() [Bảo quản]
        constexpr uintptr_t DialogFishingGetItem_DialogHide        = 0x3E521D8; // public override void DialogHide(bool isDelete)
        constexpr uintptr_t DialogFishingGetItem_DialogDelete      = 0x3E521E0; // public override void DialogDelete()

        // DialogRewardPopup (General reward popup)
        constexpr uintptr_t DialogRewardPopup_DialogShow           = 0x3A2082C; // public override void DialogShow()
        constexpr uintptr_t DialogRewardPopup_OnClickYes           = 0x3A226F4; // private void OnClickYes() [Accept / Close]
        constexpr uintptr_t DialogRewardPopup_DialogHide           = 0x3A20834; // public override void DialogHide(bool isDelete)
        constexpr uintptr_t DialogRewardPopup_DialogDelete         = 0x3A2089C; // public override void DialogDelete()

        // DialogResultGetItemView (Gacha box & Card pack open animation)
        constexpr uintptr_t DialogResultGetItemView_DialogShow         = 0x2B75434; // public override void DialogShow()
        constexpr uintptr_t DialogResultGetItemView_DialogHide         = 0x2B754AC; // public override void DialogHide(bool isDelete)
        constexpr uintptr_t DialogResultGetItemView_DialogDelete       = 0x2B755F0; // public override void DialogDelete()
        constexpr uintptr_t DialogResultGetItemView_DialogCloseFromBack = 0x2B75B00; // public override void DialogCloseFromBack()
        constexpr uintptr_t DialogResultGetItemView_SetGachaBoxOpen    = 0x2B77D50; // private void SetGachaBoxOpen()

        // DialogResultGetItemList (Gacha result summary grid)
        constexpr uintptr_t DialogResultGetItemList_DialogShow         = 0x2B71458; // public override void DialogShow()
        constexpr uintptr_t DialogResultGetItemList_DialogCloseFromBack = 0x2B715C8; // public override void DialogCloseFromBack()
    }

    // --------------------------------------------------------------------------
    // 3. Map & Teleport Subsystem
    // --------------------------------------------------------------------------
    namespace Map {
        // SystemHelper accessors
        constexpr uintptr_t SystemHelper_get_Layer = 0x342121C; // public static LayerSystem get_Layer()
        constexpr uintptr_t SystemHelper_get_Actor = 0x342166C; // public static ActorSystem get_Actor()
        constexpr uintptr_t SystemHelper_get_Map   = 0x3421558; // public static MapSystem get_Map()

        // LayerSystem map transition
        constexpr uintptr_t LayerSystem_ConnectToZoneMove = 0x2E9DBB0; // public void ConnectToZoneMove(uint targetMapId, eWhereFromType fromType, string serverName, bool useIris, bool useAdabt)
    }

    // --------------------------------------------------------------------------
    // 4. Anti-Cheat & Security Subsystem (Antiban)
    // --------------------------------------------------------------------------
    namespace Security {
        constexpr uintptr_t AntiCheat_OnOtherCheatingDetected    = 0x3063C94; // public void OnOtherCheatingDetected(AntiCheatListener.HType otherNo, string ment)
        constexpr uintptr_t AntiCheat_OnSpeedHackDetected        = 0x3063A7C; // public void OnSpeedHackDetected()
        constexpr uintptr_t AntiCheat_OnSpeedHackDetectedGpresto = 0x3063B04; // public void OnSpeedHackDetectedGpresto()
        constexpr uintptr_t AntiCheat_OnTimeCheatingDetected     = 0x3063B98; // public void OnTimeCheatingDetected()
        constexpr uintptr_t AntiCheat_OnObscuredTypeDetected     = 0x3063BA0; // public void OnObscuredTypeCheatingDetected()
        constexpr uintptr_t AntiCheat_OnTableCheatingDetected    = 0x3063C28; // public void OnTableCheatingDetected(string ment)
        constexpr uintptr_t AntiCheat_OnAnimationSpeedCheatDetect = 0x3063D34; // public void OnAnimationSpeedCheatDetect(AnimancerState state)
        constexpr uintptr_t AntiCheat_get_IsCheating             = 0x306397C; // public bool get_IsCheating()
        constexpr uintptr_t AntiCheat_CheckDetect                = 0x30639D0; // private bool CheckDetect(AntiCheatListener.HType type)
    }

    // --------------------------------------------------------------------------
    // 5. Extended Gameplay Features (Bắt Bọ, Đập Đá, Khai Quật, Nông Trại, Minigame)
    // --------------------------------------------------------------------------
    namespace Extended {
        constexpr uintptr_t OnPressInsectNet              = 0x3760894; // ActorDefaultControlPlayer.OnPressInsectNet(bool)
        constexpr uintptr_t OnClickPickax                 = 0x3774068; // ActorDefaultControlPlayer.OnClickPickax()
        constexpr uintptr_t OnClickExcavate               = 0x3769C88; // ActorDefaultControlPlayer.OnClickExcavate()
        constexpr uintptr_t OnClick_HarvestAll            = 0x3F43280; // DialogMyFarmHarvest.OnClick_HarvestAll()
        constexpr uintptr_t AnimancerState_set_Speed      = 0x2AC91FC; // AnimancerState.set_Speed(float)
        constexpr uintptr_t SendToKMGFinishGoal           = 0x35DEEE0; // NetNativeProtocol.SendToKMGFinishGoal(...)
        constexpr uintptr_t SendToSchoolQuestionResult    = 0x36080BC; // NetNativeProtocol.SendToSchoolQuestionResult(...)
    }

    // --------------------------------------------------------------------------
    // 6. Unity Engine & Camera Offsets (ESP WorldToScreen)
    // --------------------------------------------------------------------------
    namespace Engine {
        constexpr uintptr_t Camera_get_main          = 0xA1671C8; // public static Camera get_main()
        constexpr uintptr_t Camera_WorldToScreenPoint = 0xA165F00; // public Vector3 WorldToScreenPoint(Vector3)
        constexpr uintptr_t Transform_get_position   = 0xA227EBC; // public Vector3 get_position()
        constexpr uintptr_t Transform_set_position   = 0xA227FD0; // public void set_position(Vector3)
    }
}
