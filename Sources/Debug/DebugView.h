#pragma once

namespace DebugView {
    void Initialize();
    void Render();
    
    // Test callbacks
    bool RunDobbyTest();
    bool RunMemoryTest();
    bool RunImGuiTest();
}
