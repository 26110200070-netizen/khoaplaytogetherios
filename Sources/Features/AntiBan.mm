#import "AntiBan.h"
#import "Game/Offsets.h"
#import "Game/GameTypes.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"
#include <sys/stat.h>
#include <unistd.h>
#include <dlfcn.h>
#include <string>

namespace AntiBan {

    static AntiBanStats g_stats = { 0, 0, 0, 0, true };

    // --------------------------------------------------------------------------
    // C# AntiCheatListener Hooks
    // --------------------------------------------------------------------------

    // public void OnOtherCheatingDetected(AntiCheatListener.HType otherNo, string ment)
    void (*orig_OnOtherCheatingDetected)(void* this_ptr, int otherNo, void* ment) = nullptr;
    void hook_OnOtherCheatingDetected(void* this_ptr, int otherNo, void* ment) {
        if (g_stats.active) {
            g_stats.blockedReports++;
            LOG_WARN("AntiBan: Suppressed cheat report code=" + std::to_string(otherNo));
            return;
        }
        if (orig_OnOtherCheatingDetected) {
            orig_OnOtherCheatingDetected(this_ptr, otherNo, ment);
        }
    }

    // public void OnSpeedHackDetected()
    void (*orig_OnSpeedHackDetected)(void* this_ptr) = nullptr;
    void hook_OnSpeedHackDetected(void* this_ptr) {
        if (g_stats.active) {
            g_stats.blockedSpeedChecks++;
            LOG_WARN("AntiBan: Suppressed SpeedHack detection");
            return;
        }
        if (orig_OnSpeedHackDetected) {
            orig_OnSpeedHackDetected(this_ptr);
        }
    }

    // public void OnSpeedHackDetectedGpresto()
    void (*orig_OnSpeedHackDetectedGpresto)(void* this_ptr) = nullptr;
    void hook_OnSpeedHackDetectedGpresto(void* this_ptr) {
        if (g_stats.active) {
            g_stats.blockedSpeedChecks++;
            LOG_WARN("AntiBan: Suppressed G-Presto SpeedHack detection");
            return;
        }
        if (orig_OnSpeedHackDetectedGpresto) {
            orig_OnSpeedHackDetectedGpresto(this_ptr);
        }
    }

    // public void OnTimeCheatingDetected()
    void (*orig_OnTimeCheatingDetected)(void* this_ptr) = nullptr;
    void hook_OnTimeCheatingDetected(void* this_ptr) {
        if (g_stats.active) {
            g_stats.blockedSpeedChecks++;
            LOG_WARN("AntiBan: Suppressed TimeCheating detection");
            return;
        }
        if (orig_OnTimeCheatingDetected) {
            orig_OnTimeCheatingDetected(this_ptr);
        }
    }

    // public void OnObscuredTypeCheatingDetected()
    void (*orig_OnObscuredTypeDetected)(void* this_ptr) = nullptr;
    void hook_OnObscuredTypeDetected(void* this_ptr) {
        if (g_stats.active) {
            g_stats.blockedIntegrityChecks++;
            LOG_WARN("AntiBan: Suppressed ObscuredType detection");
            return;
        }
        if (orig_OnObscuredTypeDetected) {
            orig_OnObscuredTypeDetected(this_ptr);
        }
    }

    // public void OnTableCheatingDetected(string ment)
    void (*orig_OnTableCheatingDetected)(void* this_ptr, void* ment) = nullptr;
    void hook_OnTableCheatingDetected(void* this_ptr, void* ment) {
        if (g_stats.active) {
            g_stats.blockedIntegrityChecks++;
            LOG_WARN("AntiBan: Suppressed TableCheating detection");
            return;
        }
        if (orig_OnTableCheatingDetected) {
            orig_OnTableCheatingDetected(this_ptr, ment);
        }
    }

    // public void OnAnimationSpeedCheatDetect(AnimancerState state)
    void (*orig_OnAnimationSpeedCheatDetect)(void* this_ptr, void* state) = nullptr;
    void hook_OnAnimationSpeedCheatDetect(void* this_ptr, void* state) {
        if (g_stats.active) {
            g_stats.blockedSpeedChecks++;
            LOG_WARN("AntiBan: Suppressed AnimationSpeed detection");
            return;
        }
        if (orig_OnAnimationSpeedCheatDetect) {
            orig_OnAnimationSpeedCheatDetect(this_ptr, state);
        }
    }

    // public bool get_IsCheating()
    bool (*orig_get_IsCheating)(void* this_ptr) = nullptr;
    bool hook_get_IsCheating(void* this_ptr) {
        if (g_stats.active) {
            return false;
        }
        if (orig_get_IsCheating) {
            return orig_get_IsCheating(this_ptr);
        }
        return false;
    }

    // private bool CheckDetect(AntiCheatListener.HType type)
    bool (*orig_CheckDetect)(void* this_ptr, int type) = nullptr;
    bool hook_CheckDetect(void* this_ptr, int type) {
        if (g_stats.active) {
            return false;
        }
        if (orig_CheckDetect) {
            return orig_CheckDetect(this_ptr, type);
        }
        return false;
    }

    // --------------------------------------------------------------------------
    // Initialization & On-demand Hooking
    // --------------------------------------------------------------------------
    static bool s_antiBanHooksInstalled = false;

    void EnsureHooksInstalled() {
        if (s_antiBanHooksInstalled) return;
        s_antiBanHooksInstalled = true;
        LOG_INFO("Installing AntiBan report filters on-demand...");

        Memory::InstallHook((void*)Memory::GetRealOffset(Offsets::Security::AntiCheat_OnOtherCheatingDetected),
                            (void*)hook_OnOtherCheatingDetected,
                            (void**)&orig_OnOtherCheatingDetected,
                            "OnOtherCheatingDetected");

        Memory::InstallHook((void*)Memory::GetRealOffset(Offsets::Security::AntiCheat_OnSpeedHackDetected),
                            (void*)hook_OnSpeedHackDetected,
                            (void**)&orig_OnSpeedHackDetected,
                            "OnSpeedHackDetected");

        Memory::InstallHook((void*)Memory::GetRealOffset(Offsets::Security::AntiCheat_OnSpeedHackDetectedGpresto),
                            (void*)hook_OnSpeedHackDetectedGpresto,
                            (void**)&orig_OnSpeedHackDetectedGpresto,
                            "OnSpeedHackDetectedGpresto");

        Memory::InstallHook((void*)Memory::GetRealOffset(Offsets::Security::AntiCheat_OnTimeCheatingDetected),
                            (void*)hook_OnTimeCheatingDetected,
                            (void**)&orig_OnTimeCheatingDetected,
                            "OnTimeCheatingDetected");

        Memory::InstallHook((void*)Memory::GetRealOffset(Offsets::Security::AntiCheat_OnObscuredTypeDetected),
                            (void*)hook_OnObscuredTypeDetected,
                            (void**)&orig_OnObscuredTypeDetected,
                            "OnObscuredTypeDetected");

        Memory::InstallHook((void*)Memory::GetRealOffset(Offsets::Security::AntiCheat_OnTableCheatingDetected),
                            (void*)hook_OnTableCheatingDetected,
                            (void**)&orig_OnTableCheatingDetected,
                            "OnTableCheatingDetected");

        LOG_SUCCESS("AntiBan: Game security filters ACTIVE.");
    }

    void Initialize() {
        EnsureHooksInstalled();
    }

    void SetEnabled(bool enabled) {
        g_stats.active = enabled;
        LOG_INFO(std::string("AntiBan state changed: ") + (enabled ? "ENABLED" : "DISABLED"));
    }

    bool IsEnabled() {
        return g_stats.active;
    }

    AntiBanStats GetStats() {
        return g_stats;
    }

    void ResetStats() {
        g_stats.blockedReports = 0;
        g_stats.blockedSpeedChecks = 0;
        g_stats.blockedIntegrityChecks = 0;
        g_stats.blockedJailbreakProbes = 0;
        LOG_INFO("AntiBan stats counters reset");
    }
}
