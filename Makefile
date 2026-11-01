export THEOS ?= $(HOME)/theos

ARCHS = arm64
TARGET := iphone:clang:latest:14.0
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = KhoaPlaytogether

$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation Metal MetalKit QuartzCore CoreGraphics Security SystemConfiguration

$(TWEAK_NAME)_CCFLAGS = -fno-rtti -fvisibility=hidden -DNDEBUG -std=c++17 -Wno-error -Wno-nontrivial-memcall -Wno-deprecated-declarations -Wno-module-import-in-extern-c -I./Sources -I./Includes -I./Includes/IMGUI
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Wno-error -Wno-nontrivial-memcall -Wno-deprecated-declarations -Wno-module-import-in-extern-c -Wno-unused-variable -Wno-unused-value -I./Sources -I./Includes -I./Includes/IMGUI

$(TWEAK_NAME)_LDFLAGS += -L./Libraries -ldobby -lz -liconv

$(TWEAK_NAME)_FILES = \
    Sources/Main.mm \
    Sources/Menu/ImGuiDrawView.mm \
    Sources/Menu/Menu.mm \
    Sources/Menu/JHPP.m \
    Sources/Menu/JHUIViewControllerDecoupler.m \
    Sources/Features/MainFeatures.mm \
    Sources/Features/FishingFeatures.mm \
    Sources/Features/InsectFeatures.mm \
    Sources/Features/MiningFeatures.mm \
    Sources/Features/FarmFeatures.mm \
    Sources/Features/PlayerFeatures.mm \
    Sources/Features/UtilityFeatures.mm \
    Sources/Features/MapFeatures.mm \
    Sources/Features/ESPFeatures.mm \
    Sources/Features/AntiBan.mm \
    Sources/Debug/DebugView.mm \
    Sources/Utils/Memory.mm \
    Includes/IMGUI/imgui.cpp \
    Includes/IMGUI/imgui_draw.cpp \
    Includes/IMGUI/imgui_tables.cpp \
    Includes/IMGUI/imgui_widgets.cpp \
    Includes/IMGUI/imgui_impl_metal.mm

include $(THEOS_MAKE_PATH)/tweak.mk

after-all::
	@echo "==> Copying $(TWEAK_NAME).dylib to project root..."
	@if [ -f .theos/obj/arm64/$(TWEAK_NAME).dylib ]; then \
		cp -f .theos/obj/arm64/$(TWEAK_NAME).dylib ./$(TWEAK_NAME).dylib; \
	elif [ -f $(THEOS_OBJ_DIR)/$(TWEAK_NAME).dylib ]; then \
		cp -f $(THEOS_OBJ_DIR)/$(TWEAK_NAME).dylib ./$(TWEAK_NAME).dylib; \
	fi
	@ls -lh ./$(TWEAK_NAME).dylib 2>/dev/null || true
	@echo "==> [READY] ./$(TWEAK_NAME).dylib sẵn sàng cho Esign / Sideloadly"

after-clean::
	@echo "==> Cleaning root dylib and .theos cache..."
	@rm -f ./$(TWEAK_NAME).dylib
	@rm -rf .theos packages

