//
//  touchpeintureAppDelegate.m
//  touchpeinture
//
//  Created by sakira on 08/08/18.
//  Copyright 2008. All rights reserved.
//

#import "touchpeintureAppDelegate.h"
#import "touchpeintureViewController.h"
#import "constants.h"
#import "singletonjunction.h"

@implementation touchpeintureAppDelegate

@synthesize window;
@synthesize viewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {	
  application.statusBarHidden = YES;
  
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    SingletonJunction::penWidthMax = PenWidthMaxPhone;
  } else {
    SingletonJunction::penWidthMax = PenWidthMaxPad;
  }
  
#if 0
  [window addSubview:(UIView*)viewController.view];
  [window insertSubview:(UIView*)viewController.baseview atIndex:0];
  [window addSubview:(UIView*)viewController.panel_view];
  [window addSubview:(UIView*)viewController.opt_panel_view];
  [window addSubview:(UIView*)viewController.touchview];
  [window addSubview:(UIView*)viewController.loupe];
  [window addSubview:(UIView*)viewController.cross];
#endif
    //  [window addSubview:(UIView*)viewController.view];
	UIView *v = viewController.view;
//	UIView *v = window;
//  [window insertSubview:(UIView*)viewController.baseview atIndex:0];
  [v addSubview:(UIView*)viewController.baseview];
  [v addSubview:(UIView*)viewController.ptview];
  [v addSubview:(UIView*)viewController.panel_view];
  [v addSubview:(UIView*)viewController.opt_panel_view];
  [v addSubview:(UIView*)viewController.touchview];
  [v addSubview:(UIView*)viewController.loupe];
  [v addSubview:(UIView*)viewController.cross];
	[window addSubview:viewController.view];
  [window makeKeyAndVisible];
	
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
  [viewController setLoupeFollowsFinger:[def boolForKey:@"loupe_follow_preference"]];
  [viewController setShiftNozoom:[def boolForKey:@"shift_nozoom_preference"]];
  ALog(@"AppDelegate: application finish launching");
}

- (void)dealloc {
  [viewController release];
  [window release];
  [super dealloc];
}

- (void)applicationWillResignActive:(UIApplication *)application {
  [viewController.touchview applicationWillTerminate:application];
}

- (void)applicationWillTerminate:(UIApplication *)application {
  [viewController.touchview applicationWillTerminate:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
  [viewController setLoupeFollowsFinger:[def boolForKey:@"loupe_follow_preference"]];
  [viewController setShiftNozoom:[def boolForKey:@"shift_nozoom_preference"]];
}

@end
