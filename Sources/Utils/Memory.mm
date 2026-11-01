#import <Foundation/Foundation.h>
#include <stdlib.h>
#include <malloc/malloc.h>
#include <cstdlib>
#include <cstring>
#include <vector>
#include <sstream>
#import "Memory.h"
#import "Logging.h"

namespace Memory {

    ModuleInfo GetModuleInfo(const char* moduleName) {
        ModuleInfo info = { 0, nullptr, nullptr, 0, 0 };
        const uint32_t count = _dyld_image_count();

        if (!moduleName) {
            // Return main executable (image 0)
            if (count > 0) {
                info.index = 0;
                info.header = _dyld_get_image_header(0);
                info.name = _dyld_get_image_name(0);
                info.slide = _dyld_get_image_vmaddr_slide(0);
                info.baseAddress = (uintptr_t)info.header;
            }
            return info;
        }

        std::string target(moduleName);
        for (uint32_t i = 0; i < count; i++) {
            const char* name = _dyld_get_image_name(i);
            if (!name) continue;

            std::string fullPath(name);
            if (fullPath.find(target) != std::string::npos) {
                info.index = i;
                info.header = _dyld_get_image_header(i);
                info.name = name;
                info.slide = _dyld_get_image_vmaddr_slide(i);
                info.baseAddress = (uintptr_t)info.header;
                return info;
            }
        }
        return info;
    }

    uintptr_t GetModuleSlide(const char* moduleName) {
        ModuleInfo info = GetModuleInfo(moduleName);
        return info.slide;
    }

    uintptr_t GetAbsoluteAddress(const char* moduleName, uintptr_t offset) {
        ModuleInfo info = GetModuleInfo(moduleName);
        if (info.header == nullptr) {
            // Fallback to main app executable
            info = GetModuleInfo(nullptr);
        }
        if (info.header == nullptr) {
            return 0;
        }
        return info.baseAddress + offset;
    }

    uintptr_t GetRealOffset(uintptr_t offset) {
        // PlayTogether uses UnityFramework or Main executable for its il2cpp logic
        uintptr_t addr = GetAbsoluteAddress("UnityFramework", offset);
        if (addr == 0) {
            addr = GetAbsoluteAddress(nullptr, offset);
        }
        return addr;
    }

    bool SetMemoryProtection(uintptr_t address, size_t size, vm_prot_t protection) {
        kern_return_t kr = vm_protect(mach_task_self(),
                                      (mach_vm_address_t)address,
                                      size,
                                      false,
                                      protection);
        return (kr == KERN_SUCCESS);
    }

    bool WriteMemory(uintptr_t address, const void* data, size_t size) {
        if (!address || !data || size == 0) return false;

        mach_port_t port = mach_task_self();
        kern_return_t kr = vm_protect(port, (mach_vm_address_t)address, size, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
        if (kr != KERN_SUCCESS) return false;

        kr = vm_write(port, (mach_vm_address_t)address, (vm_offset_t)data, (mach_msg_type_number_t)size);
        vm_protect(port, (mach_vm_address_t)address, size, false, VM_PROT_READ | VM_PROT_EXECUTE);

        return (kr == KERN_SUCCESS);
    }

    bool ReadMemory(uintptr_t address, void* buffer, size_t size) {
        if (!address || !buffer || size == 0) return false;

        vm_size_t bytesRead = 0;
        kern_return_t kr = vm_read_overwrite(mach_task_self(),
                                             (mach_vm_address_t)address,
                                             size,
                                             (mach_vm_address_t)buffer,
                                             &bytesRead);
        return (kr == KERN_SUCCESS && bytesRead == size);
    }

    bool InstallHook(void* target, void* replacement, void** original, const char* name) {
        if (!target || !replacement) {
            std::stringstream ss;
            ss << "Hook failed: target or replacement null (" << (name ? name : "unknown") << ")";
            LOG_ERROR(ss.str());
            return false;
        }

        uintptr_t addr = (uintptr_t)target;
        if (addr < 0x100000000ULL) {
            std::stringstream ss;
            ss << "Hook skipped: target 0x" << std::hex << addr << " invalid pointer (" << (name ? name : "unknown") << ")";
            LOG_ERROR(ss.str());
            return false;
        }

        int result = DobbyHook(target, (dobby_dummy_func_t)replacement, (dobby_dummy_func_t*)original);
        std::stringstream ss;
        if (result == 0) {
            ss << "Hooked [" << (name ? name : "sub") << "] @ 0x" << std::hex << (uintptr_t)target;
            LOG_HOOK(ss.str());
            return true;
        } else {
            ss << "Failed to hook [" << (name ? name : "sub") << "] code=" << result;
            LOG_ERROR(ss.str());
            return false;
        }
    }

    // --------------------------------------------------------------------------
    // MemoryPatch implementation
    // --------------------------------------------------------------------------
    MemoryPatch::MemoryPatch() : m_address(0), m_size(0), m_originalBytes(nullptr), m_patchBytes(nullptr), m_applied(false) {}

    MemoryPatch::~MemoryPatch() {
        if (m_originalBytes) {
            ::free(m_originalBytes);
            m_originalBytes = nullptr;
        }
        if (m_patchBytes) {
            ::free(m_patchBytes);
            m_patchBytes = nullptr;
        }
    }

    MemoryPatch MemoryPatch::CreateWithBytes(uintptr_t address, const void* patchBytes, size_t size) {
        MemoryPatch patch;
        if (!address || !patchBytes || size == 0) return patch;

        patch.m_address = address;
        patch.m_size = size;
        patch.m_patchBytes = ::malloc(size);
        patch.m_originalBytes = ::malloc(size);

        if (patch.m_patchBytes && patch.m_originalBytes) {
            ::memcpy(patch.m_patchBytes, patchBytes, size);
            ReadMemory(address, patch.m_originalBytes, size);
        }
        return patch;
    }

    MemoryPatch MemoryPatch::CreateWithHex(const char* moduleName, uintptr_t offset, const std::string& hexBytes) {
        std::vector<uint8_t> bytes;
        std::stringstream ss(hexBytes);
        std::string byteStr;

        while (ss >> byteStr) {
            if (byteStr.length() == 2) {
                bytes.push_back((uint8_t)::strtoul(byteStr.c_str(), nullptr, 16));
            }
        }

        uintptr_t absAddr = GetAbsoluteAddress(moduleName, offset);
        if (absAddr == 0 || bytes.empty()) {
            return MemoryPatch();
        }
        return CreateWithBytes(absAddr, bytes.data(), bytes.size());
    }

    bool MemoryPatch::Modify() {
        if (!m_address || !m_patchBytes || m_size == 0) return false;
        if (WriteMemory(m_address, m_patchBytes, m_size)) {
            m_applied = true;
            return true;
        }
        return false;
    }

    bool MemoryPatch::Restore() {
        if (!m_address || !m_originalBytes || m_size == 0) return false;
        if (WriteMemory(m_address, m_originalBytes, m_size)) {
            m_applied = false;
            return true;
        }
        return false;
    }
}
