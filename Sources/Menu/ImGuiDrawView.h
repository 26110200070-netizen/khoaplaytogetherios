#pragma once
#import <UIKit/UIKit.h>

@interface ImGuiDrawView : UIViewController
+ (void)showChange:(BOOL)open;
+ (BOOL)isMenuOpen;
+ (void)toggleMenu;
@end
