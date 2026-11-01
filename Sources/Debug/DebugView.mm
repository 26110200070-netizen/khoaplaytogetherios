#import "DebugView.h"
#import "Utils/Memory.h"
#import "Utils/Logging.h"
#import "Features/AntiBan.h"
#import "Features/FishingFeatures.h"
#import "Features/MainFeatures.h"
#import "IMGUI/imgui.h"
#import <UIKit/UIKit.h>
#include <sys/utsname.h>
#include <chrono>

namespace DebugView {

    static std::chrono::steady_clock::time_point s_startTime;
    static uint64_t s_frameCount = 0;
    static bool s_dobbyTestResult = false;
    static bool s_memoryTestResult = false;
    static bool s_imguiTestResult = false;
    static bool s_hasRunDobbyTest = false;
    static bool s_hasRunMemoryTest = false;
    static bool s_hasRunImGuiTest = false;

    // Dummy test function for Dobby hook validation
    static int TestDummyFunction(int a, int b) {
        return a + b;
    }

    static int (*orig_TestDummyFunction)(int a, int b) = nullptr;
    static int hook_TestDummyFunction(int a, int b) {
        return (a + b) * 2;
    }

    bool RunDobbyTest() {
        s_hasRunDobbyTest = true;
        LOG_INFO("Running real Dobby hook test on local dummy function...");

        int normalResult = TestDummyFunction(10, 20); // 30
        int hookRes = DobbyHook((void*)TestDummyFunction, (dobby_dummy_func_t)hook_TestDummyFunction, (dobby_dummy_func_t*)&orig_TestDummyFunction);

        if (hookRes == 0) {
            int hookedResult = TestDummyFunction(10, 20); // Should be 60
            if (hookedResult == 60) {
                s_dobbyTestResult = true;
                LOG_SUCCESS("Dobby Test PASSED: Function intercepted successfully (expected 60, got 60).");
                return true;
            }
        }
        s_dobbyTestResult = false;
        LOG_ERROR("Dobby Test FAILED: Hook was not executed as expected.");
        return false;
    }

    bool RunMemoryTest() {
        s_hasRunMemoryTest = true;
        LOG_INFO("Running real Memory read/write protection test...");

        volatile uint32_t testValue = 0x12345678;
        uint32_t patchValue = 0x87654321;

        bool writeOk = Memory::WriteMemory((uintptr_t)&testValue, &patchValue, sizeof(patchValue));
        if (writeOk && testValue == 0x87654321) {
            s_memoryTestResult = true;
            LOG_SUCCESS("Memory Test PASSED: Virtual memory protection & write successful.");
            return true;
        }

        s_memoryTestResult = false;
        LOG_ERROR("Memory Test FAILED: WriteMemory returned false or value mismatch.");
        return false;
    }

    bool RunImGuiTest() {
        s_hasRunImGuiTest = true;
        ImGuiContext* ctx = ImGui::GetCurrentContext();
        if (ctx != nullptr) {
            s_imguiTestResult = true;
            LOG_SUCCESS("ImGui Test PASSED: Context is valid and active.");
            return true;
        }
        s_imguiTestResult = false;
        LOG_ERROR("ImGui Test FAILED: ImGuiContext is null.");
        return false;
    }

    void Initialize() {
        s_startTime = std::chrono::steady_clock::now();
        LOG_INFO("DebugView initialized successfully");
    }

    void Render() {
        s_frameCount++;

        auto now = std::chrono::steady_clock::now();
        auto uptimeSec = std::chrono::duration_cast<std::chrono::seconds>(now - s_startTime).count();
        int hours = (int)(uptimeSec / 3600);
        int mins = (int)((uptimeSec % 3600) / 60);
        int secs = (int)(uptimeSec % 60);

        // System information
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString* iosVersion = [[UIDevice currentDevice] systemVersion];
        Memory::ModuleInfo modInfo = Memory::GetModuleInfo("UnityFramework");

        // ----------------------------------------------------------------------
        // Section 1: System Information
        // ----------------------------------------------------------------------
        if (ImGui::CollapsingHeader("1. System Information", ImGuiTreeNodeFlags_DefaultOpen)) {
            ImGui::TextColored(ImVec4(0.4f, 0.8f, 1.0f, 1.0f), "OS Version:    ");
            ImGui::SameLine();
            ImGui::Text("iOS %s", [iosVersion UTF8String]);

            ImGui::TextColored(ImVec4(0.4f, 0.8f, 1.0f, 1.0f), "Hardware:      ");
            ImGui::SameLine();
            ImGui::Text("%s (%s)", systemInfo.machine, systemInfo.sysname);

            ImGui::TextColored(ImVec4(0.4f, 0.8f, 1.0f, 1.0f), "Architecture:  ");
            ImGui::SameLine();
            ImGui::Text("arm64-v8a (Apple Silicon)");

            ImGui::TextColored(ImVec4(0.4f, 0.8f, 1.0f, 1.0f), "ImGui State:   ");
            ImGui::SameLine();
            ImGui::TextColored(ImVec4(0.3f, 1.0f, 0.3f, 1.0f), "Active (v%s)", IMGUI_VERSION);

            ImGui::TextColored(ImVec4(0.4f, 0.8f, 1.0f, 1.0f), "Dobby Status:  ");
            ImGui::SameLine();
            ImGui::TextColored(ImVec4(0.3f, 1.0f, 0.3f, 1.0f), "Linked (libdobby.a arm64)");
        }

        // ----------------------------------------------------------------------
        // Section 2: Module Information
        // ----------------------------------------------------------------------
        if (ImGui::CollapsingHeader("2. Module Information", ImGuiTreeNodeFlags_DefaultOpen)) {
            ImGui::TextColored(ImVec4(0.4f, 0.8f, 1.0f, 1.0f), "Target Image:  ");
            ImGui::SameLine();
            ImGui::Text("%s", (modInfo.name ? modInfo.name : "UnityFramework (or Main)"));

            ImGui::TextColored(ImVec4(0.4f, 0.8f, 1.0f, 1.0f), "Base Address:  ");
            ImGui::SameLine();
            ImGui::Text("0x%llX", (unsigned long long)modInfo.baseAddress);

            ImGui::TextColored(ImVec4(0.4f, 0.8f, 1.0f, 1.0f), "ASLR Slide:    ");
            ImGui::SameLine();
            ImGui::Text("0x%llX", (unsigned long long)modInfo.slide);

            ImGui::TextColored(ImVec4(0.4f, 0.8f, 1.0f, 1.0f), "Mach-O Header: ");
            ImGui::SameLine();
            if (modInfo.header) {
                ImGui::TextColored(ImVec4(0.3f, 1.0f, 0.3f, 1.0f), "VALID (magic: 0x%X)", modInfo.header->magic);
            } else {
                ImGui::TextColored(ImVec4(1.0f, 0.4f, 0.4f, 1.0f), "NOT MAPPED");
            }
        }

        // ----------------------------------------------------------------------
        // Section 3: Runtime & Hook Status
        // ----------------------------------------------------------------------
        if (ImGui::CollapsingHeader("3. Runtime Information", ImGuiTreeNodeFlags_DefaultOpen)) {
            ImGui::TextColored(ImVec4(0.4f, 0.8f, 1.0f, 1.0f), "Uptime:        ");
            ImGui::SameLine();
            ImGui::Text("%02d:%02d:%02d (%llu frames)", hours, mins, secs, s_frameCount);

            auto fishStatus = FishingFeatures::GetStatus();
            ImGui::TextColored(ImVec4(0.4f, 0.8f, 1.0f, 1.0f), "Float Ctrl:    ");
            ImGui::SameLine();
            if (fishStatus.activeFloatController) {
                ImGui::TextColored(ImVec4(0.3f, 1.0f, 0.3f, 1.0f), "0x%llX [Active]", (unsigned long long)fishStatus.activeFloatController);
            } else {
                ImGui::TextColored(ImVec4(1.0f, 0.7f, 0.2f, 1.0f), "Awaiting cast...");
            }

            ImGui::TextColored(ImVec4(0.4f, 0.8f, 1.0f, 1.0f), "Player Ctrl:   ");
            ImGui::SameLine();
            if (fishStatus.activePlayerController) {
                ImGui::TextColored(ImVec4(0.3f, 1.0f, 0.3f, 1.0f), "0x%llX [Active]", (unsigned long long)fishStatus.activePlayerController);
            } else {
                ImGui::TextColored(ImVec4(1.0f, 0.7f, 0.2f, 1.0f), "Awaiting action...");
            }

            auto abStats = AntiBan::GetStats();
            ImGui::TextColored(ImVec4(0.4f, 0.8f, 1.0f, 1.0f), "Blocked Repts: ");
            ImGui::SameLine();
            ImGui::TextColored(ImVec4(0.3f, 1.0f, 0.3f, 1.0f), "%u packets suppressed", abStats.blockedReports);
        }

        // ----------------------------------------------------------------------
        // Section 4: Self-Diagnostics & Tests
        // ----------------------------------------------------------------------
        if (ImGui::CollapsingHeader("4. Verification & Diagnostics", ImGuiTreeNodeFlags_DefaultOpen)) {
            if (ImGui::Button("Test ImGui Context", ImVec2(160, 30))) {
                RunImGuiTest();
            }
            ImGui::SameLine();
            if (s_hasRunImGuiTest) {
                if (s_imguiTestResult) {
                    ImGui::TextColored(ImVec4(0.3f, 1.0f, 0.3f, 1.0f), "[PASSED] Context Valid");
                } else {
                    ImGui::TextColored(ImVec4(1.0f, 0.3f, 0.3f, 1.0f), "[FAILED]");
                }
            } else {
                ImGui::TextDisabled("Untested");
            }

            if (ImGui::Button("Test Dobby Hook", ImVec2(160, 30))) {
                RunDobbyTest();
            }
            ImGui::SameLine();
            if (s_hasRunDobbyTest) {
                if (s_dobbyTestResult) {
                    ImGui::TextColored(ImVec4(0.3f, 1.0f, 0.3f, 1.0f), "[PASSED] Intercepted 10+20 => 60");
                } else {
                    ImGui::TextColored(ImVec4(1.0f, 0.3f, 0.3f, 1.0f), "[FAILED]");
                }
            } else {
                ImGui::TextDisabled("Untested");
            }

            if (ImGui::Button("Test Memory Protect", ImVec2(160, 30))) {
                RunMemoryTest();
            }
            ImGui::SameLine();
            if (s_hasRunMemoryTest) {
                if (s_memoryTestResult) {
                    ImGui::TextColored(ImVec4(0.3f, 1.0f, 0.3f, 1.0f), "[PASSED] Mach VM Protect OK");
                } else {
                    ImGui::TextColored(ImVec4(1.0f, 0.3f, 0.3f, 1.0f), "[FAILED]");
                }
            } else {
                ImGui::TextDisabled("Untested");
            }

            if (ImGui::Button("Clear Debug Log", ImVec2(160, 30))) {
                Logger::Instance().Clear();
            }
        }

        // ----------------------------------------------------------------------
        // Section 5: Real-time Terminal Log
        // ----------------------------------------------------------------------
        ImGui::Separator();
        ImGui::TextColored(ImVec4(1.0f, 1.0f, 0.4f, 1.0f), "Diagnostic Log Terminal (%zu entries):", Logger::Instance().GetCount());

        ImGui::BeginChild("LogTerminal", ImVec2(0, 180), true, ImGuiWindowFlags_HorizontalScrollbar);
        auto entries = Logger::Instance().GetEntries();
        for (const auto& entry : entries) {
            ImVec4 color;
            switch (entry.level) {
                case LogLevel::Info:    color = ImVec4(0.8f, 0.8f, 0.8f, 1.0f); break;
                case LogLevel::Success: color = ImVec4(0.3f, 1.0f, 0.3f, 1.0f); break;
                case LogLevel::Warning: color = ImVec4(1.0f, 0.8f, 0.2f, 1.0f); break;
                case LogLevel::Error:   color = ImVec4(1.0f, 0.3f, 0.3f, 1.0f); break;
                case LogLevel::Hook:    color = ImVec4(0.9f, 0.4f, 1.0f, 1.0f); break;
            }
            ImGui::TextColored(ImVec4(0.5f, 0.5f, 0.5f, 1.0f), "[%s]", entry.timestamp.c_str());
            ImGui::SameLine();
            ImGui::TextColored(color, "%s", entry.message.c_str());
        }
        if (ImGui::GetScrollY() >= ImGui::GetScrollMaxY()) {
            ImGui::SetScrollHereY(1.0f);
        }
        ImGui::EndChild();
    }
}
