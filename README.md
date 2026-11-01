# KHOA PLAYTOGETHER – IMGUI IOS NON-JAILBREAK

Project Mod Menu ImGui dành cho **PlayTogether (VNG 2.33.0)** trên iOS (Non-Jailbreak, tiêm bằng Esign / Scarlet / TrollStore / Sideloadly).

---

## 1. Cấu Trúc Thư Mục

```text
KhoaPlaytogether/
├── Makefile                # Cấu hình build Theos cho arm64
├── control                 # Metadata package Debian/Theos
├── struct.txt              # Offset, RVA, Enums, Maps đã xác minh 100%
├── README.md               # Hướng dẫn build & sử dụng
├── Sources/
│   ├── Main.mm             # Entry point, loader, window & gesture hooks
│   ├── Menu/
│   │   ├── Menu.h / .mm    # Giao diện ImGui tabslide hiện đại (Trái: Tabs, Phải: Chức năng)
│   │   ├── ImGuiDrawView.h / .mm # Metal renderer & touch event forwarder
│   │   └── JHPP...         # Helper tìm ViewController
│   ├── Features/
│   │   ├── MainFeatures.h / .mm      # Auto bảo quản cá (0.3s), Đóng quà, Đóng hộp thẻ
│   │   ├── FishingFeatures.h / .mm   # Auto câu cá bóng 1-5, Minigame cá khổng lồ/quái vật
│   │   ├── MapFeatures.h / .mm       # Dịch chuyển 5 bản đồ (ID chuẩn)
│   │   └── AntiBan.h / .mm           # Triệt tiêu AntiCheatListener & spoof POSIX sign
│   ├── Debug/
│   │   └── DebugView.h / .mm         # Thông tin hệ thống, module, test Dobby & Memory
│   ├── Game/
│   │   ├── Offsets.h       # Danh sách RVA/VA từ UnityFramework
│   │   └── GameTypes.h     # Enums & Structs (FloatState, MapKind, HType)
│   └── Utils/
│       ├── Memory.h / .mm  # Trình đọc/ghi bộ nhớ, ASLR slide, Dobby hooks
│       └── Logging.h       # Hệ thống log thời gian thực cho tab Debug
├── Includes/
│   ├── dobby.h             # Dobby header
│   └── IMGUI/              # Dear ImGui + Metal backend + Vietnamese font (zzz.h)
└── Libraries/
    └── libdobby.a          # Static library Dobby arm64
```

---

## 2. Các Chức Năng Đã Triển Khai

1. **Tab Main:**
   - **Tự động bảo quản**: Bắt được cá sau `0.3s` tự động bấm nút `Bảo quản` (OnClick_ButtonClose) lưu vào kho.
   - **Đóng quà / hộp thẻ**: Tự động nhận quà và đóng các popup phần thưởng (`DialogRewardPopup`, `DialogResultGetItemView`).
   - **Trạng thái AntiBan**: Chặn toàn bộ gói tin báo cáo gian lận về server Haegin.

2. **Tab Câu Cá:**
   - **Auto câu cá thường (Bóng 1 - 5)**: Tự quăng cần -> Chờ dấu chấm than (!) -> Giật cần -> Cất cá -> Quăng cần lại liên tục.
   - **Cá khổng lồ & Quái vật (Minigame)**:
     - Khi cá giãy/bơi (`BigFish_Drag`): Tự động kéo lại dây.
     - Khi cá choáng (`BigFish_Stun`): Tự động giật cần liên tục với nhịp cực nhanh (mặc định `0.08s`) gọi `BigFishStunHit()` và `OnClickFishing()` để rút cạn HP quái vật.

3. **Tab Bản Đồ:**
   - Dịch chuyển tức thời đến 5 địa điểm đã xác minh trực tiếp từ `TableMap` / `Map_Kind`:
     - **Khu nghỉ dưỡng**: ID `1301` (`ResortIsland`)
     - **Cắm trại**: ID `1201` (`CampingZone`)
     - **Plaza**: ID `1001` (`Square`)
     - **Cống ngầm**: ID `1401` (`Sewer`)
     - **Down town**: ID `1502` (`DownTown`)
   - Gọi trực tiếp thông qua `LayerSystem.ConnectToZoneMove`.

4. **Tab Debug:**
   - Hiển thị phiên bản iOS, kiến trúc thiết bị (`arm64`), ASLR Slide, Mach-O header validation.
   - Hiển thị địa chỉ pointer `FishingFloatController` và `ActorDefaultControlPlayer`.
   - Các nút tự kiểm tra: `Test ImGui`, `Test Dobby Hook`, `Test Memory Protect`.
   - Terminal log hiển thị trực tiếp các sự kiện trong game.

---

## 3. Hướng Dẫn Build Bằng Theos Trên Google Cloud Shell

1. Nén hoặc tải thư mục `KhoaPlaytogether` lên Google Cloud Shell.
2. Mở terminal và chạy các lệnh:

```bash
cd KhoaPlaytogether
make clean
make
```

File dylib hoàn chỉnh sẽ được tạo tại `.theos/obj/debug/KhoaPlaytogether.dylib` (hoặc trong thư mục packages).
Dùng Esign trên iPhone để tiêm dylib này vào IPA của Play Together.
