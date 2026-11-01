#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "ImGuiDrawView.h"
#import "Menu.h"
#import "Features/ESPFeatures.h"
#import "Features/FishingFeatures.h"
#import "Features/MainFeatures.h"
#import "Features/MiningFeatures.h"
#import "Features/InsectFeatures.h"
#import "Features/PlayerFeatures.h"
#import "Features/FarmFeatures.h"
#import "IMGUI/imgui.h"
#import "IMGUI/imgui_internal.h"
#import "IMGUI/imgui_impl_metal.h"
#import "IMGUI/zzz.h"
#import "Utils/Logging.h"

static bool g_menuOpen = true;
static CGRect g_menuRect = CGRectMake(50, 40, 620, 420);
static CGRect g_titleBarRect = CGRectMake(50, 40, 620, 45);

@interface PassthroughMTKView : MTKView
@property (nonatomic, weak) UIButton *toggleButton;
@end

@implementation PassthroughMTKView {
    CGPoint _touchStartPoint;
    CGPoint _touchLastPoint;
    BOOL _isScrolling;
    BOOL _isDraggingTitleBar;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // 1. Floating Toggle Button (KP)
    if (self.toggleButton && !self.toggleButton.hidden) {
        CGPoint btnPoint = [self convertPoint:point toView:self.toggleButton];
        if ([self.toggleButton pointInside:btnPoint withEvent:event]) {
            return [self.toggleButton hitTest:btnPoint withEvent:event];
        }
    }

    // 2. Menu Window Hit Test
    if (g_menuOpen) {
        if (CGRectContainsPoint(g_menuRect, point)) {
            return self;
        }
        ImGuiContext* g = ImGui::GetCurrentContext();
        if (g && ImGui::GetIO().MouseDown[0]) {
            return self;
        }
    }

    return nil; // Passthrough to game
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (!touch) return;

    CGPoint loc = [touch locationInView:self];
    _touchStartPoint = loc;
    _touchLastPoint = loc;
    _isScrolling = NO;

    if (CGRectContainsPoint(g_titleBarRect, loc)) {
        _isDraggingTitleBar = YES;
    } else {
        _isDraggingTitleBar = NO;
    }

    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(loc.x, loc.y);
    io.MouseDown[0] = true;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (!touch) return;

    CGPoint loc = [touch locationInView:self];
    ImGuiIO &io = ImGui::GetIO();

    CGFloat totalDeltaX = fabs(loc.x - _touchStartPoint.x);
    CGFloat totalDeltaY = fabs(loc.y - _touchStartPoint.y);

    if (!_isDraggingTitleBar && !_isScrolling) {
        // Natural touch scroll detection: predominantly vertical drag
        if (totalDeltaY > 8.0f && totalDeltaY > totalDeltaX * 1.1f) {
            _isScrolling = YES;
            io.MouseDown[0] = false; // Cancel click or slider interaction
        }
    }

    if (_isScrolling) {
        io.MouseDown[0] = false;
        io.MousePos = ImVec2(loc.x, loc.y);
        CGFloat deltaY = loc.y - _touchLastPoint.y;
        // Natural touch swipe: finger up (negative deltaY) -> scroll content down
        io.MouseWheel += (deltaY / 15.0f);
    } else {
        io.MousePos = ImVec2(loc.x, loc.y);
    }

    _touchLastPoint = loc;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch && !_isScrolling) {
        CGPoint loc = [touch locationInView:self];
        ImGuiIO &io = ImGui::GetIO();
        io.MousePos = ImVec2(loc.x, loc.y);
    }

    ImGuiIO &io = ImGui::GetIO();
    io.MouseDown[0] = false;
    _isScrolling = NO;
    _isDraggingTitleBar = NO;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    ImGuiIO &io = ImGui::GetIO();
    io.MouseDown[0] = false;
    _isScrolling = NO;
    _isDraggingTitleBar = NO;
}

@end

@interface ImGuiDrawView () <MTKViewDelegate>
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@property (nonatomic, strong) UIButton *toggleButton;
@end

@implementation ImGuiDrawView

+ (void)showChange:(BOOL)open {
    g_menuOpen = open;
}

+ (BOOL)isMenuOpen {
    return g_menuOpen;
}

+ (void)toggleMenu {
    g_menuOpen = !g_menuOpen;
}

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _device = MTLCreateSystemDefaultDevice();
        if (!_device) {
            LOG_ERROR("Metal is not supported on this device");
            return self;
        }

        _commandQueue = [_device newCommandQueue];

        IMGUI_CHECKVERSION();
        ImGui::CreateContext();
        ImGuiIO& io = ImGui::GetIO();
        (void)io;
        io.IniFilename = NULL; // Disable imgui.ini persistence on iOS

        Menu::Initialize();

        // Load compressed Vietnamese font (crisp 20.0f mobile sizing)
        ImFont* font = io.Fonts->AddFontFromMemoryCompressedTTF((void*)zzz_compressed_data,
                                                                zzz_compressed_size,
                                                                20.0f,
                                                                NULL,
                                                                io.Fonts->GetGlyphRangesVietnamese());
        if (!font) {
            LOG_WARN("Failed to load compressed Vietnamese font, falling back to default font");
            io.Fonts->AddFontDefault();
        }

        ImGui_ImplMetal_Init(_device);
        LOG_SUCCESS("ImGui Metal Backend initialized successfully");
    }
    return self;
}

- (MTKView *)mtkView {
    return (MTKView *)self.view;
}

- (void)loadView {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    self.view = [[PassthroughMTKView alloc] initWithFrame:screenBounds device:self.device];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor clearColor];
    self.mtkView.clipsToBounds = YES;

    // Create floating draggable button for toggling menu on mobile
    CGFloat btnSize = 44.0;
    self.toggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.toggleButton.frame = CGRectMake(20, 100, btnSize, btnSize);
    self.toggleButton.layer.cornerRadius = btnSize / 2.0;
    self.toggleButton.layer.borderWidth = 1.5;
    self.toggleButton.layer.borderColor = [UIColor colorWithRed:0.26 green:0.70 blue:0.98 alpha:0.9].CGColor;
    self.toggleButton.backgroundColor = [UIColor colorWithRed:0.08 green:0.10 blue:0.14 alpha:0.85];
    [self.toggleButton setTitle:@"KP" forState:UIControlStateNormal];
    [self.toggleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.toggleButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];

    [self.toggleButton addTarget:self action:@selector(onToggleButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onButtonPan:)];
    [self.toggleButton addGestureRecognizer:pan];

    [self.view addSubview:self.toggleButton];
    ((PassthroughMTKView *)self.view).toggleButton = self.toggleButton;
}

- (void)onToggleButtonTapped {
    g_menuOpen = !g_menuOpen;
}

- (void)onButtonPan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.view];
    pan.view.center = CGPointMake(pan.view.center.x + translation.x, pan.view.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:self.view];
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
}

- (void)drawInMTKView:(MTKView*)view {
    if (!self.device || !self.commandQueue) return;

    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;

    CGFloat scale = view.window.screen.scale ?: [UIScreen mainScreen].scale;
    io.DisplayFramebufferScale = ImVec2(scale, scale);
    io.DeltaTime = 1.0f / (float)(view.preferredFramesPerSecond ?: 60);

    id<CAMetalDrawable> drawable = view.currentDrawable;
    MTLRenderPassDescriptor* renderPassDesc = view.currentRenderPassDescriptor;

    if (renderPassDesc != nil && drawable != nil) {
        id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
        if (!commandBuffer) return;

        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
        if (renderEncoder) {
            [renderEncoder pushDebugGroup:@"KhoaPlaytogether_ImGui"];

            ImGui_ImplMetal_NewFrame(renderPassDesc);
            ImGui::NewFrame();

            // Run active automation loops (Auto Câu, Auto Bảo Quản, Đập Đá, Bắt Bọ, Player Mods, Nông Trại, ESP)
            MainFeatures::Update();
            FishingFeatures::Update();
            MiningFeatures::Update();
            InsectFeatures::Update();
            PlayerFeatures::Update();
            FarmFeatures::Update();
            ESPFeatures::Update();

            // Render ESP overlays
            ESPFeatures::RenderESP();

            // Render Menu
            if (g_menuOpen) {
                Menu::Render(&g_menuOpen);

                ImGuiWindow* window = ImGui::FindWindowByName("KHOA PLAYTOGETHER - IMGUI iOS [Non-Jailbreak]###Play Together VNG");
                if (!window) {
                    window = ImGui::FindWindowByName("Play Together VNG");
                }
                if (window) {
                    g_menuRect = CGRectMake(window->Pos.x, window->Pos.y, window->Size.x, window->Size.y);
                    g_titleBarRect = CGRectMake(window->Pos.x, window->Pos.y, window->Size.x, window->TitleBarHeight());
                }
            }

            ImGui::Render();
            ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(), commandBuffer, renderEncoder);

            [renderEncoder popDebugGroup];
            [renderEncoder endEncoding];
            [commandBuffer presentDrawable:drawable];
        }
        [commandBuffer commit];
    }
}

@end
