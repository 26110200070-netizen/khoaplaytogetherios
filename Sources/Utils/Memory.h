#pragma once
#import <Foundation/Foundation.h>
#include <cstdint>
#include <cstddef>
#include <cstdlib>
#include <cstring>
#include <stdlib.h>
#include <string.h>
#include <malloc/malloc.h>
#include <string>
#include <mach-o/dyld.h>
#include <mach/mach.h>
#include "dobby.h"

namespace Memory {

    struct ModuleInfo {
        uint32_t index;
        const struct mach_header* header;
        const char* name;
        uintptr_t slide;
        uintptr_t baseAddress;
    };

    // Module slide discovery
    ModuleInfo GetModuleInfo(const char* moduleName = nullptr);
    uintptr_t GetModuleSlide(const char* moduleName = "UnityFramework");
    uintptr_t GetAbsoluteAddress(const char* moduleName, uintptr_t offset);
    uintptr_t GetRealOffset(uintptr_t offset);

    // Memory protection and writing
    bool SetMemoryProtection(uintptr_t address, size_t size, vm_prot_t protection);
    bool WriteMemory(uintptr_t address, const void* data, size_t size);
    bool ReadMemory(uintptr_t address, void* buffer, size_t size);

    // Dobby Hook Helper
    bool InstallHook(void* target, void* replacement, void** original, const char* name = nullptr);

    // Memory Patch Helper (KittyMemory style)
    class MemoryPatch {
    public:
        MemoryPatch();
        ~MemoryPatch();

        static MemoryPatch CreateWithBytes(uintptr_t address, const void* patchBytes, size_t size);
        static MemoryPatch CreateWithHex(const char* moduleName, uintptr_t offset, const std::string& hexBytes);

        bool Modify();
        bool Restore();
        bool IsApplied() const { return m_applied; }

    private:
        uintptr_t m_address;
        size_t m_size;
        void* m_originalBytes;
        void* m_patchBytes;
        bool m_applied;
    };
}

// Convenient Hook macros
#define HOOK_DEF(ret, name, ...) ret (*orig_##name)(__VA_ARGS__) = nullptr; ret hook_##name(__VA_ARGS__)
#define HOOK_OFFSET(offset, name) Memory::InstallHook((void*)Memory::GetRealOffset(offset), (void*)hook_##name, (void**)&orig_##name, #name)
