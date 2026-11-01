#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Menu/ImGuiDrawView.h"
#import "Menu/JHPP.h"
#import "Features/AntiBan.h"
#import "Features/MainFeatures.h"
#import "Features/FishingFeatures.h"
#import "Features/MiningFeatures.h"
#import "Features/InsectFeatures.h"
#import "Features/FarmFeatures.h"
#import "Features/PlayerFeatures.h"
#import "Features/UtilityFeatures.h"
#import "Features/MapFeatures.h"
#import "Debug/DebugView.h"
#import "Utils/Logging.h"

@interface ModLoader : NSObject
@property (nonatomic, strong) ImGuiDrawView *drawView;
@end

@implementation ModLoader

static ModLoader *s_instance = nil;

+ (void)load {
    [super load];
    LOG_INFO("ModLoader: Constructor triggered, waiting for Unity runtime...");

    // Delay 5 seconds to ensure Unity runtime, Il2cpp and UI are ready
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        s_instance = [[ModLoader alloc] init];
        @try {
            [s_instance initializeSubsystems];
        } @catch (NSException *ex) {
            NSString *err = [NSString stringWithFormat:@"Subsystems exception: %@", ex.reason];
            LOG_ERROR([err UTF8String]);
        }

        [s_instance setupOverlayUI];
    });
}

- (void)initializeSubsystems {
    LOG_INFO("==================================================");
    LOG_INFO("KHOA PLAYTOGETHER MOD MENU - INITIALIZING");
    LOG_INFO("Target: PlayTogether 2.33.0 (iOS Non-Jailbreak)");
    LOG_INFO("==================================================");

    // 1. AntiBan (Highest priority: intercept reporting immediately)
    AntiBan::Initialize();

    // 2. Main Features (Auto Bảo Quản, Đóng Quà, Hộp Thẻ)
    MainFeatures::Initialize();

    // 3. Fishing Features (Auto Câu Cá Bóng 1-7 & Cá Khổng Lồ Minigame)
    FishingFeatures::Initialize();

    // 4. Mining & Excavation (Auto Đập Đá & Đào Kho Báu)
    MiningFeatures::Initialize();

    // 5. Insect Features (Auto Bắt Bọ & Côn Trùng)
    InsectFeatures::Initialize();

    // 6. Farm Features (Nông Trại & Thu Hoạch)
    FarmFeatures::Initialize();

    // 7. Player Features (SpeedHack, HighJump, NoClip)
    PlayerFeatures::Initialize();

    // 8. Utilities (Skip Ads 0s, Stream Mode)
    UtilityFeatures::Initialize();

    // 9. Map Features (Teleport 5 verified maps)
    MapFeatures::Initialize();

    // 10. Diagnostics
    DebugView::Initialize();

    LOG_SUCCESS("All subsystems successfully initialized and active!");
}

- (void)setupOverlayUI {
    UIWindow *mainWindow = [UIApplication sharedApplication].keyWindow;
    if (!mainWindow && [UIApplication sharedApplication].windows.count > 0) {
        mainWindow = [UIApplication sharedApplication].windows[0];
    }

    UIViewController *rootVC = mainWindow.rootViewController;
    if (!mainWindow || !rootVC) {
        LOG_WARN("KeyWindow or RootViewController not ready, retrying in 2s...");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setupOverlayUI];
        });
        return;
    }

    if (self.drawView) {
        return; // Already attached
    }

    @try {
        self.drawView = [[ImGuiDrawView alloc] init];
        [rootVC.view addSubview:self.drawView.view];

        // Gesture: 3-finger double tap to toggle menu
        UITapGestureRecognizer *threeFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onGestureToggle)];
        threeFingerTap.numberOfTouchesRequired = 3;
        threeFingerTap.numberOfTapsRequired = 2;
        [rootVC.view addGestureRecognizer:threeFingerTap];

        // Gesture: 2-finger double tap as alternative
        UITapGestureRecognizer *twoFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onGestureToggle)];
        twoFingerTap.numberOfTouchesRequired = 2;
        twoFingerTap.numberOfTapsRequired = 2;
        [rootVC.view addGestureRecognizer:twoFingerTap];

        LOG_SUCCESS("Overlay UI successfully attached to root view controller!");
    } @catch (NSException *ex) {
        NSString *err = [NSString stringWithFormat:@"UI setup exception: %@", ex.reason];
        LOG_ERROR([err UTF8String]);
    }
}

- (void)onGestureToggle {
    [ImGuiDrawView toggleMenu];
}

@end
